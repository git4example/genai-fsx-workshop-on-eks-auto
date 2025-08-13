#!/bin/bash
# AWS Sponsored Workshop
# Validate the IAM role
aws sts get-caller-identity

# Set the Amazon EKS cluster variables :
export CLUSTER_NAME=eksworkshop
echo $AWS_REGION
echo $CLUSTER_NAME

# Update the kube-config file:
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
kubectl get nodes

# Deploy CSI Driver
# Step 1: Create an IAM policy, and service account, that allows the CSI driver to make the AWS API calls on your behalf
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

# Step 3: Create a Kubernetes service account for the driver and attach the policy to the service account
eksctl create iamserviceaccount \
    --region $AWS_REGION \
    --cluster=$CLUSTER_NAME \
    --namespace kube-system \
    --name=fsx-csi-controller-sa \
    --attach-policy-arn arn:aws:iam::$AWS_ACCOUNTID:policy/Amazon_FSx_Lustre_CSI_Driver \
    --role-name=fsx-csi-controller-sa \
    --role-only \
    --approve   

# Step 4: Save the Role ARN that was created into a variable
export ROLE_ARN=$(aws cloudformation describe-stacks --stack-name "eksctl-${CLUSTER_NAME}-addon-iamserviceaccount-kube-system-fsx-csi-controller-sa" --query "Stacks[0].Outputs[0].OutputValue"  --region $AWS_REGION --output text)
echo $ROLE_ARN

# Step 5: Deploy the CSI driver of FSx for Lustre
helm repo add aws-fsx-csi-driver https://kubernetes-sigs.github.io/aws-fsx-csi-driver
helm repo update

helm upgrade --install aws-fsx-csi-driver aws-fsx-csi-driver/aws-fsx-csi-driver \
    --namespace kube-system \
    --version 1.11.0 \
    --set serviceAccount.create=true \
    --set serviceAccount.name=fsx-csi-controller-sa \
    --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$ROLE_ARN

kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-fsx-csi-driver

# Create Persistent Volume on EKS Cluster
cd /home/participant/environment/eks/FSxL

FSX_SYSTEMS=$(aws fsx describe-file-systems --query 'FileSystems[*].[FileSystemId,DNSName,LustreConfiguration.MountName]' --output json)

# Count the number of file systems
FSX_COUNT=$(echo $FSX_SYSTEMS | jq length)

if [ "$FSX_COUNT" -eq 0 ]; then
    echo "No FSx for Lustre file systems found in this region."
    exit 1
elif [ "$FSX_COUNT" -eq 1 ]; then
    echo "Single FSx for Lustre file system found. Using it automatically."
    SYSTEM_INFO=$(echo $FSX_SYSTEMS | jq -r '.[0] | @tsv')
else
    echo "Multiple FSx for Lustre File Systems found:"
    echo $FSX_SYSTEMS | jq -r '.[] | @tsv' | column -t -s $'\t'
    
    # Prompt user to select a file system
    read -p "Enter the FileSystemId of the FSx file system you want to use: " FSXL_VOLUME_ID
    
    # Fetch details for the selected file system
    SYSTEM_INFO=$(aws fsx describe-file-systems --file-system-ids $FSXL_VOLUME_ID --query 'FileSystems[0].[FileSystemId,DNSName,LustreConfiguration.MountName]' --output text)
fi

# Parse the output and export variables
IFS=$'\t' read -r FSXL_VOLUME_ID DNS_NAME MOUNT_NAME <<< "$SYSTEM_INFO"
export FSXL_VOLUME_ID
export DNS_NAME
export MOUNT_NAME

# Display the results
echo "Selected File System Details:"
echo "FileSystemId: $FSXL_VOLUME_ID"
echo "DNS Name: $DNS_NAME"
echo "Mount Name: $MOUNT_NAME"
echo "Environment variables FSXL_VOLUME_ID, DNS_NAME, and MOUNT_NAME have been set."

# FSXL_VOLUME_ID=$(aws fsx describe-file-systems --query 'FileSystems[].FileSystemId' --output text)
# DNS_NAME=$(aws fsx describe-file-systems --query 'FileSystems[].DNSName' --output text)
# MOUNT_NAME=$(aws fsx describe-file-systems --query 'FileSystems[].LustreConfiguration.MountName' --output text)

