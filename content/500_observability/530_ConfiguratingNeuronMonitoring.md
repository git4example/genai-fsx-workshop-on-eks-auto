---
title : "Configuring Neuron Monitoring Dashboard"
weight : 530
---

### Overview

Neuron Monitor runs on AWS Neuron-enabled instances to collect and expose hardware metrics (like utilization, memory usage, and temperature) from AWS Inferentia and Trainium chips through a Prometheus-compatible endpoint for monitoring and optimization of ML workloads. Let's deploy neuron monitor DaemonSet to expose these metrics to Prometheus using ServiceMonitor:


1. Deploy Neuron Monitor Deamonset and Service which will expose metrics
```bash
cd /home/participant/environment/eks/genai/observability/
kubectl apply -f neuron-monitor.yaml

```
2. Deploy Service Monitor to scrape metrics

```bash
kubectl apply -f neuron-servicemonitor.yaml

```

3. Deploy Neuron Dashboard

```bash
kubectl apply -f neuron-monitoring-configmap.yaml
```

Verify dashboard on grafana "AWS Neuron Hardware Monitoring (ConfigMap)"

4. Deploy vLLM + Neuron Monitoring  Dashboard
```bash
kubectl apply -f vllm-neuron-dashboard-configmap.yaml
```

5. Navigate back to your Grafana URL, Click on the "**Dashboards**" option from the right window pane. Then in the search field enter "Comprehensive vLLM + Neuron Monitoring Dashboard", then select it to open the dashboard.


### Conclusion
You have now completed this module and workshop.

✅ In this module you have successfully installed the Neuron Monitor:

    Configured it to run only on Inferantia nodes
    Added proper node selectors and tolerations
    Enabled Prometheus ServiceMonitor integration


✅ Confirmed Neuron metrics collection:

    Verified Neuron Monitor daemon set deployment
    Accessed the metrics endpoint
    Validated Neuron telemetry data
