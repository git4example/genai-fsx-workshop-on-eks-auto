---
title : "Deploy GenAI workloads on Inferentia nodes"
weight : 210
---

Karpenter configuration comes in the form of a NodePool Custom Resource (CR). The NodePool sets constraints on the nodes that can be created by Karpenter and the pods that can run on those nodes. The NodePool can be set to do things like limiting node creation to certain computer architectures or be flexible to use multiple. A single Karpenter NodePool is capable of handling many different pod shapes. Karpenter makes scheduling and provisioning decisions based on pod attributes such as labels and affinity. A cluster may have more than one NodePool, but for the moment we will declare additional one: the inferentia NodePool.

# Create Karpenter NodePool and EC2NodeClass

A Karpenter NodePool sets constraints on the nodes that can be created by Karpenter and the pods that can run on those nodes. AWS-specific settings can be set up with NodeClasses. Multiple NodePools may point to the same EC2NodeClass.

Let's deploy a Karpenter NodePool with the following configuration:

```bash
# Set env variables for AMI like this and run below command
# export ARM_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-arm64/recommended/image_id --query Parameter.Value --output text)"
# export AMD_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2/recommended/image_id --query Parameter.Value --output text)"
export GPU_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-gpu/recommended/image_id --query Parameter.Value --output text)"
```

```bash
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: inferentia
  labels:
    intent: genai-apps
spec:
  template:
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: [ "amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["inf"]
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: inferentia
  limits:
    cpu: 1000
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h # 30 * 24h = 720h
---
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: inferentia
spec:
  amiFamily: AL2 # Amazon Linux 2
  role: "Karpenter-eksworkshop" 
  subnetSelectorTerms:          
    - tags:
        karpenter.sh/discovery: "eksworkshop"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "eksworkshop"
  role: "Karpenter-eksworkshop"
  tags:
    Name: karpenter.sh/nodepool/default
    NodeType: "genai-fsx-workshop"
    IntentLabel: "genai-apps"
  amiSelectorTerms:
    # - id: "${ARM_AMI_ID}"
    # - id: "${AMD_AMI_ID}"
    - id: "${GPU_AMI_ID}" # <- GPU Optimized AMD AMI 
#   - name: "amazon-eks-node-${K8S_VERSION}-*" # <- automatically upgrade when a new AL2 EKS Optimized AMI is released. This is unsafe for production workloads. Validate AMIs in lower environments before deploying them to production.
EOF
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

# Deploy the Java application to an x86_64 node

Let's create the x86_64 deployment, run the following command:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webbooks
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webbooks
  template:
    metadata:
      labels:
        app: webbooks
    spec:
      nodeSelector:
        intent: apps
        kubernetes.io/arch: amd64
      containers:
        - name: webbooks
          image: public.ecr.aws/j4m3t0a6/webbook:latest
          resources:
            requests:
              cpu: 1
              memory: 512M
EOF
```

As you see the Deployment is using the nodeSelector spec with `kubernetes.io/arch: amd64`, and this is what Karpenter will use to launch an x86_64 node, either Intel or AMD.

::alert[]{header="Karpenter will now provision an EC2 to host the deployment. This may take 1-2 minutes"}

Validate that a new EC2 instance has been provisioned.

:::code{showCopyAction=true showLineNumbers=false}
kubectl get nodes --label-columns=kubernetes.io/arch
:::

And check that the pod is running:

:::code{showCopyAction=true showLineNumbers=false}
kubectl get pods
:::

#### Which instance type did Karpenter use when you deployed the workload? Why that instance?

::::expand{header="click here to show the answer" defaultExpanded=false}

You can check which instance type was used running the following command:

```bash
kubectl get node --selector=intent=apps -L kubernetes.io/arch -L node.kubernetes.io/instance-type -L karpenter.sh/nodepool -L topology.kubernetes.io/zone -L karpenter.sh/capacity-type
```

There is something even more interesting to learn about how the node was provisioned. Check out Karpenter logs and look at the new node Karpenter created. The lines should be similar to the ones below:

