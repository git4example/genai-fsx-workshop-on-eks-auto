---
title : "Observability dashboard for LLM Inference"
weight : 300
---


## Module Overview

It is important to have a mechanism that provides observability into Inference workloads, across metrics such as "prompt" & "generated" tokens, inference performance & queues, and also Accelerated Compute performance details. In this section, you will create a dashboard that provides detailed observability into LLM inference workload metrics running on Amazon EKS with AWS Neuron accelerators, focusing on key metrics that help understand model performance, Neuron utilization, and system health.

While this module demonstrates how to instrument observability tools directly on EKS for learning purposes, for production environments at scale, we recommend using AWS managed services such as Amazon Managed Service for Prometheus (AMP) and Amazon Managed Grafana (AMG) for improved scalability, reduced operational overhead, and better integration with the AWS ecosystem.


This module guides you through implementing Neuron and LLM inference monitoring, divided into four sections:

1. Setting-up the observability Stack
    - Understand the deployed monitoring components
    - Review Prometheus and Grafana architecture
    - Configure Grafana Operator
    - Deploy Node Exporter for Neuron metrics collection
<br>
</br>

2. Configuring Neuron Performance Monitoring
    - Configure neuron-monitor metrics collection
    - Create Grafana dashboards for Neuron performance visualization
    - Track NeuronCore utilization, Model inference latency, Memory consumption, Hardware performance metrics


<br>
</br>

3. vLLM Model Monitoring
    - Implement vLLM-specific metrics collection
    - Create custom performance dashboards
    - Track token generation and latency metrics
    - Monitor inference queue and processing times
