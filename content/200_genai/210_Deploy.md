---
title : "Deploy GenAI workloads on Inferentia nodes"
weight : 210
---

Karpenter configuration comes in the form of a NodePool Custom Resource (CR). The NodePool sets constraints on the nodes that can be created by Karpenter and the pods that can run on those nodes. The NodePool can be set to do things like limiting node creation to certain computer architectures or be flexible to use multiple. A single Karpenter NodePool is capable of handling many different pod shapes. Karpenter makes scheduling and provisioning decisions based on pod attributes such as labels and affinity. A cluster may have more than one NodePool, but for the moment we will declare additional one: the inferentia NodePool.

# Create Karpenter NodePool and EC2NodeClass

A Karpenter NodePool sets constraints on the nodes that can be created by Karpenter and the pods that can run on those nodes. AWS-specific settings can be set up with NodeClasses. Multiple NodePools may point to the same EC2NodeClass.

Find latest Supported EKS Optimized AMI 
```bash
export K8S_VERSION=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query cluster.version --output text)
export GPU_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-gpu/recommended/image_id --query Parameter.Value --output text)"
```


Let's deploy a Karpenter NodePool with the following configuration:


```bash
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: inferentia
  labels:
    intent: genai-apps
    NodeGroupType: inf2-neuron-karpenter
spec:
  template:
    spec:
      taints:
        - key: aws.amazon.com/neuron
          value: "true"
          effect: "NoSchedule"
      requirements:
        - key: "karpenter.k8s.aws/instance-family"
          operator: In
          values: ["inf2"]
        - key: "karpenter.k8s.aws/instance-size"
          operator: In
          values: [ "xlarge", "2xlarge", "8xlarge", "24xlarge", "48xlarge"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["spot", "on-demand"]
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: inferentia
  limits:
    cpu: 1000
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenEmpty
    # expireAfter: 720h # 30 * 24h = 720h
    consolidateAfter: 180s
  weight: 100
---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: inferentia
spec:
  amiFamily: AL2
  amiSelectorTerms:
   - id : ${GPU_AMI_ID}
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        deleteOnTermination: true
        volumeSize: 100Gi
        volumeType: gp3
  role: "Karpenter-eksworkshop" 
  subnetSelectorTerms:          
    - tags:
        karpenter.sh/discovery: "eksworkshop"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "eksworkshop"
  tags:
    intent: apps
    managed-by: karpenter
EOF
```


###### Verify NodePool and EC2NodeClass:
:::code{showCopyAction=true showLineNumbers=true language=bash}
kubectl get nodepool,ec2nodeclass
:::

```
NAME                                  NODECLASS
nodepool.karpenter.sh/inferentia   inferentia

NAME                                            AGE
ec2nodeclass.karpenter.k8s.aws/inferentia   94s
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
cat <<EOF | kubectl apply -f -
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
      tolerations:
      - key: "aws.amazon.com/neuron"
        operator: "Exists"
        effect: "NoSchedule"
      containers:
      - name: netshoot
        image: nicolaka/netshoot
        command: ["sleep","infinity"]
        volumeMounts:
        - name: persistent-storage
          mountPath: "/work-dir"
      - name: inference-server
        image: public.ecr.aws/u3r1l1j7/eks-genai:neuronrayvllm-100G-root
        resources:
          requests:
            aws.amazon.com/neuron: 1
          limits:
            aws.amazon.com/neuron: 1
        args:
        - --model=$(MODEL_ID)
        - --enforce-eager
        - --gpu-memory-utilization=0.96
        - --device=neuron
        - --max-num-seqs=4
        - --tensor-parallel-size=2
        - --max-model-len=10240
        - --served-model-name=mistralai/Mistral-7B-Instruct-v0.2-neuron
        env:
        - name: MODEL_ID
          value: /work-dir/work-dir/Mistral-7B-Instruct-v0.2/
        - name: NEURON_COMPILE_CACHE_URL
          value: /work-dir/work-dir/Mistral-7B-Instruct-v0.2/neuron-cache/
        - name: PORT
          value: "8000"
        volumeMounts:
        - name: persistent-storage
          mountPath: "/work-dir"
      volumes:
      - name: dshm
        emptyDir:
          medium: Memory
      - name: persistent-storage
        persistentVolumeClaim:
          claimName: fsx-lustre-claim
---
apiVersion: v1
kind: Service
metadata:
  name: vllm-mistral7b-service
spec:
  selector:
    app: vllm-mistral-inf2-server
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
EOF
```



###### Deploy llama2 Application

As part of the llama2 application deployment, we are going to deploy 
* llama2 pod
* Service

