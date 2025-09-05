#!/bin/bash
# Quick Cleanup On-demand Workshop - Automated Cleanup Script
#
# PURPOSE: This script provides automated cleanup of all resources created by
#          quick-deploy-on-demand.sh or manual workshop setup.
#
# USAGE: ./cleanup-on-demand.sh
#
# This script safely removes:
# - CloudFormation stack and all AWS resources
# - S3 bucket and workshop files (optional)
# - Local workshop files and temporary data (optional)
# - Provides verification commands and troubleshooting guidance
#
set -e  # Exit on any error

# Disable AWS CLI pager to prevent terminal hanging on large outputs
export AWS_PAGER=""

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

# Function to wait for CloudFormation stack deletion
wait_for_stack_deletion() {
    local stack_name=$1
    local timeout=${2:-3600}  # Default 60 minutes for deletion (EKS + FSx can take long)
    local check_interval=60   # Check every minute for deletion
    local elapsed=0
    
    log_info "Waiting for CloudFormation stack ${stack_name} to be deleted..."
    log_info "Started at: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "Expected deletion time: 20-45 minutes (timeout after 60 minutes)"
    log_info "Complex resources (EKS cluster, FSx file system) take longer to delete"
    
    while [ $elapsed -lt $timeout ]; do
        local stack_status=$(aws cloudformation describe-stacks --stack-name "${stack_name}" --region $AWS_REGION --query 'Stacks[0].StackStatus' --output text 2>/dev/null)
        
        case "$stack_status" in
            "DELETE_COMPLETE")
                local total_minutes=$((elapsed / 60))
                local total_seconds=$((elapsed % 60))
                log_info "CloudFormation stack ${stack_name} deleted successfully"
                log_info "Total deletion time: ${total_minutes}m ${total_seconds}s"
                return 0
                ;;
            "DELETE_IN_PROGRESS")
                local minutes_elapsed=$((elapsed / 60))
                local seconds_in_current_minute=$((elapsed % 60))
                local minutes_remaining=$(((timeout - elapsed) / 60))
                log_info "CloudFormation stack ${stack_name} deletion in progress"
                log_info "Time elapsed: ${minutes_elapsed}m ${seconds_in_current_minute}s | Timeout in: ${minutes_remaining} minutes"
                
                # Show progress updates every 5 minutes
                if [ $((elapsed % 300)) -eq 0 ] && [ $elapsed -gt 0 ]; then
                    log_info "=== Deletion Progress Update (${minutes_elapsed} minutes elapsed) ==="
                    
                    # Show milestone messages for deletion
                    if [ $minutes_elapsed -eq 5 ]; then
                        log_info "🔄 Initial resource deletion in progress..."
                    elif [ $minutes_elapsed -eq 15 ]; then
                        log_info "🔄 EKS node groups and worker nodes being terminated..."
                    elif [ $minutes_elapsed -eq 25 ]; then
                        log_info "🔄 EKS cluster deletion in progress..."
                    elif [ $minutes_elapsed -eq 35 ]; then
                        log_info "🔄 FSx file system and VPC resources being deleted..."
                    elif [ $minutes_elapsed -ge 45 ]; then
                        log_info "⏳ Final cleanup in progress, almost complete..."
                    fi
                    
                    log_info "Recent stack events:"
                    aws cloudformation describe-stack-events --stack-name "${stack_name}" --region $AWS_REGION --query 'StackEvents[0:5].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' --output table 2>/dev/null || true
                    log_info "=============================================="
                fi
                
                sleep $check_interval
                elapsed=$((elapsed + check_interval))
                ;;
            "DELETE_FAILED")
                log_error "CloudFormation stack ${stack_name} deletion failed"
                log_error "Failed resources and reasons:"
                aws cloudformation describe-stack-events --stack-name "${stack_name}" --region $AWS_REGION --query 'StackEvents[?ResourceStatus==`DELETE_FAILED`].[LogicalResourceId,ResourceStatusReason]' --output table
                log_error "For detailed troubleshooting, check the CloudFormation console:"
                echo "  https://console.aws.amazon.com/cloudformation/home?region=${AWS_REGION}#/stacks/stackinfo?stackId=${stack_name}"
                return 1
                ;;
            "")
                log_info "CloudFormation stack ${stack_name} not found (already deleted)"
                return 0
                ;;
            *)
                log_warn "CloudFormation stack ${stack_name} has unexpected status: ${stack_status}"
                sleep $check_interval
                elapsed=$((elapsed + check_interval))
                ;;
        esac
    done
    
    log_error "Timeout waiting for CloudFormation stack ${stack_name} to be deleted after ${timeout} seconds (60 minutes)"
    log_error "Complex resources like EKS clusters and FSx file systems can take longer than expected"
    log_error "Check the CloudFormation console to monitor remaining resources"
    return 1
}

