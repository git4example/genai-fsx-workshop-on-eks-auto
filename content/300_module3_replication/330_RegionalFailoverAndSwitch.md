---
title : "Inspect vLLM, Neuron Cores, Mistral-7B data, and replicate data"
weight : 330

---
In this section, you will log-in to a Pod, inspect the Mistral-7B  model data, and generate a test file which will be shared and replicated.

##### Step 1: Login to vLLM Pod, inspect Neuron cores config and performance

Navigate to back to your VSCode IDE terminal and change to your working directory.

::code[cd /home/participant/environment/eks/FSxL]{language=bash showLineNumbers=false showCopyAction=true}

Now lets log into the vLLM Pod, first we need to get the pod name by running the following command

::code[kubectl get pods]{language=bash showLineNumbers=false showCopyAction=true}

From the output, copy the name shown in your environment that starts with **vllm**

![vllm_name](/static/images/vllm_name.png)

Log into your vLLM pod by running the below command, by replacing the value of **YOUR-vLLM-POD-NAME** with the value you just copied.

::code[kubectl exec -it YOUR-vLLM-POD-NAME -- bash]{language=bash showLineNumbers=false showCopyAction=true}


Run the below command to view the number of AWS Inferentia2 devices on your instance.

::code[neuron-ls]{showCopyAction=true showLineNumbers=false language=bash}

Let's view the performance of your AWS Inferentia2 node by running the **neuron-top** command. The neuron-top command provides information about NeuronCore and vCPU utilization, memory usage, loaded models, and Neuron applications.

::code[neuron-top]{showCopyAction=true showLineNumbers=false language=bash}

![neuron-top](/static/images/neuron-top.png)

Now re-size the neuron-top window, and also the existing WebUI client to your Chatbot, so they are side-by-side in on your monitor.

Ask the Chatbot a question, and then pay close attention to the **NeuronCores V2 utilization section** as your Chatbot processes your input/output tokens. Notice the optimized performance of AWS Inferentia2, which is designed to use all available Neuron core utilization capacity to process a request.

Press `q` to exit from `neuron-top` screen and return back to pod exec shell.

::code[q]{showCopyAction=true showLineNumbers=false language=bash}

##### Step 2: Inspect model data, and create a test file to replicate
We will now inspect the layout of the model data on the vLLM. When you run the below command you will see a mount point called **work-dir**, which is the mount location of your Persistent Volume Claim (backed by FSx for Lustre file system).

::code[df -h]{showCopyAction=true showLineNumbers=false language=bash}


![vllm_02](/static/images/vllm_02.png)

Lets inspect what's stored in this Persistent Volume

:::code{showCopyAction=true showLineNumbers=true language=bash}
cd /work-dir/
ls -ll
:::

You can see the Mistral-7B Model is stored here. Lets have a look at what the model data structure looks like.

:::code{showCopyAction=true showLineNumbers=true language=bash}
cd Mistral-7B-Instruct-v0.2/
ls -ll
:::

Next we will create a test file on the Persistent Volume (backed by FSx for lustre). Here you will see the FSx for Lustre auto-export of new/changed files to Amazon S3 capability, and also the S3 bucket to S3 bucket replication, where the file you create in your vLLM pod will seamlessly get copied to to your target S3 bucket in us-east-2. Where you could then use that data as part of an existing environment, or have the data there for a DR scenario, where you can spin up an Amazon EKS cluster, its Pods and FSx Lustre Instances to consume the replicated data in an automated manner.

Lets create the test file called **testfile** under a new folder called **test**, which will trigger an export of the test file to the S3 bucket linked to this FSx instance, and subsequently trigger the S3 Replication of the testfile between S3 buckets to the target S3 bucket (us-east-2 region) .

:::code{showCopyAction=true showLineNumbers=true language=bash}
cd /work-dir
mkdir test
cd test
cp /work-dir/Mistral-7B-Instruct-v0.2/README.md /work-dir/test/testfile
ls -ll /work-dir/test
:::


Finally exit from the pod.

::code[exit]{showCopyAction=true showLineNumbers=false language=bash}

##### Step 3: Verify data exported to S3 bucket and replicated across regions

Navigate to the Amazon S3 Console page:  [Amazon S3 console](https://s3.console.aws.amazon.com)

Click on the S3 bucket that is in your region (linked to your FSx instance). **DO NOT** click on the S3 bucket which has **2ndregion** in its name..

![S3_console_1](/static/images/s3_console_1.png)

Notice that there is a **test** folder there. Click on the **test** folder. You will now see that the **testfile** you created on the Persistent Volume in your Pod has also been automatically exported from the FSx for Lustre file system, to your S3 bucket.

![testfile](/static/images/testfile.png)

Now lets go and check out your target S3 bucket in the different AWS Region (us-east-2), to verify this testfile has also been automatically replicated there.

Now click on the **Buckets** hyperlink at the top of the window

![buckets](/static/images/buckets.png)


Now click on the S3 bucket which has **2ndregion** in its name, which is located in us-east-2. You will notice that the **test** folder, and **testfile** have also been automatically replicated by S3 Replication.

![target_bucket](/static/images/target_bucket.png)


## Summary

In this section, you have observed how you can share & replicate generated data within a Pod, using FSx for Lustre, and its auto import/export to Amazon S3 capability. You have observed how you can also seamlessly replicate generated data between S3 buckets using S3 Replication. This is useful for scenario's such as distributed data requirements to DR scenarios, where you may have an existing EKS cluster in a secondary region (i.e. DR), and can then leverage the replicated data stored in your S3 buckets, by creating an FSx for Lustre instance (linked to the S3 bucket), create an associated Persistent Volume (using the FSx instance), and then spin up your application Pod's to seamlessly consume this data in the different AWS Region.

:::alert{header="Information" type="info"}
Imagine the scenario where you need to host many AI models, or vast amounts of training data-sets, which will be accessed by hundreds of Pods in your workload. You can store this data on a single Persistent Volume (PV) backed by FSx for Lustre. This will allow you to have a centralized high-performance model/data cache location to service your application Pods, instead of having creating many individual local storage volumes attached to each of your Pods, where you could have duplicate data, and also  wait time associated with copying the data to each of the local volumes before your Pod can access it.
:::
