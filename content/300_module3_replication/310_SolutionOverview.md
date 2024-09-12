---
title : "Solution overview"
weight : 310
---
-------------------------------------------------------------

## Solution Overview

In this module you will deploy Amazon FSx for Lustre CSI driver for the existing 2 node Amazon EKS cluster provisioned for this workshop. Amazon FSx for Lustre will be auto-provisioned using CSI driver when you configure storage class and persistent volume claim (PVC). This module to help you understand how easy to auto-provision the Amazon FSx for Lustre, The integration helps you to build business continuity and DR for the modern apps leveraging the persitent storage layer of FSx for Lustre file system. 

Later we will deploy Gen AI application and Run the performance test on the Amazon FSx for Lustre file system and capture the metrics. You can setup a cross region replication (CRR) of the buckets between primary lab region and us-east-2. 

![FSx-Architecture](/static/images/FSxL-Architecture.png)
