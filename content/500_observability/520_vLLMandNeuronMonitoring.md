---
title : "vLLM and Neuron Monitoring dashboards"
weight : 520
---

### Overview

In this section, you will setup vLLM and Neuron monitoring configurations and deploy the Grafana dashboards.


##### vLLM Monitoring Setup 

Deploy a serviceMonitor configuration so that prometheus can scrape metrics from the Mistral model service endpoint.

```bash
cd /home/participant/environment/eks/genai/observability/
kubectl apply -f vllm-servicemonitor.yaml

```

### Neuron Monitoring Setup

Neuron Monitor runs on AWS Neuron-enabled instances to collect and expose hardware metrics (like utilization, memory usage, and temperature) from AWS Inferentia and Trainium chips through a Prometheus-compatible endpoint for monitoring and optimization of ML workloads. Let's deploy neuron monitor DaemonSet to expose these metrics to Prometheus using ServiceMonitor:


1. Deploy Neuron Monitor Deamonset and Service which will expose metrics

```bash
kubectl apply -f neuron-monitor.yaml

```
2. Deploy Service Monitor to scrape metrics

```bash
kubectl apply -f neuron-servicemonitor.yaml

```

##### Deploy the vLLM + Neuron Monitoring Dashboard

3. Deploy vLLM + Neuron Monitoring  Dashboard
```bash
kubectl apply -f vllm-neuron-dashboard-configmap.yaml
```

##### Log into Grafana dashboard

1. Run the following command to get the Grafana URL, and logon credentials.
```bash
GRAFANA_URL=$(kubectl get svc -n kube-system kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

```bash
echo "Grafana URL: http://$GRAFANA_URL"
echo "Username: admin"
echo "Password: $GRAFANA_PASSWORD"
```

![grafana_url](/static/images/grafana_url.png)

2. Open the Grafana URL (shown in the output) in your browser, and use the credentials shown to log-in.

3. Click on the "**Dashboards**" option from the right window pane. 


Navigate back to your Grafana URL, Click on the "**Dashboards**" option from the right window pane. Then in the search field, enter the name of the dashboard you want to view, such as the "**vLLM + Neuron Monitoring Dashboard**" that you created in the pervious steps. Click on the name that it returns to open the Grafana dashboard. DO NOT CLOSE this dashboard as you will revisit it in the below steps.

![mistral_vllm_dash_1](/static/images/mistral_vllm_dash_1.png)

4. Now go back to your Open WebUI client URL, and generate some input prompts (ask it questions or a task), and view the metrics associated with Inference, input and output tokens generated.


5. Navigate back to your vLLM monitoring dashboard and view the metrics related to input and output tokens, such as below.

![mistral_vllm_dash_1](/static/images/vLLMNeuronMonitoringDashboard.png)


6. You have successfully deployed a vLLM observability dashboard in this module. Continue to the next module to deploy an observability dashboard for your AWS Inferentia Accelerated Compute (Neuron observability dashboard).

### Summary

In this section, you have deployed a Grafana dashboard that provides observability across vLLM, Inference workload, and Neuron performance metrics.



##### Optional: Deploy additional Dashboards:

You can create the below additional dashboards on Grafana, and then search for them in Grafana dashboards and view them (as per the above step)


##### Deploy the vLLM Dashboard (Optional)

```bash
kubectl apply -f vllm-dashboard-configmap.yaml
```
This will create a dashboard called "vLLM Mistral 7B Monitoring" on Grafana

![vllm_dash_example](/static/images/vLLMMistral7BMonitoring.png)

```bash
kubectl apply -f vllm-dashboard-configmap-v2.yaml
```

This will create a dashboard called  "vLLM Mistral 7B Monitoring - v2" on Grafana
![vllm_dash_example](/static/images/vLLMMistral7BMonitoring-v2.png)

```bash
kubectl apply -f vllm-performance-dashboard.yaml
```
This will create a dashboard called "vLLM Performance Statistics" on Grafana

![vllm_dash_example](/static/images/vLLMPerformanceStatistics.png)

```bash
kubectl apply -f vllm-query-statistics.yaml
```
This will create a dashboard called "vLLM Query Statistics" on Grafana


![vllm_dash_example](/static/images/vLLMQueryStatistics.png)

##### Deploy Neuron Monitoring Dashboar (Optional)


4. Deploy Neuron Dashboard

```bash
kubectl apply -f neuron-monitoring-configmap.yaml
```

Verify dashboard on grafana "AWS Neuron Hardware Monitoring"

![vllm_dash_example](/static/images/AWSNeuronHardwareMonitoring.png)



<!--

Open file vllm-dashboard.json by double clicking (file is located under : /home/participant/environment/eks/genai/observability/)

Select all - Copy content.


Click Dashboards -- > New -- > Import -- > paste above copied json -- > click Load -- > Click Import  -->

This should load vLLM dashboard with metrics.
