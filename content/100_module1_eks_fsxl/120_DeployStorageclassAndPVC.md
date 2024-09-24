---
title : "Deploy storage class and persistent volume claim"
weight : 120
---
-------------------------------------------------------------
In this section you will define the storageclass variables and create the storageclass for Amazon FSx for Lustre. Later you will create the persistent volume claim (PVC) and deploy the storage class. Observe the FSx for lustre file system is being auto provisioned. Kindly follow the below steps.

### Two modes for persistent storage
* STatic Provisioning -  Storeage/Eks admin controls the lifecycle of the persistent volume and its data. The admin creates a PV (i.e. creates a FSxL instance and configures the PV details on EKS), and then provides these details for the DevOPS so they can make a claim for this PV in their PoD using PVC.
* Dynamic Provisioning - the DevOps requests for the creation of the PV (new FSx instance) and PVC in one flow. Doesnt require separate process for STorage/EKS admin to create for them. They control the lifecycle of the Persistent volume data.
  **XYZ

* In this workshop we have already provisioned a configured a PV using Static provisioning (this is )  Follow the below instructions to learn how you can create a PV (which will create a new FSxL instance) and request a PVC (for your Pod to use) all in one flow using Dynamic provisioning. 




### Static Provisioning
In most cases EKS Cluster Adminstrators preprovision FSx Lustre fielsystem and create Persistent Volume for the developer teams to consume FSx Lustre storage, we are going to use this approach to speed up the process. If you like to experience Dynamic provisioning then you can follow steps in second half of this page.

```bash
FSXL_VOLUME_ID=aws fsx describe-file-systems --query 'FileSystems[].FileSystemId' --output text
DNS_NAME=aws fsx describe-file-systems --query 'FileSystems[].DNSName' --output text
MOUNT_NAME=aws fsx describe-file-systems --query 'FileSystems[].LustreConfiguration.MountName' --output text 
```

#### Step 1: Create the PersistentVolume
We are going to replace these values in the PersistentVolume below :

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

Replace values : 

```bash
sed -i'' -e "s/FSXL_VOLUME_ID/$FSXL_VOLUME_ID/g" fsxL-persistent-volume.yaml
sed -i'' -e "s/DNS_NAME/$DNS_NAME/g" fsxL-persistent-volume.yaml
sed -i'' -e "s/MOUNT_NAME/$MOUNT_NAME/g" fsxL-persistent-volume.yaml
```

Verify replaced values are correct.

```bash
cat fsxL-persistent-volume.yaml
```

#### Step 2: Create the PersistentVolumeClaim

We are using following PersistentVolumeClaim to bound with above PersistentVolume, Note that we are not using storage class name here and directly referencing pre-provisioned PersistentVolume.

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

```bash
kubectl apply -f fsxL-claim.yaml
```

We will be using this PersistentVolumeClaim in next module when we deploy mistral application.

[ Now you can continue to next module to deploy mistral model and chat bot ]


### Dynamic Provisioning 
#### Step 1: Define the storageclass

In the following steps you will be using the following environment variables.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)
SUBNET_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.subnetIds[0]" --output text)
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=${VPC_ID} Name=group-name,Values="FSxLSecurityGroup01"  --query "SecurityGroups[*].GroupId" --output text)  
S3_TEST_BUCKET=$(aws s3 ls | grep fsx-lustre-test | awk '{print$3}')
:::

1. We already set following variables, Run the below command to verify the values for these variables.


:::code[]{language=bash showLineNumbers=true showCopyAction=true}
echo $SUBNET_ID
echo $SECURITY_GROUP_ID
echo $S3_TEST_BUCKET
:::

2. Go to the right working directory.

::code[cd /home/ec2-user/environment/eks/FSxL]{language=bash showLineNumbers=false showCopyAction=true}


Below is the output of the `fsxL-storage-class.yaml` file. This file has the StorageClass definition that we will use with the CSI driver to dynamically provision a Persistent Volume Claim (PVC) from Amazon FSx for Lustre. Take a moment inspect the available parameters which you can configure for the FSx for Lustre Instance that will be provisioned by the CSI driver.

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
    s3ImportPath: s3://S3_TEST_BUCKET
    s3ExportPath: s3://S3_TEST_BUCKET/export
    autoImportPolicy: NEW_CHANGED_DELETED
    deploymentType: SCRATCH_2
    fileSystemTypeVersion: "2.15"
mountOptions:
    - flock
