
DO NOT FULL SYNC THIS ASSET BUCKET. WE HAVE "Mistral-7B-Instruct-v0.2" FOLDER ON THIS BUCKET "s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20" WITH 27 GB OF MODEL WHICH WILL BE DELETED IF YOU FULL SYNC


## Create stack 

```bash
aws s3 cp ./static/GenAIFSXWorkshopOnEKS.yaml s3://databackupbucket/GenAIFSXWorkshopOnEKS.yaml
aws cloudformation validate-template --template-url https://databackupbucket.s3.amazonaws.com/GenAIFSXWorkshopOnEKS.yaml
```



```bash
export REGION=us-east-2
STACK_NAME=GenAIFSXWorkshopOnEKS
VSINSTANCE_NAME=VSCodeServerForEKS
ASSET_BUCKET_ZIPPATH=""
ASSET_BUCKET=my-genai-fsx-workshop-bucket
ASSET_BUCKET_PATH=genai-fsx-workshop-on-eks


aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-url https://databackupbucket.s3.amazonaws.com/GenAIFSXWorkshopOnEKS.yaml \
  --region $REGION \
  --parameters \
  ParameterKey=VSCodeUser,ParameterValue=participant \
  ParameterKey=InstanceName,ParameterValue=${VSINSTANCE_NAME} \
  ParameterKey=InstanceVolumeSize,ParameterValue=100 \
  ParameterKey=InstanceType,ParameterValue=t4g.medium \
  ParameterKey=InstanceOperatingSystem,ParameterValue=AmazonLinux-2023 \
  ParameterKey=HomeFolder,ParameterValue=environment \
  ParameterKey=DevServerPort,ParameterValue=8081 \
  ParameterKey=AssetZipS3Path,ParameterValue=${ASSET_BUCKET_ZIPPATH} \
  ParameterKey=BranchZipS3Path,ParameterValue="" \
  ParameterKey=FolderZipS3Path,ParameterValue="" \
  ParameterKey=C9KubectlVersion,ParameterValue=1.30.2 \
  ParameterKey=C9NodeViewerVersion,ParameterValue=latest \
  ParameterKey=EKSClusterName,ParameterValue=eksworkshop \
  ParameterKey=EKSClusterVersion,ParameterValue=1.30 \
  ParameterKey=ParticipantAssumedRoleArn,ParameterValue=NONE \
  ParameterKey=ParticipantRoleArn,ParameterValue=NONE \
  ParameterKey=ParticipantRoleArn,ParameterValue=NONE \
  ParameterKey=Assets,ParameterValue=s3://${ASSET_BUCKET}/${ASSET_BUCKET_PATH}/assets/ \
  --disable-rollback \
  --capabilities CAPABILITY_NAMED_IAM
```

## Clean up :
This may take upto 30 mins : 
```bash
aws cloudformation delete-stack --stack-name ${STACK_NAME} --region $REGION
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME} --region $REGION
```



### Stack Creation and deletion times sample  

Create workflow times from local account : 
```bash
RunVSCodeSSMDoc                         - 2024-12-11 14:36:33 UTC+1100 - 2024-12-11 14:41:04 UTC+1100 = ~ 5m
RunInfraDeleteSSMDocument               - 2024-12-11 14:36:33 UTC+1100 - 2024-12-11 14:36:41 UTC+1100 = ~ 10s
RunInfraSSMDocument                     - 2024-12-11 14:41:04 UTC+1100 - 2024-12-11 14:41:35 UTC+1100 = ~ 30s
RunDownloadWorkshopAssetsSSMDocument    - 2024-12-11 14:41:36 UTC+1100 - 2024-12-11 14:43:25 UTC+1100 = ~ 2m
RunSetupFSxLBucketSSMDocument           - 2024-12-11 14:43:26 UTC+1100 - 2024-12-11 14:44:31 UTC+1100 = ~ 1m
RunCreateVPCEKSClusterFSxLSSMDocument   - 2024-12-11 14:44:31 UTC+1100 - 2024-12-11 14:58:17 UTC+1100 = ~ 14m
RunCreateEKSClusterResourceSSMDocument  - 2024-12-11 14:58:18 UTC+1100 - 2024-12-11 15:12:04 UTC+1100 = ~ 14m

Stack : GenAIFSXWorkshopOnEKS           - 2024-12-11 14:33:32 UTC+1100 - 2024-12-11 15:12:05 UTC+1100 = ~ 39m
```

