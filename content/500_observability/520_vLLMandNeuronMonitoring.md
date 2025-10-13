---
title : "Deploy vLLM & Neuron monitoring dashboards"
weight : 520
---

### Overview

It is important to have a mechanism that provides observability into Inference workloads, across metrics such as "prompt" & "generated" tokens, inference performance & queue metrics, and also Accelerated Compute performance details. In this section you will setup & deploy Grafana based dashboards that will provide observability into inference workload, vLLM & Neuron performance metrics.


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

2. Wait 2 minutes for the load balance to become online, then open the Grafana URL (shown in the output) in your browser, and use the credentials shown to log-in.

3. Click on the "**Dashboards**" option from the right window pane.


Navigate back to your Grafana URL, Click on the "**Dashboards**" option from the right window pane. Then in the search field, enter the name of the dashboard you want to view, such as the "**vLLM + Neuron Monitoring Dashboard**" that you created in the pervious steps. Click on the name that it returns to open the Grafana dashboard. DO NOT CLOSE this dashboard as you will revisit it in the below steps.

![mistral_vllm_dash_1](/static/images/mistral_vllm_dash_1.png)

4. Now go back to your Open WebUI client URL (your chatbot). From the left hand window pane, right-click on your previous chat and select **Delete**.

![new_chat](/static/images/new_chat.png)

5. This will now start a new chat, so go ahead and generate some input prompts (ask it questions or a task), and view the metrics associated with Inference, input and output tokens generated.


5. Navigate back to your vLLM monitoring dashboard, click on the time range button and select *5min* or *15min* and select *Refresh*

![refresh_dash](/static/images/refresh_dash.png)

6. You will see metrics related to input and output tokens of your Generative AI query, such as below.

![vLLMNeuronMonitoringDashboard](/static/images/vLLMNeuronMonitoringDashboard.png)



7. You have successfully deployed a vLLM observability dashboard in this module. Continue to the next module to deploy an observability dashboard for your AWS Inferentia Accelerated Compute (Neuron observability dashboard).

### Summary

In this section, you have deployed a Grafana dashboard that provides observability across vLLM, Inference workload, and Neuron performance metrics.

Congratulations! You have now completed the workshop.


---

---




##### Optional: You can deploy additional metrics dashboards

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
