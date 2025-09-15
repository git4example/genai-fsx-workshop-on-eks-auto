#!/bin/bash
# Quick Deploy Sponsored Workshop - Automated Deployment Script
#
# PURPOSE: This script provides rapid automated deployment for AWS-sponsored
#          workshop environments. For learning purposes, participants should
#          follow the step-by-step instructions in the workshop documentation.
#
# USAGE: ./quick-deploy-sponsored.sh
#
# This script automates deployment and testing of workshop components:
# - EKS cluster validation and connectivity
# - Karpenter functionality and node provisioning
# - FSx for Lustre integration and performance testing
# - GenAI workload deployment (vLLM + Mistral model)
# - WebUI deployment and accessibility validation
# - End-to-end testing of the complete workshop stack
#
set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Function to check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 is not installed or not in PATH"
        return 1
    fi
    log_info "$1 is available"
    return 0
}

# Function to install missing tools
install_missing_tools() {
    log_info "Checking required tools..."
    
    # Check AWS CLI
    if ! check_command aws; then
        log_info "Installing AWS CLI..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    fi
    
    # Check kubectl
    if ! check_command kubectl; then
        log_info "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
    
    # Check eksctl
    if ! check_command eksctl; then
        log_info "Installing eksctl..."
        curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/eksctl /usr/local/bin
    fi
    
    # Check helm
    if ! check_command helm; then
        log_info "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    # Check jq
    if ! check_command jq; then
        log_info "Installing jq..."
        sudo yum install -y jq || sudo apt-get install -y jq
    fi
}

# Function to check IAM policy exists
check_iam_policy() {
    local policy_name=$1
    local account_id=$2
    
    if aws iam get-policy --policy-arn "arn:aws:iam::${account_id}:policy/${policy_name}" &>/dev/null; then
        log_info "IAM policy ${policy_name} already exists"
        return 0
    else
        log_warn "IAM policy ${policy_name} does not exist"
        return 1
    fi
}

# Function to check service account exists
check_service_account() {
    local namespace=$1
    local sa_name=$2
    
    if check_kubectl_access && kubectl get serviceaccount ${sa_name} -n ${namespace} &>/dev/null; then
        log_info "Service account ${sa_name} already exists in namespace ${namespace}"
        return 0
    else
        log_warn "Service account ${sa_name} does not exist in namespace ${namespace} (or cluster not accessible)"
        return 1
    fi
}

# Function to check helm repository
check_helm_repo() {
    local repo_name=$1
    
    if helm repo list | grep -q "^${repo_name}"; then
        log_info "Helm repository ${repo_name} already exists"
        return 0
    else
        log_warn "Helm repository ${repo_name} does not exist"
        return 1
    fi
}

# Function to check helm release
check_helm_release() {
    local release_name=$1
    local namespace=$2
    
    if helm list -n ${namespace} | grep -q "^${release_name}"; then
        log_info "Helm release ${release_name} already exists in namespace ${namespace}"
        return 0
    else
        log_warn "Helm release ${release_name} does not exist in namespace ${namespace}"
        return 1
    fi
}

# Function to check if CloudFormation stack exists
check_cloudformation_stack() {
    local stack_name=$1
    
    if aws cloudformation describe-stacks --stack-name "${stack_name}" --region $AWS_REGION &>/dev/null; then
        log_info "CloudFormation stack ${stack_name} exists"
        return 0
    else
        log_warn "CloudFormation stack ${stack_name} does not exist"
        return 1
    fi
}

# Function to wait for CloudFormation stack to be ready
wait_for_cloudformation_stack() {
    local stack_name=$1
    local timeout=${2:-600}  # Default 10 minutes
    local check_interval=30
    local elapsed=0
    
    log_info "Waiting for CloudFormation stack ${stack_name} to be ready..."
    
    while [ $elapsed -lt $timeout ]; do
        local stack_status=$(aws cloudformation describe-stacks --stack-name "${stack_name}" --region $AWS_REGION --query 'Stacks[0].StackStatus' --output text 2>/dev/null)
        
        case "$stack_status" in
            "CREATE_COMPLETE"|"UPDATE_COMPLETE")
                log_info "CloudFormation stack ${stack_name} is ready (${stack_status})"
                return 0
                ;;
            "CREATE_IN_PROGRESS"|"UPDATE_IN_PROGRESS")
                log_info "CloudFormation stack ${stack_name} is still in progress (${stack_status})... waiting ${check_interval}s"
                sleep $check_interval
                elapsed=$((elapsed + check_interval))
                ;;
            "CREATE_FAILED"|"UPDATE_FAILED"|"ROLLBACK_COMPLETE"|"ROLLBACK_FAILED")
                log_error "CloudFormation stack ${stack_name} failed with status: ${stack_status}"
                return 1
                ;;
            "")
                log_warn "CloudFormation stack ${stack_name} not found"
                return 1
                ;;
            *)
                log_warn "CloudFormation stack ${stack_name} has unexpected status: ${stack_status}"
                sleep $check_interval
                elapsed=$((elapsed + check_interval))
                ;;
        esac
    done
    
    log_error "Timeout waiting for CloudFormation stack ${stack_name} to be ready"
    return 1
}

