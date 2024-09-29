---
title : "Generate test files in EKS Pod, to replicate data between AWS Regions"
weight : 330

---

### IN THIS SECTION - we will show customers how they can replicate data using S3 replication, and view it at their target S3bucket. We will not get them to deploy another FSxL file system and Pod to access it,  (not good use of time).. we will state they can achieve sharing data or DR in a different region, by follow the instructions from module 1 (deploy FSxL) & 2 (deploy GenAI app) along with deploying their EKS cluster.


In this section, you will be performing a cross region replication of data between the Amazon S3 bucket. Which will enable the data movement from one EKS cluster to the other EKS cluster in `us-east-2`. To complete this section you will deploy the pod in the current region and sync the data between the regions. Deploy the pod to read the replicated data from the persistent storage layer of Amazon FSx for Lustre file system running in `us-east-2`. Let's start

### Step 1: Deploy the pod for the experiment in the EKS cluster in your current region

- Check if region and cluster names are set correctly, if not then follow one of the suitable page for your situation under **[Getting Started ](/020-setup)** to setup these variables.



Go to the right working directory.

::code[cd /home/ec2-user/environment/eks/FSxL]{language=bash showLineNumbers=false showCopyAction=true}

now lets log into the vLLM Pod, first we need to get the pod name by running the following command

::code[Kubectl get pods]{language=bash showLineNumbers=false showCopyAction=true}

From the output copy the name shown in your environment that starts with **vllm**

![vllm_name](/static/images/vllm_name.png)

Replace the **<YOUR-vLLM-POD-NAME>** value with the value you just copied, and run the below command to log into your vLLM pod.

::code[kubectl exec -it <YOUR-vLLM-POD-NAME> -- bash]{language=bash showLineNumbers=false showCopyAction=true}

Run the following commands

:::code{showCopyAction=true showLineNumbers=true language=bash}
rm /work-dir/pre-warm.txt
df -h
:::

the **work-dir** is the location that mount location of your Persistent Volume Claim.
![vllm_02](/static/images/vllm_02.png)

Lets inspect whats in this volumes

:::code{showCopyAction=true showLineNumbers=true language=bash}
cd /work-dir/
ls -ll
:::

You can see the Mistral Model is stored here. Lets have a look at what the model data structure looks like.

:::code{showCopyAction=true showLineNumbers=true language=bash}
cd Mistral-7B-Instruct-v0.2/
ls -ll
:::

Next we will create a test file on the Persistent Volume (backed by FSx for lustre). Here you will see the FSx for Lustre auto-export of new/changed files to Amazon S3 capability, and also the S3 bucket to S3 bucket replication, where the file you create in your vLLM pod will seamlessly get copied to to your target S3 bucket in us-east-2. Where you could then use that data as part of an existing environment, or have the data there for a DR scenario, where you can spin up an Amazon EKS cluster, its Pods and FSx Lustre Instances to consume the replciated data in an automated manner.

Lets create the test file we want to trigger the export and replication.

:::code{showCopyAction=true showLineNumbers=true language=bash}
cd /work-dir
mkdir test
cd test
cp /work-dir/Mistral-7B-Instruct-v0.2/README.md /work-dir/test/testfile
:::



### Check both the Source S3 bucket and the Destination S3 Bucket

Copy and run the below command from the cli to Look for the s3 bucket name

::code[aws s3 ls]{language=bash showLineNumbers=false showCopyAction=true}

Copy and run the below command to Check the out.txt are in both s3 buckets.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
aws s3 ls s3://$S3_BUCKET/export/
aws s3 ls s3://$S3_BUCKET_2NDREGION/export/
:::

You should be able to see that both S3 buckets have the `testfile` file


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
