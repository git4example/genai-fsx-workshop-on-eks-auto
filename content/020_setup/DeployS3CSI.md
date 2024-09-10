---
title : "Deploy S3 CSI Driver to EKS cluster"
weight : 12
hidden : false
---
-------------------------------------------------------------



```bash
cd /home/ec2-user/environment/eks/S3
```


```bash
CLUSTER_NAME=eksworkshop
K8S_VERSION=1.30
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)
SUBNET_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.subnetIds[0]" --output text)
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=${VPC_ID} Name=group-name,Values="FSxLSecurityGroup01"  --query "SecurityGroups[*].GroupId" --output text)  
S3_BUCKET=$(aws s3 ls | grep fsx-lustre | grep -v fsx-lustre-2ndregion | awk '{print$3}')
S3_BUCKET_2NDREGION=$(aws s3 ls | grep fsx-lustre-2ndregion | awk '{print$3}')
```


```bash
export AMD_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2/recommended/image_id --query Parameter.Value --output text)"
#export ARM_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-arm64/recommended/image_id --query Parameter.Value --output text)"
#export GPU_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-gpu/recommended/image_id --query Parameter.Value --output text)"
```

```bash
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["4"]
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmpty
    # expireAfter: 720h # 30 * 24h = 720h
    consolidateAfter: 180s
  weight: 100
---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2 # Amazon Linux 2
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        deleteOnTermination: true
        volumeSize: 100Gi
        volumeType: gp3
        iops: 10000
        throughput: 1000

  role: "Karpenter-eksworkshop" 
  subnetSelectorTerms:          
    - tags:
        karpenter.sh/discovery: "eksworkshop"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "eksworkshop"
  amiSelectorTerms:
    - id: "${AMD_AMI_ID}"
EOF
```








```bash
cat << EOF | envsubst >  s3-csi-driver.json
{
   "Version": "2012-10-17",
   "Statement": [
        {
            "Sid": "MountpointFullBucketAccess",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$S3_BUCKET"
            ]
        },
        {
            "Sid": "MountpointFullObjectAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::$S3_BUCKET/*"
            ]
        }
   ]
}
EOF
```

```bash
aws iam create-policy \
        --policy-name AmazonS3CSIDriverPolicy \
        --policy-document file://s3-csi-driver.json
```



```bash
ROLE_NAME=AmazonEKS_S3_CSI_DriverRole
eksctl create iamserviceaccount \
    --name s3-csi-driver-sa \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AmazonS3CSIDriverPolicy \
    --approve \
    --role-name $ROLE_NAME \
    --region $AWS_REGION \
    --role-only
```

```bash
eksctl create addon --name aws-mountpoint-s3-csi-driver --cluster $CLUSTER_NAME--service-account-role-arn arn:aws:iam::$ACCOUNT_ID:role/AmazonEKS_S3_CSI_DriverRole --force
```


```bash
sed -i'' -e "s/S3_BUCKET/$S3_BUCKET/g" static_provisioning.yaml
sed -i'' -e "s/AWS_REGION/$AWS_REGION/g" static_provisioning.yaml
```

## S3 Mount

```bash
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: s3-pv
spec:
  capacity:
    storage: 1200Gi # ignored, required
  accessModes:
    - ReadWriteMany # supported options: ReadWriteMany / ReadOnlyMany
  mountOptions:
    - allow-delete
    - region $AWS_REGION
    # - prefix some-s3-prefix/
  csi:
    driver: s3.csi.aws.com # required
    volumeHandle: s3-csi-driver-volume
    volumeAttributes:
      bucketName: $S3_BUCKET
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: s3-claim
spec:
  accessModes:
    - ReadWriteMany # supported options: ReadWriteMany / ReadOnlyMany
  storageClassName: "" # required for static provisioning
  resources:
    requests:
      storage: 1200Gi # ignored, required
  volumeName: s3-pv
---
apiVersion: v1
kind: Pod
metadata:
  name: s3-app
spec:
  nodeSelector:
    karpenter.sh/nodepool: default
  containers:
  - name: download
    # image: public.ecr.aws/u3r1l1j7/eks-genai:neuronrayvllm-100G-root
    image: shaowenchen/huggingface-cli
    command:
    - huggingface-cli
    - download
    - "enghwa/neuron-mistral7bv0.2"
    - "--local-dir"
    - "/work-dir/Mistral-7B-Instruct-v0.2"
    volumeMounts:
      - name: persistent-storage
        mountPath: /work-dir
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: s3-claim
EOF
```


## Luster Mount

```bash
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: fsx-lustre-pv
spec:
  capacity:
    storage: 1200Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  mountOptions:
    - flock
  persistentVolumeReclaimPolicy: Recycle
  csi:
    driver: fsx.csi.aws.com
    volumeHandle: fs-093eecd064b7eafc3
    volumeAttributes:
      dnsname: fs-093eecd064b7eafc3.fsx.ap-southeast-2.amazonaws.com
      mountname: ym6trbev
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fsx-lustre-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  resources:
    requests:
      storage: 1200Gi
  volumeName: fsx-lustre-pv
---
apiVersion: v1
kind: Pod
metadata:
  name: fsx-lustre-app
spec:
  nodeSelector:
    karpenter.sh/nodepool: default
  containers:
  - name: download
    # image: public.ecr.aws/u3r1l1j7/eks-genai:neuronrayvllm-100G-root
    image: shaowenchen/huggingface-cli
    command:
    - huggingface-cli
    - download
    - "enghwa/neuron-mistral7bv0.2"
    - "--local-dir"
    - "/work-dir/Mistral-7B-Instruct-v0.2"
    volumeMounts:
      - name: persistent-storage
        mountPath: /work-dir
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: fsx-lustre-pvc
EOF
```