# Function to check if CloudFormation stack exists
check_stack_exists() {
    local stack_name=$1
    
    if aws cloudformation describe-stacks --stack-name "${stack_name}" --region $AWS_REGION &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to check if S3 bucket exists
check_bucket_exists() {
    local bucket_name=$1
    
    if aws s3api head-bucket --bucket "${bucket_name}" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to empty S3 bucket
empty_s3_bucket() {
    local bucket_name=$1
    
    log_info "Emptying S3 bucket: ${bucket_name}"
    
    # Delete all objects including versions and delete markers
    aws s3api list-object-versions --bucket "${bucket_name}" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output text | while read key version_id; do
        if [[ -n "$key" && "$key" != "None" ]]; then
            aws s3api delete-object --bucket "${bucket_name}" --key "$key" --version-id "$version_id" >/dev/null 2>&1 || true
        fi
    done
    
    # Delete delete markers
    aws s3api list-object-versions --bucket "${bucket_name}" --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output text | while read key version_id; do
        if [[ -n "$key" && "$key" != "None" ]]; then
            aws s3api delete-object --bucket "${bucket_name}" --key "$key" --version-id "$version_id" >/dev/null 2>&1 || true
        fi
    done
    
    # Use s3 rm as backup
    aws s3 rm s3://${bucket_name} --recursive >/dev/null 2>&1 || true
    
    log_info "S3 bucket ${bucket_name} emptied"
}

# Function to delete S3 bucket
delete_s3_bucket() {
    local bucket_name=$1
    
    log_info "Deleting S3 bucket: ${bucket_name}"
    
    # First empty the bucket
    empty_s3_bucket "$bucket_name"
    
    # Then delete the bucket
    aws s3api delete-bucket --bucket "${bucket_name}" --region $AWS_REGION
    
    log_info "S3 bucket ${bucket_name} deleted"
}

# Main cleanup function
main() {
    log_step "Starting On-demand Workshop Cleanup..."
    
    # Get AWS region
    log_info "Detecting AWS region..."
    export TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
    export AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
    
    if [[ -z "$AWS_REGION" ]]; then
        log_error "Failed to detect AWS region from instance metadata"
        read -p "Please enter your AWS region (e.g., us-east-1): " AWS_REGION
        if [[ -z "$AWS_REGION" ]]; then
            log_error "AWS region is required"
            exit 1
        fi
    fi
    
    log_info "Using AWS Region: $AWS_REGION"
    
    # Validate AWS credentials
    if ! aws sts get-caller-identity &>/dev/null; then
        log_error "AWS credentials not configured or invalid"
        exit 1
    fi
    
    # Define resource names (same as in deployment script)
    STACK_NAME=GenAIFSXWorkshopOnEKS
    
    # Ask user for confirmation
    echo ""
    log_warn "This script will delete the following resources:"
    echo "  - CloudFormation stack: ${STACK_NAME}"
    echo "  - All resources created by the stack (EKS cluster, FSx, VPC, etc.)"
    echo "  - S3 bucket (optional - you will be asked)"
    echo "  - Local workshop files (optional - you will be asked)"
    echo ""
    
    read -p "Are you sure you want to proceed with cleanup? (yes/no): " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
        log_info "Cleanup cancelled by user"
        exit 0
    fi
    
    # Step 1: Delete CloudFormation stack
    log_step "Step 1: Deleting CloudFormation stack"
    
    if check_stack_exists "$STACK_NAME"; then
        log_info "Found CloudFormation stack: ${STACK_NAME}"
        
        # Show stack resources before deletion
        log_info "Stack resources to be deleted:"
        aws cloudformation describe-stack-resources --stack-name "${STACK_NAME}" --region $AWS_REGION --query 'StackResources[].{Type:ResourceType,LogicalId:LogicalResourceId,Status:ResourceStatus}' --output table 2>/dev/null || true
        
        echo ""
        read -p "Proceed with CloudFormation stack deletion? (yes/no): " DELETE_STACK
        if [[ "$DELETE_STACK" == "yes" ]]; then
            log_info "Initiating CloudFormation stack deletion..."
            aws cloudformation delete-stack --stack-name "${STACK_NAME}" --region $AWS_REGION
            
            log_info "Waiting for stack deletion to complete..."
            if wait_for_stack_deletion "$STACK_NAME" 3600; then
                log_info "CloudFormation stack deleted successfully"
            else
                log_error "CloudFormation stack deletion failed or timed out after 60 minutes"
                log_error "This is not uncommon with complex infrastructure (EKS + FSx + VPC)"
                echo ""
                log_info "Common issues and solutions:"
                echo "  - EKS cluster: May need manual deletion if it has active workloads or stuck resources"
                echo "  - FSx file system: Check for active mount targets or backup processes"
                echo "  - VPC: Ensure no ENIs, NAT gateways, or other resources are still using it"
                echo "  - Security groups: Check for circular dependencies or attached resources"
                echo "  - IAM roles: May have active sessions or attached policies"
                echo ""
                log_info "Recommended actions:"
                echo "  1. Check CloudFormation console for specific stuck resources"
                echo "  2. Manually delete stuck resources if safe to do so"
                echo "  3. Retry stack deletion after manual cleanup"
                echo "  4. Contact AWS support if resources appear stuck without reason"
                echo ""
                read -p "Continue with S3 cleanup despite stack deletion issues? (yes/no): " CONTINUE_CLEANUP
                if [[ "$CONTINUE_CLEANUP" != "yes" ]]; then
                    log_warn "Cleanup paused. Address CloudFormation issues before continuing."
                    log_info "You can re-run this script later to complete S3 and local cleanup."
                    exit 1
                fi
            fi
        else
            log_info "Skipping CloudFormation stack deletion"
        fi
    else
        log_info "CloudFormation stack ${STACK_NAME} not found (already deleted or never created)"
    fi
    
    # Step 2: Handle S3 bucket cleanup
    log_step "Step 2: S3 bucket cleanup"
    
    read -p "Enter the S3 bucket name used for the workshop (or press Enter to skip): " ASSET_BUCKET
    
    if [[ -n "$ASSET_BUCKET" ]]; then
        if check_bucket_exists "$ASSET_BUCKET"; then
            log_info "Found S3 bucket: ${ASSET_BUCKET}"
            
            # Check for workshop-specific content
            log_info "Checking for workshop content in bucket..."
            
            WORKSHOP_FOLDER_EXISTS=false
            MISTRAL_MODEL_EXISTS=false
            
            # Check for workshop folder
            if aws s3 ls s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto/ &>/dev/null; then
                WORKSHOP_FOLDER_EXISTS=true
                log_info "✓ Found workshop folder: genai-fsx-workshop-on-eks-auto/"
            fi
            
            # Check for Mistral model
            if aws s3 ls s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto/assets/Mistral-7B-Instruct-v0.2/ &>/dev/null; then
                MISTRAL_MODEL_EXISTS=true
                log_info "✓ Found Mistral model: genai-fsx-workshop-on-eks-auto/assets/Mistral-7B-Instruct-v0.2/"
            fi
            
            if [[ "$WORKSHOP_FOLDER_EXISTS" == false && "$MISTRAL_MODEL_EXISTS" == false ]]; then
                log_info "No workshop content found in this bucket"
                read -p "Delete the entire S3 bucket ${ASSET_BUCKET}? (yes/no): " DELETE_ENTIRE_BUCKET
                
                if [[ "$DELETE_ENTIRE_BUCKET" == "yes" ]]; then
                    log_warn "WARNING: This will permanently delete the entire bucket and all its contents!"
                    read -p "Are you absolutely sure? Type 'DELETE' to confirm: " CONFIRM_DELETE
                    
                    if [[ "$CONFIRM_DELETE" == "DELETE" ]]; then
                        delete_s3_bucket "$ASSET_BUCKET"
                        log_info "S3 bucket deleted completely"
                    else
                        log_info "Bucket deletion cancelled"
                    fi
                else
                    log_info "S3 bucket preserved"
                fi
            else
                echo ""
                log_info "Workshop content cleanup options:"
                
                if [[ "$WORKSHOP_FOLDER_EXISTS" == true ]]; then
                    echo "  1. Delete workshop folder only (genai-fsx-workshop-on-eks-auto/)"
                else
                    echo "  1. Delete workshop folder only (not found - unavailable)"
                fi
                
                if [[ "$MISTRAL_MODEL_EXISTS" == true ]]; then
                    echo "  2. Delete Mistral model only (~7GB)"
                else
                    echo "  2. Delete Mistral model only (not found - unavailable)"
                fi
                
                echo "  3. Delete all workshop content (folder + model)"
                echo "  4. Delete entire bucket and all contents"
                echo "  5. Keep everything (no deletion)"
                echo ""
                
                read -p "Choose option (1-5): " CLEANUP_OPTION
                
                case "$CLEANUP_OPTION" in
                    1)
                        if [[ "$WORKSHOP_FOLDER_EXISTS" == true ]]; then
                            log_info "Deleting workshop folder..."
                            aws s3 rm s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto/ --recursive --exclude "assets/Mistral-7B-Instruct-v0.2/*"
                            log_info "Workshop folder deleted (Mistral model preserved)"
                        else
                            log_warn "Workshop folder not found - nothing to delete"
                        fi
                        ;;
                    2)
                        if [[ "$MISTRAL_MODEL_EXISTS" == true ]]; then
                            log_info "Deleting Mistral model (~7GB)..."
                            aws s3 rm s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto/assets/Mistral-7B-Instruct-v0.2/ --recursive
                            log_info "Mistral model deleted"
                        else
                            log_warn "Mistral model not found - nothing to delete"
                        fi
                        ;;
                    3)
                        if [[ "$WORKSHOP_FOLDER_EXISTS" == true || "$MISTRAL_MODEL_EXISTS" == true ]]; then
                            log_info "Deleting all workshop content..."
                            aws s3 rm s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto/ --recursive
                            log_info "All workshop content deleted"
                        else
                            log_warn "No workshop content found - nothing to delete"
                        fi
                        ;;
                    4)
                        log_warn "WARNING: This will permanently delete the entire bucket and all its contents!"
                        read -p "Are you absolutely sure? Type 'DELETE' to confirm: " CONFIRM_DELETE
                        
                        if [[ "$CONFIRM_DELETE" == "DELETE" ]]; then
                            delete_s3_bucket "$ASSET_BUCKET"
                            log_info "S3 bucket deleted completely"
                        else
                            log_info "Bucket deletion cancelled"
                        fi
                        ;;
                    5|*)
                        log_info "S3 bucket and contents preserved"
                        
                        # Only show relevant manual cleanup commands
                        if [[ "$WORKSHOP_FOLDER_EXISTS" == true || "$MISTRAL_MODEL_EXISTS" == true ]]; then
                            log_info "Manual cleanup commands:"
                            
                            if [[ "$WORKSHOP_FOLDER_EXISTS" == true ]]; then
                                echo "  # Delete workshop folder only:"
                                echo "  aws s3 rm s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto/ --recursive --exclude 'assets/Mistral-7B-Instruct-v0.2/*'"
                                echo ""
                            fi
                            
                            if [[ "$MISTRAL_MODEL_EXISTS" == true ]]; then
                                echo "  # Delete Mistral model only:"
                                echo "  aws s3 rm s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto/assets/Mistral-7B-Instruct-v0.2/ --recursive"
                                echo ""
                            fi
                            
                            if [[ "$WORKSHOP_FOLDER_EXISTS" == true || "$MISTRAL_MODEL_EXISTS" == true ]]; then
                                echo "  # Delete all workshop content:"
                                echo "  aws s3 rm s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto/ --recursive"
                            fi
                        else
                            log_info "No workshop content found to clean up"
                        fi
                        ;;
                esac
            fi
        else
            log_warn "S3 bucket ${ASSET_BUCKET} not found"
        fi
    else
        log_info "Skipping S3 bucket cleanup"
    fi
    
    # Step 3: Local file cleanup
    log_step "Step 3: Local file cleanup"
    
    LOCAL_DIRS=("genai-fsx-workshop-on-eks-auto" "work-dir")
    
    for dir in "${LOCAL_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "Found local directory: ${dir}"
            
            # Check for root-owned files (especially in work-dir)
            if [[ "$dir" == "work-dir" ]]; then
                ROOT_FILES=$(find "$dir" -user root 2>/dev/null | wc -l)
                if [ "$ROOT_FILES" -gt 0 ]; then
                    log_warn "Directory ${dir} contains ${ROOT_FILES} root-owned files (from Docker)"
                    log_info "This directory requires elevated permissions to delete"
                fi
            fi
            
            read -p "Delete local directory ${dir}? (yes/no): " DELETE_DIR
            
            if [[ "$DELETE_DIR" == "yes" ]]; then
                if [[ "$dir" == "work-dir" ]]; then
                    # work-dir may contain root-owned files from Docker
                    log_info "Attempting to delete ${dir} (may require sudo for root-owned files)..."
                    
                    # First try without sudo
                    if rm -rf "$dir" 2>/dev/null; then
                        log_info "Deleted local directory: ${dir}"
                    else
                        # If that fails, try with sudo
                        log_warn "Permission denied, trying with sudo..."
                        if sudo rm -rf "$dir" 2>/dev/null; then
                            log_info "Deleted local directory: ${dir} (with sudo)"
                        else
                            log_error "Failed to delete ${dir} even with sudo"
                            log_info "Manual cleanup required:"
                            echo "  sudo rm -rf ${dir}"
                        fi
                    fi
                else
                    # Regular directory deletion
                    if rm -rf "$dir" 2>/dev/null; then
                        log_info "Deleted local directory: ${dir}"
                    else
                        log_error "Failed to delete ${dir}"
                        log_info "Manual cleanup required:"
                        echo "  rm -rf ${dir}"
                    fi
                fi
            else
                log_info "Preserved local directory: ${dir}"
                
                # Provide cleanup guidance for work-dir
                if [[ "$dir" == "work-dir" ]]; then
                    log_info "To manually delete later (requires sudo for root-owned files):"
                    echo "  sudo rm -rf ${dir}"
                fi
            fi
        fi
    done
    
    # Clean up temporary files
    TEMP_FILES=("validate_cfn.txt" "awscliv2.zip")
    
    for file in "${TEMP_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log_info "Cleaned up temporary file: ${file}"
        fi
    done
    
    # Step 4: Summary
    log_step "Cleanup Summary"
    
    log_info "Cleanup completed successfully!"
    echo ""
    log_info "What was cleaned up:"
    echo "  ✓ CloudFormation stack and all AWS resources"
    echo "  ✓ S3 bucket (if selected)"
    echo "  ✓ Local workshop files (if selected)"
    echo "  ✓ Temporary files"
    echo ""
    
    log_info "Verification commands:"
    echo "  # Check if stack still exists:"
    echo "  aws cloudformation describe-stacks --stack-name ${STACK_NAME} --region ${AWS_REGION}"
    echo ""
    echo "  # Check remaining S3 buckets:"
    echo "  aws s3 ls"
    echo ""
    
    log_info "If you encounter any issues:"
    echo "  1. Check the CloudFormation console for stuck resources"
    echo "  2. Manually delete any remaining resources"
    echo "  3. Check AWS billing dashboard to ensure no unexpected charges"
    echo ""
    
    log_info "Cleanup script completed!"
}

# Run main function
main "$@"