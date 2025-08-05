## Workshop Objective
In this workshop, you will learn how you can:
1. Deploy a Generative AI chatbot application on Kubernetes by deploying a vLLM and a WebUI Pod on an Amazon EKS cluster, store and access the Mistral-7B model using Amazon FSx for Lustre and  Amazon S3, and leverage Accelerate Compute for your Generative AI workload using AWS Inferentia Accelerator.
2. Use Karpenter to scale the number of EKS nodes, when there are additional Pod requests that require additional nodes, to enable scale and operational efficiency.
3. Use AWS Inferentia Accelerated Compute in your Amazon EKS clusters, as a new nodepool to power your Generative AI applications.
4. Configure Amazon FSx for Lustre and Amazon S3, as your performant and scalable data layer, which will host your model and data
5. Achieve operational efficiency at the data layer: accessing the same model data across container Pods without storing multiple copies, and seamlessly sharing your data across regions, for scenario's such as distributed access and sharing, to DR.


****Target Audience****: DevOps engineers, Machine Learning Scientists/Engineers, Container & Storage engineers, Cloud Architects

****Prerequisites****: Recommended to have an fundamental understanding of AWS containers, and AWS Cloud

****Duration****: Approximately take 2 hours.

![lab-image](/static/images/lab-image.png)

-----

## Generative AI and Machine Learning
Generative AI and Machine Learning (ML) is helping businesses transform the way they operate and innovate. Generative AI refers to a class of Artificial Intelligence that leverages Large Language Models (LLM) in order to generate new content from a prompt, content such as text, images, audio, and software code.

## What is a Large Language Model (LLM)
Large Language Models (LLMs) are a type of machine learning model that is trained on vast amounts of text data to learn the patterns and structure of natural language. These models can then be used for a wide range of natural language processing tasks, such as text generation, question answering, and language translation. In this lab we are going to use the open-source Mistral-7B-Instruct model, which is a specific LLM model with 7 billion parameters. The "Instruct" in the name refers to the fact that this model has been trained to follow instructions and perform a wide variety of tasks, beyond just generating text, i.e. it is suitable for chat applications. You will be using this open source LLM model in this workshop.


