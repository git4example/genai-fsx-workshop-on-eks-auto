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

- awscli : https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
:::
- Docker : 

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker participant
docker ps
:::

- Git : 
:::code[]{language=bash showLineNumbers=true showCopyAction=true}
sudo yum update -y
sudo yum install git -y
git — version
git config — global user.name “Your Name”
git config — global user.email “your_email@example.com”
:::

2. Git Clone : 

:::code[]{language=bash showLineNumbers=false showCopyAction=true}
git clone https://github.com/git4example/genai-fsx-workshop-on-eks.git
:::

3. Create s3 bucket for temporary hosting workshop asseets. These asset bucket should be in the same region as of your CFN stack. Note that some of the automation in CFN stack and terraform executing as part of setup will copy over these data to vscode instance and new s3 bucket required to upload/host the workshop data and GenAI model. 

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
export REGION=< your-region >
ASSET_BUCKET=< new-bucket-name >
aws s3api create-bucket --bucket $ASSET_BUCKET --region $REGION
:::

4. Move needful code to your asset bucket which we will be using for the provisioning resources using CloudFormation in next step. 

:::code[]{language=bash showLineNumbers=false showCopyAction=true}
aws s3 sync ./genai-fsx-workshop-on-eks ${ASSET_BUCKET}/genai-fsx-workshop-on-eks
:::


5. : Download model 
:::code[]{language=bash showLineNumbers=false showCopyAction=true}
docker run -v ./work-dir/:/work-dir/ --entrypoint huggingface-cli public.ecr.aws/parikshit/huggingface-cli:slim download "enghwa/neuron-mistral7bv0.2" --local-dir /work-dir/Mistral-7B-Instruct-v0.2
:::

6. Upload model to asset bucket. In following command replace credentials to allow access to assets bucket.

:::code[]{language=bash showLineNumbers=false showCopyAction=true}
export $(printf "AWS_ACCESS_KEY_ID=%s exp=%s AWS_SESSION_TOKEN=%s" $(aws sts assume-role --role-arn <role-arn> --role-session-name <session-name> --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" --output text))
:::

:::code[]{language=bash showLineNumbers=false showCopyAction=true}
docker run -e AWS_DEFAULT_REGION=$REGION \
  -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY="<access-key>" \
  -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
  -v ./work-dir/:/work-dir/  public.ecr.aws/parikshit/s5cmd cp /work-dir/Mistral-7B-Instruct-v0.2/ s3://<your-bucket>/Mistral-7B-Instruct-v0.2/
:::


### Part 2 : Provision workshop resources

:::alert{header="Note" type="info"}
This will take upto 45 - 60 mins. 

Any stack creation/deletion failures can be investigated by looking at Cloudformation stack along with `/aws/lambda/GenAIFSXWorkshopOnEKS-XXX` and `/aws/ssm/GenAIFSXWorkshopOnEKS-XXX` log groups in AWS Cloudwatch Logs
:::

Validate Template : 
:::code[]{language=bash showLineNumbers=false showCopyAction=true}
aws cloudformation validate-template --template-url https://${ASSET_BUCKET}.s3.amazonaws.com/genai-fsx-workshop-on-eks/static/GenAIFSXWorkshopOnEKS.yaml
:::

Set parameter values : 
:::code[]{language=bash showLineNumbers=true showCopyAction=true}
export REGION=${REGION}
STACK_NAME=GenAIFSXWorkshopOnEKS
VSINSTANCE_NAME=VSCodeServerForEKS
ASSET_BUCKET_ZIPPATH=""
ASSET_BUCKET=${ASSET_BUCKET}
ASSET_BUCKET_PATH=genai-fsx-workshop-on-eks
:::

Create stack : 
:::code[]{language=bash showLineNumbers=true showCopyAction=true}
aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-url https://${ASSET_BUCKET}.s3.amazonaws.com/GenAIFSXWorkshopOnEKS.yaml \
  --region $REGION \
  --parameters \
  ParameterKey=VSCodeUser,ParameterValue=participant \
  ParameterKey=InstanceName,ParameterValue=${VSINSTANCE_NAME} \
  ParameterKey=InstanceVolumeSize,ParameterValue=100 \
  ParameterKey=InstanceType,ParameterValue=t4g.medium \
  ParameterKey=InstanceOperatingSystem,ParameterValue=AmazonLinux-2023 \
  ParameterKey=HomeFolder,ParameterValue=environment \
  ParameterKey=DevServerPort,ParameterValue=8081 \
  ParameterKey=AssetZipS3Path,ParameterValue=${ASSET_BUCKET_ZIPPATH} \
  ParameterKey=BranchZipS3Path,ParameterValue="" \
  ParameterKey=FolderZipS3Path,ParameterValue="" \
  ParameterKey=C9KubectlVersion,ParameterValue=1.30.2 \
  ParameterKey=C9NodeViewerVersion,ParameterValue=latest \
  ParameterKey=EKSClusterName,ParameterValue=eksworkshop \
  ParameterKey=EKSClusterVersion,ParameterValue=1.30 \
  ParameterKey=ParticipantAssumedRoleArn,ParameterValue=NONE \
  ParameterKey=ParticipantRoleArn,ParameterValue=NONE \
  ParameterKey=ParticipantRoleArn,ParameterValue=NONE \
  ParameterKey=Assets,ParameterValue=s3://${ASSET_BUCKET}/${ASSET_BUCKET_PATH}/assets/ \
  --disable-rollback \
  --capabilities CAPABILITY_NAMED_IAM
:::

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

:::code[]{language=bash showLineNumbers=false showCopyAction=true}
aws sts get-caller-identity
:::

:::alert{header="Note" type="info"}
When you first time copy-paste a command on VSCode IDE, your browser may ask you to allow permission to see informaiton on clipboard. Please select **"Allow"**.

![allow-clipboard](/static/images/allow-clipboard.png)
:::

- The output assumed-role name should look like the following:

![correct-iam-role](/static/images/correct-iam-role.png)

- Set the Amazon EKS cluster variables :

::code[export CLUSTER_NAME=eksworkshop]{language=bash showLineNumbers=false showCopyAction=true}


- Check if region and cluster names are set correctly

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
echo $AWS_REGION
echo $CLUSTER_NAME
:::

## Update the kube-config file:
Before you can start running all the Kubernetes commands included in this workshop, you need to update the kube-config file with the proper credentials to access the cluster. To do so, in your VSCode IDE terminal run the below command:

::code[aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION]{language=bash showLineNumbers=false showCopyAction=true}


## Query the Amazon EKS cluster:
Run the command below to see the Kubernetes nodes currently provisioned:

::code[kubectl get nodes]{language=bash showLineNumbers=false showCopyAction=true}

You should see two nodes provisioned (which are the on-demand nodes used by the Kubernetes controllers), such as the output below:


![get-nodes](/static/images/get-nodes.png)


You now have a VSCode IDE Server environment set-up ready to use your Amazon EKS Cluster! You may now proceed with the next step.

Now, you can go to next module **[Explore workshop environment](/030_module_explore_karpenter)** to continue with your workshop, once you are done and ready to clean up visit this page and execute commands in Part 4 Clean up below.

### Part 4 : Clean up

Delete Cloud formation stack to clean up, Please note this will take upto 30 mins. 

Note:  sometimes it fails to clean up due to VPC Dependency violations error due to ELB/EC2/ENI/Security groups/NAT gateway ..etc are blocking VPC deletion. You may have to take manual action to clean up. 

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
aws cloudformation delete-stack --stack-name ${STACK_NAME} --region $REGION
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME} --region $REGION
:::