Delete workflow times from local account : (NLB and SG had to be deleted manually)
```bash
RunCreateEKSClusterResourceSSMDocument  - ~ 3s
RunInfraDeleteSSMDocument               - ~ 26m
RunCreateVPCEKSClusterFSxLSSMDocument   - ~ 1s
RunSetupFSxLBucketSSMDocument           - ~ 1s
RunDownloadWorkshopAssetsSSMDocument    - ~ 1s
RunInfraSSMDocument                     - ~ 1s
RunVSCodeSSMDoc                         - ~ 1s

Stack : GenAIFSXWorkshopOnEKS           - 2024-12-11 15:40:28 UTC+1100 - 22024-12-11 16:08:06 UTC+1100 = ~ 28m
```

Workshop Studio : 
Create workflow times from local account : 
```
2024-12-11 16:35:14 UTC+1100
2024-12-11 17:19:33 UTC+1100
stack provisioning : ~ 34m
Account provisioning took total : 00:44:49m
```




### Download install/clean up script on cloud9 in Participant/event account
```bash
ASSET_BUCKET=$(aws cloudformation describe-stacks --stack-name genaifsxworkshoponeks --query "Stacks[0].Parameters[?ParameterKey=='Assets'].ParameterValue" --output text)
ASSET_BUCKET=$(echo $ASSET_BUCKET | sed 's/\/assets\///')    
ASSET_BUCKET=$ASSET_BUCKET/static
cd /home/participant/environment/
aws s3 sync $ASSET_BUCKET/scripts ./scripts    
cd /home/participant/environment/scripts
```

<!-- 
WE DONT NEED THIS:
### USE FOLLOWING COMMANDs TO SYNC S3 TO LOCAL/CLOUD9 : 
```bash
ASSET_BUCKET=<asset bucket>
aws s3 sync $ASSET_BUCKET/eks /home/participant/environment/eks --delete
aws s3 sync $ASSET_BUCKET/terraform /home/participant/environment/terraform --delete
# Following are only required for testing
aws s3 sync $ASSET_BUCKET/download /home/participant/environment/download --delete
aws s3 sync $ASSET_BUCKET/scripts /home/participant/environment/scripts --delete
``` -->

## DOWNLOAD AND UPLOAD MODEL TO ASSET BUCKET
Step 1 : Spin up Cloud 9 environment in your account
Step 2 : change its volume to Size : 100GB , Type : GpP3 , IOPS : 10000 , Throughput : 1000

To modify volume you can use commands like this, you may need to adjust stack name according to your account: 
```bash
C9STACK=$(aws cloudformation list-stacks --query "StackSummaries[?contains(StackName, 'aws-cloud9')].StackName" --output text) 
C9INSTANCE=$(aws cloudformation describe-stack-resources --stack-name "$C9STACK" --query "StackResources[?ResourceType=='AWS::EC2::Instance'].PhysicalResourceId" --output text)
C9VOLUME=$(aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=$C9INSTANCE" --query "Volumes[].VolumeId" --output=text) 
aws ec2 modify-volume --volume-type gp3 --volume-id $C9VOLUME --size 100 --iops 10000 --throughput 1000
```


Stpe 3 : run following commands to expand volume

