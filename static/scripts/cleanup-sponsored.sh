#!/bin/bash
# Quick Cleanup Sponsored Workshop - Automated Cleanup Script
#
# PURPOSE: This script provides automated cleanup of resources deployed by
#          quick-deploy-sponsored.sh in AWS-sponsored workshop environments.
#
# USAGE: ./cleanup-sponsored.sh
#
# This script safely removes:
# - GenAI workloads (vLLM + WebUI deployments)
# - Inferentia nodepool (optional)
# - FSx Lustre PVCs and PVs
# - Dynamic FSx StorageClass (optional)
# - Helm charts (FSx CSI Driver, Neuron components)
# - Provides verification commands and troubleshooting guidance
#
set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to check if kubectl is accessible
check_kubectl_access() {
    if kubectl cluster-info &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to safely run kubectl commands
safe_kubectl() {
    if check_kubectl_access; then
        "$@"
    else
        log_warn "Cluster not accessible, skipping: $*"
    fi
}

# Function to check if resource exists
resource_exists() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-default}
    
    if [[ -n "$namespace" && "$namespace" != "default" ]]; then
        kubectl get "$resource_type" "$resource_name" -n "$namespace" &>/dev/null
    else
        kubectl get "$resource_type" "$resource_name" &>/dev/null
    fi
}

# Function to wait for resource deletion
wait_for_deletion() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-default}
    local timeout=${4:-300}
    
    log_info "Waiting for $resource_type/$resource_name to be deleted..."
    
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if ! resource_exists "$resource_type" "$resource_name" "$namespace"; then
            log_info "$resource_type/$resource_name deleted successfully"
            return 0
        fi
        
        sleep 10
        elapsed=$((elapsed + 10))
        
        if [ $((elapsed % 60)) -eq 0 ]; then
            log_info "Still waiting for $resource_type/$resource_name deletion... (${elapsed}s elapsed)"
        fi
    done
    
    log_warn "Timeout waiting for $resource_type/$resource_name deletion"
    return 1
}

