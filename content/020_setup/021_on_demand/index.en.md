---
title: 'On-demand Workshop'
chapter: false
weight: 21
---

:::alert{header="Important" type="warning"}
If you are in **AWS SPONSORED WORKSHOP** instead of self-paced On Demand Workshop, please SKIP this section and move to the next section **[AWS Sponsored Workshop](/020-setup/022-aws-event)**
:::


### Part 1 : Prerequisite of setting up On-demand Workshop
Here you will do pre-setup before launching cloud formation stack which will provision your workshop. 

:::alert{header="Note" type="info"}
Here some of step you may feel as duplication of data, however its to align it with sponsored workshop setup and code managability. 
:::


1. You will need ec2 jump box where you can run these commands with needful permissions in your account. We are not provide detil steps to provision EC2 because each account may be differently managed. 

Please create EC2 instance where you should have awscli, docker and git commands available, if not then you can install them using instuctions here on Amazon Linux 2, if you have differnt OS then please find instuctions to install these commands.

Please also make sure this EC2 instance has associated role with appropriate permissions to create resources.

- awscli : https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
- Docker : 

```bash
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker participant
docker ps
```

- Git : 
```bash
sudo yum update -y
sudo yum install git -y
git — version
git config — global user.name “Your Name”
git config — global user.email “your_email@example.com”
```

2. Git Clone : 

```bash
git clone https://github.com/git4example/genai-fsx-workshop-on-eks-auto.git
```

3. Create s3 bucket for temporary hosting workshop asseets. These asset bucket should be in the same region as of your CFN stack. Note that some of the automation in CFN stack and terraform executing as part of setup will copy over these data to vscode instance and new s3 bucket required to upload/host the workshop data and GenAI model. 

```bash
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
```

```bash
ASSET_BUCKET=< new-bucket-name >
aws s3api create-bucket --bucket $ASSET_BUCKET --region $AWS_REGION
```

4. Move needful code to your asset bucket which we will be using for the provisioning resources using CloudFormation in next step. 

```bash
aws s3 sync ./genai-fsx-workshop-on-eks s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks
```


5. You may need to increase instance volume size. We will extend volume to 100Gb to allow us enough space on instance to download model, also note we will try to use higher iops and throughput for quick download and upload performance.

To modify volume you can use commands like this, you may need to adjust stack name according to your account: 

```bash
MY_INSTANCE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_VOLUME=$(aws ec2 describe-volumes --region $AWS_REGION --filters "Name=attachment.instance-id,Values=$MY_INSTANCE" --query "Volumes[].VolumeId" --output=text) 
aws ec2 modify-volume --region $AWS_REGION --volume-type gp3 --volume-id $INSTANCE_VOLUME --size 100 --iops 10000 --throughput 1000
```

### Run following commands to expand volume

Ref : https://docs.aws.amazon.com/ebs/latest/userguide/recognize-expanded-volume-linux.html

Check disc size is now 100Gb.

```bash
sudo lsblk
```

Depending on Xen or Nitro instance types you may see different results.

Example : Xen
```
NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
xvda      202:0    0  100G  0 disk                    # <<<<<< Here 
├─xvda1   202:1    0   10G  0 part /
├─xvda127 259:0    0    1M  0 part 
└─xvda128 259:1    0   10M  0 part /boot/efi
```

Example : Nitro
```
$ lsblk
NAME          MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
nvme0n1       259:0    0  100G  0 disk                # <<<<<< Here 
├─nvme0n1p1   259:1    0   10G  0 part /
├─nvme0n1p127 259:2    0    1M  0 part 
└─nvme0n1p128 259:3    0   10M  0 part /boot/efi
```

```bash
# For Xen
sudo growpart /dev/xvda 1
lsblk
```

```
NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
xvda      202:0    0  100G  0 disk 
├─xvda1   202:1    0  100G  0 part /
├─xvda127 259:0    0    1M  0 part 
└─xvda128 259:1    0   10M  0 part /boot/efi
Admin:~/environment $ 
```


```bash
# For Nitro
$ sudo growpart /dev/nvme0n1 1
lsblk
```

```bash
NAME          MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
nvme0n1       259:0    0  100G  0 disk 
├─nvme0n1p1   259:1    0  100G  0 part /
├─nvme0n1p127 259:2    0    1M  0 part 
└─nvme0n1p128 259:3    0   10M  0 part /boot/efi
```

#### Check filesystem xfs or ext
```bash
df -hT
```

Example : Xen
```
$ df -hT
Filesystem      Type   Size    Used   Avail   Use%   Mounted on
/dev/xvda1      ext4   8.0G    1.9G   6.2G    24%    /              # <<<<<< Here 
/dev/xvdf1      xfs    24.0G   45M    8.0G    1%     /data 
...
```

Example : Nitro
```
$ df -hT
Filesystem       Type      Size  Used Avail Use% Mounted on
devtmpfs         devtmpfs  4.0M     0  4.0M   0% /dev
tmpfs            tmpfs     3.8G     0  3.8G   0% /dev/shm
tmpfs            tmpfs     1.6G  8.5M  1.6G   1% /run
/dev/nvme0n1p1   xfs        10G  5.9G  4.1G  60% /                 # <<<<<< Here 
tmpfs            tmpfs     3.8G     0  3.8G   0% /tmp
/dev/nvme0n1p128 vfat       10M  1.3M  8.7M  13% /boot/efi
tmpfs            tmpfs     773M     0  773M   0% /run/user/1000
```

#### For xfs filesystem

