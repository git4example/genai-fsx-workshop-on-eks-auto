---
title : "Create your own environment for testing Data layer"
weight : 400
---
-------------------------------------------------------------

## Module Overview
In the previous modules you learnt how you can use Static Provisioning with an existing storage instance (pre-created by an admin) to then create a Persistent Volume and Claim in your EKS cluster. In this section you will create your own testing environment, where you will deploy a Pod, and also learn how a user can use the **Dynamic Provisioning** feature to deploy an **on-demand** Persistent Volume (PV) and Persistent Volume Claim, which will automatically create the associated FSx Lustre instance on the backend (no admin pre-provisioning required). You will then mount that PVC to your Pod and for some testing in this lab section.
