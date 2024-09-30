---
title : "View options and performance details in the Amazon FSx console"
weight : 131
---
-------------------------------------------------------------

In the previous steps you have configured a Persistent Volume using FSx for Lustre. Let's take a moment to view the settings and options for a FSx for Lustre Instance.

1. Navigate to the [Amazon FSx console](https://console.aws.amazon.com/fsx/).

2. You will now see the details of the FSx for Lustre instance that was pre-provisioned for you as part of the lab (which you then configured as a Persistent Volume in the EKS cluster).

:::alert{header="Info" type="info"}
Note that this is a **Scratch_2** deployment type instance with 1200GiB of storage capacity, and 240MB/s of provisioned throughput capacity. Amazon FSx for Lustre can be deployed in different capacity and performance configurations.
:::

3. Let's take a quick look at the FSx for Lustre deployment options, click on the **Create file system** in the top right hand corner.

4. Select **Amazon FSx for Lustre** and click on next

![FSxL_console_4](/static/images/fsx_console_4.png)

5. On the following screen, you can see that you have the option to also deploy **PERSISTENT-SSD** FSx for Lustre instances (not just the SCRATCH type we deployed in this lab), where **PERSISTENT-SSD** allows you to select your desired **Throughput unit per of storage**, and also configure your Metadata IOPS. You can also set other options such as compression, configure your S3-linked bucket details for import/export options, and importantly set your default maintenance window period. Click **CANCEL** when you are finished looking at the deployment options.

![FSxL_console_5](/static/images/fsx_console_5.png)
---

6. You are then taken back to the main screen, where you will click on your FSx instance.
![FSxL_console](/static/images/fsx_console.png)

7. Click on the **Actions** button in the top right hand corner. You will see all the actions you can perform on this SCRATCH type instance (Persistent SSD type will have more options). Notice that you can have the option to **Update Storage Capacity**, lets click on this to see what options you have.

![FSxL_console_1](/static/images/fsx_console_1.png)

8. You can see that your current **storage capacity** is 1200GiB, with 240MB/s of throughput capacity. If you increased storage capacity to 2400GiB, your **throughput capacity** also increases to 480MB/s. This is because, as your FSx for Lustre storage capacity increases in size, so does the throughput capacity performance provided.

-  **IMPORTANT: CLICK ON CANCEL TO EXIT!** DO NOT ON CLICK UPDATE AS THIS WILL IMPACT YOUR WORKSHOP

![FSxL_console_2](/static/images/fsx_console_2.png)

9. Scroll to the bottom of the screen and click on the **Monitoring & performance** tab. Here you can view performance metrics across different dimensions, from summary metrics (capacity, throughput, IOPS) to detailed performance metrics (metadata performance, network etc)

![FSxL_console_3](/static/images/fsx_console_3.png)


## Summary
You have now completed this module. Through this module you have learnt about the different FSx for Lustre deployment options available, where you can also increase the storage, throughput capacity, and Metadata IOPS performance capability of an existing FSx instance, online.
