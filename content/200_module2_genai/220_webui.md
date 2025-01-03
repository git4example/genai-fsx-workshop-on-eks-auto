---
title : "Deploy WebUI chat application to interact with model"
weight : 220
---
### How to consume the Inference Service
You can connect to the Inference Service using the **"Open WebUI"** application, which is designed to consume the OpenAI-compatible endpoint provided by the vLLM-hosted Mistral-7B-Instruct model that you will deploy in the workshop. The Open WebUI application allows users to interact with the LLM model through a chat-based interface. To use the Open WebUI application, simply deploy the application container, and connect to the WebUI URL that is provided and start chatting with the LLM model. The WebUI application will handle the communication with the VLLM-hosted Mistral-7B-Instruct model, providing a seamless user experience.

### Deploy the Open WebUI pod and load balance.

1. Run the below command to deploy the Open WebUI application Pod, so we can interact with the vLLM Mistral model, that we deployed in previous step. This will also deploy an application load balancer, which will serve the chatbot Open WebUI Chat user interface.

::code[kubectl apply -f open-webui.yaml]{language=bash showLineNumbers=false showCopyAction=true}

2. Let's obtain the URL ADDRESS of the Open WebUI Chat interface by running the below command

::code[kubectl get ing]{language=bash showLineNumbers=false showCopyAction=true}

3. Now wait 1-2 minutes (for the OpenWeb UI to deploy) then copy above the URL ADDRESS, and paste it into a web browser. This will open a Open WebUI chat client interface.
:::alert{header="Note" type="info"}
Please make sure your URL is "**http:**//< URL ADDRESS >". Some browser like chrome try **"https"** by default if you dont provide protocol. (note extra **"s"** in protocol)
:::

![WebUI_url](/static/images/WebUI_url.png)

4. In the WebUI interface you will see a drop down in the top menu bar, used to select your model. Select the Mistral-7B model from the drop down, and start chatting with your newly deployed Generative AI chat application.

If you don't see the Mistral-7B model, please refresh the WebUI page until you can see the model in the top drop-down selection menu. (Remember from the previous lab module, that the vLLM Pod and the model load into memory will take approx. 7-8 minutes)

![Open WebUI](/static/images/OpenWebUI.png)


You have now successfully deployed a Generative AI Chatbot as a containerized application running on Amazon EKS, with the cached Mistral-7B model hosted on Amazon FSx Lustre, and the compute powered by AWS Inferentia Accelerators.

:::alert{header="Note" type="info"}
Don't close your WebUI browser session, as you will need it for the next module 
:::
