---
title : "Model Download and Upload"
weight : 13
hidden : false
---
-------------------------------------------------------------



```bash
cd /home/ec2-user/environment/eks/download
```


```bash
CLUSTER_NAME=eksworkshop
K8S_VERSION=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query cluster.version --output text)
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)
SUBNET_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.subnetIds[0]" --output text)
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=${VPC_ID} Name=group-name,Values="FSxLSecurityGroup01"  --query "SecurityGroups[*].GroupId" --output text)  
S3_BUCKET=$(aws s3 ls | grep fsx-lustre | grep -v fsx-lustre-2ndregion | awk '{print$3}')
S3_BUCKET_2NDREGION=$(aws s3 ls | grep fsx-lustre-2ndregion | awk '{print$3}')
```


```bash
export AMD_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2/recommended/image_id --query Parameter.Value --output text)"
```

```bash
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: download
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
        name: download
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
  name: download
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
cat << EOF | envsubst >  s3-upload.json
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
        --policy-name AmazonS3UploadPolicy \
        --policy-document file://s3-upload.json
```



```bash
ROLE_NAME=AmazonEKS_S3_Upload
eksctl create iamserviceaccount \
    --name s3-upload \
    --namespace default \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AmazonS3UploadPolicy \
    --approve \
    --role-name $ROLE_NAME \
    --region $AWS_REGION
```



```bash
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: s3-upload
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::$ACCOUNT_ID:role/AmazonEKS_S3_Upload
EOF
```


## Model Download Upload

```bash
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: download-upload-mistral
spec:  
  template:
    metadata:
      labels:
        app: download-upload-mistral
    spec:
      serviceAccountName: s3-upload
      nodeSelector:
        karpenter.sh/nodepool: download
      restartPolicy: OnFailure
      initContainers:
      - name: download
        image: hello2parikshit/huggingface-cli
        command:
        - huggingface-cli
        - download
        - "enghwa/neuron-mistral7bv0.2"
        - "--local-dir"
        - "/work-dir/Mistral-7B-Instruct-v0.2"
        volumeMounts:
        - name: workdir
          mountPath: "/work-dir"
      containers:
      - name: upload
        image: hello2parikshit/s5cmd
        args:
        - sync 
        - /work-dir/Mistral-7B-Instruct-v0.2
        - s3://$S3_BUCKET/
        volumeMounts:
        - name: workdir
          mountPath: "/work-dir"
      volumes:
      - name: workdir
        emptyDir: {}
EOF
```




```bash
alias kl='kubectl -n karpenter logs -l app.kubernetes.io/name=karpenter --all-containers=true -f --tail=20'
```

## DOWNLOAD AND UPLOAD FINISHED IN ABOUT 6 - 7 MINS
```bash
WSParticipantRole:~/environment $ kg po -w
NAME                             READY   STATUS     RESTARTS   AGE
download-upload-mistral-lt2qw    0/1     Init:0/1   0          8s
kube-ops-view-5d9d967b77-hs5zq   1/1     Running    0          4h44m
download-upload-mistral-lt2qw    0/1     PodInitializing   0          3m39s
download-upload-mistral-lt2qw    1/1     Running           0          3m41s
download-upload-mistral-lt2qw    0/1     Completed         0          6m14s
```

# 2nd Run finished in 10 mins
```bash
WSParticipantRole:~/environment/eks/download $ kg po -w
NAME                             READY   STATUS    RESTARTS   AGE
download-upload-mistral-x5gnz    0/1     Pending   0          3s
kube-ops-view-5d9d967b77-nx7hv   1/1     Running   0          10m
download-upload-mistral-x5gnz    0/1     Pending   0          30s
download-upload-mistral-x5gnz    0/1     Init:0/1   0          30s
download-upload-mistral-x5gnz    0/1     Init:0/1   0          38s
download-upload-mistral-x5gnz    0/1     PodInitializing   0          7m45s
download-upload-mistral-x5gnz    1/1     Running           0          7m50s
download-upload-mistral-x5gnz    0/1     Completed         0          10m
```