---
title : "Deploy vLLM on AWS Inferentia nodes for model Inference"
weight : 210
---


##### Step 1: Neuron Device Plugin, Neuron Scheduler, and Node Problem Detector 

Please note that we will install Neuron Device Plugin, Neuron Scheduler, and Node Problem Detector using helm chart. For better understanding use of [AWS Neuron Helm Chart](https://aws.amazon.com/blogs/containers/announcing-aws-neuron-helm-chart/).

:::code{showCopyAction=true showLineNumbers=true language=bash}
cd /home/participant/environment/terraform
helm upgrade --install neuron-helm-chart oci://public.ecr.aws/neuron/neuron-helm-chart -n kube-system -f ./helm-values/neuron-values.yaml 
:::

You should see an output similar to the one below.

:::code{showCopyAction=false showLineNumbers=false language=bash}
Release "neuron-helm-chart" does not exist. Installing it now.
Pulled: public.ecr.aws/neuron/neuron-helm-chart:1.1.1
Digest: sha256:05b0f6edfb14466c5dd232e8c4cf431f6d7fb7c536bd51470a08b7b936999c4a
NAME: neuron-helm-chart
LAST DEPLOYED: Thu Jan  9 05:35:33 2025
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
:::

Lets take a moment to understand each of these components. 

###### Neuron Device plugin

Neuron device plugin exposes Neuron cores & devices to kubernetes as a resource. `aws.amazon.com/neuroncore` and `aws.amazon.com/neuron` are the resources that the neuron device plugin registers with the kubernetes. `aws.amazon.com/neuroncore` is used for allocating neuron cores to the container. `aws.amazon.com/neuron` is used for allocating neuron devices to the container. When resource name ‘neuron’ is used, all the cores belonging to the device will be allocated to container in your pod.

For more informaiton on this, please refer [Neuron Device Plugin](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/containers/kubernetes-getting-started.html#neuron-device-plugin)


###### Neuron Scheduler
The Neuron scheduler extension is required for scheduling pods that require more than one Neuron core or device resource. Neuron scheduler extension filter out nodes with non-contiguous core/device ids and enforces allocation of contiguous core/device ids for the PODs requiring it.

The Neuron scheduler extension finds sets of directly connected devices with minimal communication latency when scheduling containers. On Inf1 and Inf2 instance types where Neuron devices are connected through a ring topology, the scheduler finds sets of contiguous devices. On Trn1.32xlarge, Trn1n.32xlarge, Trn2.48xlarge and Trn1n.32xlarge instance types where devices are connected through a 4x4, 2D Torus topology, where the Neuron scheduler enforces additional constraints.

For more informaiton on this, please refer [Neuron Scheduler Extension](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/containers/kubernetes-getting-started.html#neuron-scheduler-extension)

###### Node Problem Detector 

The Neuron Problem Detector Plugin facilitates error detection and recovery by continuously monitoring the health of Neuron devices across all Kubernetes nodes. It publishes CloudWatch metrics for node errors and can optionally trigger automatic recovery of affected nodes. 

For more informaiton on this, please refer [Neuron Problem Detector Plugin](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/containers/kubernetes-getting-started.html#neuron-scheduler-extension)

#####  Step 2: Create EKS Auto NodePool and EC2 NodeClass for AWS Inferentia Accelerators

EKS Auto configuration comes in the form of a NodePool Custom Resource (CR). The NodePool sets constraints on the nodes that can be created by EKS Auto and the pods that can run on those nodes. The NodePool can be set to do things like limiting node creation to certain computer architectures or be flexible to use multiple. A single EKS Auto NodePool is capable of handling many different pod shapes. EKS Auto makes scheduling and provisioning decisions based on pod attributes such as labels and affinity. A cluster may have more than one NodePool, but for the moment we will declare additional one: the inferentia NodePool.


1. A EKS Auto NodePool sets constraints on the nodes that can be created by EKS Auto and the pods that can run on those nodes. AWS-specific settings can be set up with NodeClasses. Multiple NodePools may point to the same EC2NodeClass.

2. Change to the working directory in your VSCode IDE terminal

:::code[]{language=bash showLineNumbers=false showCopyAction=true}
NODE_ROLE=$(cd /home/participant/environment/terraform && terraform output --raw eks_node_iam_role_name)
cd /home/participant/environment/eks/genai
sed -i'' -e "s/NODE_ROLE/$NODE_ROLE/g" inferentia_nodepool.yaml
:::

3. Lets take a look at the EKS Auto NodePool definition that we will deploy. It will create a new nodepool for AWS Inferentia INF2 Accelerated Compute nodes that we will use to power our Generative AI application (vLLM pod)

::code[cat inferentia_nodepool.yaml]{language=bash showLineNumbers=false showCopyAction=true}

4. Let's deploy the EKS Auto NodePool definition for AWS Inferentia INF2 Accelerated Compute nodes


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



##### Step 3: Deploy the vLLM application Pod

:::alert{header="Important" type="info"}
To save you time in the lab, the Mistral-7B model has already been downloaded & compiled using the AWS Neuron SDK, so that you can deploy it on the AWS Inferentia Accelerated Computes nodes for this workshop.
:::

You will now deploy the vLLM pod which will provide you with model serving capability, and inference endpoint. Once the vLLM Pod is online, it will load the Mistral-7B model (29GB) into its memory from your FSx for Lustre based Persistent Volume, then it will be ready to use.

1. Run the below command to deploy your vLLM Pod.

::code[kubectl apply -f mistral-fsxl.yaml]{language=bash showLineNumbers=false showCopyAction=true}

2. The vLLM deployment will take approx. 7-8 minutes. (**You can continue to the next steps, and don't need to wait for this step to complete**).

3. Run the below command to inspect the vLLM's mistral-fsxl.yaml deployment file. 

Please note, in this workshop we are using single Neuron resource so we may choose to not use Neuron Scheduler, however to demostrate and as a best practice we are using Neuron Scheduler.

:::alert{header="Note" type="info"}
You will notice a single pod deployment request, with a request for AWS Inferentia Neuron core, persistent storage using the PVC you created previously, using FSx for Lustre (fsx-lustre-claim), and also some model parameters.  
:::


::code[cat mistral-fsxl.yaml]{language=bash showLineNumbers=false showCopyAction=true}

:::code[]{language=yaml showLineNumbers=true showCopyAction=false}
# mistral-fsxl.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vllm-mistral-inf2-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vllm-mistral-inf2-server
  template:
    metadata:
      labels:
        app: vllm-mistral-inf2-server
    spec:
      schedulerName: my-scheduler                               # <<<<< we are using Neuron Scheduler
      tolerations:
      - key: "aws.amazon.com/neuron"
        operator: "Exists"
        effect: "NoSchedule"
      containers:
      - name: inference-server
        image: public.ecr.aws/u3r1l1j7/eks-genai:neuronrayvllm-100G-root
        resources:                                             # <<<<< Here you can specify Neuron Resources just like CPU and Memory
          requests:
            aws.amazon.com/neuron: 1                           # <<<<< Neuron Resources Request
          limits:
            aws.amazon.com/neuron: 1                           # <<<<< Neuron Resources Limits
(...)
:::

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
