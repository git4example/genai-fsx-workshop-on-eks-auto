#!/bin/bash
# Quick Deploy On-demand Workshop - Automated Setup Script
# 
# PURPOSE: This script provides rapid automated deployment for testing, demos, or when
#          manual setup is not required. For learning purposes, participants should
#          follow the step-by-step instructions in the workshop documentation.
#
# USAGE: ./quick-deploy-on-demand.sh
# 
# This script automates all the manual steps from the workshop README:
# - Tool installation (AWS CLI, Docker, Git, jq)
# - Repository cloning
# - S3 bucket creation and file upload
# - Mistral model download and upload
# - CloudFormation stack deployment
# - Progress monitoring and validation
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

# Function to wait for CloudFormation stack to be ready
wait_for_cloudformation_stack() {
    local stack_name=$1
    local timeout=${2:-3600}  # Default 60 minutes for infrastructure (EKS + FSx can take long)
    local check_interval=60
    local elapsed=0
    local start_time=$(date +%s)
    
    log_info "Waiting for CloudFormation stack ${stack_name} to be ready..."
    log_info "Started at: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "Expected completion: 30-45 minutes (timeout after 60 minutes if needed)"
    
    while [ $elapsed -lt $timeout ]; do
        local stack_status=$(aws cloudformation describe-stacks --stack-name "${stack_name}" --region $AWS_REGION --query 'Stacks[0].StackStatus' --output text 2>/dev/null)
        
        case "$stack_status" in
            "CREATE_COMPLETE"|"UPDATE_COMPLETE")
                local total_minutes=$((elapsed / 60))
                local total_seconds=$((elapsed % 60))
                log_info "CloudFormation stack ${stack_name} is ready (${stack_status})"
                log_info "Total deployment time: ${total_minutes}m ${total_seconds}s"
                return 0
                ;;
            "CREATE_IN_PROGRESS"|"UPDATE_IN_PROGRESS")
                local minutes_elapsed=$((elapsed / 60))
                local seconds_in_current_minute=$((elapsed % 60))
                local minutes_remaining=$(((timeout - elapsed) / 60))
                log_info "CloudFormation stack ${stack_name} is still in progress (${stack_status})"
                log_info "Time elapsed: ${minutes_elapsed}m ${seconds_in_current_minute}s | Timeout in: ${minutes_remaining} minutes"
                
                # Show progress milestones and recent stack events
                if [ $((elapsed % 300)) -eq 0 ] && [ $elapsed -gt 0 ]; then
                    log_info "=== Progress Update (${minutes_elapsed} minutes elapsed) ==="
                    
                    # Show milestone messages
                    if [ $minutes_elapsed -eq 5 ]; then
                        log_info "✓ Initial resources likely created (VPC, IAM roles)"
                    elif [ $minutes_elapsed -eq 15 ]; then
                        log_info "⏳ EKS cluster creation in progress..."
                    elif [ $minutes_elapsed -eq 30 ]; then
                        log_info "⏳ EKS cluster and node groups likely completing..."
                    elif [ $minutes_elapsed -eq 40 ]; then
                        log_info "🔄 Final resources being created, almost done!"
                    elif [ $minutes_elapsed -ge 50 ]; then
                        log_info "⚠️  Taking longer than usual, but still within normal range"
                    fi
                    
                    log_info "Recent stack events:"
                    aws cloudformation describe-stack-events --stack-name "${stack_name}" --region $AWS_REGION --query 'StackEvents[0:5].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' --output table 2>/dev/null || true
                    log_info "=============================================="
                fi
                
                sleep $check_interval
                elapsed=$((elapsed + check_interval))
                ;;
            "CREATE_FAILED"|"UPDATE_FAILED"|"ROLLBACK_COMPLETE"|"ROLLBACK_FAILED")
                log_error "CloudFormation stack ${stack_name} failed with status: ${stack_status}"
                log_error "Failed resources and reasons:"
                aws cloudformation describe-stack-events --stack-name "${stack_name}" --region $AWS_REGION --query 'StackEvents[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`UPDATE_FAILED`].[LogicalResourceId,ResourceStatusReason]' --output table
                log_error "For detailed troubleshooting, check the CloudFormation console:"
                echo "  https://console.aws.amazon.com/cloudformation/home?region=${AWS_REGION}#/stacks/stackinfo?stackId=${stack_name}"
                return 2  # Return 2 for stack failure
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
    
    log_error "Timeout waiting for CloudFormation stack ${stack_name} to be ready after ${timeout} seconds"
    return 1  # Return 1 for timeout
}

