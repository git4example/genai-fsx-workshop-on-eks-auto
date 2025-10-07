---
title : "Inspect vLLM & Neuron tools, and replicate data"
weight : 300
---
-------------------------------------------------------------

## Module Overview

One Persistent Volume can be shared with many Pods. Imagine the scenario where you need to host many AI models, or vast amounts of training data-sets, which will be accessed by countless Pods in your workload. You can store this data on a single Persistent Volume (PV) backed by Amazon FSx for Lustre. This will allow you to have a centralized high-performance data cache to service your application Pods, instead of creating countless individual local storage volumes attached to each of your countless Pods. this will help to eliminate the inefficiency of duplicated data across local volumes, and also the wait time associated with copying the data to into each of the local volumes when you start a new Pod, and decrease Pod startup latency.


In this module, you will log into the vLLM pod and perform the following;
- View the Mistral model data structure and how its stored on the persistent volume.
- Inspect Neuron cores and use Neuron tools to monitor performance
- Configure S3 replication between S3 buckets. Then test the automatic data export capability of your S3-linked FSx for Lustre file systems, by generating a test file on your PV (which is backed by you s3-linked FSx for Lustre file system). Then watch your data automatically export from your PV to your linked S3 bucket, and also get replicated to the target S3 bucket that you will create.
