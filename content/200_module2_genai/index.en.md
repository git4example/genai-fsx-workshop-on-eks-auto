---
title : "Deploy Generative AI Chat application"
weight : 200
---

## Module overview

In this module, you will configure and deploy a Generative AI chatbot application on Kubernetes, by deploying a vLLM Pod and a WebUI Pod on an Amazon EKS cluster, store and access the Mistral-7B model using Amazon FSx for Lustre and Amazon S3, and leverage AWS Inferentia Accelerators as the accelerated compute for your Generative AI workload.


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
To provide text generation inference capability with an OpenAI-compatible endpoint, we will deploy the Mistral-7B-Instruct model using the vLLM framework on Amazon Elastic Kubernetes Service (EKS). We will use Karpenter to spin up the AWS inferentia2 EC2 node (Accelerated Compute designed for Generative AI), where it will launch a vLLM Pod from an container image.


## AWS Inferentia Accelerators
 [**AWS Inferentia**](https://aws.amazon.com/machine-learning/inferentia/) is a custom machine learning chip designed by Amazon Web Services (AWS) to accelerate deep learning and generative AI inference applications. AWS Inferentia accelerators deliver high performance at the lowest cost in Amazon EC2, where it supports popular machine learning frameworks such as TensorFlow, PyTorch, and MXNet. It is specifically optimized for deploying machine learning models at scale, providing high performance and cost efficiency, as the underlying Inferentia2 accelerators are purpose-built to run DL models at scale. AWS Inferentia2-based Amazon EC2 Inf2 instances are optimized to deploy increasingly complex models, such as large language models (LLM) and latent diffusion models.

AWS Inferentia is used to accelerate the inference phase of machine learning. Inference involves using a trained model to make predictions or decisions based on new data. This phase is critical for real-time applications and services that require low latency and high throughput. AWS Inferentia2 is designed to deliver high throughput and low latency for a variety of inference workloads. Each Inferentia2 accelerator has two second-generation NeuronCores with up to 12 Inferentia2 accelerators per EC2 Inf2 instance. Each Inferentia2 accelerator supports up to 190 tera floating operations per second (TFLOPS) of FP16 performance. Inferentia2 offers 32 GB of HBM per accelerator, increasing the total memory by 4x and memory bandwidth by 10x over Inferentia1.

## AWS Neuron SDK - Native Support for ML Frameworks
[**AWS Neuron SDK**](https://aws.amazon.com/machine-learning/neuron/) is an SDK with a compiler, runtime, and profiling tools that unlocks high-performance and cost-effective deep learning (DL) acceleration. AWS Neuron SDK integrates natively with popular ML frameworks such as PyTorch and TensorFlow. With AWS Neuron, you can use these frameworks to optimally deploy DL models on both AWS Inferentia accelerators, and Neuron is designed to minimize code changes and tie-in to vendor-specific solutions. Neuron helps you run your inference applications for natural language processing (NLP)/understanding, language translation, text summarization, video and image generation, speech recognition, personalization, fraud detection, and more on Inferentia accelerators.
