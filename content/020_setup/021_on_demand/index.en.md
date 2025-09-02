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


You will need a Linux based Amazon Linux 2023 based EC2 jump-box that is configured with an Amazon EBS GP3 based volume that has at least 100GB FREE. This EC2 jump-box also needs to have the required account access and permissions in-order to run the commands outline below, along with being able to create AWS resources required for this workshop.  


 **Note**: You may need IAM permissions attached to this EC2 instance role with following broad indicative permissions to provision workshop resouces

Here's a broad IAM policy that you may includes all the required permissions for both CloudFormation and Terraform deployments:

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

Alternative for simplicity, you may like to use AWS managed policies: `AdministratorAccess` 


### Part 2 : Automated Workshop Deployment


Run the automated deployment script :

```bash
# Download and run the deployment script
curl -O https://raw.githubusercontent.com/git4example/genai-fsx-workshop-on-eks-auto/mainline/static/scripts/quick-deploy-on-demand.sh
chmod +x quick-deploy-on-demand.sh
./quick-deploy-on-demand.sh
```

**Time**: ~45-60 minutes (complete infrastructure deployment)

The workshop automated deployment script that handles all setup tasks including:
- Tool installation (AWS CLI, Docker, Git, jq)
- Repository cloning
- S3 bucket creation and file uploads
- Mistral-7B model download and upload
- CloudFormation stack deployment with monitoring
- Deployment validation and access information




You have now completed the workshop deployment and have a VSCode IDE Server environment ready to use with your Amazon EKS Cluster! Please proceed to the first module of the workshop **[Open source VSCode IDE](/020-setup/023_vs_code)**.


### Part 3 : Workshop Cleanup

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



