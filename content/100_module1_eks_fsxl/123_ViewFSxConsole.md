---
title : "View options and performance details in the Amazon FSx console"
weight : 131
---
-------------------------------------------------------------

In the previous steps you have configured a Persistent Volume using the FSx for Lustre we pre-provisioned for you in this lab. Let's take a moment to view the settings and options for a FSx for Lustre Instance. Note: you will get a chance to deploy your own FSxL for lustre instance and configure it with your EKS cluster in a subsequent section of this workshop.

1. Navigate to the [Amazon FSx console](https://console.aws.amazon.com/fsx/).

2. From the top right hand corner, select your AWS region, before continuing

![aws_region](/static/images/aws_region.png)

3. You will now see the details of the FSx for Lustre instance that was pre-provisioned for you as part of the lab (which you then configured as a Persistent Volume in the EKS cluster).

4. Let's take a quick look at the FSx for Lustre deployment options, click on the **Create file system** in the top right hand corner.

5. Select **Amazon FSx for Lustre** and click on next

![FSxL_console_4](/static/images/fsx_console_4.png)

6. On the following screen, you can see that you have deployment options for FSx for Lustre. From **PERSISTENT-SSD** or **Scratch** storage, to being able to configure your  your desired **Throughput unit per of storage**, and your Metadata IOPS performance. You can also set other options such as compression, and configure your S3-linked bucket  for automatic data import/export options in the **Data Repository Import/Export - optional** section.

![FSxL_console_5](/static/images/fsx_console_5.png)
---

7. You are then taken back to the main screen, where you will click on your FSx instance. Here you can see that we have already deployed a 1200GiB FSx for Lustre instance, with Persistent-SSD for **Storage Capacity**, and 300MB/s of **Throughput Capacity**. **Note**, As you increase the storage capacity of your FSx for Lustre Instance, the throughput capacity performance will also increase per unit of storage. Also note that you can also independantly increase the **Throughput capacity** without increasing storage capacity (i.e. you need more performance and not extra capacity).

![FSxL_console](/static/images/fsx_console.png)

8. On the summary screen on your FSx for Lustre Instance, click on the **Actions** button in the top right hand corner. You will see all the actions you can perform on, Notice that you can have the option to **Update Storage Capacity**, lets click on this to see what options you have.

![FSxL_console_1](/static/images/fsx_console_1.png)

9. You can see that your current **storage capacity** is 1200GiB, with 300MB/s of throughput capacity. Note that If you increase your storage capacity to 2400GiB, your **throughput capacity** also increases to 600MB/s.
-  **IMPORTANT: CLICK ON CANCEL TO EXIT!** DO NOT ON CLICK UPDATE AS THIS WILL IMPACT YOUR WORKSHOP

![FSxL_console_2](/static/images/fsx_console_2.png)

10. Scroll to the bottom of the screen and click on the **Monitoring & performance** tab. Here you can view performance metrics across different dimensions, from summary metrics (capacity, throughput, IOPS) to detailed performance metrics (metadata performance, network etc)

![FSxL_console_3](/static/images/fsx_console_3.png)


## Summary
You have now completed this module. Through this module you have learnt about the different FSx for Lustre deployment options available, where you can also increase the storage, throughput capacity, and Metadata IOPS performance capability of an existing FSx instance, online.
