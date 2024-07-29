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

## Connect to your environments via Cloud9 or Linux or Windows Management Box

:::alert{header="Important" type="warning"}
**Please click on either Cloud9 or  Linux or Windows below for the method to access the workshop. We recommend you to choose Cloud9.**
:::

::::tabs{variant="container" activeTabId="cloud9"}
:::tab{id="linux" label="Linux"}
You can access your Linux management box via two ways:

### Option A. Download the SSH key from the event engine and access from SSH client

- On the bottom left, click on **Get EC2 SSH Key**, next click **Download Key pair**

![Workshop Studio](/static/images/account_access.png)

![Access Page](/static/images/ssh_key.png)

- It will then download a `ws-default-keypair.pem` SSH key file to your users downloads folder (the downloaded file will also be shown at the bottom of the Chrome screen for reference).
- Navigate to the [EC2 console](https://console.aws.amazon.com/ec2), click on instances on the left, Select "Workshop Linux Instance 1", and Copy down the Public IPv4 address from the AWS Console for your Instance (Ensure your region is `lab-region`)

- Open your SSH client, and connect the EC2 instance

```bash
ssh -i ws-default-keypair.pem ec2-user@ip-address
```

- Logon as root user

```bash
sudo -i
```

### Option B. Use System Manager Session Manager to connect to your Linux instance terminal

- Find the EC2 Instance for Linux Management Box from the AWS Console, and click "Connect" (Ensure your region is the right region of your lab)

  ![LinuxConnect](/static/images/Linux02.png)

- Click "Connect" at the `Session Manager` Tab

  ![SessionManager](/static/images/Linux03.png)

- Switch to the root user

```bash
sudo -i
```

:::

:::tab{id="windows" label="Windows"}
Firstly let’s retrieve the Windows administrator password from AWS Secrets
Manager

- From **your workstation** navigate to your AWS console session, from the top search bar in the AWS console, type and select **Secrets Manager**.

- Click on the value shown under **Secret name** (i.e. AdminSecret-abczxy).

- Scroll down the page and click on **Retrieve secret value** under Secret Value.

![AdminSecret](/static/images/AdminSecret.png)

![Retrive](/static/images/Retrive.png)

- Copy and paste the password value shown for **Secret key value** into a notepad file.

- Next let’s connect to your Windows Server EC2 instance.

- From the AWS console and top search bar, type and & select **EC2**.

- From the left-hand menu, select **Instances**.

- In the right-hand pane, select the box next to **Workshop Windows instance 1**, then right click and select **Connect**.

- Click on The RDP Client tab, then **Download Remote Desktop File**.

- Open the downloaded Remote Desktop File and select Connect at the prompt.
- Enter the credentials below and click on OK.

| Username | Password |
| :------: | :-------:|
| Administrator | the value you obtained from Secrets manager |

- You have now successfully logged into your Windows workshop instance.
- Open Visual Studio Code -> File -> Open Folder, and choose the folder `eks-fsx-workshop` in the Desktop.

![VSD01](/static/images/vsc01.png)
![VSD02](/static/images/vsc02.png)

- Open `Visual Studio Code`, press `Ctrl+Shift+P`, and type in `select default profile`, then choose `Git Bash` as the default one.
![VS04](/static/images/VS04.png)
![VS05](/static/images/VS05.png)

- Open `Visual Studio Code` -> Terminal -> New Terminal or Open `cmd` from your Windows Workshop Instance, and run the following command, replace  with your `lab region name`.
![VSD03](/static/images/vsc03.png)


- You should be able to see `Git Bash` as your terminal
  
![VS06](/static/images/VS06.png)

::alert[It is important to run as Git Bash in this workshop, as majority of the command in the workshop are not powershell, but bash based.]{header="Important" type="warning"}

::alert[All remaining tasks for the workshop will be performed through the Remote Desktop Session to the Windows EC2 Instance you just connected to in the previous steps.]

:::

:::tab{id="cloud9" label="Cloud9"}

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

::::

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


