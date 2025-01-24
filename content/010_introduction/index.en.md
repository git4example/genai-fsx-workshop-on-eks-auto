---
title: 'Introduction'
weight: 10
---

Copyright Amazon Web Services, Inc. and its affiliates. All rights reserved. This sample code is made available under the MIT-0 license. See the [LICENSE](./LICENSE.en.md) file.

Errors or corrections? Contact ppariksh@amazon.com, akbariw@amazon.com and ameenamz@amazon.com

-------------------------------------------------------------
## Workshop Objective
In this workshop, you will learn how you can:
1. Deploy a Generative AI chatbot application on Kubernetes by deploying a vLLM and a WebUI Pod on an Amazon EKS cluster, store and access the Mistral-7B model using Amazon FSx for Lustre and  Amazon S3, and leverage Accelerate Compute for your Generative AI workload using AWS Inferentia Accelerator.
2. Let EKS Auto to scale the number of EKS managed nodes, when there are additional Pod requests that require additional nodes, to enable scale and operational efficiency.
3. Use AWS Inferentia Accelerated Compute in your Amazon EKS clusters, as a new nodepool to power your Generative AI applications.
4. Configure Amazon FSx for Lustre and Amazon S3, as your performant and scalable data layer, which will host your model and data
5. Achieve operational efficiency at the data layer: accessing the same model data across container Pods without storing multiple copies, and seamlessly sharing your data across regions, for scenario's such as distributed access and sharing, to DR.



****Target Audience****: DevOps engineers, Machine Learning Scientists/Engineers, Container & Storage engineers, Cloud Architects

****Prerequisites****: Recommended to have an fundamental understanding of AWS containers, and AWS Cloud

****Duration****: Approximately take 2 hours.

![lab-image](/static/images/lab-image.png)

-----

## Generative AI and Machine Learning
Generative AI and Machine Learning (ML) is helping businesses transform the way they operate and innovate. Generative AI refers to a class of Artificial Intelligence that leverages Large Language Models (LLM) in order to generate new content from a prompt, content such as text, images, audio, and software code.

## What is a Large Language Model (LLM)
Large Language Models (LLMs) are a type of machine learning model that is trained on vast amounts of text data to learn the patterns and structure of natural language. These models can then be used for a wide range of natural language processing tasks, such as text generation, question answering, and language translation. In this lab we are going to use the open-source Mistral-7B-Instruct model, which is a specific LLM model with 7 billion parameters. The "Instruct" in the name refers to the fact that this model has been trained to follow instructions and perform a wide variety of tasks, beyond just generating text, i.e. it is suitable for chat applications. You will be using this open source LLM model in this workshop.


## What is vLLM
[**vLLM (Virtual Large Language Model)**](https://github.com/vllm-project/vllm) is an open-source, easy-to-use, library for LLM inference and serving. It provides a framework that allows LLM models such as Mistral-7B-Instruct, to be deployed to provide text generation inference. vLLM provides an API that is compatible with OpenAI API, making it easy to integrate LLM applications.

**vLLM is fast with:**
- State-of-the-art serving throughput
- Efficient management of attention key and value memory with PagedAttention
- Continuous batching of incoming request
- Fast model execution with CUDA/HIP graph

**vLLM is flexible and easy to use with:**
- Seamless integration with popular HuggingFace models
- OpenAI-compatible API server
- Prefix caching support
- Supports chipsets such as: AWS Neuron, NVIDIA GPUs and others,

## Deploying Mistral-7B-Instruct using a vLLM on Amazon EKS
To provide text generation inference capability with an OpenAI-compatible endpoint, we will deploy the Mistral-7B-Instruct model using the vLLM framework on Amazon Elastic Kubernetes Service (EKS). We will let EKS Auto to spin up the AWS inferentia2 EC2 node (Accelerated Compute designed for Generative AI), where it will launch a vLLM Pod from an container image.

## What is Amazon EKS (Elastic Kubernetes Service)
[**Amazon EKS**](https://aws.amazon.com/eks/), is a managed service that makes it easy for you to deploy, run, manage and scale container based apps using Kubernetes on AWS, without installing and operating your own Kubernetes control plane or worker nodes. Amazon EKS clusters can scale to support thousands of containers, which makes it ideal for Generative AI and ML workloads, where you can tune and deploy LLMs on Amazon EKS. Amazon EKS serves as an effective orchestrator to help achieve rapid scale out and scale in that is required for Generative AI and ML workloads, optimal cost efficiency.

## How to consume the Inference Service
You can connect to the Inference Service using the **"Open WebUI"** application, which is designed to consume the OpenAI-compatible endpoint provided by the vLLM-hosted Mistral-7B-Instruct model that you will deploy in the workshop. The Open WebUI application allows users to interact with the LLM model through a chat-based interface. To use the Open WebUI application, simply deploy the application container, and connect to the WebUI URL that is provided and start chatting with the LLM model. The WebUI application will handle the communication with the VLLM-hosted Mistral-7B-Instruct model, providing a seamless user experience


## Storing and accessing your model and training data
In this workshop the **Mistral-7B-Instruct** model is stored in an Amazon S3 bucket [**Amazon S3**](https://aws.amazon.com/s3/), which is linked to an  [**Amazon FSx for Lustre File system S3**](https://aws.amazon.com/fsx/lustre/). The vLLM container will consume the Mistral model data via the mounted Amazon FSx for Lustre instance for the Generative AI Chat application. Amazon FSx for Lustre is a fully managed service that provides a high-performance scalable file system, for workloads where speed matters, providing sub-millisecond latency, and scaling to TB/s of throughput and millions of IOPS. Amazon FSx also integrates with Amazon S3 (highly durable, available and scalable object store), making it easy for you to store, access and process vast amounts of cloud data with the Lustre high-performance file system.

## Accelerating your Compute
 [**AWS Inferentia accelerators**](https://aws.amazon.com/machine-learning/inferentia/) are designed by AWS to deliver high performance at the lowest cost in Amazon EC2 for your deep learning (DL) and generative AI inference applications, where Inferentia2-based Amazon EC2 Inf2 instances are optimized to deploy increasingly complex models, such as large language models (LLM). [**AWS Neuron SDK**](https://aws.amazon.com/machine-learning/neuron/) is an SDK with a compiler, runtime, and profiling tools that unlocks high-performance and cost-effective deep learning (DL) acceleration. AWS Neuron SDK helps developers deploy models on the AWS Inferentia accelerators, where it integrates natively with popular frameworks, such as PyTorch and TensorFlow, so that you can continue to use your existing code and workflows and run on Inferentia accelerators.
