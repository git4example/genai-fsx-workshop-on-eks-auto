
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
huggingface-cli download "enghwa/neuron-mistral7bv0.2" --local-dir Mistral-7B-Instruct-v0.2
```

Faster download : 
```bash
pip install huggingface_hub[hf_transfer] 
export HF_HUB_ENABLE_HF_TRANSFER=1     
huggingface-cli download "enghwa/neuron-mistral7bv0.2" --local-dir Mistral-7B-Instruct-v0.2
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



Shortcuts 

```bash
alias k=kubectl
alias ka="kubectl apply -f "
alias kc="kubectl create "
alias ke="kubectl exec -it "
alias kg="kubectl get "
alias kgn="kubectl get node -o=custom-columns='Name:.metadata.name,InternalIP:.status.addresses[?(@.type==\"InternalIP\")].address,ExternalIP:.status.addresses[?(@.type==\"ExternalIP\")].address,ID:.spec.providerID'"
alias kd="kubectl describe "
alias kr="kubectl replace --force -f "
alias kdel="kubectl delete "
alias kex="kubectl explain --recursive "
alias ks="kubectl -n kube-system "
alias ksg="kubectl -n kube-system get "
alias ksd="kubectl -n kube-system describe "
alias kconf="k config set-context $(k config current-context) --namespace "
alias kconfv="k config view"
alias ktest="k run -it netshoot --image=nicolaka/netshoot /bin/bash"
export dry="-o=yaml --dry-run=client"
export w="-o=wide"
export y="-o=yaml"
export j="-o=json"
export l="--show-labels"
export c="-o=custom-columns"
```


- Deploy EKS Job with FSxL PVC to provision FSxL and then deploy pod to pull model on the S3 bucket
- This job should be successfully download model. Once this is successful then we can use this FSxL bucket to be mounted in Mistral pod in next module
- Ask Eng Hwa to install huggingface_hub[hf_transfer] in his container to help pull model faster