:::

 Run the below command, to replace the placeholder values in the `fsxL-storage-class.yaml` file for `SUBNET_ID`, `SECURITY_GROUP_ID` and `S3_TEST_BUCKET` with our actual environment values.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
sed -i'' -e "s/SUBNET_ID/$SUBNET_ID/g" fsxL-storage-class.yaml
sed -i'' -e "s/SECURITY_GROUP_ID/$SECURITY_GROUP_ID/g" fsxL-storage-class.yaml
sed -i'' -e "s/S3_TEST_BUCKET/$S3_TEST_BUCKET/g" fsxL-storage-class.yaml
:::

3. Verify replaced values are correct.

::code[cat fsxL-storage-class.yaml]{language=bash showLineNumbers=false showCopyAction=true}

::::expand{header="Click to expand the section to understand the settings defined in the fsxL-storage-class.yaml file"}

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

#### Step 2: Create the storageclass

Copy and run the below command to apply the defined settings from the step 1. This will create the storageclass.

::code[kubectl apply -f fsxL-storage-class.yaml]{language=bash showLineNumbers=false showCopyAction=true}

Copy and run the below command to verify the storageclass is created.

::code[kubectl get sc]{language=bash showLineNumbers=false showCopyAction=true}

::::expand{header="You should see the results as below, click to expand"}

:::code[]{language=bash showLineNumbers=false showCopyAction=false}
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
fsx-lustre-sc          fsx.csi.aws.com         Delete          Immediate              false                  23s
(...)
:::

::::

#### Step 3. Create the persistent volume claim (PVC)

In this step you will create the persistent volume claim for the defined storageclass.


1. Run the below command and you will see the following output as shown below.

::code[cat fsxL-dynamic-claim.yaml]{language=bash showLineNumbers=false showCopyAction=true}


:::code[]{language=yaml showLineNumbers=true showCopyAction=false}
# fsxL-dynamic-claim.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fsx-lustre-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: fsx-lustre-sc
  resources:
    requests:
      storage: 1200Gi
:::

::alert[Observe the `fsxL-dynamic-claim.yaml`, which is referring to the `fsx-lustre-sc` storage class. You will use this file to provision the FSx for Lustre storage. you are configuring the 1200GiB PVC.]


2. Deploy the storageclass.

Copy and run the below command to apply and create the pvc.

::code[kubectl apply -f fsxL-dynamic-claim.yaml]{language=bash showLineNumbers=false showCopyAction=true}


3. To check the status of the pvc from the cli with the below command.

::code[kubectl describe pvc/fsx-lustre-claim]{language=bash showLineNumbers=false showCopyAction=true}

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

::alert[The STATUS may show as Pending for up to 15 minutes, before changing to Bound. Don’t continue with the next step until the STATUS is Bound.]{header="Note:" type="info"}


:::alert[If you see some warning under Events like below, this is because FSx for Lustre filesystem is getting created.]{header="Note:" type="info"}

```
Warning ProvisioningFailed 4m45s fsx.csi.aws.com_XXXXXXXX failed to provision volume with StorageClass "fsx-lustre-sc": rpc error: code = DeadlineExceeded desc = context deadline exceeded
```
:::

4. You can also check the status of the Amazon FSx for lustre filesystem from the AWS Console. Click the [link](https://console.aws.amazon.com/fsx/)

![FSxL_provisioning](/static/images/FSxL_Provisioning.png)

#### Step 4: Confirm that the file system is provisioned

Copy and run the below command to check the status of the pvc to confirm the status is "Bound".

::code[kubectl get pvc]{language=bash showLineNumbers=false showCopyAction=true}

**Sample output**

:::code[]{language=bash showLineNumbers=false showCopyAction=false}
NAME               STATUS   VOLUME                                 CAPACITY   ACCESS MODES   STORAGECLASS          AGE
fsx-lustre-claim   Bound    pvc-15dXXXXXX-11ea-a836-02468c18769e   1200Gi     RWX            fsx-lustre-sc         7m37s
(...)
:::


Once it is successfully created, you can see a new FSx for Lustre is displayed from [AWS FSx console](https://console.aws.amazon.com/fsx/) as below screenshot.

![FSxL_01](/static/images/FSxL_01.png)


## Summary

In this section you have successfully completed defining the storage class for Amazon FSx for Lustre file system with the deployment type and Amazon S3 bucket as the data repository for the file system. Created the storageclass and created the persistent volume claim which deployed the FSx for lustre filesystem with auto provisioning of volume. In the next section you will continue with the performance testing on the filesystem.