# Function to check if S3 bucket exists
check_s3_bucket() {
    local bucket_name=$1
    
    # Suppress all output including JSON responses
    if aws s3api head-bucket --bucket "${bucket_name}" >/dev/null 2>&1; then
        log_info "S3 bucket ${bucket_name} exists"
        return 0
    else
        log_warn "S3 bucket ${bucket_name} does not exist"
        return 1
    fi
}

# Function to get S3 bucket region
get_bucket_region() {
    local bucket_name=$1
    
    # Try multiple methods to get bucket region
    local bucket_region=""
    
    # Method 1: Use get-bucket-location
    bucket_region=$(aws s3api get-bucket-location --bucket "${bucket_name}" --query 'LocationConstraint' --output text 2>/dev/null)
    
    # Method 2: If that fails, try head-bucket with region detection
    if [[ -z "$bucket_region" || "$bucket_region" == "null" || "$bucket_region" == "None" ]]; then
        # For us-east-1 buckets, LocationConstraint returns null/None
        # Try to determine if it's us-east-1 by checking if we can access it from us-east-1
        if aws s3api head-bucket --bucket "${bucket_name}" --region us-east-1 &>/dev/null; then
            bucket_region="us-east-1"
        else
            # Try other common regions
            for region in us-west-2 us-west-1 eu-west-1 eu-central-1 ap-southeast-1 ap-northeast-1; do
                if aws s3api head-bucket --bucket "${bucket_name}" --region "$region" &>/dev/null; then
                    bucket_region="$region"
                    break
                fi
            done
        fi
    fi
    
    # Default to us-east-1 if still not found
    if [[ -z "$bucket_region" || "$bucket_region" == "null" || "$bucket_region" == "None" ]]; then
        bucket_region="us-east-1"
    fi
    
    echo "$bucket_region"
}

