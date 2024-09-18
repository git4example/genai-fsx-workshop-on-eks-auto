---
title: 'Introduction'
weight: 10
---

Copyright Amazon Web Services, Inc. and its affiliates. All rights reserved. This sample code is made available under the MIT-0 license. See the [LICENSE](./LICENSE.en.md) file.

Errors or corrections? Contact ppariksh@amazon.com and ameenamz@amazon.com

-------------------------------------------------------------

## Workshop Objective

In this scenario-based workshop you will build a simple Generative AI based interactive Chatbot application using the Mistral-7B Foundation Model, on top of the following AWS services:
* Amazon Elastic Kubernetes Service (EKS) as the orchestration layer,
* Amazon FSx for Lustre & Amazon S3, for the data layer,
* AWS Inferentia as the Accelerated compute.


During this workshop, We will take you through a journey to highlight how you can leverage the Amazon EKS, Amazon FSx and AWS Inferentia stack as a pattern to easily build and test your own Generative AI and ML workloads, where along the way you will touch on dimensions such as performance, scale, integration, and also data services which allow you to replicate and access your data seamlessly across AWS Regions, to further power at-scale container-based workloads. We hope you will enjoy this fun learning experience with us.

You will perform the following high level activities during this lab:
* Use an Amazon EKS cluster and deploy PODs (containers) on an AWS Inferentia base nodepool
* Use Karpenter to schedule your POD tasks
* Deploy the CSI driver for Amazon FSx for Lustre, and integrate  Amazon FSx and Amazon S3 for your data layer for your EKS
* Deploy a simple Generative AI chatbot application with the Mistral-7B Foundation Model
* Conduct performance, scale, integration and cross-region data sharing exercises


---
NEED TO REWRITE THESE and SUMMARIZE .. AND PUT A LOGICAL Architecture DIAGRAM IN HERE FOR WHAT THEY WILL BUILD IN THE ENTIRE WORKSHOP
* use a foundation model that stored in an Amazon S3 bucket(which is created for you)
* Deploy an Amazon FSx for Lustre File system that is linked to the S3 bucket hosting the foundation model (using the EKS CSI driver),
* Create a Persistent Volume Claim (PVC) from the FSx for Lustre file system and attach it to your Amazon EKS based pod.
* Configure a new AWS Inferentia nodepool (for your GenAI pod) on your Amazon EKS cluster
* Configure the Neuron device plugin and and Scheduler for AWS Inferentia
* Deploy a Generative AI based chatbot application on your Amazon EKS cluster, using an EKS Optimized AMI with a Foundation model, through your Amazon FSx for Lustre + Amazon S3 based data layer
* Perform performance tests of data layer
* learn how you can share the same foundation model with other PODs without multiple copies
* Learn how you can seamlessly share your Foundation models and training data across accounts or regions,for scenario's such as distrubited access, data sharing to DR.
* use a foundation model that stored in an Amazon S3 bucket(which is created for you)
* Deploy an Amazon FSx for Lustre File system that is linked to the S3 bucket hosting the foundation model (using the EKS CSI driver),
* Create a Persistent Volume Claim (PVC) from the FSx for Lustre file system and attach it to your Amazon EKS based pod.
* Configure a new AWS Inferentia nodepool (for your GenAI pod) on your Amazon EKS cluster
* Deploy a Generative AI based chatbot application on your Amazon EKS cluster with a Foundation model, through your Amazon FSx for Lustre + Amazon S3 based data layer
* Perform performance tests of data layer
* learn how you can share the same foundation model with other PODs without multiple copies
* Learn how you can seamlessly share your foundation models and training data across accounts or regions, for scenario's such as distributed access, data sharing to DR.
---
