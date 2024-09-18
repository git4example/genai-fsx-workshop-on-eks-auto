
DO NOT FULL SYNC THIS ASSET BUCKET. WE HAVE "Mistral-7B-Instruct-v0.2" FOLDER ON THIS BUCKET "s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20" WITH 27 GB OF MODEL WHICH WILL BE DELETED IF YOU FULL SYNC


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
docker run -v ./work-dir/:/work-dir/ --entrypoint huggingface-cli public.ecr.aws/parikshit/huggingface-cli download "enghwa/neuron-mistral7bv0.2" --local-dir /work-dir/Mistral-7B-Instruct-v0.2
```

Step 5 : Upload model to asset bucket. In following command replace credentials from the workshop studio to allow access to assets bucket.

```bash
docker run -e AWS_DEFAULT_REGION="region" \
  -e AWS_ACCESS_KEY_ID="<access-id>>" \
  -e AWS_SECRET_ACCESS_KEY="<access-key>" \
  -e AWS_SESSION_TOKEN="<session-token>" \
  -v ./work-dir/:/work-dir/  public.ecr.aws/parikshit/s5cmd cp /work-dir/Mistral-7B-Instruct-v0.2/ s3://ws-assets-us-east-1/fb548aaa-7ac1-4162-9a4c-98efc6943f20/Mistral-7B-Instruct-v0.2/
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


Shortcuts 

```bash
alias k=kubectl
alias ka="kubectl apply -f "
alias kc="kubectl create "
alias ke="kubectl exec -it "
alias kg="kubectl get "
alias kgn="kubectl get node -o=custom-columns='Name:.metadata.name,InternalIP:.status.addresses[?(@.type==\"InternalIP\")].address,ExternalIP:.status.addresses[?(@.type==\"ExternalIP\")].address,ID:.spec.providerID'"
alias kd="kubectl describe "
alias kr="kubectl replace --force -f "
alias kdel="kubectl delete "
alias kex="kubectl explain --recursive "
alias ks="kubectl -n kube-system "
alias ksg="kubectl -n kube-system get "
alias ksd="kubectl -n kube-system describe "
alias kconf="k config set-context $(k config current-context) --namespace "
alias kconfv="k config view"
alias ktest="k run -it netshoot --image=nicolaka/netshoot /bin/bash"
export dry="-o=yaml --dry-run=client"
export w="-o=wide"
export y="-o=yaml"
export j="-o=json"
export l="--show-labels"
export c="-o=custom-columns"
```


- Deploy EKS Job with FSxL PVC to provision FSxL and then deploy pod to pull model on the S3 bucket
- This job should be successfully download model. Once this is successful then we can use this FSxL bucket to be mounted in Mistral pod in next module
- Ask Eng Hwa to install huggingface_hub[hf_transfer] in his container to help pull model faster




## Unable to register fsx luster csi node driver

```log
WSParticipantRole:~/environment/eks/genai $ ks logs fsx-csi-node-pq2mn 
Defaulted container "fsx-plugin" out of: fsx-plugin, node-driver-registrar, liveness-probe
I0909 08:55:33.484429       1 driver.go:61] "Driver Information" Driver="fsx.csi.aws.com" Version="v1.2.0"
I0909 08:55:33.484501       1 metadata.go:72] "retrieving instance data from ec2 metadata"
I0909 08:55:36.628226       1 metadata.go:75] "ec2 metadata is not available"
I0909 08:55:36.628248       1 metadata.go:83] "retrieving instance data from kubernetes api"
I0909 08:55:36.628558       1 metadata.go:88] "kubernetes api is available"
I0909 08:55:36.641170       1 node.go:66] "regionFromSession Node service" region=""
I0909 08:55:43.421070       1 mount_linux.go:243] Detected OS without systemd

WSParticipantRole:~/environment/eks/genai $ ks logs fsx-csi-node-pq2mn -c node-driver-registrar
I0909 08:55:36.751564       1 main.go:135] Version: v2.10.0
I0909 08:55:36.751601       1 main.go:136] Running node-driver-registrar in mode=
I0909 08:55:36.751606       1 main.go:157] Attempting to open a gRPC connection with: "/csi/csi.sock"
I0909 08:55:36.752246       1 main.go:164] Calling CSI driver to discover driver name
I0909 08:55:36.754234       1 main.go:173] CSI driver name: "fsx.csi.aws.com"
I0909 08:55:36.754259       1 node_register.go:55] Starting Registration Server at: /registration/fsx.csi.aws.com-reg.sock
I0909 08:55:36.754376       1 node_register.go:64] Registration Server started at: /registration/fsx.csi.aws.com-reg.sock
I0909 08:55:36.754528       1 node_register.go:88] Skipping HTTP server because endpoint is set to: ""
I0909 08:55:37.146704       1 main.go:90] Received GetInfo call: &InfoRequest{}
I0909 08:55:37.202097       1 main.go:101] Received NotifyRegistrationStatus call: &RegistrationStatus{PluginRegistered:true,Error:,}
WSParticipantRole:~/environment/eks/genai $ 


```


