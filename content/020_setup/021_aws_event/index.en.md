---
title: 'AWS Sponsored Workshop'
chapter: false
weight: 21
---
## Login into the AWS Console

::alert[Before you proceed log off from any previous AWS consoles and close all the web browser. Start a new browser]{header="Important" type="warning"}

::alert[If you are currently logged in to an AWS Account, you can logout using this [link](https://console.aws.amazon.com/console/logout!doLogout).]{type="warning"}


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
