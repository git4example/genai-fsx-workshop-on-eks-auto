---
title : "Deploy vLLM on AWS Inferentia nodes for model Inference"
weight : 210
---

### Create Karpenter NodePool and EC2NodeClass

Karpenter configuration comes in the form of a NodePool Custom Resource (CR). The NodePool sets constraints on the nodes that can be created by Karpenter and the pods that can run on those nodes. The NodePool can be set to do things like limiting node creation to certain computer architectures or be flexible to use multiple. A single Karpenter NodePool is capable of handling many different pod shapes. Karpenter makes scheduling and provisioning decisions based on pod attributes such as labels and affinity. A cluster may have more than one NodePool, but for the moment we will declare additional one: the inferentia NodePool.


1. A Karpenter NodePool sets constraints on the nodes that can be created by Karpenter and the pods that can run on those nodes. AWS-specific settings can be set up with NodeClasses. Multiple NodePools may point to the same EC2NodeClass.

2. Change to the working directory in your Cloud9 terminal

```bash
cd /home/ec2-user/environment/eks/genai
```

3. Let's deploy a Karpenter NodePool with the following configuration:


```bash
kubectl apply -f inferentia_nodepool.yaml
```


4. Verify NodePool and EC2NodeClass:
:::code{showCopyAction=true showLineNumbers=true language=bash}
kubectl get nodepool,ec2nodeclass inferentia
:::

```
NAME                               NODECLASS    NODES   READY   AGE
nodepool.karpenter.sh/inferentia   inferentia   0       True    6s

NAME                                        READY   AGE
ec2nodeclass.karpenter.k8s.aws/inferentia   True    6s
```

### Install Neuron device plugin & scheduler

#### What is Neuron, talk about how we have already pre-compiled the Mistral model into Neuron format (to save them time), so that the model can be run on AWS Inferentia accelerators, which are going to be managed by karpenter

Now that we verified the pre-requisites, lets install Neuron Device Plugin and Neuron Scheduler with is required by the AWS Inferentia Accelerator YXYZ

###### Neuron Device plugin
A neuron device plugin exposes Neuron cores & devices to Kubernetes as a resource.

###### Neuron Scheduler
The Neuron scheduler extension is required for scheduling pods that require more than one Neuron core or device resource. Neuron scheduler extension filter out nodes with non-contiguous core/device ids and enforces allocation of contiguous core/device ids for the PODs requiring it.

1. Run the following commands to Install the Neuron device plugin:
:::code{showCopyAction=true showLineNumbers=true language=bash}
kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/k8s-neuron-device-plugin-rbac.yml
kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/k8s-neuron-device-plugin.yml
:::

2. Run the below commands to install the Neuron Scheduler:
:::code{showCopyAction=true showLineNumbers=true language=bash}
kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/k8s-neuron-scheduler-eks.yml
kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/my-scheduler.yml
:::


### Deploy the vLLM application Pod

**You will deploy a vLLM pod, from ECR image, and configure it to use the PVC you previously created, where this has the inference server config details... etc.. feel free to cat the mistral-fsxl.yaml**

1. Run the below command to deploy your vLLM Pod. Once the vLLM Pod is online, it will load the Mistral-7B model (29GB) into its memory from your FSx for Lustre based Persistent Volume.

```bash
kubectl apply -f mistral-fsxl.yaml
```

2. The above deployment will take approx. 7-8 minutes. (**You can continue to the next steps, and don't need to wait for this step to complete**).

3. You can monitor the vLLM pod creation by running the following command periodically, until you see it transitioning to `Running`

```bash
kubectl get pod
```

![vllm_pod](/static/images/vllm_pod_1.png)


### Displaying Karpenter Logs

:::alert{header="Important" type="info"}
You can create a new terminal window within Cloud9 and leave the command below running so you can come back to that terminal every time you want to look for what Karpenter is doing.
:::

To read karpenter logs set-up the following alias to stream logs from all of the Karpenter controller logs:

```bash
alias kl='kubectl -n karpenter logs -l app.kubernetes.io/name=karpenter --all-containers=true -f --tail=20'
```

From now on to invoke the alias and get the logs we can just use to see if karpenter is launching inferentia node for our mistral pod.

```bash
kl
```

Hit `control + c` to exit
```bash
^C
```