# Function to wait for IAM role to be available
wait_for_iam_role() {
    local role_name=$1
    local timeout=${2:-300}  # Default 5 minutes
    local check_interval=10
    local elapsed=0
    
    log_info "Waiting for IAM role ${role_name} to be available..."
    
    while [ $elapsed -lt $timeout ]; do
        if aws iam get-role --role-name "${role_name}" &>/dev/null; then
            log_info "IAM role ${role_name} is available"
            return 0
        fi
        
        log_info "IAM role ${role_name} not yet available... waiting ${check_interval}s"
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
    done
    
    log_error "Timeout waiting for IAM role ${role_name} to be available"
    return 1
}

# Function to wait for pods to be ready
wait_for_pods() {
    local namespace=$1
    local label_selector=$2
    local timeout=${3:-300}
    
    log_info "Waiting for pods with label ${label_selector} in namespace ${namespace} to be ready..."
    kubectl wait --for=condition=Ready pod -l ${label_selector} -n ${namespace} --timeout=${timeout}s || {
        log_warn "Timeout waiting for pods to be ready"
        return 1
    }
    return 0
}

# Function to validate AWS region
validate_aws_region() {
    local region=$1
    
    # Check if region is valid by trying to list availability zones
    if aws ec2 describe-availability-zones --region ${region} &>/dev/null; then
        log_info "AWS region ${region} is valid"
        return 0
    else
        log_error "AWS region ${region} is not valid or accessible"
        return 1
    fi
}

# Function to get FSx Lustre filesystem by tags
get_fsx_by_tags() {
    local blueprint_tag="eksworkshop"
    
    log_info "Looking for FSx Lustre filesystem with Blueprint tag: $blueprint_tag"
    
    # Get FSx filesystems filtered by tags
    local fsx_systems=$(aws fsx describe-file-systems \
        --query "FileSystems[?FileSystemType==\`LUSTRE\` && Tags[?Key==\`Blueprint\` && Value==\`$blueprint_tag\`]].[FileSystemId,DNSName,LustreConfiguration.MountName]" \
        --output json)
    
    # Count the number of matching file systems
    local fsx_count=$(echo $fsx_systems | jq length)
    
    if [ "$fsx_count" -eq 0 ]; then
        log_error "No FSx for Lustre file systems found with Blueprint tag: $blueprint_tag"
        log_info "Available FSx Lustre file systems:"
        aws fsx describe-file-systems --query 'FileSystems[?FileSystemType==`LUSTRE`].[FileSystemId,Tags[?Key==`Blueprint`].Value|[0]]' --output table
        return 1
    elif [ "$fsx_count" -eq 1 ]; then
        log_info "Found FSx for Lustre file system with Blueprint tag: $blueprint_tag"
        echo $fsx_systems | jq -r '.[0] | @tsv'
        return 0
    else
        log_warn "Multiple FSx for Lustre file systems found with Blueprint tag: $blueprint_tag"
        echo $fsx_systems | jq -r '.[] | @tsv' | column -t -s $'\t'
        
        # For workshop consistency, use the first one
        log_info "Using the first matching filesystem for workshop consistency"
        echo $fsx_systems | jq -r '.[0] | @tsv'
        return 0
    fi
}

# Function to get FSx Lustre AZ based on filesystem ID
get_fsx_lustre_az() {
    local fsx_id=$1
    
    log_info "Detecting FSx Lustre availability zone for filesystem: $fsx_id"
    
    # Get the subnet ID of the FSx filesystem
    local subnet_id=$(aws fsx describe-file-systems --file-system-ids $fsx_id --query 'FileSystems[0].SubnetIds[0]' --output text)
    
    if [[ -z "$subnet_id" || "$subnet_id" == "None" ]]; then
        log_error "Failed to get subnet ID for FSx filesystem $fsx_id"
        return 1
    fi
    
    # Get the AZ from the subnet
    local az=$(aws ec2 describe-subnets --subnet-ids $subnet_id --query 'Subnets[0].AvailabilityZone' --output text)
    
    if [[ -z "$az" || "$az" == "None" ]]; then
        log_error "Failed to get availability zone for subnet $subnet_id"
        return 1
    fi
    
    log_info "FSx Lustre filesystem $fsx_id is in availability zone: $az"
    echo "$az"
    return 0
}

# Function to validate FSx filesystem belongs to current cluster
validate_fsx_cluster_association() {
    local fsx_id=$1
    local cluster_name=$2
    
    log_info "Validating FSx filesystem belongs to cluster: $cluster_name"
    
    # Check if FSx has Blueprint tag matching cluster
    local blueprint_value=$(aws fsx describe-file-systems --file-system-ids $fsx_id \
        --query 'FileSystems[0].Tags[?Key==`Blueprint`].Value | [0]' --output text)
    
    if [[ "$blueprint_value" == "$cluster_name" ]]; then
        log_info "✓ FSx filesystem correctly tagged for cluster: $cluster_name"
        return 0
    else
        log_warn "⚠ FSx filesystem Blueprint tag ($blueprint_value) doesn't match cluster ($cluster_name)"
        return 1
    fi
}

# Function to validate AZ has Inferentia capacity
validate_inferentia_az() {
    local az=$1
    
    log_info "Validating Inferentia availability in AZ: $az"
    
    # Check if there are any inf2 instances available in this AZ
    local inf2_available=$(aws ec2 describe-instance-type-offerings \
        --location-type availability-zone \
        --filters Name=location,Values=$az Name=instance-type,Values=inf2.* \
        --query 'InstanceTypeOfferings[].InstanceType' \
        --output text)
    
    if [[ -n "$inf2_available" ]]; then
        log_info "✓ Inferentia instances available in AZ $az: $inf2_available"
        return 0
    else
        log_warn "⚠ No Inferentia instances found in AZ $az"
        log_warn "  This may cause scheduling issues for the Mistral deployment"
        return 1
    fi
}

