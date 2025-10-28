---
title : "Deploy WebUI chat application to interact with model"
weight : 220
---
## Overview

In this section you will deploy the Open WebUI (chatbot UI client), and run through example prompts and view Generative-AI output.

### How to consume an Inference endpoint from an Inference engine.
A chatbot UI can interact with an Inference engine by accessing the Inference engine endpoint. The **"Open WebUI"** application is designed to consume the OpenAI-compatible endpoint provided by the vLLM Inference engine that is serving the Mistral-7B model. The Open WebUI application allows users to interact with the LLM model through a chat-based interface. To use the Open WebUI application, you need to  deploy the application container and define the inference endpoint, then connect to the Open WebUI URL and start chatting with the LLM model. The WebUI application will handle the communication with the vLLM that is serving the Mistral-7B LLM model.

<br></br>

### Deploy the Open WebUI pod.

1. Run the below command to deploy the Open WebUI application Pod, so we can interact with the vLLM Mistral model, that we deployed in previous step. This will also deploy an application load balancer, which will serve the chatbot Open WebUI Chat user interface.

::code[kubectl apply -f open-webui.yaml]{language=bash showLineNumbers=false showCopyAction=true}

2. Let's obtain the URL ADDRESS of the Open WebUI Chat interface by running the below command

::code[kubectl get ing]{language=bash showLineNumbers=false showCopyAction=true}

![WebUI_url](/static/images/WebUI_url.png)

3. Now wait 2 minutes (for the Open Web UI to deploy) then copy above the URL ADDRESS, and paste it into a web browser as "*http://<-URL-ADDRESS->*". This will open a Open WebUI chat client interface.

:::alert{header="Note" type="info"}
Make sure your URL is "**http:**//<-URL-ADDRESS->" and doesn't start with "**https:**". Some browser like chrome try **"https"** by default if you dont provide protocol.
:::


4. In the Open WebUI interface you will see a drop down in the top menu bar, used to select your model. Select the Mistral-7B model from the drop down, and start chatting with your newly deployed Generative AI chat application.

If you don't see the Mistral-7B model, please refresh the WebUI page until you can see the model in the top drop-down selection menu. (Remember from the previous lab module, that the vLLM Pod and the model load into memory will take approx. 7-8 minutes)

![Open WebUI](/static/images/OpenWebUI.png)

You can also see when vLLM Pod and the Mistral model has been loaded into the vLLM memory by running below command and seeing the "*Application startup complete*" in the output.

::code[kubectl logs <your-vLLM-pod-name> -f]{language=bash showLineNumbers=false showCopyAction=true}


5. You have now successfully deployed a Generative AI Chatbot as a containerized application running on Amazon EKS, with the cached Mistral-7B model hosted on Amazon FSx Lustre, and the compute powered by AWS Inferentia Accelerators.

<br>

<br>


### Run the below example prompt queries using the Chatbot, and view Generative-AI output.


<br>


1. **Scripting task** - Ask the Chatbot to generate a quick script for us. Copy and paste the below example prompt into the Chatbot (or write your own).

::code[write a Linux bash script that creates files, taking inputs for the size of the file (in terms of KB), the number of files to create, the number of concurrent file creation threads for the script to execute, where each file has the words "this is a test file" in it. Each created filename starts with "test" and has a 5 digit suffix appended to it, starting with 00000]{language=bash showLineNumbers=false showCopyAction=true}


<br>


2. **Language translation task** - Ask the Chatbot to perform a language translation, without telling it what language the document is in.
-  Download the document : https://pages.awscloud.com/rs/112-TZM-766/images/AWS-Summit-Japan-2025-EXPO-Guide.pdf

- Open the PDF, go to page 4, and copy one of the session descriptions thats in  Japanese (for example the one shown in the image below). You can copy a section by highlighting a section of the Japanese text using your mouse, then select copy.

![AWS Summit Tokyo session](/static/images/aws_summit_tokyo_session.jpg)

- Then ask the Chatbot to perform the following:

::code[translate this : <paste the Japanese language section that you copied>]{language=bash showLineNumbers=false showCopyAction=true}

<br>


3. **Context for prompts using files**

For this testing first ask chat bot without any document upload :
- Ask the Chatbot "What is MCP"

<br>

- Then ask "What is the guidance for deploying an MCP server"

<br>

- Without context or a reference document, its not talking about the **Model Context Protocol Server** that we were asking about in relation to Generative AI.  
<br>


:::alert{header="Note" type="info"}
**Note**: You can give the Chatbot context for prompts by attaching files directly to the prompt, or by creating a library of documents (Workspaces -> knowledge) that you can reference in your prompts.
:::


- Now lets give the Chatbot some context for our query on MCP. Download this file, which we will use to apply local context: https://d1.awsstatic.com/solutions/guidance/architecture-diagrams/deploying-model-context-protocol-servers-on-aws.pdf

<br>

- In your Chatbot session click on the "**+**" icon in your prompt, and select **Upload files**, and select the file you downloaded.

<br>

- Now run the same prompt again ""What is the guidance for deploying an MCP server"

<br>

- As you can see, the GenAI application used the attached file for local context to provide a more specific response to query we were looking for, in terms of Generative-AI.

<br>


:::alert{header="Note" type="info"}
Do not close your WebUI browser session, you will need it for the next module.
:::


### Summary
You have now completed this module, and have deployed your own Generative-AI Chatbot using an Open WebUI client to interface to vLLM inference engine, which is serving the Mistral-7B LLM, from an FSx for Lustre based Persistent Volume. You have also seen the different Generative-AI output capabilities of the model by running different prompt scenarios.
