---
title : "Observing LLM Inference workloads"
weight : 500
---
-------------------------------------------------------------


In this section, we'll explore how to implement comprehensive observability for LLM inference workloads running on Amazon EKS with AWS Neuron accelerators. We'll cover monitoring solutions for both vLLM and Ray-served models, focusing on key metrics that help understand model performance, Neuron utilization, and system health.

While this module demonstrates how to instrument observability tools directly on EKS for learning purposes, for production environments at scale, we recommend using AWS managed services such as Amazon Managed Service for Prometheus (AMP) and Amazon Managed Grafana (AMG) for improved scalability, reduced operational overhead, and better integration with the AWS ecosystem.

## Module Overview

This module guides you through exploring and implementing Neuron and LLM inference monitoring, divided into four sequential sections:

1. Setting-up Observability Stack
    - Understand the deployed monitoring components
    - Review Prometheus and Grafana architecture
    - Configure Grafana Operator
    - Deploy Node Exporter for Neuron metrics collection

2. Configuring Neuron Performance Monitoring
    - Configure neuron-monitor metrics collection
    - Create Grafana dashboards for Neuron performance visualization
    - Track NeuronCore utilization, Model inference latency, Memory consumption, Hardware performance metrics

3. vLLM Model Monitoring
    - Implement vLLM-specific metrics collection
    - Create custom performance dashboards
    - Track token generation and latency metrics
    - Monitor inference queue and processing times
