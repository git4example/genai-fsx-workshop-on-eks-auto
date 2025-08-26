---
title : "vLLM Model Monitoring"
weight : 520
---

vLLM Model Monitoring


### Deploy serviceMonitor 

Now deploy serviceMonitor configuration so that prometheus can scrape metrics from mistral service endpoint.

```bash
cat << EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: vllm-mistral-servicemonitor
  namespace: monitoring
  labels:
    release: kube-prometheus-stack   # Make sure this matches the Prometheus release label selector
    app: vllm-mistral-inf2-server
spec:
  selector:
    matchLabels:
      app: vllm-mistral-inf2-server    # Label on your Kubernetes service
  namespaceSelector:
    matchNames:
      - default          # Namespace where your service is running
  endpoints:
  - port: http    # The port name exposed by your service for metrics
    path: /metrics        # Metrics endpoint path
    interval: 15s         # Scrape interval
EOF
```



### Deploy Dashboard 

Open file vllm-dashboard.json by double clicking (file is located under : /home/participant/environment/eks/genai/observability/)

Select all - Copy content. 


Click Dashboards -- > New -- > Import -- > paste above copied json -- > click Load -- > Click Import 

This should load vLLM dashboard with metrics.

