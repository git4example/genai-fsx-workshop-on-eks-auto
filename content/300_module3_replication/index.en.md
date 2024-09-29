---
title : "Sharing and replicating data assets"
weight : 300
---
-------------------------------------------------------------

## Module Overview

Imagine you had to share your models or training data (stored in your S3 bucket), or share generated assets by your Pods (on FSx Lustre based PVs) with EKS Clusters and Pods in a different region (i.e. for DR, or distributed access by one of your different teams). In this lab section you will configure an Amazon S3 Cross Region Replication configuration between your existing S3 bucket linked to your FSx Lustre instance, and a separate S3 bucket that we have created for your in a different target AWS Region (us-east-2).

You will then create some test files on a Pod in your lab region, and notice it is replicated seamlessly for you to access at the target region (us-east-2).

![FSx-Architecture](/static/images/FSxL-Architecture.png)
