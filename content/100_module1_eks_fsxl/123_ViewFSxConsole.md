---
title : "View options and performance details in the Amazon FSx console"
weight : 131
---
-------------------------------------------------------------

In the previous steps you have configured a Persistent Volume (PV) using the FSx for Lustre we pre-provisioned for you in this lab. Let's take a moment to view the settings and options for a FSx for Lustre instance. Note: you will get a chance to deploy and configure your own FSx for Lustre instance with your EKS cluster, in a subsequent section of this workshop.

1. Navigate to the [Amazon FSx console](https://console.aws.amazon.com/fsx/).

2. From the top right hand corner, select the **AWS region** that was provided to you for this lab, before continuing

![aws_region](/static/images/aws_region.png)

3. In the FSx console you will see a list of your FSx Instances, including the details of the FSx for Lustre instance that was pre-provisioned for you as part of the lab (which you then configured as a Persistent Volume in the EKS cluster).

4. Let's take a quick look at deployment options you have for provisioning a new FSx for Lustre instance by clicking on the **Create file system** in the top right hand corner.

5. Select **Amazon FSx for Lustre** and click on **Next**

![FSxL_console_4](/static/images/fsx_console_4.png)

6. On the following screen, you can see that you have deployment options for FSx for Lustre. From **PERSISTENT-SSD** or **Scratch** storage, to being able to configure your desired **Throughput unit per of storage**, and your Metadata IOPS performance. You can also set other options such as compression, and configure your S3-linked bucket for automatic data import/export options in the **Data Repository Import/Export** section.

![FSxL_console_5](/static/images/fsx_console_5.png)

---
7.  Click the on the **Cancel** button to exit this screen, and return to the FSx console.

8. In the FSx console you can see a list of your FSx instances, and that we have already provisioned a 1200GiB FSx for Lustre instance, with Persistent-SSD for Storage, and 250MB/s of **Throughput Capacity per unit of storage**.

![FSxL_console](/static/images/fsx_console.png)

9. Click on the **File system Id** of your FSx for Lustre Instance to get further details of the configuration.

10. You will see the details related to your FSx instance, and also the items you can **update** online. Notice that you have the option to **Update Storage Capacity** and **Update Throughput per unit of storage**.

:::alert{header="Note" type="info"}
 As you increase the storage capacity of your FSx for Lustre instance, the throughput capacity performance will also increase per unit of storage. Also note that you can also independently increase the **Throughput capacity** without increasing the storage capacity (i.e. you need more throughput performance and not extra storage capacity).
:::

11. Scroll to the bottom of the screen and click on the **Monitoring & performance** tab. Here you can view performance metrics across different dimensions, from summary metrics (capacity, throughput, IOPS) to detailed performance metrics (metadata performance, network etc).

![FSxL_console_3](/static/images/fsx_console_3.png)


## Summary
You have now completed this module. Through this module you have learnt about the different FSx for Lustre deployment options available, and that you can  increase the storage, throughput capacity, and Metadata IOPS performance capability of an existing FSx instance, online.
