
DO NOT FULL SYNC THIS ASSET BUCKET. WE HAVE "neuron-mistral7bv0.2" FOLDER ON THIS BUCKET "s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20" WITH 29 GB OF MODEL WHICH WILL BE DELETED IF YOU FULL SYNC



USE FOLLOWING COMMANDs TO SYNC YOUR LOCAL TO S3 : 
```bash
aws s3 sync ./assets/eks s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20/eks --delete
aws s3 sync ./assets/karpenter s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20/karpenter --delete
aws s3 sync ./assets/terraform s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20/terraform --delete
```

USE FOLLOWING COMMANDs TO SYNC S3 TO LOCAL/CLOUD9 : 
```bash
aws s3 sync s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20/eks /home/ec2-user/environment/eks --delete
aws s3 sync s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20/karpenter /home/ec2-user/environment/karpenter --delete
aws s3 sync s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20/terraform /home/ec2-user/environment/terraform --delete
```

DOWNLOAD MODEL

```bash
huggingface-cli download "enghwa/neuron-mistral7bv0.2" --local-dir <your directory>

```