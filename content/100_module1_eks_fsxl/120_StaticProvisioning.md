---
title : "Create Persistent Volume on EKS Cluster"
weight : 120
---
-------------------------------------------------------------


### Two methods for creating Persistent Volumes
- **Static Provisioning** -  The admin creates the backend storage entity, creates the PV, and the user makes a claim (PVC) for this PV to be used in their Pod(s).

- **Dynamic Provisioning** - The user requests a PVC, and a PV (and its backed storage entity) is automatically created by the CSI driver based on the users requirements. This method doesn't require a separate process for an admin to pre-create


In this lab section, we will use the **Static Provisioning** method for Persistent Volumes (PV), where we have already provisioned an FSx for Lustre Instance for you to use in this workshop, which is linked to an Amazon S3 bucket that is hosting the Mistral-7B model. You will now create the Persistent Volume definition and also create a Persistent Volume Claim to that FSx for Lustre instance, so that you can use this storage volume within the vLLM Pod (that you will deploy in this workshop) to access the Mistral-7B model data.


Run the below command to change to the correct working directly, so you can run the commands for this exercise

::code[cd /home/participant/environment/eks/FSxL]{language=bash showLineNumbers=false showCopyAction=true}

Run the below commands in your VSCode IDE terminal to populated the variables with the FSx Lustre Instance details (that we have pre-created for you)

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
FSXL_VOLUME_ID=$(aws fsx describe-file-systems --query 'FileSystems[].FileSystemId' --output text)
DNS_NAME=$(aws fsx describe-file-systems --query 'FileSystems[].DNSName' --output text)
MOUNT_NAME=$(aws fsx describe-file-systems --query 'FileSystems[].LustreConfiguration.MountName' --output text)
:::

##### Step 1: Create the Persistent Volume

Lets take a look at a Persistent Volume (PV) yaml file definition (fsxL-persistent-volume.yaml) that has our placeholder variables in it. We have already created a 1200GiB FSx for Lustre instance for this workshop.So in this Persistent Volume definition, you will simply configure that 1200GiB FSx for Lustre instance to register as an EKS Cluster resource using a name of 'fsx-pv'.

:::code[]{language=yaml showLineNumbers=true showCopyAction=false}
# fsxL-persistent-volume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: fsx-pv
spec:
  persistentVolumeReclaimPolicy: Retain
  capacity:
    storage: 1200Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  mountOptions:
    - flock
  csi:
    driver: fsx.csi.aws.com
    volumeHandle: FSXL_VOLUME_ID
    volumeAttributes:
      dnsname: DNS_NAME
      mountname: MOUNT_NAME
:::

Run the below commands to replace `FSXL_VOLUME_ID`,  `DNS_NAME`,  and `MOUNT_NAME` with the actual values of the FSx Lustre instance.


:::code[]{language=bash showLineNumbers=true showCopyAction=true}
sed -i'' -e "s/FSXL_VOLUME_ID/$FSXL_VOLUME_ID/g" fsxL-persistent-volume.yaml
sed -i'' -e "s/DNS_NAME/$DNS_NAME/g" fsxL-persistent-volume.yaml
sed -i'' -e "s/MOUNT_NAME/$MOUNT_NAME/g" fsxL-persistent-volume.yaml
:::

You can view the output of the Persistent Volume definition with our FSx instance details. You can see we have created a 1200GiB FSx for Lustre file system for you, and its Instance ID and DNS Name.

::code[cat fsxL-persistent-volume.yaml]{language=bash showLineNumbers=false showCopyAction=true}


Let's create the PersistentVolume (PV) configuration for the FSx for Lustre instance in this EKS cluster:

::code[kubectl apply -f fsxL-persistent-volume.yaml]{language=bash showLineNumbers=false showCopyAction=true}

Check the PV called "fsx-pv" is created

::code[kubectl get pv]{language=bash showLineNumbers=false showCopyAction=true}

##### Step 2: Create the PersistentVolumeClaim

We will now create a PersistentVolumeClaim (PVC) to bind with the PersistentVolume definition that we defined in the previous step. Note that we are directly referencing the pre-provisioned PersistentVolume using the **volumeName** value of **fsx-pv**:  Below is contents of the PVC claim file (fsxL-claim.yaml) that we will deploy.

:::code[]{language=yaml showLineNumbers=true showCopyAction=false}
# fsxL-claim.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fsx-lustre-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  resources:
    requests:
      storage: 1200Gi
  volumeName: fsx-pv
:::

Deploy this PersistentVolumeClaim to the EKS cluster:

::code[kubectl apply -f fsxL-claim.yaml]{language=bash showLineNumbers=false showCopyAction=true}

Run the below command to verify that the PersistentVolumeClaim that we made, is bound to the PersistentVolume of **fsx-pv** that we defined. In the output you can see that the **persistentvolumeclaim/fsx-lustre-claim** is showing as bound to the **Volume** of **fsx-pv**
::code[kubectl get pv,pvc]{language=bash showLineNumbers=false showCopyAction=true}

## Summary

In this section you have successfully configured the PersistentVolume, and created the PersistentVolumeClaim that will be used by the vLLM to access the Mistral-7B application.
