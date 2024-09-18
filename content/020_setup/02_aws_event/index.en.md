---
title: 'AWS Sponsored Workshop'
chapter: false
weight: 10
---
## Login into the AWS Console

::alert[Before you proceed log off from any previous AWS consoles and close all the web browser. Start a new browser]{header="Important" type="warning"}

::alert[If you are currently logged in to an AWS Account, you can logout using this [link](https://console.aws.amazon.com/console/logout!doLogout).]{type="warning"}


1. From your local workstation, open a web browser to the lab access URL provided for the workshop

    - Click on the [link](https://catalog.us-east-1.prod.workshops.aws/join) to be be taken to the sign in page

    ![Workshop Studio](/static/images/signin_page.png)

    - Click on the Email one-time password(OTP) and enter your email address to recieve the OTP

    - Enter the One-time email 9 digits passcode and click sign in

    ![Workshop Studio](/static/images/One_time_passcode.png)

    - You will be redirected to Join event page,  Eneter the event access code and click on **Next**

    ![Workshop Studio](/static/images/Start_page_join.png)

    - You will then be taken to the Review & Join page, click on the check box to agree the terms and condition. Click on the Join Event

    ![Workshop Studio](/static/images/review_join.png)

    - You will be taken to the workshop instructions page with all details

    - on the left bottom of the page you will find the AWS account access information.

    ![Workshop Studio](/static/images/account_access.png)

    - Click **Open AWS Console**


<!-- ::alert[Ask Your Operator for the region to use.] -->

Please select the appropriate region in the top right corner.

## Connect to your environments via Cloud9


::alert[Note that you should be logging as eks-fsx-workshop-admin mentioned above. If you are not, please follow the instruction of Log Into AWS Console.]

- From **your workstation** navigate to your AWS console session, from the top search bar in the AWS console, type and select **Cloud9**.

- Select select **genaifsxworkshoponeks** and click the **Open** under the **Cloud9 IDE**, or click **Open in Cloud9** on the upper right corner to launch the Cloud9 environment.

 ![c9-click-button](/static/images/c9-click-button.png)

- Once the IDE loads up you can create a new terminal, by clicking at the top tabs: (+) button > New Terminal. This terminal will be used to run all the commands for this workshop.

 ![Cloud9_02](/static/images/Cloud9_02.png)


### Validate the IAM role {#validate_iam}

- In most cases, Cloud9 manages IAM credentials dynamically, however this currently not compatible with the Amazon EKS IAM authentication, so we will disable it and rely on an AWS IAM role instead. To do so, run the following commands in the Cloud9 workspace:

```bash
aws cloud9 update-environment --environment-id ${C9_PID} --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials
```

Use the [GetCallerIdentity](https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html) CLI command to validate that the Cloud9 IDE is using the correct IAM role.

```bash
aws sts get-caller-identity
```

The output assumed-role name should look like the following:

![Cloud9_Terminal](/static/images/Cloud9-Terminal-correct.png)

If you see incorrect output like below example, please run above command to fix credentials:

![Cloud9_Terminal](/static/images/Cloud9-Terminal-incorrect.png)

- Set lab region name as configured by your workshop operator.

:::code[]{language=bash showLineNumbers=false showCopyAction=true}
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
:::

- Set cluster variables :

::code[export CLUSTER_NAME=eksworkshop]{language=bash showLineNumbers=false showCopyAction=true}


- Check if region and cluster names are set correctly

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
echo $AWS_REGION
echo $CLUSTER_NAME
:::

## Update the kube-config file:
Before you can start running all the commands included in this workshop, you need to update the kube-config file with the proper credentials to access the cluster. To do so, in your Cloud9 workspace run the following command:

::code[aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION]{language=bash showLineNumbers=false showCopyAction=true}


## Test the cluster:
Run the command below to see the Kubernetes nodes currently provisioned:

::code[kubectl get nodes]{language=bash showLineNumbers=false showCopyAction=true}

You should see two nodes provisioned (which are the on-demand nodes used by the Kubernetes controllers), such as the output below:


![get-nodes](/static/images/get-nodes.png)


:::alert{header="Important" type="warning"}

Just in case you notice one of the following error on previous command :

::code[error: You must be logged in to the server (Unauthorized)]{language=bash showLineNumbers=false showCopyAction=false}

Or

::code[error: You must be logged in to the server (the server has asked for the client to provide credentials)]{language=bash showLineNumbers=false showCopyAction=false}

expand section below to run command to clear managed credentials.


::::expand{header="Run command below to allow use of Cloud9 Instance profile credentials:"}

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