```bash
sudo xfs_growfs -d /
```

#### For ext filesystem
```bash
For Xen
sudo resize2fs /dev/xvda1
```

```bash
# For Nitro
sudo resize2fs /dev/nvme0n1p1
```

6. Download model 
```bash
docker run -v ./work-dir/:/work-dir/ --entrypoint huggingface-cli public.ecr.aws/parikshit/huggingface-cli:slim download "enghwa/neuron-mistral7bv0.2" --local-dir /work-dir/Mistral-7B-Instruct-v0.2
```

7. Upload model to asset bucket. In following command replace credentials to allow access to assets bucket.

```bash
# Get the IAM role name
ROLE_NAME=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/)

# Get the credentials
CREDENTIALS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME)

# Extract and export the credentials
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Token')

# Print the credentials (be careful with this in production environments)
echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
echo "AWS_SESSION_TOKEN: $AWS_SESSION_TOKEN"
```


<!-- ```bash
export $(printf "AWS_ACCESS_KEY_ID=%s exp=%s AWS_SESSION_TOKEN=%s" $(aws sts assume-role --role-arn <role-arn> --role-session-name <session-name> --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" --output text))
::: -->

```bash
docker run -e AWS_DEFAULT_REGION=$AWS_REGION \
  -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
  -v ./work-dir/:/work-dir/  public.ecr.aws/parikshit/s5cmd cp /work-dir/Mistral-7B-Instruct-v0.2/ s3://$ASSET_BUCKET/Mistral-7B-Instruct-v0.2/
```


### Part 2 : Provision workshop resources

:::alert{header="Note" type="info"}
This will take upto 45 - 60 mins. 

Any stack creation/deletion failures can be investigated by looking at Cloudformation stack along with `/aws/lambda/GenAIFSXWorkshopOnEKS-XXX` and `/aws/ssm/GenAIFSXWorkshopOnEKS-XXX` log groups in AWS Cloudwatch Logs
:::


Set parameter values : 
```bash
STACK_NAME=GenAIFSXWorkshopOnEKS
VSINSTANCE_NAME=VSCodeServerForEKS
ASSET_BUCKET_ZIPPATH=""
ASSET_BUCKET=${ASSET_BUCKET}
ASSET_BUCKET_PATH=genai-fsx-workshop-on-eks
```

Validate Template : 
```bash
aws cloudformation validate-template --template-url https://${ASSET_BUCKET}.s3.amazonaws.com/${ASSET_BUCKET_PATH}/static/GenAIFSXWorkshopOnEKS.yaml
```

Create stack : 
```bash
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
```

### Part 3 : Access your workshop

**Connect to your AWS lab environment via Open source VSCode IDE**

Ref : [code-server](https://github.com/coder/code-server) 

You will be using the Open source VSCode IDE terminal to copy and paste commands that are provided in this workshop. 

::alert[Note: Please use google chrome browser for best user experience. Firefox may experience some issues while copy-paste commands.]{header="Important" type="warning"}

1. Go to Cloud formation console [link](https://console.aws.amazon.com/cloudformation) and select `genaifsxworkshoponeks` stack 
2. Go to Stack **Outputs**
3. Copy Password and click URL
4. Enter copied password in the new tab opened for the URL


![CFN-Output](/static/images/cfn-output.png)

5. Select your VSCode UI theam 

![Select Theme](/static/images/select-theme.png)

6. You can maximize terminal window.

![maximize](/static/images/maximize.png)

### Validate the IAM role {#validate_iam}

- Use the [GetCallerIdentity](https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html) CLI command to validate that the VSCode IDE is using the correct IAM role.

```bash
aws sts get-caller-identity
```

:::alert{header="Note" type="info"}
When you first time copy-paste a command on VSCode IDE, your browser may ask you to allow permission to see informaiton on clipboard. Please select **"Allow"**.

![allow-clipboard](/static/images/allow-clipboard.png)
:::

- The output assumed-role name should look like the following:

![correct-iam-role](/static/images/correct-iam-role.png)

- Set the Amazon EKS cluster variables :

```bash
export CLUSTER_NAME=eksworkshop
```


- Check if region and cluster names are set correctly

```bash
echo $AWS_REGION
echo $CLUSTER_NAME
```

## Update the kube-config file:
Before you can start running all the Kubernetes commands included in this workshop, you need to update the kube-config file with the proper credentials to access the cluster. To do so, in your VSCode IDE terminal run the below command:

```bash
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
```


## Query the Amazon EKS cluster:
Run the command below just to see the connectivity to EKS Auto Cluster:

```bash
kubectl get nodes
```
Initially there will be no nodes in the cluster. As you start creating pods, EKS Auto will auto provision worker nodes as per workload demands. 

You now have a VSCode IDE Server environment set-up ready to use your Amazon EKS Cluster! You may now proceed with the next step.

Now, you can go to next module **[Configure storage - Host model data on Amazon FSx for Lustre](/100_module1_eks_fsxl)** to continue with your workshop, once you are done and ready to clean up visit this page and execute commands in Part 4 Clean up below.

### Part 4 : Clean up

Delete Cloud formation stack to clean up, Please note this will take upto 30 mins. 

Note:  sometimes it fails to clean up due to VPC Dependency violations error due to ELB/EC2/ENI/Security groups/NAT gateway ..etc are blocking VPC deletion. You may have to take manual action to clean up. 

```bash
aws cloudformation delete-stack --stack-name ${STACK_NAME} --region $AWS_REGION
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME} --region $AWS_REGION
```

