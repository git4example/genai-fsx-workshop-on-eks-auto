---
title : "Deploy Open WebUI chat application to interact with model"
weight : 220
---
## Overview

In this section you will deploy the Open WebUI (chatbot UI client), and run through example prompts and view Generative-AI output.

### How to consume an Inference endpoint from an Inference engine.
A chatbot UI can interact with an Inference engine by accessing the Inference engine endpoint. The **"Open WebUI"** application is designed to consume the OpenAI-compatible endpoint provided by the vLLM Inference engine that is serving the Mistral-7B model. The Open WebUI application allows users to interact with the LLM model through a chat-based interface. To use the Open WebUI application, you need to  deploy the application container and define the inference endpoint, then connect to the Open WebUI URL and start chatting with the LLM model. The WebUI application will handle the communication with the vLLM that is serving the Mistral-7B LLM model.

<br></br>

-------------------------
### Step 1: Deploy the Open WebUI pod.
-------------------------

1. Run the below command to deploy the Open WebUI application Pod, so we can interact with the vLLM Mistral model, that we deployed in previous step. This will also deploy an application load balancer, which will serve the chatbot Open WebUI Chat user interface.

::code[kubectl apply -f open-webui.yaml]{language=bash showLineNumbers=false showCopyAction=true}

2. Let's obtain the URL ADDRESS of the Open WebUI Chat interface by running the below command (if you dont get a URL address output, run the command again)

::code[kubectl get ing]{language=bash showLineNumbers=false showCopyAction=true}

![WebUI_url](/static/images/WebUI_url.png)

3. The Open WebUI and load balancer will take up-to **2 minutes to come online**. Once you have waited 2 minutes, copy above the URL ADDRESS into a web browser as "*http://<-URL-ADDRESS->*". This will open a Open WebUI chat client interface.

:::alert{header="Note" type="info"}
Make sure your URL is "**http:**//<-URL-ADDRESS->" and doesn't start with "**https:**". Some browser like chrome try **"https"** by default if you dont provide protocol.
:::


4. In the Open WebUI interface you will see a drop down in the top menu bar, used to select your model. Select the Mistral-7B model from the drop down, and start chatting with your newly deployed Generative AI chat application.

If you don't see the Mistral-7B model, please refresh the WebUI page until you can see the model in the top drop-down selection menu. (Remember from the previous lab module, that the vLLM Pod and the model load into memory will take approx. 7 minutes)

![Open WebUI](/static/images/OpenWebUI.png)

You can also see when vLLM Pod and the Mistral model has been loaded into the vLLM memory by running below command into your terminal session, and seeing the "*Application startup complete*" in the output.

::code[kubectl logs <your-vLLM-pod-name> -f]{language=bash showLineNumbers=false showCopyAction=true}



5. You have now successfully deployed a Generative AI Chatbot as a containerized application running on Amazon EKS, with the cached Mistral-7B model hosted on Amazon FSx Lustre, and the compute powered by AWS Inferentia Accelerators.

-------------------------

### Step 2: Run example input prompt queries and view Generative-AI output.

---

✅   Task 1  | Scripting task
---

- Ask the Chatbot to generate a quick script for us. Copy and paste the below example prompt into the Chatbot (or write your own).

::code[write a Linux bash script that creates files, taking inputs for the size of the file (in terms of KB), the number of files to create, the number of concurrent file creation threads for the script to execute, where each file has the words "this is a test file" in it. Each created filename starts with "test" and has a 5 digit suffix appended to it, starting with 00000]{language=bash showLineNumbers=false showCopyAction=true}



✅   Task 2  | Language translation task
---

-  Ask the Chatbot to perform a language translation, without telling it what language the document is in.
-  Download the document : https://pages.awscloud.com/rs/112-TZM-766/images/AWS-Summit-Japan-2025-EXPO-Guide.pdf



- Open the PDF, go to page 4, and copy one of the session descriptions thats in  Japanese (for example the one shown in the image below). You can copy a section by highlighting a section of the Japanese text using your mouse, then select copy.



![AWS Summit Tokyo session](/static/images/aws_summit_tokyo_session.jpg)



- Then ask the Chatbot to perform the following:

::code[translate this : <paste the Japanese language section that you copied>]{language=bash showLineNumbers=false showCopyAction=true}



✅   Task 3  | Context for input prompts using a context document
---


For this testing, lets first ask the Chatbot the following question, without any context documents :
- Ask the Chatbot "What is MCP"

<br>

- Then ask "What is the guidance for deploying an MCP server"

<br>

- Without context or a reference document, its not talking about the **Model Context Protocol Server** that we were asking about in relation to Generative AI.  
<br>


:::alert{header="Note" type="info"}
You can give the Chatbot context for prompts by attaching files directly to the prompt, or by creating a library of documents (Workspaces -> knowledge) that you can reference in your prompts.
:::


- Now lets give the Chatbot some context for our query on MCP. Download this file, which we will use to apply local context: https://d1.awsstatic.com/solutions/guidance/architecture-diagrams/deploying-model-context-protocol-servers-on-aws.pdf

<br></br>

- In your Chatbot session click on the "**+**" icon in your prompt, and select **Upload files**, and select the file you downloaded.

<br>

- Now run the same prompt again ""What is the guidance for deploying an MCP server"

<br>

- As you can see, the GenAI application used the attached file for local context to provide a more specific response to query we were looking for, in terms of Generative-AI.

<br>

- You have now completed this module. **DO NOT CLOSE** your Open WebUI Chatbot browser session, you will need this for the next module of the workshop



### Summary
You have now completed this module, and have deployed your own Generative-AI Chatbot using an Open WebUI client to interface to vLLM inference engine, which is serving the Mistral-7B LLM, from an FSx for Lustre based Persistent Volume. You have also seen the different Generative-AI output capabilities of the model by running different prompt scenarios.
