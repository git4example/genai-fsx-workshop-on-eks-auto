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
Copy ADDRESS url for ALB an open in new browser tab.

Please note that LLM model may take about 2 - 5 mins to load in memory before you can load this model dropdown as shown below and start chatting. Until this point, you will not see this model in the dropdown because model endpoint is not communicating with webui. 

You can refresh page after sometime to see if its ready to serve the model, Once its available in dropdown, select mistral model and start chatting with our mistral model .. 

![Open WebUI](/static/images/OpenWebUI.png)

