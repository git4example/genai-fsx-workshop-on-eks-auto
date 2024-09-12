```bash
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: download-mistral
spec:  
  template:
    metadata:
      labels:
        app: download-mistral
    spec:
      serviceAccountName: s3-upload
      nodeSelector:
        karpenter.sh/nodepool: download
      restartPolicy: OnFailure
      containers:
      - name: download
        image: hello2parikshit/s5cmd
        args:
        - sync 
        - s3://$S3_BUCKET/
        - /work-di/Mistral-7B-Instruct-v0.2
        volumeMounts:
        - name: workdir
          mountPath: "/work-dir"
      volumes:
      - name: workdir
        hostPath:
          path: /work-dir
          type: DirectoryOrCreate 
EOF
```