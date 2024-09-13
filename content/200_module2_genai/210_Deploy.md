---
title : "Deploy GenAI workloads on Inferentia nodes"
weight : 210
---

Karpenter configuration comes in the form of a NodePool Custom Resource (CR). The NodePool sets constraints on the nodes that can be created by Karpenter and the pods that can run on those nodes. The NodePool can be set to do things like limiting node creation to certain computer architectures or be flexible to use multiple. A single Karpenter NodePool is capable of handling many different pod shapes. Karpenter makes scheduling and provisioning decisions based on pod attributes such as labels and affinity. A cluster may have more than one NodePool, but for the moment we will declare additional one: the inferentia NodePool.


# Create Karpenter NodePool and EC2NodeClass

A Karpenter NodePool sets constraints on the nodes that can be created by Karpenter and the pods that can run on those nodes. AWS-specific settings can be set up with NodeClasses. Multiple NodePools may point to the same EC2NodeClass.

```bash
cd /home/ec2-user/environment/eks/genai
```

Find latest Supported EKS Optimized AMI 
```bash
export K8S_VERSION=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query cluster.version --output text)
export GPU_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-gpu/recommended/image_id --query Parameter.Value --output text)"
```

Let's deploy a Karpenter NodePool with the following configuration:


```bash
cat inferentia_nodepool.yaml | envsubst | kubectl apply -f -
```


###### Verify NodePool and EC2NodeClass:
:::code{showCopyAction=true showLineNumbers=true language=bash}
kubectl get nodepool,ec2nodeclass
:::

```
NAME                               NODECLASS    NODES   READY   AGE
nodepool.karpenter.sh/download     download     0       True    37m
nodepool.karpenter.sh/inferentia   inferentia   0       True    1m

NAME                                        READY   AGE
ec2nodeclass.karpenter.k8s.aws/download     True    37m
ec2nodeclass.karpenter.k8s.aws/inferentia   True    1m
```


Now that we verified the pre-requisites, lets install Neuron Device Plugin, Neuron Scheduler and the deploy llama2 pod.
###### Install Neuron device plugin

A neuron device plugin exposes Neuron cores & devices to Kubernetes as a resource.

:::code{showCopyAction=true showLineNumbers=true language=bash}
kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/k8s-neuron-device-plugin-rbac.yml
kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/k8s-neuron-device-plugin.yml
:::

###### Install Neuron Scheduler
Neuron scheduler extension is required for scheduling pods that require more than one Neuron core or device resource. Neuron scheduler extension filter out nodes with non-contiguous core/device ids and enforces allocation of contiguous core/device ids for the PODs requiring it.

:::code{showCopyAction=true showLineNumbers=true language=bash}
kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/k8s-neuron-scheduler-eks.yml
kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/my-scheduler.yml
:::


##### Deploy Mistral Application 

```bash
kubectl apply -f mistral-fsx.yaml
```

This will take upto 10 mins. You can monitor pod creation with following commands to see it transitioning to `Running`

```bash
kubectl get pod -w
```

Hit `control + c` to exit
```bash
^C
```

## Displaying Karpenter Logs

:::alert{header="Important" type="info"}
You can create a new terminal window within Cloud9 and leave the command below running so you can come back to that terminal every time you want to look for what Karpenter is doing.
:::

To read karpenter logs set-up the following alias to stream logs from all of the Karpenter controller logs:

```bash
alias kl='kubectl -n karpenter logs -l app.kubernetes.io/name=karpenter --all-containers=true -f --tail=20'
```

From now on to invoke the alias and get the logs we can just use:

```bash
kl
```

Hit `control + c` to exit
```bash
^C
```