---
title : "On Demand Workshop"
weight : 10
#hidden: false
---
-------------------------------------------------------------

:::alert{header="Important" type="warning"}
If you are in **AWS SPONSORED WORKSHOP** instead of self-paced On Demand Workshop, please SKIP this section and move to the next section **[AWS Sponsored Workshop](/020-setup/02-aws-event)**
:::

## Prerequisites

For this walkthrough, you should have the following prerequisites:

1. An AWS account with necessary permissions to create and manage Amazon VPC, Amazon EKS cluster, Amazon FSx for NetApp ONTAP file system, and CloudFormation stack.

2. You will need : 
  - EKS 1.22 and later
  
 On your laptop: 
  - eksctl: https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html
  - kubectl: https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
  - Helm 3: https://docs.aws.amazon.com/eks/latest/userguide/helm.html

::alert[For Helm please select v3.8, instead of any later version as it might experience issues]

1. The AWS Command Line Interface (AWS CLI) configured in your working environment. For information about installing and configuring the AWS CLI, see Installing or updating the latest version of the AWS CLI. https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

## 1. Clone the Github repository

You can find the CloudFormation template and relevant code in this GitHub repo. Run the following command to clone the repository into your local workstation.

::code[git clone https://github.com/aws-samples/eks-fsx-workshop.git]{language=bash showLineNumbers=false showCopyAction=true}

There are two folders that you need to reference in the following steps, with the “eks” folder containing all manifests files related to the eks cluster resources and “FSxCFN” Cloudformation templates for spinning up the VPC environment and FSx File System.

Set region variables, Replace `<region name>` with your lab primary region name.

```bash
export REGION_1=<region name>
export REGION_2=us-east-2
```

Set cluster variables : 

```bash
export CLUSTER_NAME_1=FSx-eks-cluster
export CLUSTER_NAME_2=FSx-eks-cluster02
```

## 2. Create a VPC environment for Amazon EKS and FSx (Optional)

Create a new VPC with two private subnets and two public subnets using CloudFormation. This step is optional, and an existing VPC can be reused for the Amazon EKS cluster and the FSx file system.

Launch the CloudFormation stack to set up the network environment for both FSx and EKS cluster:

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
cd eks-fsx-workshop/FSxCFN
aws cloudformation create-stack --stack-name FSX-EKS-VPC --template-body file://./vpc-subnets.yaml --region $REGION_1
:::

![VPCCFN](/static/images/VPCCFN.png)

## 3. Create an Amazon EKS cluster

In this walkthrough, we are going to create the EKS cluster with a managed node group that contains two worker nodes residing across the two private subnets created in step 2. In the `cluster.yaml` file, substitute the VPC ID and subnet IDs based on the output of the CloudFormation stack launched in step 2.

1. Current working directory is 

::code[cd ../eks]{language=bash showLineNumbers=false showCopyAction=true} 
      

2.  Edit the file cluster.yaml and replace the region, vpcid, private subnet and public subnet

![VPCREGION](/static/images/vpcregion.png) 

If you are using your own existing VPC and subnets then copy the following CLI command in a notepad to modify it to set values.
```bash
VPCID=<your vpc id>
PUBLIC_SUBNET_1=<your public subnet 1>
PUBLIC_SUBNET_1=<your public subnet 2>
PRIVATE_SUBNET_1=<your private subnet 1>
PRIVATE_SUBNET_2=<your private subnet 2>
PUBLIC_ROUTETABLE=<your public route table>
PRIVATE_ROUTETABLE=<your private route table>
```

Else get values from the cloud formation stack created in Step 2 above : 
```bash
VPCID=$(aws cloudformation describe-stacks --stack-name FSX-EKS-VPC --region $REGION_1 --query "Stacks[0].Outputs[?OutputKey=='VPCId'].OutputValue" --output text)
VPCCIDR=$(aws cloudformation describe-stacks --stack-name FSX-EKS-VPC --region $REGION_1 --query "Stacks[0].Outputs[?OutputKey=='VpcCidrBlock'].OutputValue" --output text)
PUBLIC_SUBNET_1=$(aws cloudformation describe-stacks --stack-name FSX-EKS-VPC --region $REGION_1 --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet1'].OutputValue" --output text)
PUBLIC_SUBNET_2=$(aws cloudformation describe-stacks --stack-name FSX-EKS-VPC --region $REGION_1 --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet2'].OutputValue" --output text)
PRIVATE_SUBNET_1=$(aws cloudformation describe-stacks --stack-name FSX-EKS-VPC --region $REGION_1 --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet1'].OutputValue" --output text)
PRIVATE_SUBNET_2=$(aws cloudformation describe-stacks --stack-name FSX-EKS-VPC --region $REGION_1 --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet2'].OutputValue" --output text)
PUBLIC_ROUTETABLE=$(aws cloudformation describe-stacks --stack-name FSX-EKS-VPC --region $REGION_1 --query "Stacks[0].Outputs[?OutputKey=='PublicRouteTable'].OutputValue" --output text)
PRIVATE_ROUTETABLE=$(aws cloudformation describe-stacks --stack-name FSX-EKS-VPC --region $REGION_1 --query "Stacks[0].Outputs[?OutputKey=='PrivateRouteTable'].OutputValue" --output text)
```


```bash
sed -i'' -e "s/ap-southeast-2/$REGION_1/g" cluster.yaml
sed -i'' -e "s/vpc-id/$VPCID/g" cluster.yaml
sed -i'' -e "s/public-subnet-1/$PUBLIC_SUBNET_1/g" cluster.yaml
sed -i'' -e "s/public-subnet-2/$PUBLIC_SUBNET_2/g" cluster.yaml
sed -i'' -e "s/private-subnet1/$PRIVATE_SUBNET_1/g" cluster.yaml
sed -i'' -e "s/private-subnet2/$PRIVATE_SUBNET_2/g" cluster.yaml
```

Verify updated values : 

::code[cat cluster.yaml]{language=bash showLineNumbers=false showCopyAction=true}
     

- Create the EKS cluster by running the following command:

::code[eksctl create cluster -f ./cluster.yaml]{language=bash showLineNumbers=false showCopyAction=true}


- Create EKS Cluster in 2nd region for testing cross region desaster recovery and OpenZFS

```bash
eksctl create cluster --name $CLUSTER_NAME_2 --region $REGION_2 --nodes=2 --instance-types=c5.2xlarge
```

## 4. Create an Amazon FSx for NetApp ONTAP file system

The following steps to create the Amazon FSx for Netapp ONTAP Filesystem. If you want to skip and move to Amazon FSx for Lustre then go to to step 5

Run the following CLI command to create the Amazon FSx for NetApp ONTAP file system.  Copy the following CLI command in a notepad to modify it to define your password

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
aws cloudformation create-stack \
  --stack-name EKS-FSXONTAP \
  --template-body file://./FSxONTAP.yaml \
  --region $REGION_1 \
  --parameters \
  ParameterKey=Subnet1ID,ParameterValue=$PRIVATE_SUBNET_1 \
  ParameterKey=Subnet2ID,ParameterValue=$PRIVATE_SUBNET_2 \
  ParameterKey=myVpc,ParameterValue=$VPCID \
  ParameterKey=FSxONTAPRouteTable,ParameterValue=$PUBLIC_ROUTETABLE,$PRIVATE_ROUTETABLE \
  ParameterKey=FileSystemName,ParameterValue=EKS-myFSxONTAP \
  ParameterKey=ThroughputCapacity,ParameterValue=128 \
  ParameterKey=FSxAllowedCIDR,ParameterValue=$VPCCIDR \
  ParameterKey=FsxAdminPassword,ParameterValue=[Define password] \
  ParameterKey=SvmAdminPassword,ParameterValue=[Define password] \
  --capabilities CAPABILITY_NAMED_IAM
:::

1. Copy the above CLI command in a notepad to modify

2. Change the region that you are operating

3. Enter the values that was captured earlier during VPC creation as show in the below screenshot

![VPCCFN](/static/images/VPCCFN.png)

4. Throughput capacity input is 128MB/s. However if you wish to increase it the supported values are 256, 512, 1024 and 2048. 

:::alert{header="Important" type="warning"}
You will be charged based on the selected throughput capacity
:::

5. Default storage capacity for this deployment type is 1024


This CloudFormation stack will take approximately 45 minutes to complete; feel free to move to step 4 while waiting for the file system to be deployed.

After the completion of the deployment, we can verify in the following screenshot that the FSx NetApp ONTAP file system and Storage Virtual Machine (SVM) are created.
![FSX01](/static/images/fsx01.png)

Take a look at the details of the FSx for NetApp ONTAP file system. We can see that the file system has a primary subnet and a standby subnet.

![ONTAP04](/static/images/ontap4.png)

SVM is also created.

![ONTAP05](/static/images/ontap5.png)


## 5. Create needful resources for Amazon FSx for Lustre file system

- Creating S3 bucket for FSx Luster in primary region

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
random=`tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo ''`
s3_bucket_name="fsx-luster-bucket-${random}"
s3_2nd_bucket_name="fsx-luster-bucket-2ndregion-${random}"
:::


:::code[]{language=bash showLineNumbers=true showCopyAction=true}
aws cloudformation create-stack \
  --stack-name ${s3_bucket_name} \
  --region $REGION_1 \
  --template-body file://./S3Buckets.yaml \
  --parameters \
  ParameterKey=S3BucketName,ParameterValue=${s3_bucket_name} \
  --capabilities CAPABILITY_NAMED_IAM 
:::

- Creating S3 bucket in 2nd region 
  
:::code[]{language=bash showLineNumbers=true showCopyAction=true}
aws cloudformation create-stack \
  --stack-name ${s3_2nd_bucket_name} \
  --region $REGION_2 \
  --template-body file://./S3Buckets.yaml \
  --parameters \
  ParameterKey=S3BucketName,ParameterValue=${s3_2nd_bucket_name} \
  --capabilities CAPABILITY_NAMED_IAM 
:::


- Creating IAM Role and Policy for S3 Cross Region Replication
  
:::code[]{language=bash showLineNumbers=true showCopyAction=true}
iam_role_name="s3-crr-${random}"
sed -i'' -e "s/DOC-EXAMPLE-BUCKET1/$s3_bucket_name/g" S3ReplicationIAM.yaml
sed -i'' -e "s/DOC-EXAMPLE-BUCKET2/$s3_2nd_bucket_name/g" S3ReplicationIAM.yaml  
:::

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
aws cloudformation create-stack \
  --stack-name ${iam_role_name} \
  --region $REGION_1 \
  --template-body file://./S3ReplicationIAM.yaml \
  --parameters ParameterKey=IAMRoleName,ParameterValue=${iam_role_name} \
  --capabilities CAPABILITY_NAMED_IAM
:::

- Creating Security Group for FSx for Lustre

::code[sed -i'' -e "s/myVpc/$VPCID/g" fsxL-SecurityGroup.yaml]{language=bash showLineNumbers=false showCopyAction=true}

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
aws cloudformation create-stack \
  --stack-name FSxL-SecurityGroup-01 \
  --region $REGION_1 \
  --template-body file://./fsxL-SecurityGroup.yaml \
  --parameters ParameterKey=SecurityGroupName,ParameterValue=FSxLSecurityGroup01 \
  --capabilities CAPABILITY_NAMED_IAM 
:::

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
aws cloudformation create-stack \
  --stack-name FSxL-SecurityGroup-02 \
  --region $REGION_2 \
  --template-body file://./fsxL-SecurityGroup.yaml \
  --parameters ParameterKey=SecurityGroupName,ParameterValue=FSxLSecurityGroup02 \
  --capabilities CAPABILITY_NAMED_IAM 
:::


## 6. Create needful resources for Amazon FSx for OpenZFS 

Create Security Group for OpenZFS
              
::code[sed -i'' -e "s/myVpc/$VPCID/g" fsxZ-SecurityGroup.yaml]{language=bash showLineNumbers=false showCopyAction=true}

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
aws cloudformation create-stack \
  --stack-name fsxZ-SecurityGroup \
  --region $REGION_1 \
  --template-body file://./fsxZ-SecurityGroup.yaml \
  --parameters ParameterKey=SecurityGroupName,ParameterValue=FSxOSecurityGroup \
  --capabilities CAPABILITY_NAMED_IAM 
:::

## Clean up
Run these commands one by one in given sequence : 

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
eksctl delete nodegroup --region $REGION_2  --cluster $CLUSTER_NAME_1 --name $(eksctl get nodegroup --cluster $CLUSTER_NAME_1 --region $REGION_2 --output json | jq -r .[].Name)
eksctl delete cluster --name=$CLUSTER_NAME_1 --region $REGION_2 
eksctl delete nodegroup --cluster $CLUSTER_NAME_1 --name $(eksctl get nodegroup --cluster $CLUSTER_NAME_1 --output json | jq -r .[].Name)
eksctl delete cluster --name=$CLUSTER_NAME_1 
aws cloudformation delete-stack --stack-name FSxL-SecurityGroup-02 --region $REGION_2
aws cloudformation delete-stack --stack-name FSxL-SecurityGroup-01
aws cloudformation delete-stack --stack-name fsxZ-SecurityGroup
aws cloudformation delete-stack --stack-name ${iam_role_name}
aws cloudformation delete-stack --stack-name ${s3_2nd_bucket_name} --region $REGION_2
aws cloudformation delete-stack --stack-name ${s3_bucket_name}
aws cloudformation delete-stack --stack-name EKS-FSXONTAP
aws cloudformation delete-stack --stack-name FSX-EKS-VPC
:::


::alert[**DO NOT CLICK ON NEXT BELOW**: Please head straight to **[Module 1 - Running Amazon FSx for NetApp ONTAP on Amazon EKS](/100_module1_eks_fsxn/)** for the next action.]{header="Important" type="warning"}
