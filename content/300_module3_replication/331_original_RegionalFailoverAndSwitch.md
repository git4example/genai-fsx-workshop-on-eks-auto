---
title : "Temp page"
weight : 331
Hidden : "true"
---
-------------------------------------------------------------





### Step 2: Login to the container and manually sync the changes to S3 bucket

Copy and run the below command to login to the container

::code[kubectl exec -it fsx-app -- bash]{language=bash showLineNumbers=false showCopyAction=true}

Archive the data from the FSx for Luster file system into the linked S3 bucket. Run the below commands to manually export the file to the linked S3 bucket

::alert[lfs is a helper utility to administrate lustre cluster]

::code[lfs hsm_archive /data/out.txt]{language=bash showLineNumbers=false showCopyAction=true}

Type "exit" to exit the container
::code[exit]{language=bash showLineNumbers=false showCopyAction=true}

:::alert{header="Note:" type="info"}
New created files won't be synced back to S3 automatically. In order to sync files to s3ExportPath, you need to install lustre client in your container image and manually run following command to force sync up using `lfs hsm_archive`. And the container should run in `privileged` mode with `CAP_SYS_ADMIN capability`.**
:::

### Step 3: Check both the Source S3 bucket and the Destination S3 Bucket

Copy and run the below command from the cli to Look for the s3 bucket name

::code[aws s3 ls]{language=bash showLineNumbers=false showCopyAction=true}

Copy and run the below command to Check the out.txt are in both s3 buckets.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
aws s3 ls s3://$S3_BUCKET/export/
aws s3 ls s3://$S3_BUCKET_2NDREGION/export/
:::

You should be able to see that both S3 buckets have the `out.txt` file

::alert[This could take upto 10 minutes (???? NEED TO FIGURE OUT TIME HERE ???) for both buckets to show, because we also have Mistral model stored on the bucket which will take increased time to replicate for first time]


# [ We need to remove following steps 4 - 7 as we dont have EKS cluster in 2nd region for this workshop ]


### Step 4: Check the file is synced in the new EKS cluster in 2nd region

Run the below command to switch your kube config to the EKS Cluster in region 2nd Region (i.e. `us-east-2`)

::code[aws eks update-kubeconfig --name $CLUSTER_NAME_2 --region $REGION_2]{language=bash showLineNumbers=false showCopyAction=true}

Check your nodes are running on the cluster

::code[kubectl get nodes]{language=bash showLineNumbers=false showCopyAction=true}

### Step 5: Validate the PVC

:::alert{header="Note" type="info"}
For AWS Sponsored Workshop, the second region PVC **fsx-lustre-claim** is pre-created for you
:::

Run the below command to check the pvc status

::code[kubectl get pvc]{language=bash showLineNumbers=false showCopyAction=true}

::::expand{header="You should see the results as below, click to expand"}

:::code[]{language=bash showLineNumbers=false showCopyAction=false}
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
fsx-lustre-claim   Bound    pvc-CCCCCC----02468c18769e   1200Gi     RWX            fsx-lustre-sc         7m37s
:::

::::

You can see the new filesystem is displayed from AWS FSx console

::alert[This should be in the **us-east-2** region in the AWS Console]

![FSxL_01](/static/images/FSxL_01.png)

### Step 6: Now let's deploy the pod

Copy and run the below command to deploy the pod.

::code[kubectl apply -f pod.yaml]{language=bash showLineNumbers=false showCopyAction=true}

### Step 7. Logon to the container to see the `out.txt` is it available for use.

Run the below command to Logon to the container.

::code[kubectl exec -it fsx-app -- bash]{language=bash showLineNumbers=false showCopyAction=true}

Run the below command to verify that the file is available and all the contents are correct.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
ls -ltr /data/export/
tail -f /data/export/out.txt
:::

Type `ctrl+c` to exit the "tail" command

Type "exit" to exit the container
::code[exit]{language=bash showLineNumbers=false showCopyAction=true}

## Summary

In this section, you manged to validate the cross region replication of data available for two different EKS clusters in less than a minute. Congratulations, You have sucessfully completed this module.
