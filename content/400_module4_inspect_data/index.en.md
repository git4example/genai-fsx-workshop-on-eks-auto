---
title : "Inspect vLLM & Neuron tools, and replicate data"
weight : 400
---
-------------------------------------------------------------

## Module Overview

One Persistent Volume can be shared with many Pods. Imagine the scenario where you need to host many AI models, or vast amounts of training data-sets, which will be accessed by countless Pods in your workload. You can store this data on a single Persistent Volume (PV) backed by Amazon FSx for Lustre. This will allow you to have a centralized high-performance data cache to service your application Pods, instead of creating countless individual local storage volumes attached to each of your countless Pods. this will help to eliminate the inefficiency of duplicated data across local volumes, and also the wait time associated with copying the data to into each of the local volumes when you start a new Pod, and decrease Pod startup latency.


In this module, you will log into the vLLM pod and perform the following;
- View the Mistral model data structure and how its stored on the persistent volume.
- Inspect Neuron cores and use Neuron tools to monitor performance
- Test the automatic data export feature of S3-linked FSx for Lustre file-systems.
- Configure and test S3 replication with the S3 bucket linked to your FSx for Lustre file-system. Then watch data generated on the FSx for Lustre file-system automatically get replicated to a target S3 bucket, in a different region.
