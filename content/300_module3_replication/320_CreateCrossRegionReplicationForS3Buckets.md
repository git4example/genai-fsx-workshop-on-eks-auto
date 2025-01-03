---
title : "Configure S3 Cross-Region Replication for your S3-linked FSx for Lustre Instance"
weight : 320
---
-------------------------------------------------------------

## Configure S3 Cross Region Replication configuration between the Amazon S3 buckets

:::alert{header="Note" type="info"}
For the AWS Sponsored Workshop, we have created two Amazon S3 buckets for your. The first is in your selected region, and a target Amazon S3 bucket in **us-east-2** with a name of **fsx-lustre-bucket-2ndregion-xxxx**
:::


1. Navigate to the Amazon S3 Console page:

Open the [Amazon S3 console](https://s3.console.aws.amazon.com)


2. Click on the S3 bucket that looks like below, which is created in your region (DO NOT click on the S3 bucket name that has **2ndregion**)

![S3_console_1](/static/images/s3_console_1.png)

3. Select the **Management** tab, scroll down to **Replication rules**, and then select **Create replication rule**

![S3_01](/static/images/S3_01.png)

4. At the top of the screen, in the red pop-up box, click on **Enable Bucket Versioning**, Then under *Rule name*, enter a name for your rule to help identify the rule later. Under *Status*, see that *Enabled* is selected by default

![S3_02](/static/images/S3_02.png)

5. Under *Source bucket* ,  select **limit the scope of this rule using one or more filters**, and then enter **test/** as the value to filter by.

![s3_prefix](/static/images/s3_prefix.png)

6. Under *Destination*, click on **Browse S3**, and select the target S3 bucket we have created for you in us-east-2, which will have name such as **fsx-lustre-bucket-2ndregion-xxxx**, then click on **Choose path**.

7. Click on **Enable Bucket Versioning** in the red pop-up box.

![S3_03](/static/images/S3_03.png)

8. Now set-up an AWS Identity and Access Management (IAM) role that Amazon S3 can assume to replicate S3 objects on your behalf, between S3 buckets. Choose the existing role that has been pre-created for you (the name starts with **s3-cross-region-replication-role** )

![S3_04](/static/images/S3_04.png)

9. For Encryption, select *Replicate objects encrypted with AWS KMS* and click on the "Available AWS KMS keys" and select the only one shown.

![S3_Encryption](/static/images/S3_Encryption.png)


10. Keep all other the default options, and click **Save**, to save the configuration

11. You will a Pop-up to **replicate existing objects**, Select **NO, do not replicate existing objects**, and click **Submit**.

![S3_Existing_Objects](/static/images/S3_06.png)

11. You will be taken back to the S3 replication rules page, where you can view the rule was successfully created.
![S3_06](/static/images/S3_07.png)


## Summary

In this section, you have successfully created a S3 Cross Region Replication rule between two S3 buckets. In the next section you will create test data on a Persistent Volume mounted to one of your Pods, and notice how seamlessly your generated data gets copied to  your target S3 bucket. Amazon S3 native replication feature can help you with a data sharing, to being part of your DR/BCP plan for the containerized workload deployments.