```bash 
{"level":"DEBUG","time":"2024-01-29T17:19:06.212Z","logger":"controller.provisioner","message":"25 out of 749 instance types were excluded because they would breach limits","commit":"1072d3b","nodepool":"default"}
{"level":"INFO","time":"2024-01-29T17:19:06.225Z","logger":"controller.provisioner","message":"found provisionable pod(s)","commit":"1072d3b","pods":"default/webbooks-d86689bff-4hk58","duration":"13.084497ms"}
{"level":"INFO","time":"2024-01-29T17:19:06.225Z","logger":"controller.provisioner","message":"computed new nodeclaim(s) to fit pod(s)","commit":"1072d3b","nodeclaims":1,"pods":1}
{"level":"INFO","time":"2024-01-29T17:19:06.253Z","logger":"controller.provisioner","message":"created nodeclaim","commit":"1072d3b","nodepool":"default","nodeclaim":"default-5rxtg","requests":{"cpu":"1150m","memory":"512M","pods":"3"},"instance-types":"c3.large, c3.xlarge, c4.large, c4.xlarge, c5.2xlarge and 95 other(s)"}
{"level":"DEBUG","time":"2024-01-29T17:19:06.766Z","logger":"controller.nodeclaim.lifecycle","message":"created launch template","commit":"1072d3b","nodeclaim":"default-5rxtg","nodepool":"default","launch-template-name":"karpenter.k8s.aws/8592053038317341236","id":"lt-09986870d704d17b9"}
{"level":"INFO","time":"2024-01-29T17:19:09.158Z","logger":"controller.nodeclaim.lifecycle","message":"launched nodeclaim","commit":"1072d3b","nodeclaim":"default-5rxtg","nodepool":"default","provider-id":"aws:///eu-west-1a/i-0e8efa5985dcaf425","instance-type":"c6a.large","zone":"eu-west-1a","capacity-type":"spot","allocatable":{"cpu":"1930m","ephemeral-storage":"17Gi","memory":"3114Mi","pods":"29","vpc.amazonaws.com/pod-eni":"9"}}
{"level":"DEBUG","time":"2024-01-29T17:19:35.668Z","logger":"controller.nodeclaim.lifecycle","message":"registered nodeclaim","commit":"1072d3b","nodeclaim":"default-5rxtg","nodepool":"default","provider-id":"aws:///eu-west-1a/i-0e8efa5985dcaf425","node":"ip-10-0-44-159.eu-west-1.compute.internal"}
{"level":"DEBUG","time":"2024-01-29T17:19:45.835Z","logger":"controller.disruption","message":"discovered subnets","commit":"1072d3b","subnets":["subnet-055683062c4a20f46 (eu-west-1b)","subnet-0aeba0798cb749e0a (eu-west-1a)","subnet-00cf8aea563236842 (eu-west-1c)"]}
{"level":"INFO","time":"2024-01-29T17:19:46.493Z","logger":"controller.nodeclaim.lifecycle","message":"initialized nodeclaim","commit":"1072d3b","nodeclaim":"default-5rxtg","nodepool":"default","provider-id":"aws:///eu-west-1a/i-0e8efa5985dcaf425","node":"ip-10-0-44-159.eu-west-1.compute.internal"}
```

Notice how Karpenter picks up the instance from a diversified selection of instances. In this case it selected the following instances:

```
{"level":"INFO","time":"2024-01-29T17:19:06.253Z","logger":"controller.provisioner","message":"created nodeclaim","commit":"1072d3b","nodepool":"default","nodeclaim":"default-5rxtg","requests":{"cpu":"1150m","memory":"512M","pods":"3"},"instance-types":"c3.large, c3.xlarge, c4.large, c4.xlarge, c5.2xlarge and 95 other(s)"}
```

Instances types might be different depending on the region selected.