```bash
sudo lsblk
sudo growpart /dev/nvme0n1 1

# Check filesystem xfs or ext
df -hT
# for xfs filesystem
sudo xfs_growfs -d /

# for ext filesystem
sudo resize2fs /dev/nvme0n1p1
```

Step 4 : Download model 
```bash
docker run -v ./work-dir/:/work-dir/ --entrypoint huggingface-cli public.ecr.aws/parikshit/huggingface-cli:slim download "enghwa/neuron-mistral7bv0.2" --local-dir /work-dir/Mistral-7B-Instruct-v0.2
```

Step 5 : Upload model to asset bucket. In following command replace credentials from the workshop studio to allow access to assets bucket.

```bash
docker run -e AWS_DEFAULT_REGION="region" \
  -e AWS_ACCESS_KEY_ID="<access-id>>" \
  -e AWS_SECRET_ACCESS_KEY="<access-key>" \
  -e AWS_SESSION_TOKEN="<session-token>" \
  -v ./work-dir/:/work-dir/  public.ecr.aws/parikshit/s5cmd cp /work-dir/Mistral-7B-Instruct-v0.2/ s3://<your-bucket>/Mistral-7B-Instruct-v0.2/
```

Step 6 : Check object sizes on bucket
```bash
aws s3 ls --summarize --human-readable --recursive s3://<bucket-name>/
```

Step 7 : Terminate your cloud9 if not required. 



## OTHER WAYS to DOWNLOAD MODEL

Simple download : 
```bash
pip install -U "huggingface_hub[cli]"
huggingface-cli download "enghwa/neuron-mistral7bv0.2" --local-dir Mistral-7B-Instruct-v0.2
```
OR 

Faster download : 
```bash
pip install huggingface_hub[hf_transfer]        
export HF_HUB_ENABLE_HF_TRANSFER=1     
huggingface-cli download "enghwa/neuron-mistral7bv0.2" --local-dir Mistral-7B-Instruct-v0.2 
```


```bash
# 10 mins to download - on gp3 - 3000 iops - 125MB Throughput 
docker run -v ./myMistral:/data/myMistral hello2parikshit/huggingface-cli download enghwa/neuron-mistral7bv0.2 --local-dir /data/myMistral
```

```bash
# 12:24PM - 12:31 PM -- 7 Min on gp3 - 3000 iops - 500MB Throughput 
docker run -v ./neuron-mistral7bv0.2:/data/neuron-mistral7bv0.2 hello2parikshit/huggingface-cli download enghwa/neuron-mistral7bv0.2 --local-dir /data/neuron-mistral7bv0.2
```



```bash
# 7 mins to upload
docker run -v ./myMistral:/data/myMistral hello2parikshit/s5cmd sync /data s3://fsx-lustre-nzbq7b0527ti20240908234144828000000001/myMistral/
```

```bash
# 11:23AM (12:01 -- Still going on) -- > 
./hfdownloader -m enghwa/neuron-mistral7bv0.2 -c 5


## 11:46 AM -- cancelled due to long time taken.
docker run -v ./myMistral:/data/myMistral hello2parikshit/hfdownloader -m -m enghwa/neuron-mistral7bv0.2 -c 10
```


OR 

```bash
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | sudo bash
sudo yum install git-lfs 
git lfs install
git clone https://huggingface.co/enghwa/neuron-mistral7bv0.2
```

## UPLOAD MODEL to S3

```bash
go install github.com/peak/s5cmd/v2@master

```

Check object sizes on bucket
```bash
aws s3 ls --summarize --human-readable --recursive s3://<bucket-name>/
```




To modify volume : 
```bash
C9STACK=$(aws cloudformation list-stacks --query "StackSummaries[?contains(StackName, 'aws-cloud9')].StackName" --output text) 
C9INSTANCE=$(aws cloudformation describe-stack-resources --stack-name "$C9STACK" --query "StackResources[?ResourceType=='AWS::EC2::Instance'].PhysicalResourceId" --output text)
C9VOLUME=$(aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=$C9INSTANCE" --query "Volumes[].VolumeId" --output=text) 
aws ec2 modify-volume --volume-type gp3 --volume-id $C9VOLUME --size 100 --iops 10000 --throughput 1000
```


