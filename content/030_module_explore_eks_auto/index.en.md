---
title : "Explore EKS Auto"
weight : 30
---


## Automation used for the creation of your lab Amazon EKS Cluster

The Amazon Elastic Kubernetes Service (EKS) cluster in this workshop was created with [**Terraform**](https://www.terraform.io/) using the [**EKS Blueprints for Terraform**](https://github.com/aws-ia/terraform-aws-eks-blueprints). You can explore the blueprint by looking into the `~/environment/eksworkshop` folder on your VSCode IDE, to learn how it could be used in a your environment.

**Terraform** is an infrastructure as code tool that lets you build, change, and version infrastructure efficiently in AWS.

**EKS Blueprints for Terraform** helps you compose complete EKS clusters that are fully bootstrapped with the operational software that is needed to deploy and operate workloads. With EKS Blueprints, you describe the configuration for the desired state of your EKS environment, such as the control plane, worker nodes, and Kubernetes add-ons, as an IaC blueprint. Once a blueprint is configured, you can use it to create consistent environments across multiple AWS accounts and Regions using continuous deployment automation.

:::alert{header="Note" type="info"}
Take a moment to explore the  [Amazon EKS cluster via the AWS Console](https://console.aws.amazon.com/eks),  to view the cluster configuration, and the 2 worker nodes.
:::

## EKS Auto Mode

Amazon Elastic Kubernetes Service (Amazon EKS) Auto Mode cluster offers capability to fully automates compute, storage, and networking management for Kubernetes clusters. Amazon EKS Auto Mode simplifies running Kubernetes by offloading cluster operations to AWS, improves the performance and security of your applications, and helps optimize compute costs. 

You can use EKS Auto Mode to get Kubernetes conformant managed compute, networking, and storage for any new or existing EKS cluster. This makes it easier for you to leverage the security, scalability, availability, and efficiency of AWS for your Kubernetes applications. EKS Auto Mode removes the need for deep expertise, ongoing infrastructure management, or capacity planning by automatically selecting the best EC2 instances to run your application. It helps optimize compute costs while maintaining application availability by dynamically scaling EC2 instances based on demand. EKS Auto Mode provisions, operates, secures, and upgrades EC2 instances within your account using AWS-controlled access and lifecycle management. It handles OS patches and updates and limits security risks with ephemeral compute, which strengthens your security posture by default.

With the EKS Auto Mode, you can automate cluster management without deep Kubernetes expertise, because it selects optimal compute instances, dynamically scales resources, continuously optimizes costs, manages core add-ons, patches operating systems, and integrates with AWS security services. AWS expands its operational responsibility in EKS Auto Mode compared to customer-managed infrastructure in your EKS clusters. In addition to the EKS control plane, AWS will configure, manage, and secure the AWS infrastructure in EKS clusters that your applications need to run.

You can now get started quickly, improve performance, and reduce overhead, enabling you to focus on building applications that drive innovation instead of on cluster management tasks. EKS Auto Mode also reduces the work required to acquire and run cost-efficient GPU-accelerated instances so that your generative AI workloads have the capacity they need when they need it.

You can also migrate from Karpenter, EKS Managed Node Groups, and EKS Fargate to EKS Auto Mode. 

With EKS Auto you no longer need to manage components like:
- CoreDNS
- KubeProxy
- Amazon VPC CNI 
- AWS Load Balancer Controller
- Karpenter
- AWS EBS CSI Driver
- EKS Pod Identity Agent

You can still install additional Amazon EKS Add-ons or any other self-managed add-ons in EKS Auto clusters.

#### EKS Auto Features

EKS Auto Mode provides the following high-level features:

**Streamline Kubernetes Cluster Management:** EKS Auto Mode streamlines EKS management by providing production-ready clusters with minimal operational overhead. With EKS Auto Mode, you can run demanding, dynamic workloads confidently, without requiring deep EKS expertise.

**Application Availability:** EKS Auto Mode dynamically adds or removes nodes in your EKS cluster based on the demands of your Kubernetes applications. This minimizes the need for manual capacity planning and ensures application availability.

**Efficiency:** EKS Auto Mode is designed to compute costs while adhering to the flexibility defined by your NodePool and workload requirements. It also terminates unused instances and consolidates workloads onto other nodes to improve cost efficiency.

**Security:** EKS Auto Mode uses AMIs that are treated as immutable for your nodes. These AMIs enforce locked-down software, enable SELinux mandatory access controls, and provide read-only root file systems. Additionally, nodes launched by EKS Auto Mode have a maximum lifetime of 21 days (which you can reduce), after which they are automatically replaced with new nodes. This approach enhances your security posture by regularly cycling nodes, aligning with best practices already adopted by many customers.

**Automated Upgrades:** EKS Auto Mode keeps your Kubernetes cluster, nodes, and related components up to date with the latest patches, while respecting your configured Pod Disruption Budgets (PDBs) and NodePool Disruption Budgets (NDBs). Up to the 21-day maximum lifetime, intervention might be required if blocking PDBs or other configurations prevent updates.

**Managed Components:** EKS Auto Mode includes Kubernetes and AWS cloud features as core components that would otherwise have to be managed as add-ons. This includes built-in support for Pod IP address assignments, Pod network policies, local DNS services, GPU plug-ins, health checkers, and EBS CSI storage.

**Customizable NodePools and NodeClasses:** If your workload requires changes to storage, compute, or networking configurations, you can create custom NodePools and NodeClasses using EKS Auto Mode. While default NodePools and NodeClasses can’t be edited, you can add new custom NodePools or NodeClasses alongside the default configurations to meet your specific requirements.

#### Automated Components

EKS Auto Mode streamlines the operation of your Amazon EKS clusters by automating key infrastructure components. Enabling EKS Auto Mode further reduces the tasks to manage your EKS clusters.

The following is a list of data plane components that are automated:

- **Compute:** For many workloads, with EKS Auto Mode you can forget about many aspects of compute for your EKS clusters. These include:

    - **Nodes:** EKS Auto Mode nodes are designed to be treated like appliances. EKS Auto Mode does the following:

        - Chooses an appropriate AMI that’s configured with many services needed to run your workloads without intervention.
        - Locks down those features using SELinux enforcing mode and a read-only root file system.
        - Prevents direct access to the nodes by disallowing SSH or SSM access.
        - Includes GPU support, with separate kernel drivers and plugins for NVIDIA and Neuron GPUs, enabling high-performance workloads.

    - **Auto scaling:** Relying on Karpenter auto scaling, EKS Auto Mode monitors for unschedulable Pods and makes it possible for new nodes to be deployed to run those pods. As workloads are terminated, EKS Auto Mode dynamically disrupts and terminates nodes when they are no longer needed, optimizing resource usage.

    - **Upgrades:** Taking control of your nodes streamlines EKS Auto Mode’s ability to provide security patches and operating system and component upgrades as needed. Those upgrades are designed to provide minimal disruption of your workloads. EKS Auto Mode enforces a 21-day maximum node lifetime to ensure up-to-date software and APIs.

- **Load balancing:** EKS Auto Mode streamlines load balancing by integrating with Amazon’s Elastic Load Balancing service, automating the provisioning and configuration of load balancers for Kubernetes Services and Ingress resources. It supports advanced features for both Application and Network Load Balancers, manages their lifecycle, and scales them to match cluster demands. This integration provides a production-ready load balancing solution adhering to AWS best practices, allowing you to focus on applications rather than infrastructure management.

- **Storage:** EKS Auto Mode configures ephemeral storage for you by setting up volume types, volume sizes, encryption policies, and deletion policies upon node termination.

- **Networking:** EKS Auto Mode automates critical networking tasks for Pod and service connectivity. This includes IPv4/IPv6 support and the use of secondary CIDR blocks for extending IP address spaces.

- **Identity and Access Management:** You do not have to install the EKS Pod Identity Agent on EKS Auto Mode clusters.