All these instances are the suitable instances that reduce the waste of resources (memory and CPU) for the pod submitted. If you are interested in Algorithms, internally Karpenter is using a [First Fit Decreasing (FFD)](https://en.wikipedia.org/wiki/Bin_packing_problem#First_Fit_Decreasing_(FFD)) approach. Note however this can change in the future.

We did set Karpenter NodePool to use [EC2 Spot instances](https://aws.amazon.com/ec2/spot/), and there was no `instance-types` [requirement section in the NodePool to filter the type of instances](https://karpenter.sh/docs/concepts/nodepools/#instance-types). This means that Karpenter will use the default value of instances types to use. The default value includes all instance types with the exclusion of metal (non-virtualized), [non-HVM](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/virtualization_types.html), and GPU instances. 

Internally Karpenter used **EC2 Fleet in Instant mode** to provision the instances. You can read more about EC2 Fleet Instant mode [**here**](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instant-fleet.html). Here are a few properties to mention about EC2 Fleet instant mode that are key for Karpenter:

* EC2 Fleet instant mode provides a synchronous call to procure instances, including EC2 Spot, this simplifies and avoid error when provisioning instances. For those of you familiar with [Cluster Autoscaler on AWS](https://github.com/kubernetes/autoscaler/blob/c4b56ea56136681e8a8ff654dfcd813c0d459442/cluster-autoscaler/cloudprovider/aws/auto_scaling_groups.go#L33-L36), you may know about how it uses `i-placeholder` to coordinate instances that have been created in asynchronous ways.

* The call to EC2 Fleet in instant mode is done using `price-capacity-optimized`. This means that we will request Spot Instances from the pools that we believe have the lowest chance of interruption in the near term. EC2 Fleet then requests Spot Instances from the lowest priced of these pools. You can read more about [Allocation Strategies here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-fleet-allocation-strategy.html).

* Calls to EC2 Fleet in instant mode are not considered Spot fleets. They do not count towards the Spot Fleet limits. The implication is that Karpenter can make calls to this API as many times over time as needed.

By implementing techniques such as: Bin-packing using First Fit Decreasing, Instance diversification using EC2 Fleet in instance mode and the Spot allocation strategy: `price-capacity-optimized`, Karpenter removes the need from customer to define multiple Auto Scaling groups each one for the type of capacity constraints and sizes that all the applications need to fit in. This simplifies considerably the operational support of kubernetes clusters.
::::

# Deploy the Java application to a Graviton node

Let's change the application to now ask for a Graviton instance, to do so simply change the `nodeSelector` to `kubernetes.io/arch: arm64`. Deploy the application again, and wait for the new node to come up.

#### How would you change the Deployment to now use Graviton instances? 

::::expand{header="click here to show the answer" defaultExpanded=false}

Simply change the `amd64` arch value to `arm64`, like this:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webbooks
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webbooks
  template:
    metadata:
      labels:
        app: webbooks
    spec:
      nodeSelector:
        intent: apps
        kubernetes.io/arch: arm64
      containers:
        - name: webbooks
          image: public.ecr.aws/j4m3t0a6/webbook:latest
          resources:
            requests:
              cpu: 1
              memory: 512M
EOF
```

Then wait for Karpenter to launch the new Graviton node as the existing one doesn't fit with the Deployment specs:

```bash 
{"level":"DEBUG","time":"2024-01-29T17:27:42.359Z","logger":"controller.provisioner","message":"25 out of 749 instance types were excluded because they would breach limits","commit":"1072d3b","nodepool":"default"}
{"level":"INFO","time":"2024-01-29T17:27:42.369Z","logger":"controller.provisioner","message":"found provisionable pod(s)","commit":"1072d3b","pods":"default/webbooks-55cf95797f-xv7c9","duration":"11.07748ms"}
{"level":"INFO","time":"2024-01-29T17:27:42.369Z","logger":"controller.provisioner","message":"computed new nodeclaim(s) to fit pod(s)","commit":"1072d3b","nodeclaims":1,"pods":1}
{"level":"INFO","time":"2024-01-29T17:27:42.386Z","logger":"controller.provisioner","message":"created nodeclaim","commit":"1072d3b","nodepool":"default","nodeclaim":"default-r2jhs","requests":{"cpu":"1150m","memory":"512M","pods":"3"},"instance-types":"c6g.12xlarge, c6g.16xlarge, c6g.2xlarge, c6g.4xlarge, c6g.8xlarge and 95 other(s)"}
{"level":"DEBUG","time":"2024-01-29T17:27:42.772Z","logger":"controller.nodeclaim.lifecycle","message":"created launch template","commit":"1072d3b","nodeclaim":"default-r2jhs","nodepool":"default","launch-template-name":"karpenter.k8s.aws/3732224982842035755","id":"lt-07a63606b6d788db4"}
{"level":"INFO","time":"2024-01-29T17:27:44.782Z","logger":"controller.nodeclaim.lifecycle","message":"launched nodeclaim","commit":"1072d3b","nodeclaim":"default-r2jhs","nodepool":"default","provider-id":"aws:///eu-west-1b/i-0774daa0fd1885ac5","instance-type":"c6g.large","zone":"eu-west-1b","capacity-type":"spot","allocatable":{"cpu":"1930m","ephemeral-storage":"17Gi","memory":"3055Mi","pods":"29","vpc.amazonaws.com/pod-eni":"9"}}
{"level":"DEBUG","time":"2024-01-29T17:27:48.417Z","logger":"controller.disruption","message":"discovered subnets","commit":"1072d3b","subnets":["subnet-0aeba0798cb749e0a (eu-west-1a)","subnet-00cf8aea563236842 (eu-west-1c)","subnet-055683062c4a20f46 (eu-west-1b)"]}
{"level":"DEBUG","time":"2024-01-29T17:28:09.364Z","logger":"controller.nodeclaim.lifecycle","message":"registered nodeclaim","commit":"1072d3b","nodeclaim":"default-r2jhs","nodepool":"default","provider-id":"aws:///eu-west-1b/i-0774daa0fd1885ac5","node":"ip-10-0-72-68.eu-west-1.compute.internal"}
{"level":"DEBUG","time":"2024-01-29T17:28:16.432Z","logger":"controller","message":"deleted launch template","commit":"1072d3b","id":"lt-09986870d704d17b9","name":"karpenter.k8s.aws/8592053038317341236"}
{"level":"INFO","time":"2024-01-29T17:28:20.671Z","logger":"controller.nodeclaim.lifecycle","message":"initialized nodeclaim","commit":"1072d3b","nodeclaim":"default-r2jhs","nodepool":"default","provider-id":"aws:///eu-west-1b/i-0774daa0fd1885ac5","node":"ip-10-0-72-68.eu-west-1.compute.internal"}
{"level":"DEBUG","time":"2024-01-29T17:28:55.109Z","logger":"controller.disruption","message":"discovered subnets","commit":"1072d3b","subnets":["subnet-0aeba0798cb749e0a (eu-west-1a)","subnet-00cf8aea563236842 (eu-west-1c)","subnet-055683062c4a20f46 (eu-west-1b)"]}
```

Then, Karpenter removed the x86_64 node as it was no longer needed:

```bash 
{"level":"INFO","time":"2024-01-29T17:28:55.144Z","logger":"controller.disruption","message":"disrupting via consolidation delete, terminating 1 candidates ip-10-0-44-159.eu-west-1.compute.internal/c6a.large/spot","commit":"1072d3b"}
{"level":"INFO","time":"2024-01-29T17:28:55.190Z","logger":"controller.node.termination","message":"tainted node","commit":"1072d3b","node":"ip-10-0-44-159.eu-west-1.compute.internal"}
{"level":"INFO","time":"2024-01-29T17:28:55.529Z","logger":"controller.node.termination","message":"deleted node","commit":"1072d3b","node":"ip-10-0-44-159.eu-west-1.compute.internal"}
{"level":"INFO","time":"2024-01-29T17:28:55.866Z","logger":"controller.nodeclaim.termination","message":"deleted nodeclaim","commit":"1072d3b","nodeclaim":"default-5rxtg","nodepool":"default","node":"ip-10-0-44-159.eu-west-1.compute.internal","provider-id":"aws:///eu-west-1a/i-0e8efa5985dcaf425"}
```

::::

# Cleanup

Finish by removing all deployments, then Karpenter will automatically remove the nodes:

```bash
kubectl delete deployment webbooks
```