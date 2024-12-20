---
title : "Use Dynamic Provisioning to deploy a new PV and FSx Lustre instance for testing"
weight : 422
---

In the previous module you learnt how you can use Static Provisioning with an existing storage entity (created by an admin) to create a Persistent Volume and Claim. In this section you will learn how a user can use the CSI driver and its Dynamic Provisioning feature, to deploy an on-demand Persistent Volume and Claim, which also creates the associated FSx Lustre instance on the backend (no admin pre-provisioning required). You will create the definitions for the StorageClass, PersistentVolume and PersistentVolumeClaims, to highlight the difference between Static and Dynamic provisioning, where you will use this Persistent Volume for some testing in this lab section.


#### Step 1: Define the StorageClass

In the following steps you will be using the below environment variables,so lets set them. Copy and paste the below into your VSCode IDE Terminal.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)
SUBNET_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.subnetIds[0]" --output text)
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=${VPC_ID} Name=group-name,Values="FSxLSecurityGroup01"  --query "SecurityGroups[*].GroupId" --output text)  
:::

1. Let's see the outputs of a few of these variables. Here you can see the S3 bucket we are going to link to the new FSx for Lustre Instance that we will deploy using Dynamic Provisioning.


:::code[]{language=bash showLineNumbers=true showCopyAction=true}
echo $SUBNET_ID
echo $SECURITY_GROUP_ID
:::

2. Change to the right working directory so the lab commands work.

::code[cd /home/participant/environment/eks/FSxL]{language=bash showLineNumbers=false showCopyAction=true}


Below is the output of the `fsxL-storage-class.yaml` file. This file has the StorageClass definition that we will use with the CSI driver to dynamically provision a Persistent Volume Claim (PVC) from FSx for Lustre. Take a moment inspect the parameters shown, which you can configure an FSx for Lustre Instance that will be provisioned by the CSI driver.

**Note:** Did you notice there is no **storage** capacity value here, or **accessModes**? You will actually define how much storage capacity you need in your subsequent PersistentVolumeClaim request, along with your access mode required by the PoD for the Persistent Volume.

:::code[]{language=yaml showLineNumbers=true showCopyAction=false}
# fsxL-storage-class.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
    name: fsx-lustre-sc
provisioner: fsx.csi.aws.com
parameters:
  subnetId: SUBNET_ID
  securityGroupIds: SECURITY_GROUP_ID
  deploymentType: SCRATCH_2
  fileSystemTypeVersion: "2.15"
mountOptions:
  - flock
:::

 Run the below command, to replace the placeholder values in the `fsxL-storage-class.yaml` file for `SUBNET_ID` and `SECURITY_GROUP_ID` with our actual environment values.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
sed -i'' -e "s/SUBNET_ID/$SUBNET_ID/g" fsxL-storage-class.yaml
sed -i'' -e "s/SECURITY_GROUP_ID/$SECURITY_GROUP_ID/g" fsxL-storage-class.yaml
:::

3. Lets inspect the fsxL-storage-class.yaml file, to verify the replaced values are correct.

::code[cat fsxL-storage-class.yaml]{language=bash showLineNumbers=false showCopyAction=true}

::::expand{header="Click to expand - Understanding the value fields in the fsxL-storage-class.yaml file"}

* **subnetId** – The subnet ID that the Amazon FSx for Lustre file system should be created in. Amazon FSx for Lustre is not supported in all Availability Zones. Open the Amazon FSx for Lustre console at `https://console.aws.amazon.com/fsx/` to confirm that the subnet that you want to use is in a supported Availability Zone. The subnet can include your nodes, or can be a different subnet or VPC. If the subnet that you specify is not the same subnet that you have nodes in, then your VPCs must be connected, and you must ensure that you have the necessary ports open in your security groups.

* **securityGroupIds** – The security group ID for your nodes.

* **s3ImportPath** – The Amazon Simple Storage Service data repository that you want to copy data from to the persistent volume.

* **s3ExportPath** – The Amazon S3 data repository that you want to export new or modified files to.

* **deploymentType** – The file system deployment type. Valid values are SCRATCH_1, SCRATCH_2, and PERSISTENT_1. For more information about deployment types, see Create your Amazon FSx for Lustre file system.

