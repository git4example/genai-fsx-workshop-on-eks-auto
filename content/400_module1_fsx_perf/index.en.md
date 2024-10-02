---
title : "Create your own environment for testing Data layer"
weight : 400
---
-------------------------------------------------------------

## Module Overview
In the previous modules you learnt how you can use Static Provisioning with an existing storage instance (pre-created by an admin) to then create a Persistent Volume and Claim in your EKS cluster. In this section you will create your own testing environment, by firstly learning how a user can use the **Dynamic Provisioning** feature to deploy an **on-demand** Persistent Volume (PV), which also creates the associated FSx Lustre instance on the backend (no admin pre-provisioning required). You will then use the new Persistent Volume and a new Pod that you will deploy for some testing in this lab section.