# Function to check if bucket is in the same region
check_bucket_region() {
    local bucket_name=$1
    local expected_region=$2
    
    log_info "Checking bucket region for ${bucket_name}..."
    local bucket_region=$(get_bucket_region "$bucket_name")
    
    if [[ "$bucket_region" == "$expected_region" ]]; then
        log_info "Bucket ${bucket_name} is in the correct region (${bucket_region})"
        return 0
    else
        log_warn "Bucket ${bucket_name} is in region ${bucket_region}, but we need ${expected_region}"
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

# Function to validate bucket name
validate_bucket_name() {
    local bucket_name=$1
    
    # Check bucket name length (3-63 characters)
    if [[ ${#bucket_name} -lt 3 || ${#bucket_name} -gt 63 ]]; then
        log_error "Bucket name must be between 3 and 63 characters"
        return 1
    fi
    
    # Check for valid characters (lowercase letters, numbers, hyphens)
    if [[ ! $bucket_name =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
        log_error "Bucket name can only contain lowercase letters, numbers, and hyphens"
        return 1
    fi
    
    # Check that it doesn't start or end with hyphen
    if [[ $bucket_name =~ ^- || $bucket_name =~ -$ ]]; then
        log_error "Bucket name cannot start or end with a hyphen"
        return 1
    fi
    
    return 0
}

# Part 1 : Prerequisite of setting up an On-demand Workshop (using your own AWS account)
log_info "Starting On-demand Workshop Setup..."

# Install AWS CLI if not present
if ! check_command aws; then
    log_info "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
else
    log_info "AWS CLI already installed"
fi

# Install Docker if not present
if ! check_command docker; then
    log_info "Installing Docker..."
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -a -G docker participant
else
    log_info "Docker already installed"
    # Ensure Docker is running
    if ! sudo systemctl is-active --quiet docker; then
        log_info "Starting Docker service..."
        sudo service docker start
    fi
fi

# Test Docker access
log_info "Testing Docker access..."
sudo docker ps

# Install Git if not present
if ! check_command git; then
    log_info "Installing Git..."
    sudo yum install git -y
else
    log_info "Git already installed"
fi

# Install jq if not present
if ! check_command jq; then
    log_info "Installing jq..."
    sudo yum install jq -y
else
    log_info "jq already installed"
fi

git --version

# Configure Git (only if not already configured)
if [[ -z "$(git config --global user.name)" ]]; then
    log_info "Configuring Git user..."
    git config --global user.name "Workshop Participant"
    git config --global user.email "participant@workshop.example.com"
else
    log_info "Git already configured"
fi

# Clone repository if not already present
if [[ ! -d "genai-fsx-workshop-on-eks-auto" ]]; then
    log_info "Cloning workshop repository..."
    git clone https://github.com/git4example/genai-fsx-workshop-on-eks-auto.git
else
    log_info "Workshop repository already exists"
fi

# Get AWS region and validate credentials
log_info "Detecting AWS region and validating credentials..."
export TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

if [[ -z "$AWS_REGION" ]]; then
    log_error "Failed to detect AWS region from instance metadata"
    exit 1
fi

log_info "Detected AWS Region: $AWS_REGION"

# Validate AWS credentials
if ! aws sts get-caller-identity &>/dev/null; then
    log_error "AWS credentials not configured or invalid"
    exit 1
fi

# Request bucket name with validation
BUCKET_CREATED=false
while true; do
    read -p "Enter S3 bucket name (will create if new, or use existing if in same region): " ASSET_BUCKET
    
    if [[ -z "$ASSET_BUCKET" ]]; then
        log_error "Bucket name cannot be empty"
        continue
    fi
    
    if ! validate_bucket_name "$ASSET_BUCKET"; then
        continue
    fi
    
    # Check if bucket already exists
    if check_s3_bucket "$ASSET_BUCKET"; then
        # Bucket exists, check if it's in the same region
        if check_bucket_region "$ASSET_BUCKET" "$AWS_REGION"; then
            log_info "Using existing bucket $ASSET_BUCKET in region $AWS_REGION"
            BUCKET_CREATED=false
            break
        else
            BUCKET_REGION=$(get_bucket_region "$ASSET_BUCKET")
            log_error "Bucket $ASSET_BUCKET exists in region $BUCKET_REGION, but we need it in $AWS_REGION"
            log_error "Please choose a different bucket name or use a bucket in $AWS_REGION"
            continue
        fi
    else
        # Bucket doesn't exist, we'll create it
        log_info "Bucket $ASSET_BUCKET doesn't exist, will create it in region $AWS_REGION"
        BUCKET_CREATED=true
        break
    fi
done

# Create S3 bucket if it doesn't exist
if [ "$BUCKET_CREATED" = true ]; then
    log_info "Creating S3 bucket: $ASSET_BUCKET"
    if [[ "$AWS_REGION" == "us-east-1" ]]; then
        # us-east-1 doesn't need LocationConstraint
        aws s3api create-bucket --bucket $ASSET_BUCKET --region $AWS_REGION
    else
        aws s3api create-bucket --bucket $ASSET_BUCKET --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION
    fi
    
    # Wait for bucket to be available
    log_info "Waiting for bucket to be available..."
    aws s3api wait bucket-exists --bucket $ASSET_BUCKET
else
    log_info "Using existing bucket: $ASSET_BUCKET"
fi

# Check if workshop files already exist in S3
log_info "Checking for existing workshop files in S3..."
if aws s3 ls s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto/ &>/dev/null; then
    log_info "Workshop files already exist in S3 bucket"
    read -p "Do you want to update the workshop files? (y/N): " UPDATE_FILES
    
    if [[ "$UPDATE_FILES" =~ ^[Yy]$ ]]; then
        log_info "Updating workshop files in S3..."
        aws s3 sync ./genai-fsx-workshop-on-eks-auto s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto
    else
        log_info "Skipping workshop files update"
    fi
else
    log_info "Uploading workshop files to S3..."
    aws s3 sync ./genai-fsx-workshop-on-eks-auto s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto
fi

# Download Mistral Model
log_info "Downloading Mistral Model (this may take several minutes)..."
if [[ ! -d "./work-dir/Mistral-7B-Instruct-v0.2" ]]; then
    mkdir -p ./work-dir
    sudo docker run -v ./work-dir/:/work-dir/ --entrypoint huggingface-cli public.ecr.aws/parikshit/huggingface-cli:slim download "enghwa/neuron-mistral7bv0.2" --local-dir /work-dir/Mistral-7B-Instruct-v0.2
else
    log_info "Mistral model already downloaded"
fi

# Get AWS credentials from instance metadata
log_info "Retrieving AWS credentials from instance metadata..."
export ROLE_NAME=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/)
export CREDENTIALS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME)
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Token')

# Validate credentials were retrieved
if [[ -z "$AWS_ACCESS_KEY_ID" || "$AWS_ACCESS_KEY_ID" == "null" ]]; then
    log_error "Failed to retrieve AWS credentials from instance metadata"
    exit 1
fi

log_info "AWS credentials retrieved successfully"

# Upload model to S3
ASSET_BUCKET_PATH=genai-fsx-workshop-on-eks-auto

# Check if Mistral model already exists in S3
log_info "Checking for existing Mistral model in S3..."
if aws s3 ls s3://${ASSET_BUCKET}/${ASSET_BUCKET_PATH}/assets/Mistral-7B-Instruct-v0.2/ &>/dev/null; then
    log_info "Mistral model already exists in S3 bucket"
    read -p "Do you want to re-upload the Mistral model? (y/N): " UPLOAD_MODEL
    
    if [[ "$UPLOAD_MODEL" =~ ^[Yy]$ ]]; then
        log_info "Re-uploading Mistral model to S3 (this may take several minutes)..."
        sudo docker run -e AWS_DEFAULT_REGION=$AWS_REGION \
          -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
          -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
          -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
          -v ./work-dir/:/work-dir/  public.ecr.aws/parikshit/s5cmd cp /work-dir/Mistral-7B-Instruct-v0.2/ s3://${ASSET_BUCKET}/${ASSET_BUCKET_PATH}/assets/Mistral-7B-Instruct-v0.2/
    else
        log_info "Skipping Mistral model upload"
    fi
else
    log_info "Uploading Mistral model to S3 (this may take several minutes)..."
    sudo docker run -e AWS_DEFAULT_REGION=$AWS_REGION \
      -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
      -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
      -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
      -v ./work-dir/:/work-dir/  public.ecr.aws/parikshit/s5cmd cp /work-dir/Mistral-7B-Instruct-v0.2/ s3://${ASSET_BUCKET}/${ASSET_BUCKET_PATH}/assets/Mistral-7B-Instruct-v0.2/
fi

# Part 2 : Provision workshop resources
log_info "Starting CloudFormation stack deployment..."

STACK_NAME=GenAIFSXWorkshopOnEKS
VSINSTANCE_NAME=VSCodeServerForEKS
ASSET_BUCKET_ZIPPATH=""
ASSET_BUCKET_PATH=genai-fsx-workshop-on-eks-auto

# Validate CloudFormation template
log_info "Validating CloudFormation template..."
aws cloudformation validate-template --template-url https://${ASSET_BUCKET}.s3.amazonaws.com/${ASSET_BUCKET_PATH}/static/GenAIFSXWorkshopOnEKS.yaml > validate_cfn.txt

if [[ $? -eq 0 ]]; then
    log_info "CloudFormation template validation successful"
    cat validate_cfn.txt
else
    log_error "CloudFormation template validation failed"
    cat validate_cfn.txt
    exit 1
fi

# Check if stack already exists
if check_cloudformation_stack "$STACK_NAME"; then
    log_warn "CloudFormation stack $STACK_NAME already exists"
    read -p "Do you want to update the existing stack? (y/N): " UPDATE_STACK
    
    if [[ "$UPDATE_STACK" =~ ^[Yy]$ ]]; then
        log_info "Updating existing CloudFormation stack..."
        aws cloudformation update-stack \
          --stack-name ${STACK_NAME} \
          --template-url https://${ASSET_BUCKET}.s3.amazonaws.com/${ASSET_BUCKET_PATH}/static/GenAIFSXWorkshopOnEKS.yaml \
          --region $AWS_REGION \
          --parameters \
          ParameterKey=VSCodeUser,ParameterValue=participant \
          ParameterKey=InstanceName,ParameterValue=${VSINSTANCE_NAME} \
          ParameterKey=InstanceVolumeSize,ParameterValue=100 \
          ParameterKey=InstanceType,ParameterValue=t4g.medium \
          ParameterKey=InstanceOperatingSystem,ParameterValue=AmazonLinux-2023 \
          ParameterKey=HomeFolder,ParameterValue=environment \
          ParameterKey=DevServerPort,ParameterValue=8081 \
          ParameterKey=AssetZipS3Path,ParameterValue=${ASSET_BUCKET_ZIPPATH} \
          ParameterKey=Assets,ParameterValue=s3://${ASSET_BUCKET}/${ASSET_BUCKET_PATH}/assets/ \
          --capabilities CAPABILITY_NAMED_IAM
    else
        log_info "Skipping stack update"
    fi
else
    log_info "Creating CloudFormation stack..."
    aws cloudformation create-stack \
      --stack-name ${STACK_NAME} \
      --template-url https://${ASSET_BUCKET}.s3.amazonaws.com/${ASSET_BUCKET_PATH}/static/GenAIFSXWorkshopOnEKS.yaml \
      --region $AWS_REGION \
      --parameters \
      ParameterKey=VSCodeUser,ParameterValue=participant \
      ParameterKey=InstanceName,ParameterValue=${VSINSTANCE_NAME} \
      ParameterKey=InstanceVolumeSize,ParameterValue=100 \
      ParameterKey=InstanceType,ParameterValue=t4g.medium \
      ParameterKey=InstanceOperatingSystem,ParameterValue=AmazonLinux-2023 \
      ParameterKey=HomeFolder,ParameterValue=environment \
      ParameterKey=DevServerPort,ParameterValue=8081 \
      ParameterKey=AssetZipS3Path,ParameterValue=${ASSET_BUCKET_ZIPPATH} \
      ParameterKey=Assets,ParameterValue=s3://${ASSET_BUCKET}/${ASSET_BUCKET_PATH}/assets/ \
      --disable-rollback \
      --capabilities CAPABILITY_NAMED_IAM
fi

# Wait for CloudFormation stack to complete (up to 60 minutes)
log_info "Starting CloudFormation stack monitoring..."
log_info "Expected resources being created:"
echo "  - VPC and networking components (5-10 minutes)"
echo "  - IAM roles and policies (2-5 minutes)"
echo "  - EKS cluster (15-20 minutes)"
echo "  - EKS node groups (10-15 minutes)"
echo "  - FSx for Lustre file system (10-15 minutes)"
echo "  - Security groups and other resources (5-10 minutes)"
log_info "Typical completion time: 30-45 minutes (max timeout: 60 minutes)"
log_info "Progress updates will be shown every 5 minutes..."

wait_for_cloudformation_stack "$STACK_NAME" 3600
WAIT_RESULT=$?

if [ $WAIT_RESULT -eq 1 ]; then
    log_error "CloudFormation stack deployment timed out after 60 minutes"
    log_error "Check the CloudFormation console for detailed error information"
    exit 1
elif [ $WAIT_RESULT -eq 2 ]; then
    log_error "CloudFormation stack deployment failed"
    log_error "Check the CloudFormation console for detailed error information"
    exit 1
elif [ $WAIT_RESULT -ne 0 ]; then
    log_error "CloudFormation stack deployment encountered an unexpected error"
    log_error "Check the CloudFormation console for detailed error information"
    exit 1
fi

# Get stack outputs
log_info "Retrieving stack outputs..."
STACK_OUTPUTS=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --region $AWS_REGION --query 'Stacks[0].Outputs' --output json)

if [[ -n "$STACK_OUTPUTS" && "$STACK_OUTPUTS" != "null" ]]; then
    log_info "Stack outputs:"
    echo "$STACK_OUTPUTS" | jq -r '.[] | "\(.OutputKey): \(.OutputValue)"'
else
    log_warn "No stack outputs available"
fi

# Part 3: Access your workshop
log_info "Workshop setup completed successfully!"
log_info "Resources created:"
echo "  - S3 Bucket: $ASSET_BUCKET"
echo "  - CloudFormation Stack: $STACK_NAME"
echo "  - Workshop files uploaded to S3"
echo "  - Mistral model uploaded to S3"

log_info "Next steps:"
echo "  1. Access your VS Code server using the URL from stack outputs"
echo "  2. Follow the step-by-step workshop instructions for learning (Recommended)"
echo "  3. Or run ./quick-deploy-sponsored.sh for automated deployment of workshop"
echo ""
log_info "Workshop Learning Path (Recommended):"
echo "  - Navigate to the workshop documentation"
echo "  - Follow each module step-by-step to understand the architecture"
echo "  - Learn about EKS, FSx and how to deploy GenAI workloads"
echo ""
log_info "Quick Testing Path (only for testing):"
echo "  - Use ./quick-deploy-sponsored.sh for rapid validation"
echo "  - This skips the learning experience but tests functionality"

log_info "Access Information:"
echo "  - VS Code Server: Check CloudFormation stack outputs for URL and password"
echo "  - Workshop Documentation: Available in the VS Code environment"
echo "  - Stack Status: aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION"
echo ""
log_info "Cleanup (when finished):"
echo "  - Run ./cleanup-on-demand.sh to safely remove all resources"
echo "  - This prevents unexpected AWS charges"
echo ""
log_info "Setup completed successfully! Ready for workshop learning experience."