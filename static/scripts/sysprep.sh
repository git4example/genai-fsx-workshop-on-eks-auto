#!/bin/bash

aws sts get-caller-identity
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
export CLUSTER_NAME=eksworkshop
echo $AWS_REGION
echo $CLUSTER_NAME
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
cd /home/participant/environment/eks/FSxL
AWS_ACCOUNTID=$(aws sts get-caller-identity --query "Account" --output text)
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

aws iam create-policy \
        --policy-name Amazon_FSx_Lustre_CSI_Driver \
        --policy-document file://fsx-csi-driver.json

eksctl create iamserviceaccount \
    --region $AWS_REGION \
    --name fsx-csi-controller-sa \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn arn:aws:iam::$AWS_ACCOUNTID:policy/Amazon_FSx_Lustre_CSI_Driver \
    --approve

export ROLE_ARN=$(aws cloudformation describe-stacks --stack-name "eksctl-${CLUSTER_NAME}-addon-iamserviceaccount-kube-system-fsx-csi-controller-sa" --query "Stacks[0].Outputs[0].OutputValue"  --region $AWS_REGION --output text)
echo $ROLE_ARN

kubectl apply -k "github.com/kubernetes-sigs/aws-fsx-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.2"
kubectl annotate serviceaccount -n kube-system fsx-csi-controller-sa eks.amazonaws.com/role-arn=$ROLE_ARN --overwrite=true
kubectl get sa/fsx-csi-controller-sa -n kube-system -o yaml


# Get all FSx for Lustre file systems in the region
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

sed -i'' -e "s/FSXL_VOLUME_ID/$FSXL_VOLUME_ID/g" fsxL-persistent-volume.yaml
sed -i'' -e "s/DNS_NAME/$DNS_NAME/g" fsxL-persistent-volume.yaml
sed -i'' -e "s/MOUNT_NAME/$MOUNT_NAME/g" fsxL-persistent-volume.yaml


cat fsxL-persistent-volume.yaml

kubectl apply -f fsxL-persistent-volume.yaml
kubectl apply -f fsxL-claim.yaml
kubectl get pv,pvc


ASSET_BUCKET=$(aws cloudformation describe-stacks --stack-name genaifsxworkshoponeks --query "Stacks[0].Parameters[?ParameterKey=='Assets'].ParameterValue" --output text)
ASSET_BUCKET=$(echo $ASSET_BUCKET | sed 's/\/assets\///')    
ASSET_BUCKET=$ASSET_BUCKET/static
aws s3 sync $ASSET_BUCKET/download/ /home/participant/environment/download    
cd /home/participant/environment/download

sed -i'' -e "s/FSXL_VOLUME_ID/$FSXL_VOLUME_ID/g" sysprep-new.yaml
sed -i'' -e "s/DNS_NAME/$DNS_NAME/g" sysprep-new.yaml
sed -i'' -e "s/MOUNT_NAME/$MOUNT_NAME/g" sysprep-new.yaml

kubectl apply -f sysprep-nodepool.yaml
kubectl apply -f sysprep-new.yaml

sed -i'' -e "s/FSXL_VOLUME_ID/$FSXL_VOLUME_ID/g" check.yaml
sed -i'' -e "s/DNS_NAME/$DNS_NAME/g" check.yaml
sed -i'' -e "s/MOUNT_NAME/$MOUNT_NAME/g" check.yaml

kubectl apply -f check.yaml