## What is vLLM
[**vLLM (Virtual Large Language Model)**](https://github.com/vllm-project/vllm) is an open-source, easy-to-use, library for LLM inference and serving. It provides a framework that allows LLM models such as Mistral-7B-Instruct, to be deployed to provide text generation inference. vLLM provides an API that is compatible with OpenAI API, making it easy to integrate LLM applications.

**vLLM is fast with:**
- State-of-the-art serving throughput
- Efficient management of attention key and value memory with PagedAttention
- Continuous batching of incoming request
- Fast model execution with CUDA/HIP graph

**vLLM is flexible and easy to use with:**
- Seamless integration with popular HuggingFace models
- OpenAI-compatible API server
- Prefix caching support
- Supports chipsets such as: AWS Neuron, NVIDIA GPUs and others,

## Deploying Mistral-7B-Instruct using a vLLM on Amazon EKS
To provide text generation inference capability with an OpenAI-compatible endpoint, we will deploy the Mistral-7B-Instruct model using the vLLM framework on Amazon Elastic Kubernetes Service (EKS). We will use Karpenter to spin up the AWS inferentia2 EC2 node (Accelerated Compute designed for Generative AI), where it will launch a vLLM Pod from an container image.

## What is Amazon EKS (Elastic Kubernetes Service)
[**Amazon EKS**](https://aws.amazon.com/eks/), is a managed service that makes it easy for you to deploy, run, manage and scale container based apps using Kubernetes on AWS, without installing and operating your own Kubernetes control plane or worker nodes. Amazon EKS clusters can scale to support thousands of containers, which makes it ideal for Generative AI and ML workloads, where you can tune and deploy LLMs on Amazon EKS. Amazon EKS serves as an effective orchestrator to help achieve rapid scale out and scale in that is required for Generative AI and ML workloads, optimal cost efficiency.

## How to consume the Inference Service
You can connect to the Inference Service using the **"Open WebUI"** application, which is designed to consume the OpenAI-compatible endpoint provided by the vLLM-hosted Mistral-7B-Instruct model that you will deploy in the workshop. The Open WebUI application allows users to interact with the LLM model through a chat-based interface. To use the Open WebUI application, simply deploy the application container, and connect to the WebUI URL that is provided and start chatting with the LLM model. The WebUI application will handle the communication with the VLLM-hosted Mistral-7B-Instruct model, providing a seamless user experience


## Storing and accessing your model and training data
In this workshop the **Mistral-7B-Instruct** model is stored in an Amazon S3 bucket [**Amazon S3**](https://aws.amazon.com/s3/), which is linked to an  [**Amazon FSx for Lustre File system S3**](https://aws.amazon.com/fsx/lustre/). The vLLM container will consume the Mistral model data via the mounted Amazon FSx for Lustre instance for the Generative AI Chat application. Amazon FSx for Lustre is a fully managed service that provides a high-performance scalable file system, for workloads where speed matters, providing sub-millisecond latency, and scaling to TB/s of throughput and millions of IOPS. Amazon FSx also integrates with Amazon S3 (highly durable, available and scalable object store), making it easy for you to store, access and process vast amounts of cloud data with the Lustre high-performance file system.

## Accelerating your Compute
 [**AWS Inferentia accelerators**](https://aws.amazon.com/machine-learning/inferentia/) are designed by AWS to deliver high performance at the lowest cost in Amazon EC2 for your deep learning (DL) and generative AI inference applications, where Inferentia2-based Amazon EC2 Inf2 instances are optimized to deploy increasingly complex models, such as large language models (LLM). [**AWS Neuron SDK**](https://aws.amazon.com/machine-learning/neuron/) is an SDK with a compiler, runtime, and profiling tools that unlocks high-performance and cost-effective deep learning (DL) acceleration. AWS Neuron SDK helps developers deploy models on the AWS Inferentia accelerators, where it integrates natively with popular frameworks, such as PyTorch and TensorFlow, so that you can continue to use your existing code and workflows and run on Inferentia accelerators.


## Repo structure

```bash
.
├── README.md
├── assets
├── content
│   ├── 010_introduction
│   │   └── index.en.md
│   ├── 020_setup
│   │   ├── 021_on_demand
│   │   │   └── index.en.md
│   │   ├── 022_aws_event
│   │   │   └── index.en.md
│   │   └── index.en.md
│   ├── 030_module_explore_karpenter
│   │   └── index.en.md
│   ├── 100_module1_eks_fsxl
│   │   ├── 110_DeployAmazonFSxLustreCSIDriverToEKS.md
│   │   ├── 120_StaticProvisioning.md
│   │   ├── 123_ViewFSxConsole.md
│   │   └── index.en.md
│   ├── 200_module2_genai
│   │   ├── 210_Deploy.md
│   │   ├── 220_webui.md
│   │   └── index.en.md
│   ├── 300_module3_replication
│   │   ├── 320_CreateCrossRegionReplicationForS3Buckets.md
│   │   ├── 330_RegionalFailoverAndSwitch.md
│   │   └── index.en.md
│   ├── 400_module1_fsx_perf
│   │   ├── 422_DynamicProvisioning.md
│   │   ├── 430_Fio_performanceTesting.md
│   │   └── index.en.md
│   └── index.en.md
└── static
    ├── GenAIFSXWorkshopOnEKS.yaml
    ├── download
    │   ├── check.yaml
    │   ├── download-upload.yaml
    │   ├── s3-upload.json
    │   └── sysprep.yaml
    ├── eks
    │   ├── FSxL
    │   │   ├── fsxL-claim.yaml
    │   │   ├── fsxL-dynamic-claim.yaml
    │   │   ├── fsxL-persistent-volume.yaml
    │   │   ├── fsxL-storage-class.yaml
    │   │   ├── pod.yaml
    │   │   └── pod_performance.yaml
    │   └── genai
    │       ├── inferentia_nodepool.yaml
    │       ├── mistral-fsxl.yaml
    │       └── open-webui.yaml
    ├── images
    │   ├── [ workshop images .. ]
    │   
    │   └── vllm_pod_1.png
    ├── scripts
    │   ├── cleanup.sh
    │   ├── install.sh
    │   └── sysprep.sh
    └── terraform
        ├── helm-values
        │   ├── kube-prometheus.yaml
        │   └── nvidia-values.yaml
        ├── sysprep.tf
        └── main.tf
```


### Part 1 : Prerequisite of setting up an On-demand Workshop (using your own AWS account)
Follow the below instructions to complete the required steps before you can launch the AWS CloudFormation Stack that will provision this workshop.

:::alert{header="Note" type="info"}
Here some of step you may feel as duplication of data, however its to align it with sponsored workshop setup and code managability.
:::


1. You will need a Linux based Amazon EC2 jump-box that is configured with an Amazon EBS GP3 based volume that has at least 100GB FREE. The Linux based Amazon EC2 jump-box also needs to have the required account access and permissions in-order to run the commands outline below, along with being able to create AWS resources required for this workshop.  

Logon onto to your Amazon EC2 instance and follow run the below commands to install the items: awscli, docker and git.

 **Note**: The example commands provided are for Amazon Linux 2 based EC2 instances, if you are using a different OS then follow these steps (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)


- Run the below commands to install AWSCLI:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
- Run the below commands to install Docker:

```bash
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker participant
sudo docker ps
```

- Run the below commands to install Git :
```bash
sudo yum install git -y
sudo yum install jq
git --version
git config --global user.name “Your Name”
git config --global user.email “your_email@example.com”
```

2. Run the below commands to perform a git clone of the workshop package:

```bash
git clone https://github.com/git4example/genai-fsx-workshop-on-eks-auto.git
```

3. Follow the below commands to create a new Amazon S3 bucket (using AWSCLI or the Amazon S3 console), this will be for temporarily hosting workshop assets. This S3 asset bucket should be in the same region where your Amazon EC2 Jump-box is and where you will deploy the workshops AWS CloudFormation stack.

**Note**: The automation in AWS CloudFormation stack and its Terraform modules, as part of the initial deployment setup, will copy over workshop data into a VScode instance (which will become your IDE for the workshop), and also create an additional temporary S3 bucket. This S3 bucket will be used by the workshop to host the workshop data and the Mistral-7B LLM  model that is used in the workshop by the Generative AI chatbot.


```bash
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
```

Replace **< new-bucket-name >** with your own **S3 bucket name**

```bash
ASSET_BUCKET= <your-new-bucket-name>
aws s3api create-bucket --bucket $ASSET_BUCKET --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION
```

4. Move the workshop code to your asset S3 bucket, which will be used for the provisioning resources using CloudFormation in next step.

```bash
aws s3 sync ./genai-fsx-workshop-on-eks-auto s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto
```


5. Download the Mistral-7B LLM model
```bash
sudo docker run -v ./work-dir/:/work-dir/ --entrypoint huggingface-cli public.ecr.aws/parikshit/huggingface-cli:slim download "enghwa/neuron-mistral7bv0.2" --local-dir /work-dir/Mistral-7B-Instruct-v0.2
```

6. Upload LLM model to the S3 asset bucket you created previously. In following command replace the credentials to allow access to s3 assets bucket.

**Get the IAM role name associated with your EC2 instance:**
```bash
ROLE_NAME=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/)
```

**Get the credentials:**
```bash
CREDENTIALS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME)
```

**Extract and export the credentials into variables to use:**
```bash
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Token')
```

**View and verify the credentials:**
```bash
echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
echo "AWS_SESSION_TOKEN: $AWS_SESSION_TOKEN"
```


<!-- ```bash
export $(printf "AWS_ACCESS_KEY_ID=%s exp=%s AWS_SESSION_TOKEN=%s" $(aws sts assume-role --role-arn <role-arn> --role-session-name <session-name> --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" --output text))
::: -->

**Copy Mistral-7B LLM model to asset bucket:** (This can take a few minutes to upload the model data to your S3 bucket)
```bash
ASSET_BUCKET_PATH=genai-fsx-workshop-on-eks-auto

sudo docker run -e AWS_DEFAULT_REGION=$AWS_REGION \
  -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
  -v ./work-dir/:/work-dir/  public.ecr.aws/parikshit/s5cmd cp /work-dir/Mistral-7B-Instruct-v0.2/ s3://${ASSET_BUCKET}/${ASSET_BUCKET_PATH}/assets/Mistral-7B-Instruct-v0.2/
```


### Part 2 : Provision workshop resources

:::alert{header="Note" type="info"}
The CloudFormation stack for the workshop will take up-to 45 - 60 mins to successfully provision the workshop components.

**Note:** Any stack creation/deletion failures can be investigated by looking at Cloudformation stack along with `/aws/lambda/GenAIFSXWorkshopOnEKS-XXX` and `/aws/ssm/GenAIFSXWorkshopOnEKS-XXX` log groups in AWS Cloudwatch Logs
:::

Run the following commands to provision the workshop resources

**Set parameter values :**
```bash
STACK_NAME=GenAIFSXWorkshopOnEKS
VSINSTANCE_NAME=VSCodeServerForEKS
ASSET_BUCKET_ZIPPATH=""
ASSET_BUCKET=${ASSET_BUCKET}
ASSET_BUCKET_PATH=genai-fsx-workshop-on-eks-auto
```

**Validate Template:**
```bash
aws cloudformation validate-template --template-url https://${ASSET_BUCKET}.s3.amazonaws.com/${ASSET_BUCKET_PATH}/static/GenAIFSXWorkshopOnEKS.yaml > validate_cfn.txt
```
View the contents of the output (and verify no errors are shown) in-order to validate that the above link to CloudFormation template worked.
```bash
cat validate_cfn.txt
```

**Create stack:**
```bash
aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-url https://${ASSET_BUCKET}.s3.amazonaws.com/${ASSET_BUCKET_PATH}/static/GenAIFSXWorkshopOnEKS.yaml \
  --region $AWS_REGION \
  --parameters \
  ParameterKey=VSCodeUser,ParameterValue=participant \
  ParameterKey=InstanceName,ParameterValue=${VSINSTANCE_NAME} \
  ParameterKey=InstanceVolumeSize,ParameterValue=100 \
  ParameterKey=InstanceType,ParameterValue=t4g.medium \
  ParameterKey=InstanceOperatingSystem,ParameterValue=AmazonLinux-2023 \
  ParameterKey=HomeFolder,ParameterValue=environment \
  ParameterKey=DevServerPort,ParameterValue=8081 \
  ParameterKey=AssetZipS3Path,ParameterValue=${ASSET_BUCKET_ZIPPATH} \
  ParameterKey=Assets,ParameterValue=s3://${ASSET_BUCKET}/${ASSET_BUCKET_PATH}/assets/ \
  --disable-rollback \
  --capabilities CAPABILITY_NAMED_IAM
```

### Part 3: Access your workshop

**Connect to your AWS lab environment via the Open source VSCode IDE**.

You will be using an Open source VSCode IDE terminal to copy and paste the required commands provided in this workshop modules. refer to this link for further information on the [VSCode IDE code-server](https://github.com/coder/code-server)

::alert[Note: Use Google chrome browser for the best user experience with VSCode IDE, as Firefox users may experience some issues with copy-paste commands.]{header="Important" type="warning"}

**Log into your VSCode IDE Instance:**
1. Navigate to the AWS CloudFormation console [link](https://console.aws.amazon.com/cloudformation) and select the `genaifsxworkshoponeks` stack
2. Click on Stack **Outputs**
3. Copy the **Password** and click on the URL to open the VSCode IDE interface
4. Enter the password you copied into the VSCode IDE interface


![CFN-Output](/static/images/cfn-output.png)

5. Select your VSCode UI theme

![Select Theme](/static/images/select-theme.png)

6. Click the top right hand icon to maximize terminal window.

![maximize](/static/images/maximize.png)

### Validate the IAM role

- Use the [GetCallerIdentity](https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html) CLI command to validate that the VSCode IDE is using the correct IAM role.

```bash
aws sts get-caller-identity
```

:::alert{header="Note" type="info"}
The first time you copy-paste a command into the VSCode IDE, your browser may ask you to allow permission, select **"Allow"**.

![allow-clipboard](/static/images/allow-clipboard.png)
:::

- The output of the assumed-role name should look like the following:

![correct-iam-role](/static/images/correct-iam-role.png)

- Set the Amazon EKS cluster variables :

```bash
export CLUSTER_NAME=eksworkshop
```


- Check that your region and cluster names are set correctly, to match your current region.

```bash
echo $AWS_REGION
echo $CLUSTER_NAME
```

## Update the kube-config file:
Before you can start running all the Kubernetes commands included in this workshop, you need to update the kube-config file with the required credentials to access the EKS cluster. In your VSCode IDE terminal, run the below command:

```bash
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
```


## Query the Amazon EKS cluster:
Run the command below to test connectivity to the EKS cluster:

```bash
kubectl get nodes
```

You should see a provisioned node, which was provisioned by EKS Auto-Mode to run some of the core components required for the workshop.

![get-nodes](/static/images/get-nodes.png)

You now now completed the workshop deployment and have a VSCode IDE Server environment ready to use with your Amazon EKS Cluster! Please proceed to the first module of the workshop **[Explore EKS Auto](/030_module_explore_eks_auto)**.

**Note:** Once you have completed the workshop, navigate back to this page, and the below section to perform the **Clean up** tasks.

### Part 4 : Clean up

1. Run the below command (replacing STACK_NAME with your CloudFormation Stack name) to delete the AWS CloudFormation Stack and remove the provisioned workshop, note this will take can take up-to 30 mins.

Note: If you have created any AWS resources outside of the CloudFormation templates provisioned resources, or have modified resources deployed by the original CloudFormation template, then you might encounter errors when deleting the CloudFormation stack. If that occurs, refer to the errors shown and action and/or delete resources as outlined by the CloudFormation  delete stack job.

```bash
aws cloudformation delete-stack --stack-name ${STACK_NAME} --region $AWS_REGION
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME} --region $AWS_REGION
```


