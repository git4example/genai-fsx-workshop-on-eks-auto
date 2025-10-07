---
title : "Setting up observability stack"
weight : 510
---
### Overview

In this section, we'll install the core components for our observability stack, designed to monitor LLM inference workloads on Amazon EKS.

## Observability Stack Components

For monitoring LLM inference workloads, we will need to deploy several key components (as outlined below) in the cluster for our observability stack:

Each component serves a specific purpose:
  - Prometheus Server: Central metrics collection and storage
  - Node Exporter: Collects hardware and OS metrics from each node (runs as DaemonSet)
  - Kube State Metrics: Generates metrics about Kubernetes objects
  - This includes Grafana setup, with Grafana server exposed via NLB


#### Kube Prometheus Stack

The Kube Prometheus Stack provides a complete monitoring solution. Let's start by installing kube prometheus stack :


#### Install kube prometheus stack

The Kube Prometheus Stack provides a complete monitoring solution. Lets deploy it in our cluster.

1. Get the grafana password, which we are going to use during helm install.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
SECRET_NAME=$(aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `oss-grafana`)].Name' --output text)
GRAFANA_PASSWORD=$(aws secretsmanager get-secret-value \
    --secret-id $SECRET_NAME \
    --query 'SecretString' \
    --output text)
:::

2. Update helm repo

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
cd /home/participant/environment/eks/genai/observability/
:::


3. Install the kube prometheus stack

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace kube-system \
    --version 75.13.0 \
    -f kube-prom-stack.yaml \
    --set grafana.adminPassword=$GRAFANA_PASSWORD \
    --set grafana.service.type=LoadBalancer \
    --set grafana.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"=internet-facing \
    --set prometheus.service.type=LoadBalancer \
    --set prometheus.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"=internet-facing
:::


4. Check monitoring namespace for successful kube prometheus stack deployment and its components
::code[kubectl get pods -n kube-system]{language=bash showLineNumbers=false showCopyAction=true}





5. Check Prometheus deployment

::code[kubectl get pods -l "app.kubernetes.io/name=prometheus" -n kube-system]{language=bash showLineNumbers=false showCopyAction=true}

6. Check Node Exporter DaemonSet

::code[kubectl get pods -l "app.kubernetes.io/name=prometheus-node-exporter" -n kube-system]{language=bash showLineNumbers=false showCopyAction=true}

7. Check Kube State Metrics deployment

::code[kubectl get pods -l "app.kubernetes.io/name=kube-state-metrics" -n kube-system]{language=bash showLineNumbers=false showCopyAction=true}




### Conclusion

In this section, we have:

✅ Verified our existing monitoring stack components:

    Kube Prometheus Stack
    Grafana
    Alert Manager
    Node Exporter
    Kube State Metrics



#### Next Steps

In the next sections, you will Learn how to monitor LLM inference workloads using configure Grafana dashboards for vLLM and Neuron monitoring

You can now proceed to the next module to learn about setting up custom dashboards for monitoring your Inference workloads.
