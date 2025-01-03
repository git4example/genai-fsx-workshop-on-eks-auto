---
title: 'AWS Sponsored Workshop'
chapter: false
weight: 22
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

::alert[Before getting started, from the top right corner of your AWS Console session, select the **AWS Region** that has been stated for your workshop session.]{header="Important" type="warning"}


## Connect to your AWS lab environment via Open source VSCode IDE
Ref : [code-server](https://github.com/coder/code-server)

You will be using the Open source VSCode IDE terminal to copy and paste commands that are provided in this workshop. Let's get started and connect to your VScode IDE instance by running the follow actions.

::alert[Note: Please use a Google chrome browser for this workshop, Firefox users may experience some issues with copy-paste commands.]{header="Important" type="warning"}

1. Navigate to the CloudFrmation console using this [link](https://console.aws.amazon.com/cloudformation), then select the `genaifsxworkshoponeks` stack
2. In the Stack window, select the **Outputs** tab as shown in the image below
3. Copy the temporary **Password** that has been generated for this workshop as shown, and click then on the **URL** shown to launch the VSCode-Server interface
4. In the VSCode IDE that pops up, enter the password you previously copied, and click **Submit**

![CFN-Output](/static/images/cfn-output.png)

5. Select your VSCode UI theam

![Select Theme](/static/images/select-theme.png)

6. Click on the **TERMINAL** TAB, and maximize your terminal window.

![maximize](/static/images/maximize.png)


### Validate the IAM role {#validate_iam}

- Copy and paste the below CLI command into your VSCode IDE terminal to validate that the VSCode IDE is using the correct IAM role.

::code[aws sts get-caller-identity]{language=bash showLineNumbers=false showCopyAction=true}


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
Before you can start running all the Kubernetes commands included in this workshop, you need to update the kube-config file with the proper credentials to access the cluster. To do so, in your VSCode terminal run the below command:

::code[aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION]{language=bash showLineNumbers=false showCopyAction=true}


## Query the Amazon EKS cluster:
Run the command below just to see the connectivity to EKS Auto Cluster:

::code[kubectl get nodes]{language=bash showLineNumbers=false showCopyAction=true}

Initially there will be no nodes in the cluster. As you start creating pods, EKS Auto will auto provision worker nodes as per workload demands. 

You now have a VSCode IDE Server environment set-up ready to use your Amazon EKS Cluster! You may now proceed with the next step.
