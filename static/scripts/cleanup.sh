#! /bin/bash

rm -vf ${HOME}/.aws/credentials
aws sts get-caller-identity
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
export CLUSTER_NAME=eksworkshop
echo $AWS_REGION
echo $CLUSTER_NAME
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
cd /home/participant/environment/eks/FSxL
rm fsx-csi-driver.json

cd /home/participant/environment/eks/genai

kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/k8s-neuron-device-plugin-rbac.yml
kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/k8s-neuron-device-plugin.yml

kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/k8s-neuron-scheduler-eks.yml
kubectl delete -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/master/src/k8/my-scheduler.yml

kubectl delete -f mistral-fsxl.yaml
kubectl delete -f open-webui.yaml
kubectl delete -f inferentia_nodepool.yaml 
kubectl get nodepool,ec2nodeclass 

kubectl get ing

cd /home/participant/environment/eks/FSxL
kubectl delete sa fsx-csi-controller-sa
kubectl delete -f fsxL-claim.yaml
kubectl delete -f fsxL-persistent-volume.yaml

cd /home/participant/environment/download
kubectl delete -f check.yaml
kubeclt delete deploy sysprep-check
kubectl delete pvc fsx-lustre-claim-check 
kubectl delete pv fsx-pv-check 

kubectl delete -f sysprep.yaml
kubectl delete job sysprep
kubectl delete pvc fsx-lustre-claim-sysprep 
kubectl delete pv fsx-pv-sysprep 

kubectl delete -f sysprep-nodepool.yaml

kubectl get pv,pvc
kubectl delete -k "github.com/kubernetes-sigs/aws-fsx-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.2"
rm -rf /home/participant/environment/eks/download