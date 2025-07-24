#!/bin/bash
terraform --version

echo "Creating FSx Lustre Bucket"
terraform apply -target="module.fsx-lustre-bucket" -auto-approve 

# Create VPC
echo '=== Create VPC for EKS Cluster ==='
terraform apply -target="module.vpc" --auto-approve 


# Create EKS Cluster and FSx Filesystem
echo '=== Create EKS Cluster and FSx Filesystem ==='
terraform apply -target="aws_fsx_lustre_file_system.fsx_lustre" -target="module.eks" --auto-approve


echo "Applying Terraform configuration..."
terraform apply --auto-approve





echo "Running sysprep job"
terraform apply -var="create_one_off_job=true" --auto-approve

echo "Deleting FSx Lustre sysprep resources...Deleting sysprep sysprep job, pv, pvc and fsx csi driver"

echo "Deleting with create_one_off_job=false --> kubernetes_job.sysprep, kubectl_manifest.sysprep_pvc, kubectl_manifest.sysprep_pv, helm_release.fsx_csi_driver..."
terraform apply -var="create_one_off_job=false" --auto-approve 

echo "Cleanup completed."