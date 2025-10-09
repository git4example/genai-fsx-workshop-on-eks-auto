---
title: 'Open source VSCode IDE'
chapter: false
weight: 23
---

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


## Update the kube-config file for Amazon EKS cluster:
Before you can start running all the Kubernetes commands included in this workshop, you need to update the kube-config file with the proper configuration to access EKS cluster. To do so, in your VSCode terminal run the below commands:

::code[export CLUSTER_NAME=eksworkshop]{language=bash showLineNumbers=false showCopyAction=true}

:::alert{header="Note" type="info"}
When you first time copy-paste a command on VSCode IDE, your browser may ask you to allow permission to see informaiton on clipboard. Please select **"Allow"**.

![allow-clipboard](/static/images/allow-clipboard.png)
:::

- Check if region and cluster names are set correctly

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
echo $AWS_REGION
echo $CLUSTER_NAME
:::

::code[aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION]{language=bash showLineNumbers=false showCopyAction=true}


## Test Amazon EKS cluster connectivity:
Run the command below just to see the connectivity to EKS Auto Cluster:

::code[kubectl get nodes]{language=bash showLineNumbers=false showCopyAction=true}

You should see one node provisioned which was provisioned by EKS Auto to run some of the core components required for the workshop.

![get-nodes](/static/images/get-nodes.png)

You now have a VSCode IDE Server environment set-up ready to use your Amazon EKS Cluster! You may now proceed with the next step.
