---
title : "Deploy Amazon FSx for Lustre CSI Driver to EKS cluster"
weight : 120
---
-------------------------------------------------------------

In this section, the following steps will guide you to deploy CSI Driver of Amazon FSx for Lustre. As a prerequisite step you will have to set the environment variables, create a service account & IAM poilcy with role ARN. Then proceed with the CSI driver deployment for FSx for lustre filesystem.

Below steps to ensure that you are operating from the right AWS region and in the right working directory with the access to the EKS cluster.


::alert[As mentioned in the previous session, you should have run the following commands to be able to run `kubectl` to connect to your EKS cluster. But if you missed it, please run the following commands]

::::expand{header="Confirm your access to the EKS cluster, Only run these commands if you have not yet done so in the previous steps."}

- Check if region and cluster names are set correctly, if not then follow one of the suitable page for your situation under **[Getting Started ](/020-setup)** to setup these variables. 

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
echo $REGION_1
echo $REGION_2
echo $CLUSTER_NAME_1
echo $CLUSTER_NAME_2
:::

- Next update kubeconfig file to point it to EKS cluster in that region.

::code[aws eks update-kubeconfig --name $CLUSTER_NAME_1 --region $REGION_1]{language=bash showLineNumbers=false showCopyAction=true}

- Run kubectl command to confirm your access to the EKS cluster

::code[kubectl get nodes]{language=bash showLineNumbers=false showCopyAction=true}

::::


1. Go to the right working directory.

::::tabs{variant="container" activeTabId="cloud9"}
:::tab{id="linux" label="Linux"}

::code[cd /eks-fsx-workshop/eks/FSxL]{language=bash showLineNumbers=false showCopyAction=true}
:::
:::tab{id="windows" label="Windows"}

::code[cd /c/Users/Administrator/Desktop/eks-fsx-workshop/eks/FSxL]{language=bash showLineNumbers=false showCopyAction=true}

You should be in the current working directory as shown in the below screenshot
![windows_FSxL](/static/images/Windows_FSxL.png)

:::
:::tab{id="cloud9" label="Cloud9"}

::code[cd /home/ec2-user/environment/eks-fsx-workshop/eks/FSxL]{language=bash showLineNumbers=false showCopyAction=true}
:::
::::

The below steps will guide you to set the environmental variables, create a service account, create and attach an IAM policy and deploy the CSI driver for Amazon FSx for Lustre.

### Step 1: Prerequisite - setting the required environmental variable

Copy and paste the following lines in the CLI.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
CLUSTER_NAME_1="FSx-eks-cluster"
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME_1 --region $REGION_1 --query "cluster.resourcesVpcConfig.vpcId" --output text)
SUBNET_ID=$(aws eks describe-cluster --name $CLUSTER_NAME_1 --region $REGION_1 --query "cluster.resourcesVpcConfig.subnetIds[0]" --output text)
SECURITY_GROUP_ID=$(aws cloudformation describe-stacks --stack-name FSxL-SecurityGroup-01 --region $REGION_1 --query "Stacks[0].Outputs[0].OutputValue" --output text)  
S3_BUCKET=$(aws s3 ls | grep fsx-luster-bucket | grep -v fsx-luster-bucket-2ndregion | awk '{print$3}')
S3_BUCKET_2NDREGION=$(aws s3 ls | grep fsx-luster-bucket-2ndregion | awk '{print$3}')
:::

:::alert{header="Note" type="info"}
Note: For AWS Sponsored Workshop, Security Group and S3 Bucket have been pre-created for you. If you are running the self-paced labs, please expand the below to create your security groups and S3 bucket.
:::

For more information about what rule is required for the FSx Lustre Security Group, please refer to the [official document](https://docs.aws.amazon.com/fsx/latest/LustreGuide/limit-access-security-groups.html).


### Step 2: Create an IAM policy and service account that allows the driver to make the AWS API calls on your behalf

Copy and run the below command to create the fsx-csi-driver.json file.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
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
:::

### Step 3: Create the IAM policy

Copy and run the following command to create an IAM polcy. 

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
aws iam create-policy \
        --policy-name Amazon_FSx_Lustre_CSI_Driver \
        --policy-document file://fsx-csi-driver.json
:::

### Step 4: Create a Kubernetes service account for the driver and attach the policy to the service account

Copy and run the below command to create the service account and attach the IAM policy created in Step 3. 

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
eksctl create iamserviceaccount \
    --region $REGION_1 \
    --name fsx-csi-controller-sa \
    --namespace kube-system \
    --cluster $CLUSTER_NAME_1 \
    --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/Amazon_FSx_Lustre_CSI_Driver \
    --approve
:::

::alert[you need to wait for 30 to 60 secs for the above command to complete]

::::expand{header="You’ll see several lines of output as the service account is created. The last line of output is similar to the following example line, click to expand"}

```
(...)
2023-09-29 07:40:56 [ℹ]  created serviceaccount "kube-system/fsx-csi-controller-sa"
```

::::

### Step 5: Save the Role ARN that was created via CloudFormation into a variable

Copy and run the below command to save the role ARN.

::code[export ROLE_ARN=$(aws cloudformation describe-stacks --stack-name "eksctl-${CLUSTER_NAME_1}-addon-iamserviceaccount-kube-system-fsx-csi-controller-sa" --query "Stacks[0].Outputs[0].OutputValue"  --region $REGION_1 --output text)]{language=bash showLineNumbers=false showCopyAction=true}


### Step 6: Deploy the CSI driver of FSx for Lustre

Copy and the run the following command to deploy the CSI driver.

::code[kubectl apply -k "github.com/kubernetes-sigs/aws-fsx-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.1"]{language=bash showLineNumbers=false showCopyAction=true}


Verify whether the CSI driver has been installed successfully with the following command.

::code[kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-fsx-csi-driver]{language=bash showLineNumbers=false showCopyAction=true}


::::expand{header="You should see the results as below, click to expand"}

```
fsx-csi-controller-c7d98b5b-j47bq   4/4     Running   0          45s
fsx-csi-controller-c7d98b5b-kdgs9   4/4     Running   0          45s
fsx-csi-node-ckqjr                  3/3     Running   0          45s
fsx-csi-node-jxscw                  3/3     Running   0          45s
```

::::

### Step 7: Annotate service account that we created in step 4 above

Copy and the run the following commands to add IAM role to the service account 

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
kubectl annotate serviceaccount -n kube-system fsx-csi-controller-sa \
 eks.amazonaws.com/role-arn=$ROLE_ARN --overwrite=true
:::

You can verify checking the service account contents

::code[kubectl get sa/fsx-csi-controller-sa -n kube-system -o yaml]{language=bash showLineNumbers=false showCopyAction=true}

::::expand{header="You can see the Service account has the annotation to the IAM Role created just now, click to expand"}

:::code[]{language=yaml showLineNumbers=true showCopyAction=false}
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::0048XXXXXXXX:role/eksctl-FSx-eks-cluster-addon-iamserviceaccount-Role1-1MCAGIVMRJ8SZ
...
  labels:
    app.kubernetes.io/managed-by: eksctl
    app.kubernetes.io/name: aws-fsx-csi-driver
  name: fsx-csi-controller-sa
  namespace: kube-system
secrets:
- name: fsx-csi-controller-sa-token-XXX
:::

::::

## Summary

In this section you have completed the pre-requisite tasks of creating environmental variables, creating service account with the right IAM policy and role ARN. Post which you have deployed the CSI driver of FSx for Lustre and verified the service account contents.  In the next section you will create the storage class and the persistent volume claim (PVC) for FSx for Lustre file system. 