# Main cleanup function
main() {
    log_step "Starting Sponsored Workshop Cleanup..."
    
    # Validate kubectl access
    if ! check_kubectl_access; then
        log_error "Cannot access Kubernetes cluster"
        log_error "Please ensure kubectl is configured and cluster is accessible"
        exit 1
    fi
    
    # Get cluster info
    CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2 2>/dev/null || echo "unknown")
    log_info "Connected to cluster: $CLUSTER_NAME"
    
    # Ask user for confirmation
    echo ""
    log_warn "This script will clean up the following workshop resources:"
    echo "  - GenAI workloads (vLLM Mistral deployment, WebUI)"
    echo "  - Kubernetes services and ingresses"
    echo "  - FSx Lustre PVCs and PVs"
    echo "  - Inferentia nodepool (optional)"
    echo "  - Dynamic FSx StorageClass (optional)"
    echo "  - Helm charts (FSx CSI Driver, Neuron components) (optional)"
    echo ""
    log_warn "Note: This will NOT delete the EKS cluster or core infrastructure"
    echo ""
    
    read -p "Are you sure you want to proceed with cleanup? (yes/no): " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
        log_info "Cleanup cancelled by user"
        exit 0
    fi
    
    # Step 1: Clean up GenAI workloads
    log_step "Step 1: Cleaning up GenAI workloads"
    
    # Delete WebUI deployment
    if resource_exists "deployment" "open-webui-deployment"; then
        log_info "Deleting WebUI deployment..."
        safe_kubectl kubectl delete deployment open-webui-deployment
        safe_kubectl kubectl delete service open-webui-service --ignore-not-found=true
        safe_kubectl kubectl delete ingress open-webui-ingress --ignore-not-found=true
        safe_kubectl kubectl delete ingressclass alb --ignore-not-found=true
        safe_kubectl kubectl delete ingressclassparams alb --ignore-not-found=true
        log_info "WebUI resources deleted"
    else
        log_info "WebUI deployment not found"
    fi
    
    # Delete vLLM deployment
    if resource_exists "deployment" "vllm-mistral-inf2-deployment"; then
        log_info "Deleting vLLM Mistral deployment..."
        safe_kubectl kubectl delete deployment vllm-mistral-inf2-deployment
        safe_kubectl kubectl delete service vllm-mistral7b-service --ignore-not-found=true
        
        # Wait for pods to terminate
        log_info "Waiting for vLLM pods to terminate..."
        safe_kubectl kubectl wait --for=delete pod -l app=vllm-mistral-inf2-server --timeout=300s || log_warn "Timeout waiting for vLLM pods to terminate"
        log_info "vLLM resources deleted"
    else
        log_info "vLLM deployment not found"
    fi
    
    # Step 2: Clean up FSx Lustre resources
    log_step "Step 2: Cleaning up FSx Lustre resources"
    
    # Delete main FSx PVC first
    if resource_exists "pvc" "fsx-lustre-claim"; then
        log_info "Deleting FSx Lustre PVC..."
        safe_kubectl kubectl delete pvc fsx-lustre-claim
        wait_for_deletion "pvc" "fsx-lustre-claim" "default" 300
    else
        log_info "FSx Lustre PVC not found"
    fi
    
    # Handle FSx PV cleanup (fix claimRef issue)
    if resource_exists "pv" "fsx-pv"; then
        PV_STATUS=$(kubectl get pv fsx-pv -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
        log_info "FSx PV current status: $PV_STATUS"
        
        if [[ "$PV_STATUS" == "Released" ]]; then
            log_warn "FSx PV is in Released status (has stale claimRef)"
            echo ""
            log_info "PV cleanup options:"
            echo "  1. Clear claimRef (make PV available for reuse)"
            echo "  2. Delete PV completely"
            echo "  3. Leave PV as-is (manual cleanup required)"
            echo ""
            read -p "Choose option (1-3): " PV_CLEANUP_OPTION
            
            case "$PV_CLEANUP_OPTION" in
                1)
                    log_info "Clearing claimRef to make PV available for reuse..."
                    if kubectl patch pv fsx-pv --type json -p='[{"op": "remove", "path": "/spec/claimRef"}]' 2>/dev/null; then
                        log_info "ClaimRef cleared successfully"
                        
                        # Verify PV is now Available
                        sleep 3
                        NEW_PV_STATUS=$(kubectl get pv fsx-pv -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
                        if [[ "$NEW_PV_STATUS" == "Available" ]]; then
                            log_info "✓ FSx PV is now Available for reuse"
                        else
                            log_warn "FSx PV status: $NEW_PV_STATUS (may need time to update)"
                        fi
                    else
                        log_error "Failed to clear claimRef"
                        log_info "Manual command: kubectl patch pv fsx-pv --type json -p='[{\"op\": \"remove\", \"path\": \"/spec/claimRef\"}]'"
                    fi
                    ;;
                2)
                    log_info "Deleting FSx PV completely..."
                    safe_kubectl kubectl delete pv fsx-pv
                    wait_for_deletion "pv" fsx-pv "" 300
                    log_warn "PV deleted - you'll need to recreate it for future deployments"
                    ;;
                3|*)
                    log_info "Leaving FSx PV as-is"
                    log_info "Manual cleanup command:"
                    echo "  kubectl patch pv fsx-pv --type json -p='[{\"op\": \"remove\", \"path\": \"/spec/claimRef\"}]'"
                    ;;
            esac
            
        elif [[ "$PV_STATUS" == "Available" ]]; then
            log_info "✓ FSx PV is already Available for reuse"
            
        elif [[ "$PV_STATUS" == "Bound" ]]; then
            log_warn "FSx PV is currently Bound - skipping deletion"
            log_info "Delete the associated PVC first if you want to clean up this PV"
            
        else
            read -p "Delete FSx PV (status: $PV_STATUS)? (y/N): " DELETE_PV
            if [[ "$DELETE_PV" =~ ^[Yy]$ ]]; then
                log_info "Deleting FSx PV..."
                safe_kubectl kubectl delete pv fsx-pv
                wait_for_deletion "pv" fsx-pv "" 300
            else
                log_info "Preserving FSx PV"
            fi
        fi
    else
        log_info "FSx PV not found"
    fi
    
    # Step 3: Optional dynamic FSx cleanup
    log_step "Step 3: Dynamic FSx Lustre cleanup (optional)"
    
    DYNAMIC_FSX_EXISTS=false
    if resource_exists "pvc" "fsx-lustre-dynamic-claim" || resource_exists "storageclass" "fsx-lustre-sc"; then
        DYNAMIC_FSX_EXISTS=true
    fi
    
    if [[ "$DYNAMIC_FSX_EXISTS" == true ]]; then
        echo ""
        log_info "Found dynamic FSx Lustre resources"
        read -p "Delete dynamic FSx Lustre resources (PVC, StorageClass)? (y/N): " DELETE_DYNAMIC_FSX
        
        if [[ "$DELETE_DYNAMIC_FSX" =~ ^[Yy]$ ]]; then
            # Delete dynamic PVC
            if resource_exists "pvc" "fsx-lustre-dynamic-claim"; then
                log_info "Deleting dynamic FSx Lustre PVC..."
                safe_kubectl kubectl delete pvc fsx-lustre-dynamic-claim
                wait_for_deletion "pvc" "fsx-lustre-dynamic-claim" "default" 600
            fi
            
            # Delete StorageClass
            if resource_exists "storageclass" "fsx-lustre-sc"; then
                log_info "Deleting FSx Lustre StorageClass..."
                safe_kubectl kubectl delete storageclass fsx-lustre-sc
                log_info "StorageClass deleted"
            fi
            
            log_info "Dynamic FSx resources cleaned up"
        else
            log_info "Preserving dynamic FSx resources"
        fi
    else
        log_info "No dynamic FSx resources found"
    fi
    
    # Step 4: Optional Inferentia nodepool cleanup
    log_step "Step 4: Inferentia nodepool cleanup (optional)"
    
    if resource_exists "nodepool" "inferentia"; then
        echo ""
        log_warn "Found Inferentia nodepool"
        log_warn "Deleting nodepool will terminate all Inferentia nodes"
        read -p "Delete Inferentia nodepool? (y/N): " DELETE_NODEPOOL
        
        if [[ "$DELETE_NODEPOOL" =~ ^[Yy]$ ]]; then
            log_info "Deleting Inferentia nodepool..."
            safe_kubectl kubectl delete nodepool inferentia
            
            log_info "Waiting for nodepool deletion (this may take several minutes)..."
            wait_for_deletion "nodepool" "inferentia" "" 900
            log_info "Inferentia nodepool deleted"
        else
            log_info "Preserving Inferentia nodepool"
        fi
    else
        log_info "Inferentia nodepool not found"
    fi
    
    # Step 5: Optional Helm chart cleanup
    log_step "Step 5: Helm chart cleanup (optional)"
    
    echo ""
    log_warn "Helm chart cleanup options:"
    echo "  - FSx CSI Driver (may affect other FSx usage)"
    echo "  - Neuron components (may affect other Inferentia workloads)"
    echo ""
    read -p "Delete Helm charts (FSx CSI Driver, Neuron components)? (y/N): " DELETE_HELM
    
    if [[ "$DELETE_HELM" =~ ^[Yy]$ ]]; then
        # Delete Neuron Helm chart
        if helm list -n kube-system | grep -q neuron-helm-chart; then
            log_info "Uninstalling Neuron Helm chart..."
            helm uninstall neuron-helm-chart -n kube-system
            log_info "Neuron Helm chart uninstalled"
        else
            log_info "Neuron Helm chart not found"
        fi
        
        # Delete FSx CSI Driver
        if helm list -n kube-system | grep -q aws-fsx-csi-driver; then
            log_info "Uninstalling FSx CSI Driver..."
            helm uninstall aws-fsx-csi-driver -n kube-system
            log_info "FSx CSI Driver uninstalled"
        else
            log_info "FSx CSI Driver not found"
        fi
    else
        log_info "Preserving Helm charts"
    fi
    
    # Step 6: Cleanup summary and verification
    log_step "Cleanup Summary"
    
    log_info "Cleanup completed successfully!"
    echo ""
    log_info "Resources cleaned up:"
    echo "  ✓ GenAI workloads (vLLM, WebUI)"
    echo "  ✓ FSx Lustre PVCs and PVs"
    
    if [[ "$DELETE_DYNAMIC_FSX" =~ ^[Yy]$ ]]; then
        echo "  ✓ Dynamic FSx resources"
    else
        echo "  - Dynamic FSx resources (preserved)"
    fi
    
    if [[ "$DELETE_NODEPOOL" =~ ^[Yy]$ ]]; then
        echo "  ✓ Inferentia nodepool"
    else
        echo "  - Inferentia nodepool (preserved)"
    fi
    
    if [[ "$DELETE_HELM" =~ ^[Yy]$ ]]; then
        echo "  ✓ Helm charts"
    else
        echo "  - Helm charts (preserved)"
    fi
    
    echo ""
    log_info "Verification commands:"
    echo "  # Check remaining deployments:"
    echo "  kubectl get deployments"
    echo ""
    echo "  # Check remaining PVCs:"
    echo "  kubectl get pvc"
    echo ""
    echo "  # Check remaining nodepools:"
    echo "  kubectl get nodepool"
    echo ""
    echo "  # Check Helm releases:"
    echo "  helm list -A"
    echo ""
    
    log_info "Note: EKS cluster and core infrastructure remain intact"
    log_info "Workshop environment is ready for re-deployment if needed"
    echo ""
    
    # Clean up any temporary files that might have been left behind
    log_info "Cleaning up temporary files..."
    cd /home/participant/environment/eks/genai 2>/dev/null || true
    rm -f mistral-fsxl-temp.yaml mistral-fsxl-display.yaml 2>/dev/null || true
    log_info "Temporary files cleaned up"
    echo ""
    
    log_info "To re-deploy workshop components, run:"
    echo "  ./quick-deploy-sponsored.sh"
    echo ""
    
    log_info "Cleanup script completed!"
}

# Run main function
main "$@"