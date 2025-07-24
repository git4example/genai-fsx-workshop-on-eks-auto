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

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
:::

#### Create namespace
::code[kubectl create namespace monitoring]{language=bash showLineNumbers=false showCopyAction=true}


#### Basic install
:::code[]{language=bash showLineNumbers=true showCopyAction=true}
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --version 75.13.0 \
    --set grafana.adminPassword=your-secure-password
:::

::code[kubectl get pods -n monitoring]{language=bash showLineNumbers=false showCopyAction=true}



Each component serves a specific purpose:
  - Prometheus Server: Central metrics collection and storage
  - Node Exporter: Collects hardware and OS metrics from each node (runs as DaemonSet)
  - Kube State Metrics: Generates metrics about Kubernetes objects

#### Check Prometheus deployment

::code[kubectl get pods -l "app.kubernetes.io/name=prometheus" -n monitoring]{language=bash showLineNumbers=false showCopyAction=true}

#### Check Node Exporter DaemonSet

::code[kubectl get pods -l "app.kubernetes.io/name=prometheus-node-exporter" -n monitoring]{language=bash showLineNumbers=false showCopyAction=true}

#### Check Kube State Metrics deployment

::code[kubectl get pods -l "app.kubernetes.io/name=kube-state-metrics" -n monitoring]{language=bash showLineNumbers=false showCopyAction=true}




# Grafana Stack


Our Grafana setup includes both the Grafana server and Grafana Operator to provision Dashboards using YAML files:

    Check Grafana Server deployment


kubectl get pods -l "app.kubernetes.io/name=grafana" -n monitoring

    Check Grafana Operator deployment


kubectl get pods -l "app.kubernetes.io/name=grafana-operator" -n monitoring

Grafana Operator

Grafana Operator is being used to create Grafana dashboards using custom resources. Use the following command to check the configuration:


kubectl get Grafana external-grafana -n monitoring -o yaml

Configuring Neuron Monitor

Neuron Monitor runs on AWS Neuron-enabled instances to collect and expose hardware metrics (like utilization, memory usage, and temperature) from AWS Inferentia and Trainium chips through a Prometheus-compatible endpoint for monitoring and optimization of ML workloads. Let's deploy neuron monitor DaemonSet to expose these metrics to Prometheus using ServiceMonitor:


cat <<EOF > neuron-monitor.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: neuron-monitor
  namespace: monitoring
  labels:
    app: neuron-monitor
spec:
  selector:
    matchLabels:
      app: neuron-monitor
  template:
    metadata:
      labels:
        app: neuron-monitor
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9010"
    spec:
      containers:
        - name: app
          image: public.ecr.aws/neuron/neuron-monitor:1.3.0
          command: ["/bin/sh"]
          args:
            - "-c"
            - "neuron-monitor | neuron-monitor-prometheus.py --port 9010"
          ports:
            - name: metrics
              containerPort: 9010
              hostPort: 9010
          resources:
            limits:
              cpu: 200m
              memory: 200Mi
            requests:
              cpu: 100m
              memory: 100Mi
          volumeMounts:
            - name: dev
              mountPath: /dev
          securityContext:
            privileged: true
      tolerations:
        - key: aws.amazon.com/neuron
          operator: Exists
          effect: NoSchedule
      nodeSelector:
        instanceType: trn1.2xlarge
        provisionerType: Karpenter
        neuron.amazonaws.com/neuron-device: "true"
      volumes:
        - name: dev
          hostPath:
            path: /dev
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/app-metrics: "true"
    prometheus.io/port: "9010"
  name: neuron-monitor
  namespace: monitoring
  labels:
    app: neuron-monitor
spec:
  clusterIP: None
  ports:
    - name: metrics
      port: 9010
      protocol: TCP
  selector:
    app: neuron-monitor
  type: ClusterIP
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: neuron-monitor
  namespace: monitoring
  labels:
    release: kube-prometheus-stack
spec:
  namespaceSelector:
    matchNames:
      - monitoring
  selector:
    matchLabels:
      app: neuron-monitor
  endpoints:
    - port: metrics
      interval: 30s
      path: /metrics
      scheme: http
EOF
kubectl apply -f neuron-monitor.yaml

Verify that neuron-monitor is collecting Neuron metrics correctly:

    Get the name of a neuron-monitor pod

1
2
3
NAME=$(kubectl get pods -l "app=neuron-monitor" \
                       -n monitoring \
                       -o "jsonpath={ .items[0].metadata.name}")

    Set up port forwarding to access the metrics endpoint

1
kubectl port-forward -n monitoring $NAME 9010:9010

    In another terminal, query the metrics endpoint

1
curl -sL http://127.0.0.1:9010/metrics

Conclusion

In this section, we have:

✅ Verified our existing monitoring stack components:

    Kube Prometheus Stack
    Grafana and Grafana Operator
    Alert Manager
    Node Exporter
    Kube State Metrics

✅ Successfully installed Neuron Monitor:

    Configured it to run only on Trainium nodes
    Added proper node selectors and tolerations
    Enabled Prometheus ServiceMonitor integration

✅ Confirmed Neuron metrics collection:

    Verified Neuron Monitor daemon set deployment
    Accessed the metrics endpoint
    Validated Neuron telemetry data

Next Steps

In the following sections, we will:

    Configure Grafana dashboards for Neuron monitoring
    Learn how to monitor LLM inference workloads using these tools for both vLLM and Ray

You can now proceed to the next module to learn about setting up custom dashboards for monitoring your GPU workloads.