Check object sizes on bucket
```bash
aws s3 ls s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20 --recursive --human-readable --summarize
```


## Shortcuts 

```bash
alias k=kubectl
alias ka="kubectl apply -f "
alias ke="kubectl exec -it "
alias kg="kubectl get "
alias kd="kubectl describe "
alias kdel="kubectl delete "
alias kl='kubectl -n karpenter logs -l app.kubernetes.io/name=karpenter --all-containers=true -f --tail=20'
alias ks="kubectl -n kube-system "
alias ksg="kubectl -n kube-system get "
alias ksd="kubectl -n kube-system describe "
alias ktest="k run -it netshoot --image=nicolaka/netshoot /bin/bash"
```

## Model loaded in 2.5 mins

```
WSParticipantRole:~/environment/eks/genai $ kg po -w
NAME                                            READY   STATUS    RESTARTS   AGE
kube-ops-view-5d9d967b77-vqdnb                  1/1     Running   0          5h49m
vllm-mistral-inf2-deployment-7d886c8cc8-5dwcx   0/1     Pending   0          3s
vllm-mistral-inf2-deployment-7d886c8cc8-5dwcx   0/1     Pending   0          11s
vllm-mistral-inf2-deployment-7d886c8cc8-5dwcx   0/1     Pending   0          19s
vllm-mistral-inf2-deployment-7d886c8cc8-5dwcx   0/1     ContainerCreating   0          19s
open-webui-deployment-5d7ff94bc9-6s7f9          0/1     Pending             0          0s
open-webui-deployment-5d7ff94bc9-6s7f9          0/1     Pending             0          0s
open-webui-deployment-5d7ff94bc9-6s7f9          0/1     ContainerCreating   0          0s
open-webui-deployment-5d7ff94bc9-6s7f9          1/1     Running             0          70s
vllm-mistral-inf2-deployment-7d886c8cc8-5dwcx   1/1     Running             0          2m25s
```

