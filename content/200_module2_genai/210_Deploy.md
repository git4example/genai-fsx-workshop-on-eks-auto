---
title : "Deploy vLLM on AWS Inferentia nodes for model Inference"
weight : 210
---

## Overview

In this section you will configure the AWS Inferentia nodepool on the EKS cluster, install the AWS Neuron plugins, and then deploy the vLLM inference engine Pod.

##### Step 1: Install Neuron Device Plugin & Neuron Scheduler

In order to use the AWS Inferentia accelerated compute nodes to host our Mistral LLM mode, we need to install the Neuron Device Plugin, Neuron Scheduler, and Node Problem Detector on the EKS Cluster using helm chart. Click on this link to learn more about the [AWS Neuron Helm Chart](https://aws.amazon.com/blogs/containers/announcing-aws-neuron-helm-chart/).

1. Copy & paste the below command into your terminal to install the neuron helm chart.

:::code{showCopyAction=true showLineNumbers=true language=bash}
cd /home/participant/environment/terraform

helm upgrade --install neuron-helm-chart \
    oci://public.ecr.aws/neuron/neuron-helm-chart \
    --namespace kube-system \
    --version 1.2.0 \
    -f ./helm-values/neuron-values.yaml
:::

You should see an output similar to the one below.

:::code{showCopyAction=false showLineNumbers=false language=bash}
Release "neuron-helm-chart" does not exist. Installing it now.
Pulled: public.ecr.aws/neuron/neuron-helm-chart:1.2.0
Digest: sha256:892b10353badc5e970519bfef42441f72c69ff48437f43a49948e18e4fef87c3
NAME: neuron-helm-chart
LAST DEPLOYED: Thu Jul 24 01:57:53 2025
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
:::

Lets take a moment to understand each of these components.

###### Neuron Device plugin

The Neuron device plugin exposes Neuron cores & devices to kubernetes as a resource. `aws.amazon.com/neuroncore` and `aws.amazon.com/neuron` are the resources that the neuron device plugin registers with the kubernetes. `aws.amazon.com/neuroncore` is used for allocating neuron cores to the container. `aws.amazon.com/neuron` is used for allocating neuron devices to the container. When resource name ‘neuron’ is used, all the cores belonging to the device will be allocated to container in your pod.

For more information on this, please refer [Neuron Device Plugin](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/containers/kubernetes-getting-started.html#neuron-device-plugin)


###### Neuron Scheduler
The Neuron scheduler extension is required for scheduling pods that require more than one Neuron core or device resource. Neuron scheduler extension filter out nodes with non-contiguous core/device ids and enforces allocation of contiguous core/device ids for the PODs requiring it.

The Neuron scheduler extension finds sets of directly connected devices with minimal communication latency when scheduling containers. On Inf1 and Inf2 instance types where Neuron devices are connected through a ring topology, the scheduler finds sets of contiguous devices. On Trn1.32xlarge, Trn1n.32xlarge, Trn2.48xlarge and Trn1n.32xlarge instance types where devices are connected through a 4x4, 2D Torus topology, where the Neuron scheduler enforces additional constraints.

For more information on this, please refer [Neuron Scheduler Extension](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/containers/kubernetes-getting-started.html#neuron-scheduler-extension)

###### Node Problem Detector

The Neuron Problem Detector Plugin facilitates error detection and recovery by continuously monitoring the health of Neuron devices across all Kubernetes nodes. It publishes CloudWatch metrics for node errors and can optionally trigger automatic recovery of affected nodes.

For more information on this, please refer [Neuron Problem Detector Plugin](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/containers/kubernetes-getting-started.html#neuron-scheduler-extension)

#####  Step 2: Create EKS Auto Mode NodePool and EC2 NodeClass for AWS Inferentia Accelerators

The EKS Auto Mode configuration comes in the form of a NodePool Custom Resource (CR). The NodePool sets constraints on the EC2 nodes that can be used by EKS Auto Mode, and the pods that can run on those EC2 nodes. Multiple NodePools may point to the same EC2NodeClass.The NodePool can be set to do things like; limiting node creation to certain compute architectures, or be flexible to use multiple. A single EKS Auto Mode NodePool is capable of handling many different pod shapes. EKS Auto Mode makes scheduling and provisioning decisions based on pod attributes such as labels and affinity. A cluster may have more than one NodePool, for this workshop we will declare an additional inferentia NodePool.


1. Run the following command to create the EKS Auto Mode inferentia NodePool definition

:::code[]{language=bash showLineNumbers=false showCopyAction=true}
NODE_ROLE=$(cd /home/participant/environment/terraform && terraform output --raw eks_node_iam_role_name)
cd /home/participant/environment/eks/genai
sed -i'' -e "s/NODE_ROLE/$NODE_ROLE/g" inferentia_nodepool.yaml
:::

2. Lets take a look at the EKS Auto NodePool definition for the inferentia NodePool before we apply it. This configuration will create a new nodepool for AWS Inferentia (using "INF2" type for instance-family), where the AWS INF2 compute nodes will power Generative AI application (vLLM pod).

::code[cat inferentia_nodepool.yaml]{language=bash showLineNumbers=false showCopyAction=true}

4. Let's deploy the inferentia NodePool

::code[kubectl apply -f inferentia_nodepool.yaml]{language=bash showLineNumbers=false showCopyAction=true}

5. Verify NodePool and NodeClass:
::code[kubectl get nodepool,nodeclass inferentia]{language=bash showLineNumbers=false showCopyAction=true}

You should see an output similar to the one below. **Note** that you will initially see 0 nodes in the pool, that's because we haven't deployed any pods that need this accelerated compute node.

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

1. Run the below commands to update the mistral-fsxl.yaml with your AWS environment variables.

:::code[]{language=bash showLineNumbers=false showCopyAction=true}
cd /home/participant/environment/eks/genai
:::

:::code[]{language=bash showLineNumbers=false showCopyAction=true}
FSX_LUSTRE_AZ=$(aws fsx describe-file-systems  --region $AWS_REGION --query 'FileSystems[0].SubnetIds[0]' --output text | xargs -I {} aws ec2 describe-subnets --subnet-ids {} --query 'Subnets[0].AvailabilityZone' --output text)
:::

:::code[]{language=bash showLineNumbers=false showCopyAction=true}
sed -i'' -e "s/FSX_LUSTRE_AZ/$FSX_LUSTRE_AZ/g" mistral-fsxl.yaml
:::

2. Run the below command to deploy the vLLM Pod.


::code[kubectl apply -f mistral-fsxl.yaml]{language=bash showLineNumbers=false showCopyAction=true}


3. Now run the below command, and you will see the Inferentia node count increase to 1, as we have deployed a pod that requires the accelerated compute node. Note that the increase to a value of 1 can take 30 seconds to update.
::code[kubectl get nodepool,nodeclass inferentia]{language=bash showLineNumbers=false showCopyAction=true}

:::alert{header="Note" type="info"}
**The vLLM pod deployment will take approx. 7 minutes. You can continue to the next steps, and don't need to wait for this step to complete**.  
:::


3. Run the below command to inspect the vLLM's mistral-fsxl.yaml deployment file.

::code[cat mistral-fsxl.yaml]{language=bash showLineNumbers=false showCopyAction=true}

:::alert{header="Note" type="info"}
You will notice a single pod deployment request, with a request for a single AWS Inferentia Neuron core, persistent storage using the PVC you created previously (fsx-lustre-claim), and also some model parameters.  
:::


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
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: topology.kubernetes.io/zone
                operator: In
                values:
                - FSX_LUSTRE_AZ                                 # <<<<< Replace with your FSx Lustre AZ
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


4. You can monitor the vLLM pod creation by running the following command periodically, until you see it transitioning to `Running`, and when its at the 7 minute mark (and the vLLM is online and the model has been loaded into memory)

::code[kubectl get pod]{language=bash showLineNumbers=false showCopyAction=true}

![vllm_pod](/static/images/vllm_pod_1.png)


5. While you are waiting for the vLLM pod to deploy, lets go check out the EKS NodePools by navigating to the [Amazon EKS cluster Console](https://console.aws.amazon.com/eks)

6. Click on your cluster name (i.e. eksworkshop)

7. Click on the   **Compute** tab, you will see there is now a new AWS Inferentia **inf2.xlarge** compute node

![inf2_node](/static/images/inf2_node.png)

8. Click on the **Node name**, where it will show you the capacity allocation and Pod details relating to the inf2.xlarge compute node


### Summary
You have now deployed the vLLM Pod. Continue to the next lab section to deploy the WebUI Pod, so you can interact with the Mistral-7B model through the vLLM (model serving and inferencing).
