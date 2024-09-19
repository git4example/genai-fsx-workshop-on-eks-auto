---
title : "Explore EKS and Karpenter"
weight : 31
---

## Automation used for the creation of this Amazon EKS Cluster

The Amazon EKS cluster was created with [**Terraform**](https://www.terraform.io/) using the [**EKS Blueprints for Terraform**](https://github.com/aws-ia/terraform-aws-eks-blueprints). You can explore the blueprint (and learn how it could be used in a real environment) by looking into the `~/environment/eksworkshop` folder on your Cloud9 instance.

**Terraform** is an infrastructure as code tool that lets you build, change, and version infrastructure safely and efficiently in AWS.

**EKS Blueprints for Terraform** helps you compose complete EKS clusters that are fully bootstrapped with the operational software that is needed to deploy and operate workloads. With EKS Blueprints, you describe the configuration for the desired state of your EKS environment, such as the control plane, worker nodes, and Kubernetes add-ons, as an IaC blueprint. Once a blueprint is configured, you can use it to stamp out consistent environments across multiple AWS accounts and Regions using continuous deployment automation.

:::alert{header="Important" type="info"}
Explore the Amazon Elastic Kubernetes Service (Amazon EKS) section in the AWS Console and the properties of the newly created Amazon EKS cluster.
:::

## Explore the Karpenter installation

In this section, we will review Karpenter which has been pre-installed on your Amazon EKS cluster and learn how to configure a default [NodePool CRD](https://karpenter.sh/docs/concepts/nodepools/) to set the configuration. Karpenter can be installed with a [helm](https://helm.sh/) chart ([official Karpenter helm chart](https://github.com/aws/karpenter/blob/main/charts/karpenter/values.yaml)), but we made use of Amazon EKS blueprints to provision this cluster with Karpenter pre-installed.

Karpenter follows best practices for Kubernetes controllers as part of its configuration. Karpenter uses [Custom Resource Definition (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) to declare its configuration which is an extension of the Kubernetes API. One of the premises of Kubernetes is the [declarative aspect of its APIs](https://kubernetes.io/docs/concepts/overview/kubernetes-api/). Karpenter simplifies its configuration by adhering to that principle.

Karpenter uses environment variables for configuration.

Execute the following to checkout the Karpenter configuration:

```bash
kubectl -n karpenter get deploy/karpenter -o yaml
```

Inspecting the output for the Karpenter controller Pod you can see the following environment variables set:

* *CLUSTER_ENDPOINT* is the external Kubernetes cluster endpoint for new nodes to connect with, if the endpoint is not specified, nodes will discover the cluster endpoint using DescribeCluster API.
* *INTERRUPTION_QUEUE* is the endpoint to the SQS queue created as part of the EKS Terraform blueprint. This SQS queue is used to hold Spot interruption notifications and AWS Health events.

Checkout the [Karpenter documentation](https://karpenter.sh/docs/reference/settings/) for information on the other configuration options.

To check Karpenter is running you can check that the Pods are running using the below command. There should be at least two `karpenter` pods.
```bash
kubectl get pods --namespace karpenter
```

You should see an output similar to the one below.
```
NAME                         READY   STATUS    RESTARTS   AGE
karpenter-75f6596894-pgrsd   1/1     Running   0          48s
karpenter-75f6596894-t4mrx   1/1     Running   0          48s
```
