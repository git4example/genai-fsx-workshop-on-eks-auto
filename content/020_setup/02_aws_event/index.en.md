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


::alert[Ask Your Operator for the region to use.]


Please select the appropriate region in the top right corner.

## Connect to your environments via Cloud9 


::alert[Note that you should be logging as eks-fsx-workshop-admin mentioned above. If you are not, please follow the instruction of Log Into AWS Console.]

- From **your workstation** navigate to your AWS console session, from the top search bar in the AWS console, type and select **Cloud9**.

- Click 3 lines on left : 
  
  ![Cloud9_000](/static/images/Cloud9_000.png)

- Click **Shared with me**
 
 ![Cloud9_00](/static/images/Cloud9_00.png)

- Select select **eks-fsx-workshop** and click the **Open** under the **Cloud9 IDE**, or click **Open in Cloud9** on the upper right corner to launch the Cloud9 environment.

 ![c9-click-button](/static/images/c9-click-button.png)

- The **eks-fsx-workshop** folder has already been cloned from github repo. And you can open New Terminal to run commands from the Cloud9 Terminal.

 ![Cloud9_02](/static/images/Cloud9_02.png)


- Check to see Cloud9 EC2 instance role. Check whether you are using `eks-fsx-workshop-admin` assumed IAM Role, using the following command.

```bash
aws sts get-caller-identity
```

Expected Output look like this, Do not to confuse with command prompt `WSParticipantRole`, this is expected. 

![Cloud9_Terminal](/static/images/Cloud9-Terminal.png)


- Replace `<region name>` with your lab region name as shared by your workshop operator. 

::code[export REGION_1=<region name>]{language=bash showLineNumbers=false showCopyAction=true}

::code[export REGION_2=us-east-2]{language=bash showLineNumbers=false showCopyAction=true}

- Set cluster variables : 

```bash
export CLUSTER_NAME_1=FSx-eks-cluster
export CLUSTER_NAME_2=FSx-eks-cluster02
```

- Check if region and cluster names are set correctly

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
echo $REGION_1
echo $REGION_2
echo $CLUSTER_NAME_1
echo $CLUSTER_NAME_2
:::

- Next update kubeconfig file to point it to EKS cluster in that region.

::code[aws eks update-kubeconfig --name $CLUSTER_NAME_1 --region $REGION_1]{language=bash showLineNumbers=false showCopyAction=true}

- Run kubectl command to confirm your access to the EKS cluster.

::code[kubectl get nodes]{language=bash showLineNumbers=false showCopyAction=true}

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
rm -f  ~/.aws/credentials 
```

Check once again to see you are using `eks-fsx-workshop-admin` role: 

```bash
kubectl get nodes
```
::::


