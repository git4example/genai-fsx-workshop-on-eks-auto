
DO NOT FULL SYNC THIS ASSET BUCKET. WE HAVE "neuron-mistral7bv0.2" FOLDER ON THIS BUCKET "s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20" WITH 29 GB OF MODEL WHICH WILL BE DELETED IF YOU FULL SYNC



USE FOLLOWING COMMANDs TO SYNC YOUR LOCAL TO S3 : 
```bash
aws s3 sync ./assets/eks s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20/eks --delete
aws s3 sync ./assets/karpenter s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20/karpenter --delete
aws s3 sync ./assets/terraform s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20/terraform --delete
```

USE FOLLOWING COMMANDs TO SYNC S3 TO LOCAL/CLOUD9 : 
```bash
aws s3 sync s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20/eks /home/ec2-user/environment/eks --delete
aws s3 sync s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20/karpenter /home/ec2-user/environment/karpenter --delete
aws s3 sync s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20/terraform /home/ec2-user/environment/terraform --delete
```

DOWNLOAD MODEL

Simple download : 
```bash
pip install -U "huggingface_hub[cli]"
huggingface-cli download "enghwa/neuron-mistral7bv0.2" --local-dir <your directory>
```

Faster download : 
```bash
pip install huggingface_hub[hf_transfer] # Faster download 
export HF_HUB_ENABLE_HF_TRANSFER=1     
huggingface-cli download "enghwa/neuron-mistral7bv0.2" --local-dir <your directory>
```
OR 

```bash
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | sudo bash
sudo yum install git-lfs 
git lfs install
git clone https://huggingface.co/enghwa/neuron-mistral7bv0.2
```

To modify volume : 
```bash
C9STACK=$(aws cloudformation list-stacks --query "StackSummaries[?contains(StackName, 'aws-cloud9')].StackName" --output text) 
C9INSTANCE=$(aws cloudformation describe-stack-resources --stack-name "$C9STACK" --query "StackResources[?ResourceType=='AWS::EC2::Instance'].PhysicalResourceId" --output text)
C9VOLUME=$(aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=$C9INSTANCE" --query "Volumes[].VolumeId" --output=text) 
aws ec2 modify-volume --volume-id $C9VOLUME --size 100
```


Check object sizes on bucket
```bash
aws s3 ls s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20 --recursive --human-readable --summarize
```