sed -i'' -e "s/FSXL_VOLUME_ID/$FSXL_VOLUME_ID/g" fsxL-persistent-volume.yaml
sed -i'' -e "s/DNS_NAME/$DNS_NAME/g" fsxL-persistent-volume.yaml
sed -i'' -e "s/MOUNT_NAME/$MOUNT_NAME/g" fsxL-persistent-volume.yaml

cat fsxL-persistent-volume.yaml

kubectl apply -f fsxL-persistent-volume.yaml

kubectl apply -f fsxL-claim.yaml
kubectl get pv,pvc

# Deploy Generative AI Chat application
# Deploy vLLM on AWS Inferentia nodes for model Inference

# Step 1: Neuron Device Plugin, Neuron Scheduler, and Node Problem Detector
cd /home/participant/environment/terraform

helm upgrade --install neuron-helm-chart \
    oci://public.ecr.aws/neuron/neuron-helm-chart \
    --namespace kube-system \
    --version 1.2.0 \
    -f ./helm-values/neuron-values.yaml

# Step 2: Create EKS Auto NodePool and EC2 NodeClass for AWS Inferentia Accelerators

NODE_ROLE=$(cd /home/participant/environment/terraform && terraform output --raw eks_node_iam_role_name)
cd /home/participant/environment/eks/genai
sed -i'' -e "s/NODE_ROLE/$NODE_ROLE/g" inferentia_nodepool.yaml

cat inferentia_nodepool.yaml
kubectl apply -f inferentia_nodepool.yaml
kubectl get nodepool,nodeclass inferentia

# Step 3: Deploy the vLLM application Pod
kubectl apply -f mistral-fsxl.yaml
cat mistral-fsxl.yaml

kubectl get pod

# Deploy WebUI chat application to interact with model
kubectl apply -f open-webui.yaml
sleep 60
kubectl get ing

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

# Use Dynamic Provisioning to deploy a new PV and FSx Lustre instance for testing
# Step 1: Define the StorageClass

VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)
SUBNET_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.subnetIds[0]" --output text)
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=${VPC_ID} Name=group-name,Values="FSxLSecurityGroup01"  --query "SecurityGroups[*].GroupId" --output text)  

echo $SUBNET_ID
echo $SECURITY_GROUP_ID

cd /home/participant/environment/eks/FSxL

sed -i'' -e "s/SUBNET_ID/$SUBNET_ID/g" fsxL-storage-class.yaml
sed -i'' -e "s/SECURITY_GROUP_ID/$SECURITY_GROUP_ID/g" fsxL-storage-class.yaml

cat fsxL-storage-class.yaml

# Step 2: Create the StorageClass

kubectl apply -f fsxL-storage-class.yaml

kubectl get sc

# Step 3. Create the Persistent Volume Claim (PVC)
cat fsxL-dynamic-claim.yaml

kubectl apply -f fsxL-dynamic-claim.yaml
kubectl describe pvc/fsx-lustre-dynamic-claim
kubectl get pvc

# Step 4: Confirm that the FSx Lustre instance has been provisioned, and PVC is bound

kubectl get pvc

# Performance testing
# Step 1: Provision the testing pod using a yaml file and the 10 GB storage on FSx for Lustre
# cd /home/participant/environment/eks/FSxL
# aws ec2 describe-subnets --subnet-id $SUBNET_ID --region $AWS_REGION | jq .Subnets[0].AvailabilityZone

# vi pod_performance.yaml
# kubectl apply -f pod_performance.yaml
# kubectl get pods

# Step 2: Log in to the container and perform FIO and IOping testing
# kubectl exec -it fsxl-performance  -- bash
# apt-get update
# apt-get install fio ioping -y
# ioping -c 20 .

# mkdir -p /data/performance
# cd /data/performance
# fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=testfio8gb --bs=1MB --iodepth=64 --size=8G --readwrite=randrw --rwmixread=50 --numjobs=8 --group_reporting --runtime=10

# exit