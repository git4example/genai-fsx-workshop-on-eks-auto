---
title: 'On-demand Workshop'
chapter: false
weight: 21
---

:::alert{header="Important" type="warning"}
If you are in **AWS SPONSORED WORKSHOP** instead of self-paced On Demand Workshop, please SKIP this section and move to the next section **[AWS Sponsored Workshop](/020-setup/022-aws-event)**
:::


### Part 1 : Prerequisite of setting up an On-demand Workshop (using your own AWS account)
Follow the below instructions to complete the required steps before you can launch the AWS CloudFormation Stack that will provision this workshop.

:::alert{header="Note" type="info"}
Here some of step you may feel as duplication of data, however its to align it with sponsored workshop setup and code managability.
:::


1. You will need a Linux based Amazon EC2 jump-box that is configured with an Amazon EBS GP3 based volume that has at least 100GB FREE. The Linux based Amazon EC2 jump-box also needs to have the required account access and permissions in-order to run the commands outline below, along with being able to create AWS resources required for this workshop.  

Logon onto to your Amazon EC2 instance and follow run the below commands to install the items: awscli, docker and git.

 **Note**: The example commands provided are for Amazon Linux 2 based EC2 instances, if you are using a different OS then follow these steps (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)


- Run the below commands to install AWSCLI:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
- Run the below commands to install Docker:

```bash
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker participant
sudo docker ps
```

- Run the below commands to install Git :
```bash
sudo yum install git -y
sudo yum install jq
git --version
git config --global user.name “Your Name”
git config --global user.email “your_email@example.com”
```

2. Run the below commands to perform a git clone of the workshop package:

```bash
git clone https://github.com/git4example/genai-fsx-workshop-on-eks-auto.git
```

3. Follow the below commands to create a new Amazon S3 bucket (using AWSCLI or the Amazon S3 console), this will be for temporarily hosting workshop assets. This S3 asset bucket should be in the same region where your Amazon EC2 Jump-box is and where you will deploy the workshops AWS CloudFormation stack.

**Note**: The automation in AWS CloudFormation stack and its Terraform modules, as part of the initial deployment setup, will copy over workshop data into a VScode instance (which will become your IDE for the workshop), and also create an additional temporary S3 bucket. This S3 bucket will be used by the workshop to host the workshop data and the Mistral-7B LLM  model that is used in the workshop by the Generative AI chatbot.


```bash
export TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
```

Replace **< your-new-bucket-name >** with your own **S3 bucket name**

```bash
export ASSET_BUCKET=<your-new-bucket-name>
```

```bash
aws s3api create-bucket --bucket $ASSET_BUCKET --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION
```

4. Move the workshop code to your asset S3 bucket, which will be used for the provisioning resources using CloudFormation in next step.

```bash
aws s3 sync ./genai-fsx-workshop-on-eks-auto s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto
```


5. Download the Mistral-7B LLM model
```bash
sudo docker run -v ./work-dir/:/work-dir/ --entrypoint huggingface-cli public.ecr.aws/parikshit/huggingface-cli:slim download "enghwa/neuron-mistral7bv0.2" --local-dir /work-dir/Mistral-7B-Instruct-v0.2
```

6. Upload LLM model to the S3 asset bucket you created previously. In following command replace the credentials to allow access to s3 assets bucket.

**Get the IAM role name associated with your EC2 instance:**
```bash
export TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export ROLE_NAME=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/)
```

**Get the credentials:**
```bash
export CREDENTIALS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME)
```

**Extract and export the credentials into variables to use:**
```bash
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Token')
```

**View and verify the credentials:**
```bash
echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
echo "AWS_SESSION_TOKEN: $AWS_SESSION_TOKEN"
```


<!-- ```bash
export $(printf "AWS_ACCESS_KEY_ID=%s exp=%s AWS_SESSION_TOKEN=%s" $(aws sts assume-role --role-arn <role-arn> --role-session-name <session-name> --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" --output text))
::: -->

**Copy Mistral-7B LLM model to asset bucket:** (This can take a few minutes to upload the model data to your S3 bucket)
```bash
export ASSET_BUCKET_PATH=genai-fsx-workshop-on-eks-auto

sudo docker run -e AWS_DEFAULT_REGION=$AWS_REGION \
  -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
  -v ./work-dir/:/work-dir/  public.ecr.aws/parikshit/s5cmd cp /work-dir/Mistral-7B-Instruct-v0.2/ s3://${ASSET_BUCKET}/${ASSET_BUCKET_PATH}/assets/Mistral-7B-Instruct-v0.2/