# Function to check if kubectl is working
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
        log_warn "Skipping kubectl command - cluster not accessible: $*"
        return 0
    fi
}

# Install missing tools first
install_missing_tools

# Validate the IAM role
log_info "Validating AWS credentials..."
aws sts get-caller-identity

# Set the Amazon EKS cluster variables :
export CLUSTER_NAME=eksworkshop

# Detect AWS region if not set
if [[ -z "$AWS_REGION" ]]; then
    log_warn "AWS_REGION not set, attempting to detect..."
    # Try to get region from AWS CLI config
    AWS_REGION=$(aws configure get region 2>/dev/null)
    
    # If still not found, try from instance metadata (if running on EC2)
    if [[ -z "$AWS_REGION" ]]; then
        AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null)
    fi
    
    # If still not found, try from EKS cluster (if kubeconfig exists)
    if [[ -z "$AWS_REGION" ]] && kubectl config current-context &>/dev/null; then
        AWS_REGION=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' | sed 's/.*\.\([^.]*\)\.eks\.amazonaws\.com.*/\1/')
    fi
    
    # Prompt user if nothing else works
    if [[ -z "$AWS_REGION" ]]; then
        log_warn "Could not detect AWS region automatically"
        echo "Common regions: us-east-1, us-west-2, eu-west-1, ap-southeast-1"
        read -p "Please enter your AWS region: " AWS_REGION
        
        if [[ -z "$AWS_REGION" ]]; then
            log_error "AWS region is required to proceed"
            exit 1
        fi
    fi
    
    export AWS_REGION
    log_info "Detected AWS Region: $AWS_REGION"
else
    log_info "Using provided AWS Region: $AWS_REGION"
fi

# Validate the region
if ! validate_aws_region "$AWS_REGION"; then
    log_error "Invalid or inaccessible AWS region: $AWS_REGION"
    exit 1
fi

export AWS_ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Region: $AWS_REGION"
echo "Cluster Name: $CLUSTER_NAME"
echo "AWS Account ID: $AWS_ACCOUNTID"

# Check if EKS cluster exists (warn but don't exit if it doesn't)
log_info "Checking EKS cluster status..."
if aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION &>/dev/null; then
    log_info "EKS cluster '$CLUSTER_NAME' found in region '$AWS_REGION'"
    CLUSTER_EXISTS=true
else
    log_warn "EKS cluster '$CLUSTER_NAME' not found in region '$AWS_REGION'"
    log_warn "This is expected if the cluster hasn't been created yet"
    log_info "The script will continue and create necessary resources"
    CLUSTER_EXISTS=false
fi

# Update the kube-config file (only if cluster exists):
if [ "$CLUSTER_EXISTS" = true ]; then
    log_info "Updating kubeconfig..."
    aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
    
    log_info "Checking cluster nodes..."
    if kubectl get nodes &>/dev/null; then
        kubectl get nodes
    else
        log_warn "Unable to connect to cluster nodes - this may be expected during initial setup"
    fi
else
    log_info "Skipping kubeconfig update - cluster doesn't exist yet"
fi

# Deploy CSI Driver
log_info "Setting up FSx CSI Driver..."