```log
 k logs vllm-mistral-inf2-deployment-65d8f69d55-vv2mc -f 
WARNING 09-09 21:35:36 _custom_ops.py:11] Failed to import from vllm._C with ModuleNotFoundError("No module named 'vllm._C'")
INFO 09-09 21:35:38 api_server.py:177] vLLM API server version 0.5.0
INFO 09-09 21:35:38 api_server.py:178] args: Namespace(host=None, port=8000, uvicorn_log_level='info', allow_credentials=False, allowed_origins=['*'], allowed_methods=['*'], allowed_headers=['*'], api_key=None, lora_modules=None, chat_template=None, response_role='assistant', ssl_keyfile=None, ssl_certfile=None, ssl_ca_certs=None, ssl_cert_reqs=0, root_path=None, middleware=[], model='/work-dir/Mistral-7B-Instruct-v0.2/', tokenizer=None, skip_tokenizer_init=False, revision=None, code_revision=None, tokenizer_revision=None, tokenizer_mode='auto', trust_remote_code=False, download_dir=None, load_format='auto', dtype='auto', kv_cache_dtype='auto', quantization_param_path=None, max_model_len=10240, guided_decoding_backend='outlines', distributed_executor_backend=None, worker_use_ray=False, pipeline_parallel_size=1, tensor_parallel_size=2, max_parallel_loading_workers=None, ray_workers_use_nsight=False, block_size=16, enable_prefix_caching=False, disable_sliding_window=False, use_v2_block_manager=False, num_lookahead_slots=0, seed=0, swap_space=4, gpu_memory_utilization=0.96, num_gpu_blocks_override=None, max_num_batched_tokens=None, max_num_seqs=4, max_logprobs=20, disable_log_stats=False, quantization=None, rope_scaling=None, rope_theta=None, enforce_eager=True, max_context_len_to_capture=None, max_seq_len_to_capture=8192, disable_custom_all_reduce=False, tokenizer_pool_size=0, tokenizer_pool_type='ray', tokenizer_pool_extra_config=None, enable_lora=False, max_loras=1, max_lora_rank=16, lora_extra_vocab_size=256, lora_dtype='auto', long_lora_scaling_factors=None, max_cpu_loras=None, fully_sharded_loras=False, device='neuron', image_input_type=None, image_token_id=None, image_input_shape=None, image_feature_size=None, image_processor=None, image_processor_revision=None, disable_image_processor=False, scheduler_delay_factor=0.0, enable_chunked_prefill=False, speculative_model=None, num_speculative_tokens=None, speculative_max_model_len=None, speculative_disable_by_batch_size=None, ngram_prompt_lookup_max=None, ngram_prompt_lookup_min=None, model_loader_extra_config=None, preemption_mode=None, served_model_name=['mistralai/Mistral-7B-Instruct-v0.2-neuron'], qlora_adapter_name_or_path=None, engine_use_ray=False, disable_log_requests=False, max_log_len=None)
INFO 09-09 21:35:38 config.py:623] Defaulting to use ray for distributed inference
WARNING 09-09 21:35:38 config.py:436] Possibly too large swap space. 8.00 GiB out of the 15.27 GiB total CPU memory is allocated for the swap space.
INFO 09-09 21:35:38 llm_engine.py:161] Initializing an LLM engine (v0.5.0) with config: model='/work-dir/Mistral-7B-Instruct-v0.2/', speculative_config=None, tokenizer='/work-dir/Mistral-7B-Instruct-v0.2/', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, rope_scaling=None, rope_theta=None, tokenizer_revision=None, trust_remote_code=False, dtype=torch.bfloat16, max_seq_len=10240, download_dir=None, load_format=LoadFormat.AUTO, tensor_parallel_size=2, disable_custom_all_reduce=False, quantization=None, enforce_eager=True, kv_cache_dtype=auto, quantization_param_path=None, device_config=cpu, decoding_config=DecodingConfig(guided_decoding_backend='outlines'), seed=0, served_model_name=mistralai/Mistral-7B-Instruct-v0.2-neuron)
WARNING 09-09 21:35:39 utils.py:456] Pin memory is not supported on Neuron.
2024-09-09 21:37:09.000563:  27  INFO ||NEURON_CACHE||: Compile cache path: /work-dir/Mistral-7B-Instruct-v0.2/neuron-cache/
2024-09-09 21:37:09.000565:  27  INFO ||NEURON_CACHE||: Compile cache path: /work-dir/Mistral-7B-Instruct-v0.2/neuron-cache/
2024-09-09 21:37:09.000576:  28  INFO ||NEURON_CACHE||: Compile cache path: /work-dir/Mistral-7B-Instruct-v0.2/neuron-cache/
2024-09-09 21:37:09.000578:  28  INFO ||NEURON_CACHE||: Compile cache path: /work-dir/Mistral-7B-Instruct-v0.2/neuron-cache/
concurrent.futures.process._RemoteTraceback: 
"""
Traceback (most recent call last):
  File "/home/ray/anaconda3/lib/python3.11/concurrent/futures/process.py", line 261, in _process_worker
    r = call_item.fn(*call_item.args, **call_item.kwargs)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/transformers_neuronx/compiler.py", line 471, in compile
    self.build()
  File "/home/ray/anaconda3/lib/python3.11/site-packages/transformers_neuronx/compiler.py", line 478, in build
    self.neff_bytes = compile_hlo_module(self.hlo_module, self.tag)
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/transformers_neuronx/compiler.py", line 121, in compile_hlo_module
    neff_bytes = neuron_xla_compile(module_bytes, flags, input_format="hlo", platform_target="trn1",
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/libneuronxla/neuron_cc_wrapper.py", line 268, in neuron_xla_compile
    neuron_xla_compile_impl(
  File "/home/ray/anaconda3/lib/python3.11/site-packages/libneuronxla/neuron_cc_wrapper.py", line 309, in neuron_xla_compile_impl
    model_exists = compile_cache.exists(model_path)
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/libneuronxla/neuron_cc_cache.py", line 137, in wrapper
    with self.lock_dir:
  File "/home/ray/anaconda3/lib/python3.11/site-packages/libneuronxla/neuron_cc_cache.py", line 118, in __enter__
    self.lock_fd = open(self.lock_path, 'w')
                   ^^^^^^^^^^^^^^^^^^^^^^^^^
PermissionError: [Errno 13] Permission denied: '/work-dir/Mistral-7B-Instruct-v0.2/neuron-cache/lock'
"""

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "<frozen runpy>", line 198, in _run_module_as_main
  File "<frozen runpy>", line 88, in _run_code
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/entrypoints/openai/api_server.py", line 196, in <module>
    engine = AsyncLLMEngine.from_engine_args(
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/engine/async_llm_engine.py", line 395, in from_engine_args
    engine = cls(
             ^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/engine/async_llm_engine.py", line 349, in __init__
    self.engine = self._init_engine(*args, **kwargs)
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/engine/async_llm_engine.py", line 470, in _init_engine
    return engine_class(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/engine/llm_engine.py", line 223, in __init__
    self.model_executor = executor_class(
                          ^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/executor/executor_base.py", line 41, in __init__
    self._init_executor()
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/executor/neuron_executor.py", line 21, in _init_executor
    self._init_worker()
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/executor/neuron_executor.py", line 34, in _init_worker
    self.driver_worker.load_model()
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/worker/neuron_worker.py", line 45, in load_model
    self.model_runner.load_model()
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/worker/neuron_model_runner.py", line 42, in load_model
    self.model = get_neuron_model(self.model_config,
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/model_executor/model_loader/neuron.py", line 127, in get_neuron_model
    model.load_weights(
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/model_executor/model_loader/neuron.py", line 98, in load_weights
    self.model.to_neuron()
  File "/home/ray/anaconda3/lib/python3.11/site-packages/transformers_neuronx/base.py", line 73, in to_neuron
    self.compile()
  File "/home/ray/anaconda3/lib/python3.11/site-packages/transformers_neuronx/base.py", line 55, in compile
    kernel.neff_bytes = neff_bytes_futures[hash_hlo(kernel.hlo_module)].result()
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/concurrent/futures/_base.py", line 456, in result
    return self.__get_result()
           ^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/concurrent/futures/_base.py", line 401, in __get_result
    raise self._exception
PermissionError: [Errno 13] Permission denied: '/work-dir/Mistral-7B-Instruct-v0.2/neuron-cache/lock'
```