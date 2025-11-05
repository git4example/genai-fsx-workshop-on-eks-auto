---
title: 'On-demand Workshop'
chapter: false
weight: 21
---

:::alert{header="Important" type="warning"}
If you are at an AWS event and are using **[AWS Sponsored Workshop](/020-setup/022-aws-event)** instead of on-demand workshop, please **SKIP** this section and go straight to the **[AWS Sponsored Workshop](/020-setup/022-aws-event)**
:::


**On-demand workshops** are workshops that you deploy in your own environment. These are different to **AWS Sponsored workshops**, where AWS will provide you with a temporary workshop lab account, which already has the workshop provisioned in it.

### Part 1 : Identify an Amazon EC2 instance that you can use for the initial workshop provisioning

To deploy the workshop script (in part 2 of this module), you will need access to a Linux based Amazon Linux 2023 Amazon EC2 instance, with an Amazon EBS GP3 volume with at least 100GB free capacity (to download the LLM model data and other items required for the workshop)

This Linux based EC2 instance also needs to have the required AWS account access and permissions in-order to run the commands outlined below, along with being able to create AWS resources required for this workshop (as shown below).  

Below is an EXAMPLE of a broad IAM policy that you could use, which includes all the required permissions for both CloudFormation and Terraform deployments:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity",
                "s3:*",
                "cloudformation:*",
                "ec2:*",
                "eks:*",
                "iam:*",
                "fsx:*",
                "cloudfront:*",
                "lambda:*",
                "ssm:*",
                "logs:*",
                "secretsmanager:*"
            ],
            "Resource": "*"
        }
    ]
}
```


### Part 2 : Automated workshop deploymentbscript

The below workshop automated deployment script handles setup tasks including:
- Tool installation (AWS CLI, Docker, Git, jq)
- Repository cloning\
- Creating of AWS resources: Amazon EKS cluster, Amazon EC2 instance, Amazon S3 bucket
- Mistral-7B model download to S3 bucket
- Deployment of the VSCode IDE terminal (which you will use to interact with the workshop)
- CloudFormation stack deployment with monitoring
- Deployment validation and access information

1. Run the below commands to start the automated workshop environment deployment script:

```bash
curl -O https://raw.githubusercontent.com/git4example/genai-fsx-workshop-on-eks-auto/mainline/static/scripts/quick-deploy-on-demand.sh
chmod +x quick-deploy-on-demand.sh
./quick-deploy-on-demand.sh
```

2. A few minutes into the deployment, the script will ask you to enter a unique name for an S3 bucket that will be created to host the downloaded Mistral-7B model and workshop artifacts.

**Deployment time will take approx:** ~45 minutes (complete infrastructure deployment)

3. Wait until you see the following output on your screen before progressing to the next step of **Part 3 : Use VScode IDE to access workshop**

![ondemand_setup_complete](/static/images/ondemand_setup_complete.png)



### Part 3 : Use VScode IDE to access workshop

You have now completed the workshop deployment and its components.

Click on the following link to access your **[Open source VSCode IDE](/023_vs_code)** and begin the workshop.


### Part 4 : Workshop Cleanup - Once you have finished with the workshop.

When you're finished with the workshop, use the cleanup script to remove all resources:

```bash
# Navigate to scripts directory (if not already there)
cd genai-fsx-workshop-on-eks-auto/static/scripts

# Run cleanup script
./cleanup-on-demand.sh
```

**Cleanup Features**:
- Interactive confirmation for each cleanup step
- CloudFormation stack deletion with progress monitoring
- Optional S3 bucket and contents removal
- Local files and temporary data cleanup
- Verification commands to confirm resource removal

**Time**: ~30-60 minutes (CloudFormation deletion of complex resources)

:::alert{header="Important" type="warning"}
Always run the cleanup script after completing the workshop to avoid unexpected AWS charges.
:::