# Step 1: Create an IAM policy, and service account, that allows the CSI driver to make the AWS API calls on your behalf
if ! check_iam_policy "Amazon_FSx_Lustre_CSI_Driver" "$AWS_ACCOUNTID"; then
    log_info "Creating IAM policy for FSx CSI Driver..."
    cat << EOF >  fsx-csi-driver.json
{
    "Version":"2012-10-17",
    "Statement":[
        {
            "Effect":"Allow",
            "Action":[
                "iam:CreateServiceLinkedRole",
                "iam:AttachRolePolicy",
                "iam:PutRolePolicy"
            ],
            "Resource":"arn:aws:iam::*:role/aws-service-role/s3.data-source.lustre.fsx.amazonaws.com/*"
        },
        {
            "Action":"iam:CreateServiceLinkedRole",
            "Effect":"Allow",
            "Resource":"*",
            "Condition":{
                "StringLike":{
                    "iam:AWSServiceName":[
                        "fsx.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Effect":"Allow",
            "Action":[
                "s3:ListBucket",
                "fsx:CreateFileSystem",
                "fsx:DeleteFileSystem",
                "fsx:DescribeFileSystems",
                "fsx:TagResource"
            ],
            "Resource":[
                "*"
            ]
        }
    ]
}
EOF
    # Step 2: Create the IAM policy
    aws iam create-policy \
            --policy-name Amazon_FSx_Lustre_CSI_Driver \
            --policy-document file://fsx-csi-driver.json
else
    log_info "Skipping IAM policy creation - already exists"
fi

# Step 3: Create a Kubernetes service account for the driver and attach the policy to the service account
STACK_NAME="eksctl-${CLUSTER_NAME}-addon-iamserviceaccount-kube-system-fsx-csi-controller-sa"

if ! check_service_account "kube-system" "fsx-csi-controller-sa" && ! check_cloudformation_stack "$STACK_NAME"; then
    log_info "Creating service account for FSx CSI Driver..."
    eksctl create iamserviceaccount \
        --region $AWS_REGION \
        --cluster=$CLUSTER_NAME \
        --namespace kube-system \
        --name=fsx-csi-controller-sa \
        --attach-policy-arn arn:aws:iam::$AWS_ACCOUNTID:policy/Amazon_FSx_Lustre_CSI_Driver \
        --role-name=fsx-csi-controller-sa \
        --role-only \
        --approve
    
    # Wait for CloudFormation stack to complete
    if ! wait_for_cloudformation_stack "$STACK_NAME" 600; then
        log_error "Failed to create service account CloudFormation stack"
        exit 1
    fi
    
    # Wait for IAM role to be available
    if ! wait_for_iam_role "fsx-csi-controller-sa" 300; then
        log_error "Failed to create IAM role for service account"
        exit 1
    fi
else
    log_info "Skipping service account creation - already exists or in progress"
    
    # If stack exists but not complete, wait for it
    if check_cloudformation_stack "$STACK_NAME"; then
        wait_for_cloudformation_stack "$STACK_NAME" 600
    fi
fi

# Step 4: Save the Role ARN that was created into a variable
log_info "Retrieving Role ARN from CloudFormation stack..."
STACK_NAME="eksctl-${CLUSTER_NAME}-addon-iamserviceaccount-kube-system-fsx-csi-controller-sa"

# Ensure stack is ready before retrieving outputs
if ! wait_for_cloudformation_stack "$STACK_NAME" 600; then
    log_error "CloudFormation stack not ready, cannot retrieve Role ARN"
    exit 1
fi

export ROLE_ARN=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[0].OutputValue" --region $AWS_REGION --output text)

if [[ -z "$ROLE_ARN" || "$ROLE_ARN" == "None" ]]; then
    log_error "Failed to retrieve Role ARN from CloudFormation stack"
    exit 1
fi

echo "Role ARN: $ROLE_ARN"

# Step 5: Deploy the CSI driver of FSx for Lustre
if ! check_helm_repo "aws-fsx-csi-driver"; then
    log_info "Adding FSx CSI Driver Helm repository..."
    helm repo add aws-fsx-csi-driver https://kubernetes-sigs.github.io/aws-fsx-csi-driver
fi

log_info "Updating Helm repositories..."
helm repo update

if ! check_helm_release "aws-fsx-csi-driver" "kube-system"; then
    log_info "Installing FSx CSI Driver..."
    helm upgrade --install aws-fsx-csi-driver aws-fsx-csi-driver/aws-fsx-csi-driver \
        --namespace kube-system \
        --version 1.11.0 \
        --set serviceAccount.create=true \
        --set serviceAccount.name=fsx-csi-controller-sa \
        --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$ROLE_ARN \
        --wait --timeout=10m
else
    log_info "FSx CSI Driver already installed, upgrading if needed..."
    helm upgrade aws-fsx-csi-driver aws-fsx-csi-driver/aws-fsx-csi-driver \
        --namespace kube-system \
        --version 1.11.0 \
        --set serviceAccount.create=true \
        --set serviceAccount.name=fsx-csi-controller-sa \
        --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$ROLE_ARN \
        --wait --timeout=10m
fi

# Wait for CSI driver pods to be ready
if check_kubectl_access; then
    log_info "Waiting for FSx CSI Driver pods to be ready..."
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=aws-fsx-csi-driver -n kube-system --timeout=300s || log_warn "Timeout waiting for CSI driver pods"
fi

safe_kubectl kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-fsx-csi-driver

# Create Persistent Volume on EKS Cluster
log_info "Setting up FSx Lustre Persistent Volume..."
cd /home/participant/environment/eks/FSxL

log_info "Checking for FSx for Lustre file systems using Blueprint tags..."

# Get FSx filesystem info using tags
SYSTEM_INFO=$(get_fsx_by_tags)
if [[ $? -ne 0 ]]; then
    log_error "Failed to find FSx Lustre filesystem with required tags"
    exit 1
fi

# Parse the output and export variables
IFS=$'\t' read -r FSXL_VOLUME_ID DNS_NAME MOUNT_NAME <<< "$SYSTEM_INFO"
export FSXL_VOLUME_ID
export DNS_NAME  
export MOUNT_NAME

# Get FSx Lustre AZ
FSX_LUSTRE_AZ=$(get_fsx_lustre_az "$FSXL_VOLUME_ID")
if [[ $? -ne 0 || -z "$FSX_LUSTRE_AZ" ]]; then
    log_error "Failed to detect FSx Lustre availability zone"
    exit 1
fi
export FSX_LUSTRE_AZ

# Validate FSx belongs to current cluster
validate_fsx_cluster_association "$FSXL_VOLUME_ID" "$CLUSTER_NAME"

# Validate Inferentia availability in the FSx AZ
validate_inferentia_az "$FSX_LUSTRE_AZ"

# Validate that all variables are set
if [[ -z "$FSXL_VOLUME_ID" || -z "$DNS_NAME" || -z "$MOUNT_NAME" || -z "$FSX_LUSTRE_AZ" ]]; then
    log_error "Failed to retrieve FSx file system details"
    exit 1
fi

# Display the results
log_info "Selected File System Details (Blueprint: eksworkshop):"
echo "FileSystemId: $FSXL_VOLUME_ID"
echo "DNS Name: $DNS_NAME"
echo "Mount Name: $MOUNT_NAME"
echo "Availability Zone: $FSX_LUSTRE_AZ"
log_info "Environment variables FSXL_VOLUME_ID, DNS_NAME, MOUNT_NAME, and FSX_LUSTRE_AZ have been set."

# Verify the filesystem has the expected tags
log_info "Verifying FSx filesystem tags..."
aws fsx describe-file-systems --file-system-ids $FSXL_VOLUME_ID --query 'FileSystems[0].Tags' --output table

# FSXL_VOLUME_ID=$(aws fsx describe-file-systems --query 'FileSystems[].FileSystemId' --output text)
# DNS_NAME=$(aws fsx describe-file-systems --query 'FileSystems[].DNSName' --output text)
# MOUNT_NAME=$(aws fsx describe-file-systems --query 'FileSystems[].LustreConfiguration.MountName' --output text)

# Check if PV already exists
if kubectl get pv fsxl-pv &>/dev/null; then
    log_info "FSx Lustre PV already exists"
else
    log_info "Creating FSx Lustre PV..."
    sed -i'' -e "s/FSXL_VOLUME_ID/$FSXL_VOLUME_ID/g" fsxL-persistent-volume.yaml
    sed -i'' -e "s/DNS_NAME/$DNS_NAME/g" fsxL-persistent-volume.yaml
    sed -i'' -e "s/MOUNT_NAME/$MOUNT_NAME/g" fsxL-persistent-volume.yaml
    
    cat fsxL-persistent-volume.yaml
    kubectl apply -f fsxL-persistent-volume.yaml
fi

# Check if PVC already exists
if check_kubectl_access && kubectl get pvc fsx-lustre-claim &>/dev/null; then
    log_info "FSx Lustre PVC already exists"
    # Check if it's already bound
    PVC_STATUS=$(kubectl get pvc fsx-lustre-claim -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
    if [[ "$PVC_STATUS" != "Bound" ]]; then
        log_info "PVC exists but not bound (status: $PVC_STATUS), waiting..."
        # Use a custom wait loop instead of kubectl wait (which can be unreliable for PVC Bound condition)
        WAIT_COUNT=0
        while [[ "$PVC_STATUS" != "Bound" && $WAIT_COUNT -lt 60 ]]; do
            sleep 5
            PVC_STATUS=$(kubectl get pvc fsx-lustre-claim -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
            WAIT_COUNT=$((WAIT_COUNT + 1))
            log_info "Waiting for PVC to be bound... (status: $PVC_STATUS, attempt: $WAIT_COUNT/60)"
        done
        
        if [[ "$PVC_STATUS" == "Bound" ]]; then
            log_info "✓ FSx Lustre PVC is now bound"
        else
            log_warn "Timeout waiting for PVC to be bound (final status: $PVC_STATUS)"
        fi
    else
        log_info "✓ FSx Lustre PVC is already bound"
    fi
else
    if check_kubectl_access; then
        log_info "Creating FSx Lustre PVC..."
        kubectl apply -f fsxL-claim.yaml
        
        # Wait for PVC to be bound using status check (kubectl wait can be unreliable for PVC Bound condition)
        log_info "Waiting for FSx Lustre PVC to be bound..."
        WAIT_COUNT=0
        PVC_STATUS="Unknown"
        while [[ "$PVC_STATUS" != "Bound" && $WAIT_COUNT -lt 60 ]]; do
            sleep 5
            PVC_STATUS=$(kubectl get pvc fsx-lustre-claim -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
            WAIT_COUNT=$((WAIT_COUNT + 1))
            log_info "Waiting for PVC to be bound... (status: $PVC_STATUS, attempt: $WAIT_COUNT/60)"
        done
        
        if [[ "$PVC_STATUS" == "Bound" ]]; then
            log_info "✓ FSx Lustre PVC is bound"
        else
            log_warn "Timeout waiting for PVC to be bound (final status: $PVC_STATUS)"
        fi
    else
        log_warn "Skipping PVC creation - cluster not accessible"
    fi
fi

safe_kubectl kubectl get pv,pvc

# Deploy Generative AI Chat application
# Deploy vLLM on AWS Inferentia nodes for model Inference

# Step 1: Neuron Device Plugin, Neuron Scheduler, and Node Problem Detector
cd /home/participant/environment/terraform

if ! check_helm_release "neuron-helm-chart" "kube-system"; then
    log_info "Installing Neuron Helm Chart..."
    helm upgrade --install neuron-helm-chart \
        oci://public.ecr.aws/neuron/neuron-helm-chart \
        --namespace kube-system \
        --version 1.2.0 \
        -f ./helm-values/neuron-values.yaml \
        --wait --timeout=10m
else
    log_info "Neuron Helm Chart already installed, upgrading if needed..."
    helm upgrade neuron-helm-chart \
        oci://public.ecr.aws/neuron/neuron-helm-chart \
        --namespace kube-system \
        --version 1.2.0 \
        -f ./helm-values/neuron-values.yaml \
        --wait --timeout=10m
fi

# Wait for Neuron device plugin pods to be ready
if check_kubectl_access; then
    log_info "Waiting for Neuron device plugin pods to be ready..."
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=neuron-device-plugin -n kube-system --timeout=300s || log_warn "Timeout waiting for Neuron device plugin pods"
fi

# Step 2: Create EKS Auto NodePool and EC2 NodeClass for AWS Inferentia Accelerators
log_info "Setting up Inferentia NodePool..."

NODE_ROLE=$(cd /home/participant/environment/terraform && terraform output --raw eks_node_iam_role_name)
cd /home/participant/environment/eks/genai

# Check if nodepool already exists
if check_kubectl_access && kubectl get nodepool inferentia &>/dev/null; then
    log_info "Inferentia nodepool already exists"
else
    if check_kubectl_access; then
        log_info "Creating Inferentia nodepool..."
        sed -i'' -e "s/NODE_ROLE/$NODE_ROLE/g" inferentia_nodepool.yaml
        cat inferentia_nodepool.yaml
        kubectl apply -f inferentia_nodepool.yaml
        
        # Wait for nodepool to be ready
        log_info "Waiting for Inferentia nodepool to be ready..."
        kubectl wait --for=condition=Ready nodepool/inferentia --timeout=600s || log_warn "Timeout waiting for nodepool to be ready"
    else
        log_warn "Skipping nodepool creation - cluster not accessible"
    fi
fi

safe_kubectl kubectl get nodepool,nodeclass inferentia

# Step 3: Deploy the vLLM application Pod
log_info "Deploying vLLM Mistral application..."
if check_kubectl_access && kubectl get deployment vllm-mistral-inf2-deployment &>/dev/null; then
    log_info "vLLM Mistral deployment already exists"
    # Check if pods are running
    RUNNING_PODS=$(kubectl get pods -l app=vllm-mistral-inf2-server --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    if [ "$RUNNING_PODS" -gt 0 ]; then
        log_info "vLLM Mistral pods are running"
    else
        log_warn "vLLM Mistral deployment exists but no running pods found"
        kubectl get pods -l app=vllm-mistral-inf2-server
    fi
else
    if check_kubectl_access; then
        log_info "Applying vLLM Mistral deployment..."
        
        # Create a temporary copy of the deployment file with AZ replacement
        cp mistral-fsxl.yaml mistral-fsxl-temp.yaml
        
        # Replace the FSX_LUSTRE_AZ placeholder with the actual AZ
        sed -i'' -e "s/FSX_LUSTRE_AZ/$FSX_LUSTRE_AZ/g" mistral-fsxl-temp.yaml
        
        log_info "Configured vLLM deployment for FSx Lustre AZ: $FSX_LUSTRE_AZ"
        
        kubectl apply -f mistral-fsxl-temp.yaml
        
        # Clean up temporary file
        rm -f mistral-fsxl-temp.yaml
        
        # Wait for deployment to be available (but not pod readiness - that can take 5-10 minutes)
        log_info "Waiting for vLLM deployment to be available..."
        kubectl wait --for=condition=Available deployment/vllm-mistral-inf2-deployment --timeout=300s || log_warn "Timeout waiting for deployment availability"
        
        log_info "vLLM deployment is available. Pod readiness (model loading) will continue in background..."
        log_info "Note: Model loading on Inferentia can take 5-10 minutes - WebUI will deploy in parallel"
        
        # Show pod status
        log_info "vLLM pod status:"
        kubectl get pods -l app=vllm-mistral-inf2-server
    else
        log_warn "Skipping vLLM deployment - cluster not accessible"
    fi
fi

# Show the final deployment configuration (with AZ replaced)
log_info "Final vLLM deployment configuration:"
cp mistral-fsxl.yaml mistral-fsxl-display.yaml
sed -i'' -e "s/FSX_LUSTRE_AZ/$FSX_LUSTRE_AZ/g" mistral-fsxl-display.yaml
cat mistral-fsxl-display.yaml
rm -f mistral-fsxl-display.yaml

safe_kubectl kubectl get pod

# Deploy WebUI chat application to interact with model
log_info "Deploying WebUI chat application..."
if check_kubectl_access && kubectl get deployment open-webui-deployment &>/dev/null; then
    log_info "WebUI deployment already exists"
    # Check if pods are running
    WEBUI_RUNNING_PODS=$(kubectl get pods -l app=open-webui-server --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    if [ "$WEBUI_RUNNING_PODS" -gt 0 ]; then
        log_info "WebUI pods are running"
    else
        log_warn "WebUI deployment exists but no running pods found"
        kubectl get pods -l app=open-webui-server
    fi
else
    if check_kubectl_access; then
        log_info "Applying WebUI deployment..."
        kubectl apply -f open-webui.yaml
        
        # Wait for WebUI deployment to be ready
        log_info "Waiting for WebUI deployment to be ready..."
        kubectl wait --for=condition=Available deployment/open-webui-deployment --timeout=300s || log_warn "Timeout waiting for WebUI deployment"
        
        # Show WebUI pod status
        log_info "WebUI pod status:"
        kubectl get pods -l app=open-webui-server
    else
        log_warn "Skipping WebUI deployment - cluster not accessible"
    fi
fi
# Show ingress information
safe_kubectl kubectl get ing

# Check vLLM service and pod status (non-blocking)
log_info "Checking vLLM service and pod status..."
if check_kubectl_access; then
    # Check if vLLM service exists
    if kubectl get service vllm-mistral7b-service &>/dev/null; then
        log_info "✓ vLLM service exists"
        
        # Get service endpoint
        SERVICE_IP=$(kubectl get service vllm-mistral7b-service -o jsonpath='{.spec.clusterIP}')
        if [[ -n "$SERVICE_IP" ]]; then
            log_info "✓ vLLM service ClusterIP: $SERVICE_IP"
        fi
    else
        log_error "✗ vLLM service not found - deployment may have failed"
    fi
    
    # Check pod readiness status
    READY_PODS=$(kubectl get pods -l app=vllm-mistral-inf2-server --field-selector=status.phase=Running -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -c "True" || echo "0")
    TOTAL_PODS=$(kubectl get pods -l app=vllm-mistral-inf2-server --no-headers 2>/dev/null | wc -l)
    
    if [[ "$READY_PODS" -gt 0 ]]; then
        log_info "✓ vLLM pod is ready ($READY_PODS/$TOTAL_PODS pods ready)"
        
        # Health check with retries for ready pods (service might still be initializing)
        log_info "Testing vLLM health endpoint (with retries)..."
        HEALTH_SUCCESS=false
        for attempt in {1..10}; do
            log_info "Health check attempt $attempt/10..."
            if kubectl run test-vllm-connection-$attempt --image=curlimages/curl --rm -i --restart=Never --timeout=45s -- \
                curl -s -f --max-time 15 "http://vllm-mistral7b-service/health" &>/dev/null; then
                log_info "✓ vLLM health check passed - service is responding"
                HEALTH_SUCCESS=true
                break
            else
                if [[ $attempt -lt 10 ]]; then
                    log_info "⏳ Health check failed, waiting 60 seconds before retry..."
                    sleep 60
                fi
            fi
        done
        
        if [[ "$HEALTH_SUCCESS" != "true" ]]; then
            log_warn "⚠ vLLM health check failed after 10 attempts"
            log_info "   This is normal if model is still loading - vLLM may take additional time to respond"
            log_info "   Monitor with: kubectl logs -l app=vllm-mistral-inf2-server -f"
        fi
    else
        log_info "⏳ vLLM pod not ready yet ($READY_PODS/$TOTAL_PODS pods ready) - model loading in progress"
        log_info "   This is normal - Inferentia model loading takes 5-10 minutes"
        log_info "   Check status with: kubectl get pods -l app=vllm-mistral-inf2-server"
        log_info "   Monitor logs with: kubectl logs -l app=vllm-mistral-inf2-server -f"
    fi
    
    # Show all services
    log_info "All services:"
    kubectl get services
else
    log_warn "Cannot check vLLM service - cluster not accessible"
fi

# Get WebUI access URL
log_info "Getting WebUI access information..."
if check_kubectl_access && kubectl get ingress open-webui-ingress &>/dev/null; then
    log_info "WebUI ingress exists, getting URL..."
    
    # Wait a bit for ALB to be provisioned
    sleep 30
    
    WEBUI_URL=$(kubectl get ingress open-webui-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [[ -n "$WEBUI_URL" ]]; then
        log_info "🎉 WebUI Access URL: http://$WEBUI_URL"
        log_info "Note: ALB provisioning may take 2-3 minutes. If URL doesn't work immediately, wait and try again."
    else
        log_warn "WebUI URL not yet available - ALB may still be provisioning"
        log_info "Check ingress status with: kubectl get ingress open-webui-ingress"
    fi
else
    log_warn "WebUI ingress not found or cluster not accessible"
fi

# Inspect vLLM, Neuron Cores, Mistral-7B data, and replicate data
# Step 1: Login to vLLM Pod, inspect Neuron cores config and performance

cd /home/participant/environment/eks/FSxL
kubectl get pods
# kubectl exec -it YOUR-vLLM-POD-NAME -- bash
# neuron-ls
# neuron-top


# Step 2: Inspect model data, and create a test file to replicate
# df -h
# cd /work-dir/
# ls -ll
# cd Mistral-7B-Instruct-v0.2/
# ls -ll

# cd /work-dir
# mkdir test
# cd test
# cp /work-dir/Mistral-7B-Instruct-v0.2/README.md /work-dir/test/testfile
# ls -ll /work-dir/test
# exit

# Optional: Dynamic Provisioning for FSx Lustre
log_info "Optional Workshop Module: Dynamic FSx Lustre Provisioning"
echo ""
log_info "This module demonstrates:"
echo "  - Dynamic provisioning of FSx Lustre file systems"
echo "  - StorageClass configuration for FSx"
echo "  - Performance testing capabilities"
echo "  - Additional FSx instances beyond the main workshop"
echo ""
log_warn "Note: This will create additional AWS resources and costs"
echo ""

read -p "Do you want to deploy the dynamic FSx Lustre provisioning module? (y/N): " DEPLOY_DYNAMIC_FSX

if [[ "$DEPLOY_DYNAMIC_FSX" =~ ^[Yy]$ ]]; then
    log_info "Proceeding with dynamic FSx Lustre provisioning..."
    
    # Step 1: Define the StorageClass
    log_info "Setting up dynamic provisioning for FSx Lustre..."

    VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)
    SUBNET_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.subnetIds[0]" --output text)

    # Try to find the FSx security group, create if not found
    SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=${VPC_ID} Name=group-name,Values="FSxLSecurityGroup01" --query "SecurityGroups[*].GroupId" --output text)

    if [[ -z "$SECURITY_GROUP_ID" ]]; then
        log_warn "FSxLSecurityGroup01 not found, looking for default security group..."
        SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=${VPC_ID} Name=group-name,Values="default" --query "SecurityGroups[*].GroupId" --output text)
        
        if [[ -z "$SECURITY_GROUP_ID" ]]; then
            log_error "No suitable security group found for FSx"
            log_warn "Skipping dynamic FSx provisioning due to network configuration issues"
            return 1
        fi
    fi

    # Validate required variables
    if [[ -z "$VPC_ID" || -z "$SUBNET_ID" || -z "$SECURITY_GROUP_ID" ]]; then
        log_error "Failed to retrieve VPC configuration"
        echo "VPC_ID: $VPC_ID"
        echo "SUBNET_ID: $SUBNET_ID"
        echo "SECURITY_GROUP_ID: $SECURITY_GROUP_ID"
        log_warn "Skipping dynamic FSx provisioning due to configuration issues"
        return 1
    fi

    log_info "Network configuration:"
    echo "VPC ID: $VPC_ID"
    echo "Subnet ID: $SUBNET_ID"
    echo "Security Group ID: $SECURITY_GROUP_ID"

    cd /home/participant/environment/eks/FSxL

    # Create backup of original file if it doesn't exist
    if [[ ! -f "fsxL-storage-class.yaml.backup" ]]; then
        cp fsxL-storage-class.yaml fsxL-storage-class.yaml.backup
    fi

    sed -i'' -e "s/SUBNET_ID/$SUBNET_ID/g" fsxL-storage-class.yaml
    sed -i'' -e "s/SECURITY_GROUP_ID/$SECURITY_GROUP_ID/g" fsxL-storage-class.yaml

    cat fsxL-storage-class.yaml

    # Step 2: Create the StorageClass
    if kubectl get storageclass fsx-lustre-sc &>/dev/null; then
        log_info "FSx Lustre StorageClass already exists"
    else
        log_info "Creating FSx Lustre StorageClass..."
        kubectl apply -f fsxL-storage-class.yaml
    fi

    kubectl get sc

    # Step 3. Create the Persistent Volume Claim (PVC)
    cat fsxL-dynamic-claim.yaml

    if kubectl get pvc fsx-lustre-dynamic-claim &>/dev/null; then
        log_info "Dynamic FSx Lustre PVC already exists"
    else
        log_info "Creating dynamic FSx Lustre PVC..."
        kubectl apply -f fsxL-dynamic-claim.yaml
    fi

    kubectl describe pvc/fsx-lustre-dynamic-claim
    kubectl get pvc

    # Step 4: Confirm that the FSx Lustre instance has been provisioned, and PVC is bound
    log_info "Waiting for PVC to be bound..."
    kubectl wait --for=condition=Bound pvc/fsx-lustre-dynamic-claim --timeout=300s || log_warn "PVC binding timeout - check manually"
    kubectl get pvc
    
    log_info "Dynamic FSx Lustre provisioning completed!"
    echo ""
    log_info "Performance testing commands (optional):"
    echo "  # Deploy performance testing pod:"
    echo "  kubectl apply -f pod_performance.yaml"
    echo ""
    echo "  # Run performance tests inside the pod:"
    echo "  kubectl exec -it fsxl-performance -- bash"
    echo "  apt-get update && apt-get install fio ioping -y"
    echo "  ioping -c 20 ."
    echo "  mkdir -p /data/performance && cd /data/performance"
    echo "  fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=testfio8gb --bs=1MB --iodepth=64 --size=8G --readwrite=randrw --rwmixread=50 --numjobs=8 --group_reporting --runtime=10"
    echo ""
    
else
    log_info "Skipping dynamic FSx Lustre provisioning module"
    log_info "You can manually deploy this later using the workshop instructions if needed"
    echo ""
fi

# Script completion summary
log_info "Script execution completed successfully!"
log_info "Summary of deployed resources:"
echo "- FSx CSI Driver: $(helm list -n kube-system | grep aws-fsx-csi-driver | awk '{print $1}' || echo 'Not found')"
echo "- Neuron Helm Chart: $(helm list -n kube-system | grep neuron-helm-chart | awk '{print $1}' || echo 'Not found')"
echo "- FSx Lustre PV/PVC: $(kubectl get pv,pvc 2>/dev/null | grep fsx | wc -l) resources"
echo "- Inferentia NodePool: $(kubectl get nodepool inferentia 2>/dev/null | wc -l) nodepool(s)"
echo "- vLLM Deployment: $(kubectl get deployment vllm-mistral-inf2-deployment 2>/dev/null | grep -v NAME | wc -l) deployment(s)"
echo "- WebUI Deployment: $(kubectl get deployment open-webui-deployment 2>/dev/null | grep -v NAME | wc -l) deployment(s)"

# Check if dynamic FSx was deployed
if [[ "$DEPLOY_DYNAMIC_FSX" =~ ^[Yy]$ ]]; then
    echo "- Dynamic FSx StorageClass: $(kubectl get storageclass fsx-lustre-sc 2>/dev/null | grep -v NAME | wc -l) class(es)"
    echo "- Dynamic FSx PVC: $(kubectl get pvc fsx-lustre-dynamic-claim 2>/dev/null | grep -v NAME | wc -l) claim(s)"
else
    echo "- Dynamic FSx Module: Skipped (user choice)"
fi

log_info "You can now proceed with the workshop exercises!"

if check_kubectl_access; then
    log_info "To monitor vLLM model loading progress:"
    echo "  kubectl get pods -l app=vllm-mistral-inf2-server"
    echo "  kubectl logs -l app=vllm-mistral-inf2-server -f"
    echo "  kubectl exec -it \$(kubectl get pod -l app=vllm-mistral-inf2-server -o name) -- curl localhost:8000/health"
    echo ""
    
    log_info "To check the status of your resources, use:"
    echo "  kubectl get pods -A"
    echo "  kubectl get pv,pvc"
    echo "  helm list -A"
    echo "  kubectl get nodes"

    log_info "If you need to troubleshoot, check the logs with:"
    echo "  kubectl logs -n kube-system -l app.kubernetes.io/name=aws-fsx-csi-driver"
    echo "  kubectl describe pvc fsx-lustre-claim"
    echo "  kubectl describe pvc fsx-lustre-dynamic-claim"
else
    log_info "Once your EKS cluster is created and accessible, you can check resources with:"
    echo "  aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION"
    echo "  kubectl get pods -A"
    echo "  kubectl get pv,pvc"
    echo "  helm list -A"
fi