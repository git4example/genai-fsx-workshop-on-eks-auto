---
title : "Deploy webui chat application"
weight : 220
---

Now lets deploy chatboot to interact with our mistral model we deployed in previous step.

```bash
kubectl apply -f open-webui.yaml
````

This will take upto 2 - 5 mins for the application load balancer to be ready to serve chatbot.
```bash
kubectl get ing
```
Copy ADDRESS URL that is displayed for ALB, then open a web browser and enter that URL to open a client.

![WebUI_url](/static/images/WebUI_url.png)

Please note that LLM model may take about 2mins to load in memory before you can load this model dropdown as shown below and start chatting. Until this point, you will not see this model in the dropdown because model endpoint is not communicating with WebUI.

You can refresh the page until you can select mistral model from the top drop-down menu. Once you have selected the model, you can start chatting with the model.


![Open WebUI](/static/images/OpenWebUI.png)



You have now successfully deploy a Generative AI Chatbot as a containerized application running on Amazon EKS, with the model data stored in Amazon FSx Lustre, and powered by AWS Inferentia Accelerators.
