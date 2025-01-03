---
title : "Performance testing"
weight : 430
---
-------------------------------------------------------------

In this section, you will look at important parameters related to storage performance, IOPS, throughput and latency for the FSx for Lustre file system provisioned by the CSI driver. You will use [FIO (Flexible I/O)](https://fio.readthedocs.io/en/latest/), which is a popular storage benchmarking tool, and [IOping](https://github.com/koct9i/ioping), a tool to monitor I/O latency in real time, to test the performances on FSx for Lustre drive from an EKS Pod that you will deploy.

Let's start...

### Step 1: Provision the testing pod using a yaml file and the 10 GB storage on FSx for Lustre

Go to the correct working directory.


::code[cd /home/participant/environment/eks/FSxL]{language=bash showLineNumbers=false showCopyAction=true}


Run the below command and write down the output shown for availability zone of the FSx for Lustre Instance (i.e. "us-west-2c")

::code[aws ec2 describe-subnets --subnet-id $SUBNET_ID --region $AWS_REGION | jq .Subnets[0].AvailabilityZone]{language=bash showLineNumbers=false showCopyAction=true}

Edit the pod deployment configuration, and update it

::code[vi pod_performance.yaml]{language=bash showLineNumbers=false showCopyAction=true}

::alert[The below steps are very important for your performance test, as it makes ensures that you deploy the pod in the same availability zone as your FSx for Lustre file system.]{header="Important" type="info"}

- Press “i” to go into edit mode

- Uncomment by removing `#` in the last two lines starting with **nodeSelector** and **topology.kubernetes.io/zone**, as the below screenshot.

- Replace the `us-east-2c` with the availability zone you noted from the previous step, as the below screenshot.

- Press ESC and type `:wq` then press enter.

![FSXlperf03](/static/images/fsxl_perf_03.png)

- Copy and run the below command to provision the performance testing pod

::code[kubectl apply -f pod_performance.yaml]{language=bash showLineNumbers=false showCopyAction=true}

- Run the below command to check the status of your pod. It will take approx 1. minute for your Pod to change its status to RUNNING.

::code[kubectl get pods]{language=bash showLineNumbers=false showCopyAction=true}

:::alert{header="Important" type="info"}
 If your Pod events shows message such as below, this means that FSx Lustre filesystem hasn't completed provisioning.

PVC `fsx-lustre-claim` should be in pending status, wait for upto 15 mins. Pod should transision to running once PVC `fsx-lustre-claim` is in bound status.

:::code[]{language=bash showLineNumbers=false showCopyAction=false}
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  25s   default-scheduler  0/2 nodes are available: 2 pod has unbound immediate PersistentVolumeClaims. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.
:::


### Step 2: Log in to the container and perform FIO and IOping testing

The below steps is to install the FIO and IOping utilities. Post which you will run the performance load testing and observe the IOPS and throughput

1. Login to the container with the below command

::code[kubectl exec -it fsxl-performance  -- bash]{language=bash showLineNumbers=false showCopyAction=true}

2. Install FIO and IOping

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
apt-get update
apt-get install fio ioping -y
:::


3. Run the below command of **IOping** to test the latency of the FSx for Lustre file system.

::code[ioping -c 20 .]{language=bash showLineNumbers=false showCopyAction=true}

- Take note of the average latency number, which is usually < 0.5ms (500us), which highlights the low-latency and high performance that the FSx for Lustre file system can provide.

![Diagram](/static/images/Ioping-test-FSxL.png)

4. Run the below instructions and FIO command to perform load testing, and take note of the Throughput values

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
mkdir -p /data/performance
cd /data/performance
fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=testfio8gb --bs=1MB --iodepth=64 --size=8G --readwrite=randrw --rwmixread=50 --numjobs=8 --group_reporting --runtime=10
:::

::alert[IMPORTANT: In this lab, you have deployed the smallest FSx for Lustre configuration size of 1.2TiB, which provides a baseline throughput of 240MB/s. As you increase your FSx for Lustre file system size, your baseline throughput also increases. The highlighted red section in image will show you your average read and write throughput from the FIO test. In the FIO test, you are running a simulation of a load test using 1MB large block size to test throughput (instead of small block size to test IOPS) using your small EKS containers environment, with 50% read/write mix, with a random read-write pattern using 8 concurrent jobs]{header="Important" type="info"}

![FIO01](/static/images/fio_01.png)


5. Exit from the Pod.

:::code[]{language=bash showLineNumbers=true showCopyAction=true}
exit
:::

## Performance Summary

The specific amount of throughput and IOPS that your workload can drive on your FSx for Lustre file system depends on the throughput capacity, storage capacity configuration of your file system, and the nature of your workload. For more information on the Amazon FSx for Lustre performance kindly check this link [Amazon FSx for Lustre performance chart](https://docs.aws.amazon.com/fsx/latest/LustreGuide/performance.html)

## Summary

You have successfully completed this section on performance testing of Amazon FSx for Lustre filesystem using FIO and IOping tool. You observed the different performance metrics with EKS pod running the load on the FSx for Lustre with high throughput and sub-millisecond latency.


**This is the end of the workshop**
