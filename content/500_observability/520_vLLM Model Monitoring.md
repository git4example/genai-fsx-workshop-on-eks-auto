---
title : "vLLM Monitoring dashboard"
weight : 520
---

### Overview

In this section, you will setup vLLM monitoring and deploy the Grafana dashboard.


##### Deploy Service Monitor to scrape metrics

Deploy a serviceMonitor configuration so that prometheus can scrape metrics from the Mistral model service endpoint.

```bash
cd /home/participant/environment/eks/genai/observability/
kubectl apply -f vllm-servicemonitor.yaml

```

##### Deploy the Dashboard

```bash
kubectl apply -f vllm-dashboard-configmap.yaml
```
This will create a dashboard called "vLLM Mistral 7B Monitoring" on Grafana


#### Grafana Stack

Get grafana loadbalancer
::code[kubectl get svc -n kube-system kube-prometheus-stack-grafana]{language=bash showLineNumbers=false showCopyAction=true}

```bash
NAME                            TYPE           CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)        AGE
kube-prometheus-stack-grafana   LoadBalancer   172.20.211.49   a0b4c567b25944afb889f19b945efad4-1467842165.us-west-2.elb.amazonaws.com   80:30387/TCP   18m
```



# Get LoadBalancer URL
```bash
GRAFANA_URL=$(kubectl get svc -n kube-system kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

# Log into Grafana dashboard

1. Run the following command to get the Grafana URL, and logon credentials.

```bash
echo "Grafana URL: http://$GRAFANA_URL"
echo "Username: admin"
echo "Password: $GRAFANA_PASSWORD"
```

![grafana_url](/static/images/grafana_url.png)

2. Open the Grafana URL (shown in the output) in your browser, and use the credentials shown to log-in.

3. Click on the "**Dashboards**" option from the right window pane. Then in the search field, enter the name of the dashboard you want to view, such as the "**vLLM Mistral 7B Monitoring**" that you created in the pervious steps. Click on the name that it returns to open the Grafana dashboard. DO NOT CLOSE this dashboard as you will revisit it in the below steps.

![mistral_vllm_dash_1](/static/images/mistral_vllm_dash_1.png)



4. Now go back to your Open WebUI client URL, and generate some input prompts (ask it questions or a task), and view the metrics associated with Inference, input and output tokens generated.


5. Navigate back to your vLLM monitoring dashboard and view the metrics related to input and output tokens, such as below.

![vllm_dash_example](/static/images/vllm_dash_example.png)



6. You have successfully deployed a vLLM observability dashboard in this module. Continue to the next module to deploy an observability dashboard for your AWS Inferentia Accelerated Compute (Neuron observability dashboard).

### Summary

In this section, you have deployed a Grafana dashboard that provides observability across vLLM, Inference workload, and Neuron performance metrics.



##### Optional: Deploy additional Dashboards:

You can create the below additional dashboards on Grafana, and then search for them in Grafana dashboards and view them (as per the above step)
```bash
kubectl apply -f vllm-dashboard-configmap-v2.yaml
```

This will create a dashboard called  "vLLM Mistral 7B Monitoring - v2" on Grafana

```bash
kubectl apply -f vllm-performance-dashboard.yaml
```
This will create a dashboard called "Performance Statistics" on Grafana

```bash
kubectl apply -f vllm-query-statistics.yaml
```
This will create a dashboard called "Query Statistics_New4" on Grafana

<!--

Open file vllm-dashboard.json by double clicking (file is located under : /home/participant/environment/eks/genai/observability/)

Select all - Copy content.


Click Dashboards -- > New -- > Import -- > paste above copied json -- > click Load -- > Click Import  -->

This should load vLLM dashboard with metrics.