:::code{showCopyAction=true showLineNumbers=true language=bash}
cat > llama2_deploy.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: llama2-app
  labels:
    app: llama2-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: llama2-app
  template:
    metadata:
      labels:
        app: llama2-app
    spec:
      schedulerName: default-scheduler
      nodeSelector:
        node.kubernetes.io/instance-type: inf2.xlarge
      containers:
      - name: llama2-inf
        image: "763104351884.dkr.ecr.us-east-1.amazonaws.com/djl-inference:0.26.0-neuronx-sdk2.16.0"
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
          name: http-web-svc
        command: ["djl-serving"]
        args: ["-m", "-e SERVING_LOAD_MODELS=",
               "-e OPTION_ENTRYPOINT=",
               "-e OPTION_MODEL_ID=",
               "-e OPTION_BATCH_SIZE=",
               "-e OPTION_NEURON_OPTIMIZE_LEVEL=",
               "-e OPTION_TENSOR_PARALLEL_DEGREE=",
               "-e OPTION_N_POSITIONS=",
               "-e OPTION_DTYPE="]
        env:
        - name: SERVING_LOAD_MODELS
          value: "test::Python=/opt/ml/model"
        - name: OPTION_ENTRYPOINT
          value: "djl_python.transformers_neuronx"
        - name: OPTION_MODEL_ID
          value: "PY007/TinyLlama-1.1B-intermediate-step-480k-1T"
        - name: OPTION_BATCH_SIZE
          value: "4"
        - name: OPTION_NEURON_OPTIMIZE_LEVEL
          value: "1"
        - name: OPTION_TENSOR_PARALLEL_DEGREE
          value: "2"
        - name: OPTION_N_POSITIONS
          value: "512"
        - name: OPTION_DTYPE
          value: "fp16"
        volumeMounts:
        - name: model
          mountPath: "/dev/shm"
        resources:
          limits:
            aws.amazon.com/neuron: 1
      volumes:
      - name: model
        emptyDir: {}
  
---

apiVersion: v1
kind: Service
metadata:
  name: llama2-service
spec:
  selector:
    app: llama2-app
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 8080
EOF

kubectl apply -f llama2_deploy.yaml
:::

In the next steps, we will verify if all the deployments are success.





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
        intent: genai-apps
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
kubectl get node --selector=intent=genai-apps -L kubernetes.io/arch -L node.kubernetes.io/instance-type -L karpenter.sh/nodepool -L topology.kubernetes.io/zone -L karpenter.sh/capacity-type
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
        karpenter.sh/nodepool: inferentia
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
{"level":"INFO","time":"2024-08-29T06:28:26.608Z","logger":"controller.provisioner","message":"found provisionable pod(s)","commit":"2c8f2a5","pods":"default/webbooks-56d9bb9f6-cpx2l","duration":"14.131866ms"}
{"level":"INFO","time":"2024-08-29T06:28:26.608Z","logger":"controller.provisioner","message":"computed new nodeclaim(s) to fit pod(s)","commit":"2c8f2a5","nodeclaims":1,"pods":1}
{"level":"INFO","time":"2024-08-29T06:28:26.621Z","logger":"controller.provisioner","message":"created nodeclaim","commit":"2c8f2a5","nodepool":"inferentia","nodeclaim":"inferentia-9cnq2","requests":{"cpu":"1180m","memory":"622880Ki","pods":"6"},"instance-types":"inf1.24xlarge, inf1.2xlarge, inf1.6xlarge, inf1.xlarge"}
{"level":"INFO","time":"2024-08-29T06:28:28.986Z","logger":"controller.nodeclaim.lifecycle","message":"launched nodeclaim","commit":"2c8f2a5","nodeclaim":"inferentia-9cnq2","provider-id":"aws:///us-west-1b/i-0ab091d28a059e5c0","instance-type":"inf1.xlarge","zone":"us-west-1b","capacity-type":"spot","allocatable":{"aws.amazon.com/neuron":"1","cpu":"3920m","ephemeral-storage":"17Gi","memory":"6804Mi","pods":"38","vpc.amazonaws.com/pod-eni":"38"}}
{"level":"INFO","time":"2024-08-29T06:28:30.494Z","logger":"controller.provisioner","message":"found provisionable pod(s)","commit":"2c8f2a5","pods":"default/webbooks-56d9bb9f6-cpx2l","duration":"9.65238ms"}
```

::::

# Cleanup

Finish by removing all deployments, then Karpenter will automatically remove the nodes:

```bash
kubectl delete deployment webbooks
```