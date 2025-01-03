---
title : "Inspect vLLM config, and replicate generated data assets"
weight : 300
---
-------------------------------------------------------------

## Module Overview

In this module, you will log into the vLLM pod and view the Mistral model data structure that is stored on the persistent volume. By logging into the vLLM Pod, you will also see how you can view and access all the data stored in your S3 bucket through using the Persistent Volume that is backed by your FSx Lustre file system. Imagine the scenario where you had to share your models or training data (that you are storing in your S3 bucket), or share generated assets by your Pods with EKS Clusters in a different region (i.e. for DR, or distributed access by one of your different teams). So, in this lab section, you will generate a test file on your EKS Pod on your Persistent Volume (backed by FSx for Lustre), and watch it get automatically exported to your S3 bucket, and through the S3 Replication that you will configure, you will see how that test file will also get automatically replicated to an S3 bucket in a different target AWS Region that we have created for you (us-east-2).

:::alert{header="Information" type="info"}
One Persistent Volume Claim shared with many Pods- Imagine the scenario where you need to host many AI models, or vast amounts of training data-sets, which will be accessed by countless Pods in your workload. You can store this data on a single Persistent Volume (PV) and Persistent Volume Claim (PVC) backed by FSx for Lustre. This will allow you to have a centralized high-performance model/data cache location to service your application Pods, instead of having creating many individual local storage volumes attached to each of your countless Pods, helping to eliminate the inefficiency of duplicated data across local volumes, and also the wait time associated with copying the data to into each of the local volumes when you start a new Pod.
:::


![FSx-Architecture](/static/images/FSxL-Architecture.png)
