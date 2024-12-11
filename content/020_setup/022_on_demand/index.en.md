---
title: 'On-demand Workshop'
chapter: false
weight: 22
---
## Login into the AWS Console

### Part 1 : here you need to have an ec2 jump box where you can run these commands with needful permissions in your account. We are unable to provide detil steps for this because each account may be differently managed. 

1. Create EC2 instance where you should have awscli, docker and git commands available, if not then you can install them using 
    - awscli : https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
    - Docker : 
        - sudo yum update -y
        - sudo yum install -y docker
        - sudo service docker start
        - sudo usermod -a -G docker ec2-user
        - docker ps
    - Git : 
        - sudo yum update -y
        - sudo yum install git -y
        - git — version
        - git config — global user.name “Your Name”
        - git config — global user.email “your_email@example.com”

1. Git Clone : 

```bash
git clone https://github.com/git4example/genai-fsx-workshop-on-eks.git
```

2. Create s3 bucket for temporary hosting workshop asseets. These asset bucket should be in the same region as of your CFN stack. Note that some of the automation in CFN stack and terraform executing as part of setup will copy over these data to vscode instance and new s3 bucket required for the workshop. 
    - export REGION=<current region>
    - ASSET_BUCKET=<my-bucket-name>
    - aws s3api create-bucket --bucket $ASSET_BUCKET --region $REGION
3. Move needful code to your asset bucket which we will be using for the provisioning resources using CloudFormation in next step. 

```bash
cd genai-fsx-workshop-on-eks 
aws s3 sync ${ASSET_BUCKET}/static/eks ./static/eks
aws s3 sync ${ASSET_BUCKET}/static/terraform ./static/terraform
aws s3 sync ${ASSET_BUCKET}/static/download ./static/download
aws s3 sync ${ASSET_BUCKET}/static/script ./static/script
```

4. : Download model 
```bash
docker run -v ./work-dir/:/work-dir/ --entrypoint huggingface-cli public.ecr.aws/parikshit/huggingface-cli:slim download "enghwa/neuron-mistral7bv0.2" --local-dir /work-dir/Mistral-7B-Instruct-v0.2
```

5. Upload model to asset bucket. In following command replace credentials to allow access to assets bucket.

```bash
export $(printf "AWS_ACCESS_KEY_ID=%s exp=%s AWS_SESSION_TOKEN=%s" $(aws sts assume-role --role-arn <role-arn> --role-session-name <session-name> --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" --output text))
```

```bash
docker run -e AWS_DEFAULT_REGION=$REGION \
  -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY="<access-key>" \
  -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
  -v ./work-dir/:/work-dir/  public.ecr.aws/parikshit/s5cmd cp /work-dir/Mistral-7B-Instruct-v0.2/ s3://<your-bucket>/Mistral-7B-Instruct-v0.2/
```

6. Now create stack 


```bash
aws s3 cp ./static/GenAIFSXWorkshopOnEKS.yaml s3://${ASSET_BUCKET}/GenAIFSXWorkshopOnEKS.yaml
aws cloudformation validate-template --template-url https://${ASSET_BUCKET}.s3.amazonaws.com/GenAIFSXWorkshopOnEKS.yaml
```


```bash
export REGION=us-east-2
STACK_NAME=GenAIFSXWorkshopOnEKS
VSINSTANCE_NAME=VSCodeServerForEKS
ASSET_BUCKET_ZIPPATH=""
ASSET_BUCKET=my-genai-fsx-workshop-bucket
ASSET_BUCKET_PATH=genai-fsx-workshop-on-eks


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
```

7. Clean up 
This may take upto 30 mins. 
Note:  sometimes it fails to clean up due to VPC Dependency violations error due to ELB/EC2/ENI/Security groups/NAT gateway ..etc are blocking VPC deletion. You may have to take manual action to clean up. 
```bash
aws cloudformation delete-stack --stack-name ${STACK_NAME} --region $REGION
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME} --region $REGION
```