* **autoImportPolicy** - the policy FSx will follow that determines how the filesystem is automatically updated with changes made in the linked data repository. For a list of acceptable policies, please view the [official FSx for Lustre documentation](https://docs.aws.amazon.com/fsx/latest/APIReference/API_CreateFileSystemLustreConfiguration.html)

* **perUnitStorageThroughput** - for deployment type PERSISTENT_1, customer can specify the storage throughput. Default: "200". Note that customer has to specify as a string here like "200" or "100" etc.

::::

:::alert{header="Note:" type="info"}
The Amazon S3 bucket for s3ImportPath and s3ExportPath must be the same, otherwise the driver cannot create the Amazon FSx for Lustre file system. The s3ImportPath can stand alone. A random path will be created automatically like s3://ml-training-data-000/FSxLustre20190308T012310Z. The s3ExportPath cannot be used without specifying a value for S3ImportPath.
:::

#### Step 2: Create the StorageClass

Copy and run the below command to apply the defined settings from the step 1. This will create the storageclass.

::code[kubectl apply -f fsxL-storage-class.yaml]{language=bash showLineNumbers=false showCopyAction=true}

Copy and run the below command to verify the StorageClass was created.

::code[kubectl get sc]{language=bash showLineNumbers=false showCopyAction=true}

::::expand{header="You should see the results as below, click to expand"}

:::code[]{language=bash showLineNumbers=false showCopyAction=false}
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
fsx-lustre-sc          fsx.csi.aws.com         Delete          Immediate              false                  23s
(...)
:::

::::

#### Step 3. Create the Persistent Volume Claim (PVC)

In this step you will create the persistent volume claim for the storageclass you defined earlier.

1. Run the below command and you will see the following output as shown below.

::code[cat fsxL-dynamic-claim.yaml]{language=bash showLineNumbers=false showCopyAction=true}

:::code[]{language=yaml showLineNumbers=true showCopyAction=false}
# fsxL-dynamic-claim.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fsx-lustre-dynamic-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: fsx-lustre-sc
  resources:
    requests:
      storage: 1200Gi
:::

::alert[Observe the `fsxL-dynamic-claim.yaml`, is referring to the `fsx-lustre-sc` storage class that you created. You will use this file to provision the claim for FSx for Lustre storage, where you are request a 1200GiB PVC of **storage**, which will create a 1200GiB FSx for Lustre Instance for your using Dynamic Provisioning.]


2. Create the PersistentVolumeClaim (PVC) request.

Copy and run the below command to apply and create the PVC.

::code[kubectl apply -f fsxL-dynamic-claim.yaml]{language=bash showLineNumbers=false showCopyAction=true}


3. To check the status of the PVC from the cli with the below command.

::code[kubectl describe pvc/fsx-lustre-dynamic-claim]{language=bash showLineNumbers=false showCopyAction=true}

4. Lets check that status of the PVC request. You can see the PVC claim you just requested for "fsx-lustre-dynamic-claim" is in a pending state, where it is bound to the fsx-lustre-sc StorageClass you created earlier.

::code[kubectl get pvc]{language=bash showLineNumbers=false showCopyAction=true}


![dynamic_provisioning_pvc](/static/images/dynamic_provisioning_pvc.png)


::alert[The Dynamic Provisioning operation to create a new FSx for Lustre instance and PV will take approx. 15 mins. The STATUS may show as Pending for up to 15 minutes, before changing to Bound. DO NOT continue to the next module of performance testing until the STATUS is Bound.]{header="Note:" type="info"}


#### Step 4: Confirm that the FSx Lustre instance has been provisioned, and PVC is bound

After waiting approx. 15 mins, copy and run the below command to check the status of the PVC to confirm the status is "Bound".

::code[kubectl get pvc]{language=bash showLineNumbers=false showCopyAction=true}


**Sample output**

:::code[]{language=bash showLineNumbers=false showCopyAction=false}
NAME                       STATUS   VOLUME                                 CAPACITY   ACCESS MODES   STORAGECLASS          AGE
fsx-lustre-dynamic-claim   Bound    pvc-15dXXXXXX-11ea-a836-02468c18769e   1200Gi     RWX            fsx-lustre-sc         7m37s
(...)
:::



::::expand{header="If you see the below output, it means that your volume creation is not expected to have issues. Otherwise, there might be problems that you need to troubleshoot, click to expand"}

:::code[]{language=yaml showLineNumbers=true showCopyAction=false}
Name:          fsx-lustre-claim
Namespace:     default
StorageClass:  fsx-lustre-sc
Status:        Pending
Volume:        
Labels:        <none>
(...)
  Type    Reason                Age               From                                                                                                Message
  ----    ------                ----              ----                                                                                                -------
  Normal  Provisioning          59s               fsx.csi.aws.com_ip-10-0-1-184.ap-southeast-2.compute.internal_2e634ffa-c57c-481e-9c04-dbb0142f81d1  External provisioner is provisioning volume for claim "default/fsx-lustre-claim"
  Normal  ExternalProvisioning  1s (x5 over 59s)  persistentvolume-controller                                                                         waiting for a volume to be created, either by external provisioner "fsx.csi.aws.com" or manually created by system administrator
:::

::::




:::alert[If you see some warning under Events like below, this is because FSx for Lustre filesystem is getting created.]{header="Note:" type="info"}

```
Warning ProvisioningFailed 4m45s fsx.csi.aws.com_XXXXXXXX failed to provision volume with StorageClass "fsx-lustre-sc": rpc error: code = DeadlineExceeded desc = context deadline exceeded
```
:::

-  You can also check the status and details of the Amazon FSx for lustre filesystem by navigating to the [Amazon FSx console](https://console.aws.amazon.com/fsx/).

Below is an image form the Amazon FSx console, showing an FSx instance and its details. Note that the Status will change from Creating to Available when its ready for use.

![FSxL_provisioning](/static/images/FSxL_Provisioning.png)




## Summary
In this section you have successfully used Dynamic Provisioning to create a new PV and its associated FSx for Lustre file that is linked to an Amazon S3 bucket. You have created a StoragClass definition to use FSx for Lustre for your Persistent Volumes, and created a Persistent Volume Claim to enable a Pod to access to your created Persistent Volume. In the next lab section, you will use this PV with a new Pod that you will deploy for performance testing of the FSx Lustre Instance.
