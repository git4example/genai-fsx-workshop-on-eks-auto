---
title: 'Introduction'
weight: 10
---

Copyright Amazon Web Services, Inc. and its affiliates. All rights reserved. This sample code is made available under the MIT-0 license. See the [LICENSE](./LICENSE.en.md) file.

Errors or corrections? Contact ppariksh@amazon.com and ameenamz@amazon.com

-------------------------------------------------------------

****Reword this****

Generative Artificial Intelligence is transforming the way businesses function and is accelerating the pace of innovation. In general, the AI field is changing the way businesses utilize technology. Generative AI technology involves tuning and deploying Large Language Models (LLM), and gives developers access to those models to execute prompts and conversations. Platform teams who standardize on Kubernetes can tune and deploy the LLMs on Amazon Elastic Kubernetes Service (https://aws.amazon.com/eks/ ). Amazon EKS is a managed Kubernetes service that makes it easier to deploy, manage, and scale containerized applications using Kubernetes on AWS. One of the core strengths of Amazon EKS is its scalability; the data plane can dynamically expand, which ensues that as the AI models demand more computational power, Amazon EKS can seamlessly accommodate. For instance, Amazon EKS clusters can scale to support tens of thousands of active containers, which makes it ideal for intensive AI workloads. Beyond scalability, Amazon EKS offers a high degree of customization, that allows users to fine-tune configurations to match specific requirements. Amazon EKS incorporates robust built-in safeguards to protect both your AI models and the data.

Generative AI models represent a significant breakthrough in the field of Artificial Intelligence/Machine Learning, due to its wide ranging applicability along with easy accessibility for non-AI experts. Traditionally, utilizing AI meant creation of a specialized model for each specific use-case, which required a huge amount of compute and human resources each time. Generative AI models overcome this bottleneck by creating Foundation Models (FM). FMs allow reuse by providing ability to fine-tune them to be utilized for multiple use-cases without having to build models from the ground up repeatedly. The most popularly used foundational models today utilize transformers (text generation)/diffusers (i.e., image generation) to achieve this adaptability. These models have potential applicability across a wide range of use-cases and industry verticals ranging from chatbots and virtual assistants to generating videos completely via text prompts for marketing.

LLMs comprise of billions of parameters which require large amount of resources for high performance training as well as low latency inference. Amazon EKS serves as an effective orchestrator to help achieve rapid scale out and scale in needed for these generative AI workloads while providing tools to meet enterprise governance and control. Amazon EKS not only simplifies management but also offers a wide variety of open-source tools to tackle unique ML challenges. Amazon EKS empowers you with full control over your environments, which ensures optimal cost efficiency.


## Workshop Objective
In this workshop, you will learn how you can:
1. Easily deploy a Generative AI chatbot application on kubernetes with Amazon EKS
2. Use Karpenter for scaling your Pod tasks within Amazon EKS, for scale and operational efficiency
3. Use AWS Inferentia Accelerated Compute and its Neuron device plugin & scheduler in your Amazon EKS clusters, as a new nodepool for your Generative AI applications
4. Configure Amazon FSx for Lustre and Amazon S3 bucket, as your performant and scalable data layer, to host your models and data
6. Achieve operational efficiency at the data layer, and share the same foundation model and data with other container Pods without storing multiple copies, and how you can seamlessly share your data across AWS accounts & regions, for scenario's such as distributed access and sharing, to DR.



****Target Audience****
DevOps engineers, Machine Learning Scientists/Engineers, Containers engineers, Storage engineers, Cloud Architects, and technical Founders.

****Prerequisites****
It is recommended to have an fundamental understanding of containers, and AWS Cloud and using the AWS Console.

****Duration****
Completing all the modules in this workshop will approximately take 2 hours.






---