```


### Part 2 : Provision workshop resources

:::alert{header="Note" type="info"}
The CloudFormation stack for the workshop will take up-to 45 - 60 mins to successfully provision the workshop components.

**Note:** Any stack creation/deletion failures can be investigated by looking at Cloudformation stack along with `/aws/lambda/GenAIFSXWorkshopOnEKS-XXX` and `/aws/ssm/GenAIFSXWorkshopOnEKS-XXX` log groups in AWS Cloudwatch Logs
:::

Run the following commands to provision the workshop resources

**Set parameter values :**
```bash
STACK_NAME=GenAIFSXWorkshopOnEKS
VSINSTANCE_NAME=VSCodeServerForEKS
ASSET_BUCKET_ZIPPATH=""
ASSET_BUCKET=${ASSET_BUCKET}
ASSET_BUCKET_PATH=genai-fsx-workshop-on-eks-auto
```

**Validate Template:**
```bash
aws cloudformation validate-template --template-url https://${ASSET_BUCKET}.s3.amazonaws.com/${ASSET_BUCKET_PATH}/static/GenAIFSXWorkshopOnEKS.yaml > validate_cfn.txt
```
View the contents of the output (and verify no errors are shown) in-order to validate that the above link to CloudFormation template worked.
```bash
cat validate_cfn.txt
```

**Create stack:**
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

### Part 3: Access your workshop

**Connect to your AWS lab environment via the Open source VSCode IDE**.

You will be using an Open source VSCode IDE terminal to copy and paste the required commands provided in this workshop modules. refer to this link for further information on the [VSCode IDE code-server](https://github.com/coder/code-server)

::alert[Note: Use Google chrome browser for the best user experience with VSCode IDE, as Firefox users may experience some issues with copy-paste commands.]{header="Important" type="warning"}

**Log into your VSCode IDE Instance:**
1. Navigate to the AWS CloudFormation console [link](https://console.aws.amazon.com/cloudformation) and select the `genaifsxworkshoponeks` stack
2. Click on Stack **Outputs**
3. Copy the **Password** and click on the URL to open the VSCode IDE interface
4. Enter the password you copied into the VSCode IDE interface


![CFN-Output](/static/images/cfn-output.png)

5. Select your VSCode UI theme

![Select Theme](/static/images/select-theme.png)

6. Click the top right hand icon to maximize terminal window.

![maximize](/static/images/maximize.png)

### Validate the IAM role

- Use the [GetCallerIdentity](https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html) CLI command to validate that the VSCode IDE is using the correct IAM role.

```bash
aws sts get-caller-identity
```

:::alert{header="Note" type="info"}
The first time you copy-paste a command into the VSCode IDE, your browser may ask you to allow permission, select **"Allow"**.

![allow-clipboard](/static/images/allow-clipboard.png)
:::

- The output of the assumed-role name should look like the following:

![correct-iam-role](/static/images/correct-iam-role.png)

- Set the Amazon EKS cluster variables :

```bash
export CLUSTER_NAME=eksworkshop
```


- Check that your region and cluster names are set correctly, to match your current region.

```bash
echo $AWS_REGION
echo $CLUSTER_NAME
```

## Update the kube-config file:
Before you can start running all the Kubernetes commands included in this workshop, you need to update the kube-config file with the required credentials to access the EKS cluster. In your VSCode IDE terminal, run the below command:

```bash
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
```


## Query the Amazon EKS cluster:
Run the command below to test connectivity to the EKS cluster:

```bash
kubectl get nodes
```

You should see a provisioned node, which was provisioned by EKS Auto-Mode to run some of the core components required for the workshop.

![get-nodes](/static/images/get-nodes.png)

You now now completed the workshop deployment and have a VSCode IDE Server environment ready to use with your Amazon EKS Cluster! Please proceed to the first module of the workshop **[Explore EKS Auto](/030_module_explore_eks_auto)**.

**Note:** Once you have completed the workshop, navigate back to this page, and the below section to perform the **Clean up** tasks.

### Part 4 : Clean up

1. Run the below command (replacing STACK_NAME with your CloudFormation Stack name) to delete the AWS CloudFormation Stack and remove the provisioned workshop, note this will take can take up-to 30 mins.

Note: If you have created any AWS resources outside of the CloudFormation templates provisioned resources, or have modified resources deployed by the original CloudFormation template, then you might encounter errors when deleting the CloudFormation stack. If that occurs, refer to the errors shown and action and/or delete resources as outlined by the CloudFormation  delete stack job.

```bash
aws cloudformation delete-stack --stack-name ${STACK_NAME} --region $AWS_REGION
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME} --region $AWS_REGION
```
