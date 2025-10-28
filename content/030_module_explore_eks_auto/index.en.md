---
title : "Explore EKS Auto Mode"
weight : 30
---


## Overview

Amazon Elastic Kubernetes Service (Amazon EKS) Auto Mode is used in this workshop for Amazon EKS cluster provisioning and management.

Workshop creation details: The Amazon Elastic Kubernetes Service (EKS) cluster in this workshop was created using [**Terraform**](https://www.terraform.io/), and the [**EKS Blueprints for Terraform**](https://github.com/aws-ia/terraform-aws-eks-blueprints). You can explore the blueprint by looking into the `~/environment/eksworkshop` folder which is located in your VSCode IDE, if you want to learn how to use it in your own environment.

**Terraform** is an infrastructure-as-code tool that lets you build, change, and version infrastructure efficiently in AWS.

**EKS Blueprints for Terraform** helps you compose complete EKS clusters that are fully bootstrapped with the operational software that is needed to deploy and operate workloads. With EKS Blueprints, you describe the configuration for the desired state of your EKS environment, such as the control plane, worker nodes, and Kubernetes add-ons, as an IaC blueprint. Once a blueprint is configured, you can use it to create consistent environments across multiple AWS accounts and Regions using continuous deployment automation.

:::alert{header="Note" type="info"}
Take a moment to explore the  [Amazon EKS cluster deployed in the workshop via the AWS Console](https://console.aws.amazon.com/eks). Here you will see the cluster configuration, and the deployed worker nodes.
:::

---
<br></br>

# Additional reading
<br></br>

#### EKS Auto Mode

Amazon EKS Auto Mode offers the capability to fully automate compute, storage, and networking management for Kubernetes clusters. Amazon EKS Auto Mode makes getting started with Kubernetes, easier and faster, by offloading EKS cluster operations to AWS, allowing for improved performance and security of your applications, and optimized compute costs.

You can use EKS Auto Mode to obtain Kubernetes managed compute, networking, and storage for any new or existing EKS cluster. This makes it easier for you to leverage the security, scalability, availability, and efficiency of AWS for your Kubernetes applications. EKS Auto Mode removes the need for deep expertise, where EKS Auto Mode selects the optimal compute instances, dynamically scales resources as required, continuously optimizes costs, manages core add-ons, and patching. Using EKS Auto Mode you can also install additional Amazon EKS or self-managed add-ons in EKS Auto Mode clusters.

Click here to [**learn more about EKS Auto Mode and how it automates cluster infrastructure**](https://docs.aws.amazon.com/eks/latest/userguide/automode.html)

You can also migrate from Karpenter, EKS Managed Node Groups, and EKS Fargate to EKS Auto Mode.

By using EKS Auto Mode, you no longer need to manage components such as:
- CoreDNS
- KubeProxy
- Amazon VPC CNI
- AWS Load Balancer Controller
- Karpenter
- AWS EBS CSI Driver
- EKS Pod Identity Agent
