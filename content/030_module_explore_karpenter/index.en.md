---
title : "Explore workshop environment"
weight : 30
---

## Automation used for the creation of your lab Amazon EKS Cluster

The Amazon Elastic Kubernetes Service (EKS) cluster in this workshop was created with [**Terraform**](https://www.terraform.io/) using the [**EKS Blueprints for Terraform**](https://github.com/aws-ia/terraform-aws-eks-blueprints). You can explore the blueprint by looking into the `~/environment/eksworkshop` folder on your Cloud9 instance, to learn how it could be used in a your environment.

**Terraform** is an infrastructure as code tool that lets you build, change, and version infrastructure efficiently in AWS.

**EKS Blueprints for Terraform** helps you compose complete EKS clusters that are fully bootstrapped with the operational software that is needed to deploy and operate workloads. With EKS Blueprints, you describe the configuration for the desired state of your EKS environment, such as the control plane, worker nodes, and Kubernetes add-ons, as an IaC blueprint. Once a blueprint is configured, you can use it to create consistent environments across multiple AWS accounts and Regions using continuous deployment automation.

:::alert{header="Note" type="info"}
Take a moment to explore the  [Amazon EKS cluster via the AWS Console](https://console.aws.amazon.com/eks),  to view the cluster configuration, and the 2 worker nodes.
:::

## Explore the Karpenter installation

In this section, we will review [Karpenter](https://karpenter.sh/), which has been pre-installed on your Amazon EKS cluster. Karpenter can be installed with a [helm](https://helm.sh/) chart ([official Karpenter helm chart](https://github.com/aws/karpenter/blob/main/charts/karpenter/values.yaml)), but we made use of Amazon EKS blueprints to provision this cluster with Karpenter pre-installed.

Karpenter follows best practices for Kubernetes controllers as part of its configuration. Karpenter uses [Custom Resource Definition (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) to declare its configuration, which is an extension of the Kubernetes API. One of the premises of Kubernetes is the [declarative aspect of its APIs](https://kubernetes.io/docs/concepts/overview/kubernetes-api/). Karpenter simplifies its configuration by adhering to that principle, where in this environment karpenter is used to configure a default [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/).

Karpenter uses environment variables for configuration. Run the below command in your Cloud9 terminal to checkout the Karpenter configuration:

```bash
kubectl -n karpenter get deploy/karpenter -o yaml
```

Inspecting the output for the Karpenter controller Pod you can see the following environment variables set:

* **CLUSTER_ENDPOINT** - is the external Kubernetes cluster endpoint for new nodes to connect with. If the endpoint is not specified, nodes will discover the cluster endpoint using DescribeCluster API.
* **INTERRUPTION_QUEUE** - is the endpoint to the SQS queue created as part of the EKS Terraform blueprint. This SQS queue is used to hold Spot interruption notifications and AWS Health events.

Checkout the [Karpenter documentation](https://karpenter.sh/docs/reference/settings/) for information on the other configuration options.

To verify if Karpenter is running in your Amazon EKS environment, you can check that the Pods are running by issue the below command in your Cloud9 terminal. There should be at least two `karpenter` pods.
```bash
kubectl get pods --namespace karpenter
```

You should see an output similar to the one below.
```
NAME                         READY   STATUS    RESTARTS   AGE
karpenter-75f6596894-pgrsd   1/1     Running   0          48s
karpenter-75f6596894-t4mrx   1/1     Running   0          48s
```


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
