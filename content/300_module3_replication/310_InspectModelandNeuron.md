---
title : "Inspect vLLM, Mistral-7B model, and Neuron performance tools"
weight : 310

---
In this section, you will log-in to the vLLM Pod, inspect the Mistral-7B  model, Inspect Neuron cores and use Neuron tools to monitor performance, and generate a test file to test automatic data export from FSx for Lustre to your S3 bucket.


##### Step 1: Login to vLLM Pod, Inspect LLM model data

1. Navigate to back to your VSCode IDE terminal and change to your working directory.

::code[cd /home/participant/environment/eks/FSxL]{language=bash showLineNumbers=false showCopyAction=true}

2. Now lets log into the vLLM Pod, first we need to get the pod name by running the following command

::code[kubectl get pods]{language=bash showLineNumbers=false showCopyAction=true}

From the output, copy the name shown in your environment that starts with **vllm**

![vllm_name](/static/images/vllm_name.png)

3. Log into your vLLM pod by running the below command, by replacing the value of **YOUR-vLLM-POD-NAME** with the value you just copied.

::code[kubectl exec -it YOUR-vLLM-POD-NAME -- bash]{language=bash showLineNumbers=false showCopyAction=true}



4. We will now inspect the layout of the model data on the vLLM. When you run the below command you will see a mount point called **work-dir**, which is the mount location of your Persistent Volume Claim (backed by FSx for Lustre file system).


::code[df -h]{showCopyAction=true showLineNumbers=false language=bash}


![vllm_02](/static/images/vllm_02.png)

5. Lets inspect what's stored in this Persistent Volume

:::code{showCopyAction=true showLineNumbers=true language=bash}
cd /work-dir/
ls -ll
:::

You can see the Mistral-7B Model is stored here. Lets have a look at what the model data structure looks like.

:::code{showCopyAction=true showLineNumbers=true language=bash}
cd Mistral-7B-Instruct-v0.2/
ls -ll
:::


Here is a description of the model data you are seeing in the Mistral model folder.

| File | Purpose | Details |
|------|-----------|-----------|
| PyTorch | Contains model weights and parameters |  Used for Model architecture and learned parameters storage. Can be converted to different formats (NEFF, etc.) |
| Tokenizer | Contains vocabulary and rules for text processing | Used for converting raw text to/from numerical tokens
| Config |  Contains model architecture and settings | Used to define model structure & parameters  |

:::alert{header="Note" type="info"}
When using vLLM with AWS Neuron devices, a dedicated model executor is employed. The process works as follows:

- The model's structure and weights are first loaded
- If not previously compiled, the model is compiled for Neuron hardware using tools like neuronx-cc
- The compiled model is then deployed to Neuron cores for running inference
- During compilation, the PyTorch model is converted into NEFF (Neuron Executable File Format). NEFF is an optimized format specifically designed for Neuron hardware acceleration. This optimized NEFF format ensures efficient model execution on Neuron devices.
:::



##### Step 2: Inspect Neuron cores config and performance

Run the below command to view the number of AWS Inferentia2 devices on your instance.

::code[neuron-ls]{showCopyAction=true showLineNumbers=false language=bash}

Let's view the performance of your AWS Inferentia2 node by running the **neuron-top** command. The neuron-top command provides information about NeuronCore and vCPU utilization, memory usage, loaded models, and Neuron applications.

::code[neuron-top]{showCopyAction=true showLineNumbers=false language=bash}

![neuron-top](/static/images/neuron-top.png)

Now re-size the neuron-top browserwindow and also the existing WebUI browser session to your Chatbot, so they are side-by-side on your monitor.

Ask the Chatbot a question, and then pay close attention to the **NeuronCores V2 utilization section** as your Chatbot processes your input/output tokens. Notice the optimized performance of AWS Inferentia2, which is designed to use all available Neuron core utilization capacity to process a request.

Press `q` to exit from `neuron-top` screen and return back to pod exec shell.

::code[q]{showCopyAction=true showLineNumbers=false language=bash}


Finally exit from the pod, and back to the terminal window for the next module.

::code[exit]{showCopyAction=true showLineNumbers=false language=bash}

## Summary

In this module you have logged into the vLLM, viewed the mounted PV and the hosted Mistal model data, and used the Neuron tools to monitor performance.
