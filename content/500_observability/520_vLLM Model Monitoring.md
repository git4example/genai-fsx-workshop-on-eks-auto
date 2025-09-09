---
title : "vLLM Model Monitoring"
weight : 520
---

vLLM Model Monitoring


### Deploy Service Monitor to scrape metrics

Now deploy serviceMonitor configuration so that prometheus can scrape metrics from mistral service endpoint.

```bash
kubectl apply -f vllm-servicemonitor.yaml

```



### Deploy Dashboard 

```bash
cd /home/participant/environment/eks/genai/observability/
kubectl apply -f vllm-dashboard-configmap.yaml
```

# Get LoadBalancer URL
```bash
GRAFANA_URL=$(kubectl get svc -n kube-system kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```


# Show credentials
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

