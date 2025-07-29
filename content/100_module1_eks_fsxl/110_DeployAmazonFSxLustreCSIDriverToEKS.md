---
title : "Deploy CSI Driver"
weight : 110
---

In this section, the following steps will guide you to set the required environmental variables, create a service account, and  create/attach an IAM policy for use with your EKS cluster, allowing you to then deploy the CSI driver for FSx for Lustre.

:::alert{header="Note" type="info"}
For an AWS Sponsored Workshop, the Security Group and S3 Bucket have been pre-created for you.
:::

For more information about what rule is required for the FSx Lustre Security Group, please refer to the [official document](https://docs.aws.amazon.com/fsx/latest/LustreGuide/limit-access-security-groups.html).


##### Step 1: Create an IAM policy, and service account, that allows the CSI driver to make the AWS API calls on your behalf

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

##### Step 2: Create the IAM policy

Copy and run the following command to create an IAM polcy.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
aws iam create-policy \
        --policy-name Amazon_FSx_Lustre_CSI_Driver \
        --policy-document file://fsx-csi-driver.json
:::

##### Step 3: Create a Kubernetes service account for the driver and attach the policy to the service account

Copy and run the below command to create the service account and attach the IAM policy created in Step 3.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
eksctl create iamserviceaccount \
    --region $AWS_REGION \
    --name fsx-csi-controller-sa \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn arn:aws:iam::$AWS_ACCOUNTID:policy/Amazon_FSx_Lustre_CSI_Driver \
    --approve
:::

::alert[you need to wait for 30 to 60 secs for the above command to complete]

::::expand{header="You’ll see several lines of output as the service account is created. The last line of output is similar to the following example line, click to expand"}

:::code[]{language=bash showLineNumbers=false showCopyAction=false}
(...)
2023-09-29 07:40:56 [ℹ]  created serviceaccount "kube-system/fsx-csi-controller-sa"
:::

::::

##### Step 4: Save the Role ARN that was created into a variable

Copy and run the below command to save the role ARN.

::code[export ROLE_ARN=$(aws cloudformation describe-stacks --stack-name "eksctl-${CLUSTER_NAME}-addon-iamserviceaccount-kube-system-fsx-csi-controller-sa" --query "Stacks[0].Outputs[0].OutputValue"  --region $AWS_REGION --output text)]{language=bash showLineNumbers=false showCopyAction=true}

Copy the output of this ROLE_ARN into your notepad file
::code[echo $ROLE_ARN]{language=bash showLineNumbers=false showCopyAction=true}


##### Step 5: Deploy the CSI driver of FSx for Lustre

Copy and the run the following command to deploy the CSI driver for FSx for Lustre

**Add repository**
:::code[]{language=bash showLineNumbers=true showCopyAction=true}
helm repo add aws-fsx-csi-driver https://kubernetes-sigs.github.io/aws-fsx-csi-driver
helm repo update
:::

**Install**
:::code[]{language=bash showLineNumbers=true showCopyAction=true}
helm upgrade --install aws-fsx-csi-driver aws-fsx-csi-driver/aws-fsx-csi-driver \
    --namespace kube-system \
    --version 1.11.0 \
    --set serviceAccount.create=true \
    --set serviceAccount.name=fsx-csi-controller-sa \
    --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$ROLE_ARN
:::

Verify that the CSI driver has been installed successfully with the following command.

::code[kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-fsx-csi-driver]{language=bash showLineNumbers=false showCopyAction=true}


::::expand{header="You should see the results as below, click to expand"}

:::code[]{language=bash showLineNumbers=false showCopyAction=false}
NAME                                  READY   STATUS    RESTARTS   AGE
fsx-csi-controller-659fd7dcd4-dvrn5   4/4     Running   0          38s
fsx-csi-controller-659fd7dcd4-wtzsl   4/4     Running   0          38s
fsx-csi-node-2pcvt                    3/3     Running   0          38s
:::

::::

## Summary

In this section you have completed the pre-requisite tasks of creating environmental variables, creating a service account with the right IAM policy and role ARN, and deployed the CSI driver of FSx for Lustre. In the next sections you will create the Persistent Volume (PV), Persistent Volume Claim (PVC), and StorageClass for FSx for Lustre.
