---
title : "Deploy vLLM & Neuron monitoring dashboards"
weight : 320
---

### Overview

It is important to have a mechanism that provides observability into Inference workloads, across metrics such as "prompt" & "generated" tokens, inference performance & queue metrics, and also Accelerated Compute performance details. In this section you will setup & deploy Grafana based dashboards that will provide observability into inference workload, vLLM & Neuron performance metrics.


#### vLLM Monitoring Setup

Run the below commands to deploy a Service Monitor configuration so that prometheus can scrape metrics from the vLLM service endpoint.

```bash
cd /home/participant/environment/eks/genai/observability/
kubectl apply -f vllm-servicemonitor.yaml
```

#### Neuron Monitoring Setup

Neuron monitor collects and exposes hardware metrics (utilization, memory usage, and temperature) from AWS Inferentia and Trainium chips through a Prometheus-compatible.

1. Run the below command to deploy the Neuron Monitor Deamonset and service to expose metrics

```bash
kubectl apply -f neuron-monitor.yaml
```
2. Deploy Service Monitor to scrape metrics

```bash
kubectl apply -f neuron-servicemonitor.yaml
```

#### Deploy the vLLM + Neuron Monitoring Dashboard

3. Now that we have our vLLM and Neuron metrics collectors setup, run the below command to deploy our custom "vLLM + Neuron monitoring" Grafana based dashboard. This custom dashboard combines specific Inference metrics along with Neuron metrics into a single dashboard view.

```bash
kubectl apply -f vllm-neuron-dashboard-configmap.yaml
```

#### Log into Grafana dashboard

1. Run the following command to get the Grafana dashboard URL, and logon credentials.
```bash
GRAFANA_URL=$(kubectl get svc -n kube-system kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

```bash
echo "Grafana URL: http://$GRAFANA_URL"
echo "Username: admin"
echo "Password: $GRAFANA_PASSWORD"
```

![grafana_url](/static/images/grafana_url.png)

2. You will need to for 2 minutes for the Grafana URL load balancer to become online. Then open the Grafana URL (shown in the output) in your browser, and use the credentials shown to log-in.

<br>

3. Within the Grafana URL, click on the "**Dashboards**" option from the right window pane.

4. In the search field, enter the name of the dashboard you want to view, such as the "**vLLM + Neuron Monitoring Dashboard**" that you created in the pervious steps. Click on the name that it returns to open the Grafana dashboard. **DO NOT CLOSE** this dashboard as you will revisit it in the below steps.

![mistral_vllm_dash_1](/static/images/mistral_vllm_dash_1.png)

5. Navigate back to your Open WebUI client URL (your chatbot) and generate some input prompts (ask it questions or a task).


7. Navigate back to your vLLM monitoring dashboard, click on the time range button and select *5min* or *15min* and select *Refresh*

![refresh_dash](/static/images/refresh_dash.png)

8. You will now see Inference metrics (such as below) related to inference query load, input prompt tokens, output generated tokens, Neuron compute performance etc, based on your previous prompt query. 

![vLLMNeuronMonitoringDashboard](/static/images/vLLMNeuronMonitoringDashboard.png)


### Summary

In this section, you have deployed a Grafana dashboard that provides observability across vLLM, Inference workload, and Neuron compute performance metrics.



---




#### Optional: Additional metrics dashboards available for deployment.

You can deploy any of the optional dashboards below to view different metrics. Once you deploy one of the below dashboards, simply search for them in Grafana dashboards to view them (as per the above step).


1. Deploy a dashboard called "vLLM Performance Statistics" on Grafana

```bash
kubectl apply -f vllm-performance-dashboard.yaml
```

2. Deploy a dashboard called "vLLM Query Statistics" on Grafana

```bash
kubectl apply -f vllm-query-statistics.yaml
```


3. Deploy a dashboard called "AWS Neuron Hardware Monitoring" on Grafana

```bash
kubectl apply -f neuron-monitoring-configmap.yaml
```
