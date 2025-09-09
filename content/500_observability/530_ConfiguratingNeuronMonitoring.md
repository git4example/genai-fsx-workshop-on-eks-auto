---
title : "Configuring Neuron Monitoring Dashboard"
weight : 530
---
# Following is still work in progress. Go to next page to setup model monitoring.

Configuring Neuron Monitoring Dashboard




Configuring Neuron Monitor

Neuron Monitor runs on AWS Neuron-enabled instances to collect and expose hardware metrics (like utilization, memory usage, and temperature) from AWS Inferentia and Trainium chips through a Prometheus-compatible endpoint for monitoring and optimization of ML workloads. Let's deploy neuron monitor DaemonSet to expose these metrics to Prometheus using ServiceMonitor:


### Deploy Neuron Monitor Deamonset and Service which will expose metrics
```bash
kubectl apply -f neuron-monitor.yaml

```
### Deploy Service Monitor to scrape metrics

```bash
kubectl apply -f neuron-servicemonitor.yaml

```

### Deploy Neuron Dashboard 

```bash
kubectl apply -f neuron-monitoring-configmap.yaml 
```

Verify dashboard on grafana "AWS Neuron Hardware Monitoring (ConfigMap)" 

### Deploy Comprehensive Dashboard 
```bash
kubectl apply -f comprehensive-vllm-neuron-dashboard.yaml 
```

Verify dashboard on grafana "Comprehensive vLLM + Neuron Monitoring Dashboard" 



✅ Successfully installed Neuron Monitor:

    Configured it to run only on Inferantia nodes
    Added proper node selectors and tolerations
    Enabled Prometheus ServiceMonitor integration




✅ Confirmed Neuron metrics collection:

    Verified Neuron Monitor daemon set deployment
    Accessed the metrics endpoint
    Validated Neuron telemetry data