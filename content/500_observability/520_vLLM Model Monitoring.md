---
title : "vLLM Model Monitoring"
weight : 520
---

## vLLM Model Monitoring





##### Deploy Service Monitor to scrape metrics

Now deploy serviceMonitor configuration so that prometheus can scrape metrics from mistral service endpoint.

```bash
cd /home/participant/environment/eks/genai/observability/
kubectl apply -f vllm-servicemonitor.yaml

```

##### Deploy Dashboard 

```bash
kubectl apply -f vllm-dashboard-configmap.yaml
```
Look for "vLLM Mistral 7B Monitoring" Dashboard on Grafana

##### Other Experimental Dashboards: 
```bash
kubectl apply -f vllm-dashboard-configmap-v2.yaml
```

Look for "vLLM Mistral 7B Monitoring - v2" Dashboard on Grafana

```bash
kubectl apply -f vllm-performance-dashboard.yaml
```
Look for "Performance Statistics" Dashboard on Grafana

```bash
kubectl apply -f vllm-query-statistics.yaml
```
Look for "Query Statistics_New4" Dashboard on Grafana


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

# Show credentials
Open loadbalancer url and username and password from following output. 

```bash
echo "Grafana URL: http://$GRAFANA_URL"
echo "Username: admin"
echo "Password: $GRAFANA_PASSWORD"
```




<!-- 

Open file vllm-dashboard.json by double clicking (file is located under : /home/participant/environment/eks/genai/observability/)

Select all - Copy content. 


Click Dashboards -- > New -- > Import -- > paste above copied json -- > click Load -- > Click Import  -->

This should load vLLM dashboard with metrics.

