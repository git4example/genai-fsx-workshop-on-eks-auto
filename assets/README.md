
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

## DOWNLOAD MODEL

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
aws ec2 modify-volume --volume-id $C9VOLUME --size 100
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




```bash
sudo lsblk
sudo growpart /dev/nvme0n1 1
# for xfs filesystem
sudo xfs_growfs -d /

# for ext filesystem
sudo resize2fs /dev/nvme0n1p1
```

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
$ k logs vllm-mistral-inf2-deployment-66c8966cfc-sjbbs 
WARNING 09-09 02:04:04 _custom_ops.py:11] Failed to import from vllm._C with ModuleNotFoundError("No module named 'vllm._C'")
INFO 09-09 02:04:06 api_server.py:177] vLLM API server version 0.5.0
INFO 09-09 02:04:06 api_server.py:178] args: Namespace(host=None, port=8000, uvicorn_log_level='info', allow_credentials=False, allowed_origins=['*'], allowed_methods=['*'], allowed_headers=['*'], api_key=None, lora_modules=None, chat_template=None, response_role='assistant', ssl_keyfile=None, ssl_certfile=None, ssl_ca_certs=None, ssl_cert_reqs=0, root_path=None, middleware=[], model='/work-dir/Mistral-7B-Instruct-v0.2/', tokenizer=None, skip_tokenizer_init=False, revision=None, code_revision=None, tokenizer_revision=None, tokenizer_mode='auto', trust_remote_code=False, download_dir=None, load_format='auto', dtype='auto', kv_cache_dtype='auto', quantization_param_path=None, max_model_len=10240, guided_decoding_backend='outlines', distributed_executor_backend=None, worker_use_ray=False, pipeline_parallel_size=1, tensor_parallel_size=2, max_parallel_loading_workers=None, ray_workers_use_nsight=False, block_size=16, enable_prefix_caching=False, disable_sliding_window=False, use_v2_block_manager=False, num_lookahead_slots=0, seed=0, swap_space=4, gpu_memory_utilization=0.96, num_gpu_blocks_override=None, max_num_batched_tokens=None, max_num_seqs=4, max_logprobs=20, disable_log_stats=False, quantization=None, rope_scaling=None, rope_theta=None, enforce_eager=True, max_context_len_to_capture=None, max_seq_len_to_capture=8192, disable_custom_all_reduce=False, tokenizer_pool_size=0, tokenizer_pool_type='ray', tokenizer_pool_extra_config=None, enable_lora=False, max_loras=1, max_lora_rank=16, lora_extra_vocab_size=256, lora_dtype='auto', long_lora_scaling_factors=None, max_cpu_loras=None, fully_sharded_loras=False, device='neuron', image_input_type=None, image_token_id=None, image_input_shape=None, image_feature_size=None, image_processor=None, image_processor_revision=None, disable_image_processor=False, scheduler_delay_factor=0.0, enable_chunked_prefill=False, speculative_model=None, num_speculative_tokens=None, speculative_max_model_len=None, speculative_disable_by_batch_size=None, ngram_prompt_lookup_max=None, ngram_prompt_lookup_min=None, model_loader_extra_config=None, preemption_mode=None, served_model_name=['mistralai/Mistral-7B-Instruct-v0.2-neuron'], qlora_adapter_name_or_path=None, engine_use_ray=False, disable_log_requests=False, max_log_len=None)
Traceback (most recent call last):
  File "/home/ray/anaconda3/lib/python3.11/site-packages/transformers/utils/hub.py", line 402, in cached_file
    resolved_file = hf_hub_download(
                    ^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/huggingface_hub/utils/_deprecation.py", line 101, in inner_f
    return f(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/huggingface_hub/utils/_validators.py", line 106, in _inner_fn
    validate_repo_id(arg_value)
  File "/home/ray/anaconda3/lib/python3.11/site-packages/huggingface_hub/utils/_validators.py", line 154, in validate_repo_id
    raise HFValidationError(
huggingface_hub.errors.HFValidationError: Repo id must be in the form 'repo_name' or 'namespace/repo_name': '/work-dir/Mistral-7B-Instruct-v0.2/'. Use `repo_type` argument if needed.

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "<frozen runpy>", line 198, in _run_module_as_main
  File "<frozen runpy>", line 88, in _run_code
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/entrypoints/openai/api_server.py", line 196, in <module>
    engine = AsyncLLMEngine.from_engine_args(
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/engine/async_llm_engine.py", line 371, in from_engine_args
    engine_config = engine_args.create_engine_config()
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/engine/arg_utils.py", line 630, in create_engine_config
    model_config = ModelConfig(
                   ^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/config.py", line 136, in __init__
    self.hf_config = get_config(self.model, trust_remote_code, revision,
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/vllm/transformers_utils/config.py", line 33, in get_config
    config = AutoConfig.from_pretrained(
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/transformers/models/auto/configuration_auto.py", line 972, in from_pretrained
    config_dict, unused_kwargs = PretrainedConfig.get_config_dict(pretrained_model_name_or_path, **kwargs)
                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/transformers/configuration_utils.py", line 632, in get_config_dict
    config_dict, kwargs = cls._get_config_dict(pretrained_model_name_or_path, **kwargs)
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/transformers/configuration_utils.py", line 689, in _get_config_dict
    resolved_config_file = cached_file(
                           ^^^^^^^^^^^^
  File "/home/ray/anaconda3/lib/python3.11/site-packages/transformers/utils/hub.py", line 466, in cached_file
    raise EnvironmentError(
OSError: Incorrect path_or_model_id: '/work-dir/Mistral-7B-Instruct-v0.2/'. Please provide either the path to a local folder or the repo_id of a model on the Hub.
```