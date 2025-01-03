---
title : "Deploy vLLM on AWS Inferentia nodes for model Inference"
weight : 210
---

#####  Step 1: Create Karpenter NodePool and EC2 NodeClass for AWS Inferentia Accelerators

Karpenter configuration comes in the form of a NodePool Custom Resource (CR). The NodePool sets constraints on the nodes that can be created by Karpenter and the pods that can run on those nodes. The NodePool can be set to do things like limiting node creation to certain computer architectures or be flexible to use multiple. A single Karpenter NodePool is capable of handling many different pod shapes. Karpenter makes scheduling and provisioning decisions based on pod attributes such as labels and affinity. A cluster may have more than one NodePool, but for the moment we will declare additional one: the inferentia NodePool.


1. A Karpenter NodePool sets constraints on the nodes that can be created by Karpenter and the pods that can run on those nodes. AWS-specific settings can be set up with NodeClasses. Multiple NodePools may point to the same EC2NodeClass.

2. Change to the working directory in your VSCode IDE terminal

:::code[]{language=bash showLineNumbers=false showCopyAction=true}
NODE_ROLE=$(cd /home/participant/environment/terraform && terraform output --raw eks_node_iam_role_name)
cd /home/participant/environment/eks/genai
sed -i'' -e "s/NODE_ROLE/$NODE_ROLE/g" inferentia_nodepool.yaml
:::

3. Lets take a look at the Karpenter NodePool definition that we will deploy. It will create a new nodepool for AWS Inferentia INF2 Accelerated Compute nodes that we will use to power our Generative AI application (vLLM pod)

::code[cat inferentia_nodepool.yaml]{language=bash showLineNumbers=false showCopyAction=true}

4. Let's deploy the Karpenter NodePool definition for AWS Inferentia INF2 Accelerated Compute nodes


::code[kubectl apply -f inferentia_nodepool.yaml]{language=bash showLineNumbers=false showCopyAction=true}

5. Verify NodePool and NodeClass:
::code[kubectl get nodepool,nodeclass inferentia]{language=bash showLineNumbers=false showCopyAction=true}

You should see an output similar to the one below.

:::code{showCopyAction=false showLineNumbers=false language=bash}
NAME                               NODECLASS    NODES   READY   AGE
nodepool.karpenter.sh/inferentia   inferentia   0       True    11s

NAME                                     ROLE                                              READY   AGE
nodeclass.eks.amazonaws.com/inferentia   eksworkshop-eks-auto-20250103063226329700000003   True    11s
:::

##### Step 2: Install Neuron device plugin & scheduler

:::alert{header="Important" type="info"}
To save you time in the lab, the Mistral-7B model has already been downloaded & compiled using the AWS Neuron SDK, so that you can deploy it on the AWS Inferentia Accelerated Computes nodes for this workshop.
:::


Now we need to install the Neuron Device Plugin and Neuron Scheduler on the EKS cluster.

###### Neuron Device plugin
A Neuron device plugin exposes Neuron cores & devices to Kubernetes as a resource.

1. Run the following commands to Install the Neuron device plugin (ignore any kubectl warnings):
:::code{showCopyAction=true showLineNumbers=true language=bash}
kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/k8s-neuron-device-plugin-rbac.yml
kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/k8s-neuron-device-plugin.yml
:::

###### Neuron Scheduler
The Neuron scheduler extension is required for scheduling pods that require more than one Neuron core or device resource. Neuron scheduler extension filter out nodes with non-contiguous core/device ids and enforces allocation of contiguous core/device ids for the PODs requiring it.


2. Run the below commands to install the Neuron Scheduler:
:::code{showCopyAction=true showLineNumbers=true language=bash}
kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/k8s-neuron-scheduler-eks.yml
kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/my-scheduler.yml
:::


##### Step 3: Deploy the vLLM application Pod

You will now deploy the vLLM pod which will provide you with model serving capability, and inference endpoint. Once the vLLM Pod is online, it will load the Mistral-7B model (29GB) into its memory from your FSx for Lustre based Persistent Volume, then it will be ready to use.

1. Run the below command to deploy your vLLM Pod.

::code[kubectl apply -f mistral-fsxl.yaml]{language=bash showLineNumbers=false showCopyAction=true}

2. The vLLM deployment will take approx. 7-8 minutes. (**You can continue to the next steps, and don't need to wait for this step to complete**).

3. Run the below command to inspect the vLLM's mistral-fsxl.yaml deployment file.

:::alert{header="Note" type="info"}
You will notice a single pod deployment request, with a request for AWS Inferentia Neuron core, persistent storage using the PVC you created previously, using FSx for Lustre (fsx-lustre-claim), and also some model parameters.  
:::


::code[cat mistral-fsxl.yaml]{language=bash showLineNumbers=false showCopyAction=true}


4. You can monitor the vLLM pod creation by running the following command periodically, until you see it transitioning to `Running`

::code[kubectl get pod]{language=bash showLineNumbers=false showCopyAction=true}

![vllm_pod](/static/images/vllm_pod_1.png)


5. Navigate to the [Amazon EKS cluster Console](https://console.aws.amazon.com/eks)

6. Click on your cluster name (i.e. eksworkshop)

7. Click on the   **Compute** tab, you will see there is now a new AWS Inferentia **inf2.xlarge** compute node

![inf2_node](/static/images/inf2_node.png)

8. Click on the **Node name**, where it will show you the capacity allocation and Pod details relating to the inf2.xlarge compute node


### Summary
You have now deployed the vLLM Pod. Continue to the next lab section to deploy the WebUI Pod, so you can interact with the Mistral-7B model through the vLLM (model serving and inferencing).
