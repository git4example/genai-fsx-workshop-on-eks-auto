---
title : "Configuring Neuron Monitoring Dashboard"
weight : 530
---
# Following is still work in progress. Go to next page to setup model monitoring.

Configuring Neuron Monitoring Dashboard




Configuring Neuron Monitor

Neuron Monitor runs on AWS Neuron-enabled instances to collect and expose hardware metrics (like utilization, memory usage, and temperature) from AWS Inferentia and Trainium chips through a Prometheus-compatible endpoint for monitoring and optimization of ML workloads. Let's deploy neuron monitor DaemonSet to expose these metrics to Prometheus using ServiceMonitor:

```bash
cat <<EOF > neuron-monitor.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: neuron-monitor
  namespace: kube-system
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
        karpenter.sh/nodepool: inferentia
        eks.amazonaws.com/instance-family: inf2
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
  namespace: kube-system
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
  namespace: kube-system
  labels:
    release: kube-prometheus-stack
spec:
  namespaceSelector:
    matchNames:
      - kube-system
  selector:
    matchLabels:
      app: neuron-monitor
  endpoints:
    - port: metrics
      interval: 30s
      path: /metrics
      scheme: http
EOF
```

```bash
kubectl apply -f neuron-monitor.yaml

```


```bash
kubectl apply -f neuron-monitoring-configmap.yaml 
```

Verify dashboard on grafana "AWS Neuron Hardware Monitoring (ConfigMap)" 



✅ Successfully installed Neuron Monitor:

    Configured it to run only on Inferantia nodes
    Added proper node selectors and tolerations
    Enabled Prometheus ServiceMonitor integration




✅ Confirmed Neuron metrics collection:

    Verified Neuron Monitor daemon set deployment
    Accessed the metrics endpoint
    Validated Neuron telemetry data