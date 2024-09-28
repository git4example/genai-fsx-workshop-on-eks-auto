---
title : "Deploy WebUI chat application to interact with model"
weight : 220
---

Now lets deploy the chatbot Pod, so we can interact with the Mistral model we deployed in previous step. This will also deploy an application load balancer, which will serve the chatbot WebUI.

```bash
kubectl apply -f open-webui.yaml
````

Now lets get the URL address of the ChatBot application by running the below command

```bash
kubectl get ing
```
Copy the URL ADDRESS, and paste it into a web browser. This will open a WebUI client.

![WebUI_url](/static/images/WebUI_url.png)

In the WebUI client you will see a drop down in the top menu bar, to select your model. Please note that Mistral-7B model (approx 29GB) will take approx. 2mins to load into the vLLM's memory, and you will not see the Mistral-7B model in the dropdown option until the memory load is complete (where model endpoint is communicating with WebUI).

You can refresh the page until you can see and select the Mistral model from the top drop-down menu. Once you have selected the model, you can start chatting with the model.


![Open WebUI](/static/images/OpenWebUI.png)


You have now successfully deployed a Generative AI Chatbot as a containerized application running on Amazon EKS, with the cached model data hosted in Amazon FSx Lustre, and powered by AWS Inferentia Accelerators.
