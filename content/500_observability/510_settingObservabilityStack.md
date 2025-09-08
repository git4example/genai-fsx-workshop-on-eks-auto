---
title : "Setting up Observability stack for Neuron"
weight : 510
---

## Setting up Observability stack for Neuron


In this section, we'll install and explore the core components of our observability stack designed to monitor LLM inference workloads on Amazon EKS.
## Observability Stack Components

For monitoring LLM inference workloads, we will need to deploy several key components in the cluster for our observability stack:

#### Kube Prometheus Stack

The Kube Prometheus Stack provides a complete monitoring solution. Let's start by installing kube prometheus stack :


#### Install kube prometheus stack

The Kube Prometheus Stack provides a complete monitoring solution. Lets deploy it in our cluster.

Get the grafana password, which we are going to use during helm install.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
SECRET_NAME=$(aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `oss-grafana`)].Name' --output text)
GRAFANA_PASSWORD=$(aws secretsmanager get-secret-value \
    --secret-id $SECRET_NAME \
    --query 'SecretString' \
    --output text)
:::


:::code[]{language=bash showLineNumbers=true showCopyAction=true}
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
cd /home/participant/environment/eks/genai/observability/
:::



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


Check monitoring namespace for successful kube prometheus stack deployment and its components 
::code[kubectl get pods -n kube-system]{language=bash showLineNumbers=false showCopyAction=true}



Each component serves a specific purpose:
  - Prometheus Server: Central metrics collection and storage
  - Node Exporter: Collects hardware and OS metrics from each node (runs as DaemonSet)
  - Kube State Metrics: Generates metrics about Kubernetes objects
  - This includes Grafana setup, with Grafana server exposed via NLB



#### Check Prometheus deployment

::code[kubectl get pods -l "app.kubernetes.io/name=prometheus" -n kube-system]{language=bash showLineNumbers=false showCopyAction=true}

#### Check Node Exporter DaemonSet

::code[kubectl get pods -l "app.kubernetes.io/name=prometheus-node-exporter" -n kube-system]{language=bash showLineNumbers=false showCopyAction=true}

#### Check Kube State Metrics deployment

::code[kubectl get pods -l "app.kubernetes.io/name=kube-state-metrics" -n kube-system]{language=bash showLineNumbers=false showCopyAction=true}




#### Grafana Stack

Get grafana loadbalancer 
::code[kubectl get svc -n kube-system kube-prometheus-stack-grafana]{language=bash showLineNumbers=false showCopyAction=true}

```bash
NAME                            TYPE           CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)        AGE
kube-prometheus-stack-grafana   LoadBalancer   172.20.211.49   a0b4c567b25944afb889f19b945efad4-1467842165.us-west-2.elb.amazonaws.com   80:30387/TCP   18m
```

Open loadbalancer and use "admin" as username and password from following output. 

```bash
echo $GRAFANA_PASSWORD
```

### Conclusion

In this section, we have:

✅ Verified our existing monitoring stack components:

    Kube Prometheus Stack
    Grafana 
    Alert Manager
    Node Exporter
    Kube State Metrics



#### Next Steps

In the following sections, we will:

    Configure Grafana dashboards for Neuron monitoring
    Learn how to monitor LLM inference workloads using these tools for both vLLM and Ray

You can now proceed to the next module to learn about setting up custom dashboards for monitoring your GPU workloads.






# Following is still work in progress. Go to next page to setup model monitoring.


### Grafana operator 

h

#### Install Grafana Operator using Helm (run this command separately)
:::code[]{language=bash showLineNumbers=false showCopyAction=true}
 helm upgrade -i grafana-operator oci://ghcr.io/grafana/helm-charts/grafana-operator \
   --version v5.18.0 \
   --namespace kube-system
:::




```bash
cat << EOF | kubectl apply -f -
apiVersion: grafana.integreatly.org/v1beta1
kind: Grafana
metadata:
  name: grafana-operator-instance
  namespace: monitoring
  labels:
    dashboards: "grafana"
spec:
  config:
    log:
      mode: "console"
      level: "info"
    security:
      admin_user: admin
      admin_password: "${GRAFANA_PASSWORD}"
    server:
      root_url: "http://localhost:3000"
    datasources:
      datasources.yaml:
        apiVersion: 1
        datasources:
          - name: Prometheus
            type: prometheus
            url: http://kube-prometheus-stack-prometheus:9090
            access: proxy
            isDefault: true
  service:
    metadata:
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    spec:
      type: LoadBalancer
      ports:
        - name: grafana
          port: 3000
          protocol: TCP
          targetPort: 3000
EOF
```


```bash
cat << EOF | kubectl apply -f -
apiVersion: grafana.integreatly.org/v1beta1
kind: Grafana
metadata:
  name: grafana
  namespace: monitoring
  labels:
    dashboards: "grafana"
spec:
  config:
    log:
      mode: "console"
    security:
      admin_user: admin
      admin_password: $GRAFANA_PASSWORD
EOF
```



Our Grafana setup includes both the Grafana server and Grafana Operator to provision Dashboards using YAML files:

Check Grafana Server deployment

::code[kubectl get pods -l "app.kubernetes.io/name=grafana" -n kube-system]{language=bash showLineNumbers=false showCopyAction=true}


Check Grafana Operator deployment

::code[kubectl get pods -l "app.kubernetes.io/name=grafana-operator" -n kube-system]{language=bash showLineNumbers=false showCopyAction=true}


Grafana Operator

Grafana Operator is being used to create Grafana dashboards using custom resources. Use the following command to check the configuration:
::code[kubectl get Grafana external-grafana -n kube-system -o yaml]{language=bash showLineNumbers=false showCopyAction=true}