3. Log into your AWS CloudFormation console [link](https://console.aws.amazon.com/cloudformation)
4. Go to your desired region 

5. Create stack and select file `GenAIFSXWorkshopOnEKS-on-demand.yaml` from <yourpath>/genai-fsx-workshop-on-eks/static/GenAIFSXWorkshopOnEKS-on-demand.yaml



```bash
aws s3 cp ./static/GenAIFSXWorkshopOnEKS.yaml s3://databackupbucket/GenAIFSXWorkshopOnEKS.yaml
aws cloudformation validate-template --template-url https://databackupbucket.s3.amazonaws.com/GenAIFSXWorkshopOnEKS.yaml
```



```bash
export REGION=us-east-2
STACK_NAME=GenAIFSXWorkshopOnEKS
VSINSTANCE_NAME=VSCodeServerForEKS
ASSET_BUCKET_ZIPPATH=""
ASSET_BUCKET=my-genai-fsx-workshop-bucket
ASSET_BUCKET_PATH=genai-fsx-workshop-on-eks


aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-url https://databackupbucket.s3.amazonaws.com/GenAIFSXWorkshopOnEKS.yaml \
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
```

```bash
aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-body file://static/GenAIFSXWorkshopOnEKS.yaml \
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
```

This may take upto 30 mins : 
```bash
aws cloudformation delete-stack --stack-name ${STACK_NAME} --region $REGION
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME} --region $REGION
```











## -----------------------------------------

```bash
export REGION=us-east-2
ASSET_BUCKET=my-genai-fsx-workshop-bucket
aws cloudformation create-stack \
  --stack-name GenAIFSXWorkshopOnEKS \
  --template-body file://static/GenAIFSXWorkshopOnEKS-on-demand.yaml \
  --region $REGION \
  --parameters \
  ParameterKey=Assets,ParameterValue=s3://${ASSET_BUCKET}/assets \
  ParameterKey=C9InstanceType,ParameterValue=m5.large \
  ParameterKey=C9KubectlVersion,ParameterValue=1.30.2 \
  ParameterKey=C9NodeViewerVersion,ParameterValue=v0.6.0 \
  ParameterKey=C9TerraformVersion,ParameterValue=1.9.5 \
  ParameterKey=EKSClusterName,ParameterValue=eksworkshop \
  ParameterKey=EKSClusterVersion,ParameterValue=1.30 \
  ParameterKey=ParticipantAssumedRoleArn,ParameterValue=NONE \
  ParameterKey=ParticipantRoleArn,ParameterValue=NONE \
  ParameterKey=ParticipantRoleArn,ParameterValue=NONE \
  --capabilities CAPABILITY_NAMED_IAM
```
Share Cloud9 environment with your assumed role in console : 
```bash
aws cloud9 create-environment-membership --environment-id $(aws cloud9 list-environments --query 'environmentIds[*]' --output text --region us-east-2) --user-arn arn:aws:sts::064250592128:assumed-role/Admin/ppariksh-Isengard --permissions read-write --region $REGION
```


1. From your local workstation, open a web browser to the lab access URL that has been provided for the workshop,OR Click on the [link](https://catalog.us-east-1.prod.workshops.aws/join) and enter the Event access code provided.

    - Click on the Email one-time password(OTP) and enter your email address to receive the OTP

        ![Workshop Studio](/static/images/signin_page.png)

    - Enter the One-time email 9 digits passcode and click sign in

    ![Workshop Studio](/static/images/One_time_passcode.png)

    - You will be redirected to Join event page,  Enter the event access code and click on **Next**

    ![Workshop Studio](/static/images/Start_page_join.png)

    - You will then be taken to the Review & Join page, review the stated terms and condition, and select the "I Agree with the Terms & Conditions" checkbox when you are ready. Next click on **Join Event**

    - You will redirected to the workshop instructions page, on the left bottom of the window pane, you will find the AWS account access information.

    - Click  on **Open AWS Console** to get started

    ![Workshop Studio](/static/images/account_access.png)




<!-- ::alert[Ask Your Operator for the region to use.] -->


::alert[Before getting started, from the top right corner of your AWS Console session, select the **AWS Region** that has been stated for your workshop session.]{header="Important" type="warning"}

## Connect to your AWS lab environment via Cloud9

You will be using the Cloud9 IDE terminal to copy and paste commands that are provided in this workshop.

- From **your workstation** navigate to your AWS console session, from the top search bar in the AWS console, type and select **Cloud9**.

- Select  **genaifsxworkshoponeks**

- Click the **Open** under the **Cloud9 IDE**  to launch the Cloud9 environment.

 ![c9-click-button](/static/images/c9-click-button.png)

- Once the Cloud9 IDE screen loads,  create a new terminal, by clicking at the top tabs: (+) button > New Terminal. This terminal will be used to run all the commands for this workshop.

 ![Cloud9_02](/static/images/Cloud9_02.png)


### Validate the IAM role {#validate_iam}

In most cases, Cloud9 manages IAM credentials dynamically, however this currently not compatible with the Amazon EKS IAM authentication. So we will disable it and rely on an AWS IAM role instead. To do this, **COPY and PASTE** the following commands into the Cloud9 terminal, then press **ENTER** to run these commands:

```bash
aws cloud9 update-environment --environment-id ${C9_PID} --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials
```

- Use the [GetCallerIdentity](https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html) CLI command to validate that the Cloud9 IDE is using the correct IAM role.

```bash
aws sts get-caller-identity
```

- The output assumed-role name should look like the following:

![Cloud9_Terminal](/static/images/Cloud9-Terminal-correct.png)

- If you see incorrect output like below example, please run above command to fix credentials:

![Cloud9_Terminal](/static/images/Cloud9-Terminal-incorrect.png)

- Run the below command to setup the lab region name as configured by your workshop operator.

:::code[]{language=bash showLineNumbers=false showCopyAction=true}
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
:::

- Set the Amazon EKS cluster variables :

::code[export CLUSTER_NAME=eksworkshop]{language=bash showLineNumbers=false showCopyAction=true}


- Check if region and cluster names are set correctly

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
echo $AWS_REGION
echo $CLUSTER_NAME
:::

## Update the kube-config file:
Before you can start running all the Kubernetes commands included in this workshop, you need to update the kube-config file with the proper credentials to access the cluster. To do so, in your Cloud9 terminal run the below command:

::code[aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION]{language=bash showLineNumbers=false showCopyAction=true}


## Query the Amazon EKS cluster:
Run the command below to see the Kubernetes nodes currently provisioned:

::code[kubectl get nodes]{language=bash showLineNumbers=false showCopyAction=true}

You should see two nodes provisioned (which are the on-demand nodes used by the Kubernetes controllers), such as the output below:


![get-nodes](/static/images/get-nodes.png)


:::alert{header="Important" type="warning"}

If you notice one of the following errors while running one of the previous commands :

::code[error: You must be logged in to the server (Unauthorized)]{language=bash showLineNumbers=false showCopyAction=false}

Or

::code[error: You must be logged in to the server (the server has asked for the client to provide credentials)]{language=bash showLineNumbers=false showCopyAction=false}


::::expand{header=" **CLICK TO EXPAND** Run the below commands to clear managed credentials, and allow use of the Cloud9 Instance profile credentials:"}

Delete credentials file

```bash
aws cloud9 update-environment --environment-id ${C9_PID} --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials
```

Check once again to see you are using `eks-fsx-workshop-admin` role:

```bash
kubectl get nodes
```
::::


You now have a Cloud9 environment set-up ready to use your Amazon EKS Cluster! You may now proceed with the next step.
