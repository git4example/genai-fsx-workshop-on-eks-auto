#! /bin/bash

rm -vf ${HOME}/.aws/credentials
aws sts get-caller-identity

export CLUSTER_NAME=eksworkshop
echo $AWS_REGION
echo $CLUSTER_NAME
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION


rm fsx-csi-driver.json

cd /home/participant/environment/eks/genai

helm uninstall -n kube-system neuron-helm-chart

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

kubectl get pv,pvc
helm uninstall -n kube-system aws-fsx-csi-driver 
rm -rf /home/participant/environment/eks/download