```
$ k logs vllm-mistral-inf2-deployment-7d886c8cc8-5dwcx -f
WARNING 09-23 00:07:19 _custom_ops.py:11] Failed to import from vllm._C with ModuleNotFoundError("No module named 'vllm._C'")
INFO 09-23 00:07:22 api_server.py:177] vLLM API server version 0.5.0
INFO 09-23 00:07:22 api_server.py:178] args: Namespace(host=None, port=8000, uvicorn_log_level='info', allow_credentials=False, allowed_origins=['*'], allowed_methods=['*'], allowed_headers=['*'], api_key=None, lora_modules=None, chat_template=None, response_role='assistant', ssl_keyfile=None, ssl_certfile=None, ssl_ca_certs=None, ssl_cert_reqs=0, root_path=None, middleware=[], model='/work-dir/Mistral-7B-Instruct-v0.2/', tokenizer=None, skip_tokenizer_init=False, revision=None, code_revision=None, tokenizer_revision=None, tokenizer_mode='auto', trust_remote_code=False, download_dir=None, load_format='auto', dtype='auto', kv_cache_dtype='auto', quantization_param_path=None, max_model_len=10240, guided_decoding_backend='outlines', distributed_executor_backend=None, worker_use_ray=False, pipeline_parallel_size=1, tensor_parallel_size=2, max_parallel_loading_workers=None, ray_workers_use_nsight=False, block_size=16, enable_prefix_caching=False, disable_sliding_window=False, use_v2_block_manager=False, num_lookahead_slots=0, seed=0, swap_space=4, gpu_memory_utilization=0.96, num_gpu_blocks_override=None, max_num_batched_tokens=None, max_num_seqs=4, max_logprobs=20, disable_log_stats=False, quantization=None, rope_scaling=None, rope_theta=None, enforce_eager=True, max_context_len_to_capture=None, max_seq_len_to_capture=8192, disable_custom_all_reduce=False, tokenizer_pool_size=0, tokenizer_pool_type='ray', tokenizer_pool_extra_config=None, enable_lora=False, max_loras=1, max_lora_rank=16, lora_extra_vocab_size=256, lora_dtype='auto', long_lora_scaling_factors=None, max_cpu_loras=None, fully_sharded_loras=False, device='neuron', image_input_type=None, image_token_id=None, image_input_shape=None, image_feature_size=None, image_processor=None, image_processor_revision=None, disable_image_processor=False, scheduler_delay_factor=0.0, enable_chunked_prefill=False, speculative_model=None, num_speculative_tokens=None, speculative_max_model_len=None, speculative_disable_by_batch_size=None, ngram_prompt_lookup_max=None, ngram_prompt_lookup_min=None, model_loader_extra_config=None, preemption_mode=None, served_model_name=['mistralai/Mistral-7B-Instruct-v0.2-neuron'], qlora_adapter_name_or_path=None, engine_use_ray=False, disable_log_requests=False, max_log_len=None)
INFO 09-23 00:07:22 config.py:623] Defaulting to use ray for distributed inference
WARNING 09-23 00:07:22 config.py:436] Possibly too large swap space. 8.00 GiB out of the 15.27 GiB total CPU memory is allocated for the swap space.
INFO 09-23 00:07:22 llm_engine.py:161] Initializing an LLM engine (v0.5.0) with config: model='/work-dir/Mistral-7B-Instruct-v0.2/', speculative_config=None, tokenizer='/work-dir/Mistral-7B-Instruct-v0.2/', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, rope_scaling=None, rope_theta=None, tokenizer_revision=None, trust_remote_code=False, dtype=torch.bfloat16, max_seq_len=10240, download_dir=None, load_format=LoadFormat.AUTO, tensor_parallel_size=2, disable_custom_all_reduce=False, quantization=None, enforce_eager=True, kv_cache_dtype=auto, quantization_param_path=None, device_config=cpu, decoding_config=DecodingConfig(guided_decoding_backend='outlines'), seed=0, served_model_name=mistralai/Mistral-7B-Instruct-v0.2-neuron)
WARNING 09-23 00:07:23 utils.py:456] Pin memory is not supported on Neuron.


2024-09-23 00:08:59.000814:  27  INFO ||NEURON_CACHE||: Compile cache path: /work-dir/Mistral-7B-Instruct-v0.2/neuron-cache/
2024-09-23 00:08:59.000900:  28  INFO ||NEURON_CACHE||: Compile cache path: /work-dir/Mistral-7B-Instruct-v0.2/neuron-cache/
2024-09-23 00:09:00.000437:  27  INFO ||NEURON_CC_WRAPPER||: Using a cached neff at /work-dir/Mistral-7B-Instruct-v0.2/neuron-cache/neuronxcc-2.14.227.0+2d4f85be/MODULE_b100285780ea94e4e6ea+2c2d707e/model.neff. Exiting with a successfully compiled graph.
2024-09-23 00:09:00.000441:  27  INFO ||NEURON_CACHE||: Compile cache path: /work-dir/Mistral-7B-Instruct-v0.2/neuron-cache/
2024-09-23 00:09:00.000471:  28  INFO ||NEURON_CC_WRAPPER||: Using a cached neff at /work-dir/Mistral-7B-Instruct-v0.2/neuron-cache/neuronxcc-2.14.227.0+2d4f85be/MODULE_8ece72ba8982f6779d71+2c2d707e/model.neff. Exiting with a successfully compiled graph.
2024-09-23 00:09:00.000490:  28  INFO ||NEURON_CACHE||: Compile cache path: /work-dir/Mistral-7B-Instruct-v0.2/neuron-cache/
2024-Sep-23 00:09:01.0809 1:26 [1] include/socket.h:270 CCOM WARN Skipping IPv6 loopback adddress
2024-Sep-23 00:09:01.0817 1:26 [1] init.cc:108 CCOM WARN Linux kernel 5.10 requires setting FI_EFA_FORK_SAFE=1 environment variable.  Multi-node support will be disabled.
Please restart with FI_EFA_FORK_SAFE=1 set.
2024-Sep-23 00:09:01.0830 1:26 [1] include/socket.h:270 CCOM WARN Skipping IPv6 loopback adddress
2024-Sep-23 00:09:01.0830 1:25 [0] include/socket.h:270 CCOM WARN Skipping IPv6 loopback adddress
INFO 09-23 00:09:22 serving_chat.py:92] Using default chat template:
INFO 09-23 00:09:22 serving_chat.py:92] {%- if messages[0]['role'] == 'system' %}
INFO 09-23 00:09:22 serving_chat.py:92]     {%- set system_message = messages[0]['content'] %}
INFO 09-23 00:09:22 serving_chat.py:92]     {%- set loop_messages = messages[1:] %}
INFO 09-23 00:09:22 serving_chat.py:92] {%- else %}
INFO 09-23 00:09:22 serving_chat.py:92]     {%- set loop_messages = messages %}
INFO 09-23 00:09:22 serving_chat.py:92] {%- endif %}
INFO 09-23 00:09:22 serving_chat.py:92] 
INFO 09-23 00:09:22 serving_chat.py:92] {{- bos_token }}
INFO 09-23 00:09:22 serving_chat.py:92] {%- for message in loop_messages %}
INFO 09-23 00:09:22 serving_chat.py:92]     {%- if (message['role'] == 'user') != (loop.index0 % 2 == 0) %}
INFO 09-23 00:09:22 serving_chat.py:92]         {{- raise_exception('After the optional system message, conversation roles must alternate user/assistant/user/assistant/...') }}
INFO 09-23 00:09:22 serving_chat.py:92]     {%- endif %}
INFO 09-23 00:09:22 serving_chat.py:92]     {%- if message['role'] == 'user' %}
INFO 09-23 00:09:22 serving_chat.py:92]         {%- if loop.first and system_message is defined %}
INFO 09-23 00:09:22 serving_chat.py:92]             {{- ' [INST] ' + system_message + '\n\n' + message['content'] + ' [/INST]' }}
INFO 09-23 00:09:22 serving_chat.py:92]         {%- else %}
INFO 09-23 00:09:22 serving_chat.py:92]             {{- ' [INST] ' + message['content'] + ' [/INST]' }}
INFO 09-23 00:09:22 serving_chat.py:92]         {%- endif %}
INFO 09-23 00:09:22 serving_chat.py:92]     {%- elif message['role'] == 'assistant' %}
INFO 09-23 00:09:22 serving_chat.py:92]         {{- ' ' + message['content'] + eos_token}}
INFO 09-23 00:09:22 serving_chat.py:92]     {%- else %}
INFO 09-23 00:09:22 serving_chat.py:92]         {{- raise_exception('Only user and assistant roles are supported, with the exception of an initial optional system message!') }}
INFO 09-23 00:09:22 serving_chat.py:92]     {%- endif %}
INFO 09-23 00:09:22 serving_chat.py:92] {%- endfor %}
INFO 09-23 00:09:22 serving_chat.py:92] 
WARNING 09-23 00:09:22 serving_embedding.py:141] embedding_mode is False. Embedding API will not work.
INFO:     Started server process [1]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     10.0.99.182:33646 - "GET /v1/models HTTP/1.1" 200 OK
INFO 09-23 00:09:32 metrics.py:341] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO 09-23 00:09:42 metrics.py:341] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO:     10.0.99.182:59268 - "GET /v1/models HTTP/1.1" 200 OK
```