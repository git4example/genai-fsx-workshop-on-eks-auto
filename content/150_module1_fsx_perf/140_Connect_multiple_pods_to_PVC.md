---
title : "Connect multiple PODs to same PV/PVC"
weight : 140
---
-------------------------------------------------------------

In this section, you will connect multiple PODS to the same PVC you created, showing how you can easily use a FSx for Lustre data layer, as a high performance cache location for hosting models and your training data for use with your distributed compute.








:::alert{header="Information" type="info"}
Imagine the scenario where you need to host many AI models, or vast amounts of training data-sets, which will be accessed by hundreds of Pods in your workload. You can store this data on a single Persistent Volume (PV) backed by FSx for Lustre. This will allow you to have a centralized high-performance model/data cache location to service your application Pods, instead of having creating many individual local storage volumes attached to each of your Pods, where you could have duplicate data, and also  wait time associated with copying the data to each of the local volumes before your Pod can access it.
:::
