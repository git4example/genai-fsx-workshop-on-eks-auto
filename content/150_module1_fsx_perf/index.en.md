---
title : "Testing data layer"
weight : 100
---
-------------------------------------------------------------

## Module Overview
In the previous module you learnt how you can use Static Provisioning with an existing storage instance (pre-created by an admin) to then create a Persistent Volume and Claim in your EKS cluster. In this section you will learn how a user can use the **Dynamic Provisioning** feature, and the CSI driver, to deploy an **on-demand** Persistent Volume (PV), which also creates the associated FSx Lustre instance on the backend (no admin pre-provisioning required). You will create the definitions for the StorageClass, PersistentVolume (PV) and PersistentVolumeClaims (PVC), and learn the difference between Static and Dynamic provisioning. You will then use the new Persistent Volume that you just depoloyed for some testing in this lab section.
