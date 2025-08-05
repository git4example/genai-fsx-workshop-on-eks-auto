#!/bin/bash
# Part 1 : Prerequisite of setting up an On-demand Workshop (using your own AWS account)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker participant
sudo docker ps


sudo yum install git -y
sudo yum install jq
git --version
git config --global user.name “Your Name”
git config --global user.email “your_email@example.com”

git clone https://github.com/git4example/genai-fsx-workshop-on-eks-auto.git


TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)


ASSET_BUCKET= <your-new-bucket-name>
aws s3api create-bucket --bucket $ASSET_BUCKET --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION



aws s3 sync ./genai-fsx-workshop-on-eks-auto s3://${ASSET_BUCKET}/genai-fsx-workshop-on-eks-auto


sudo docker run -v ./work-dir/:/work-dir/ --entrypoint huggingface-cli public.ecr.aws/parikshit/huggingface-cli:slim download "enghwa/neuron-mistral7bv0.2" --local-dir /work-dir/Mistral-7B-Instruct-v0.2

ROLE_NAME=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/)
CREDENTIALS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME)
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Token')


echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
echo "AWS_SESSION_TOKEN: $AWS_SESSION_TOKEN"


ASSET_BUCKET_PATH=genai-fsx-workshop-on-eks-auto

sudo docker run -e AWS_DEFAULT_REGION=$AWS_REGION \
  -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
  -v ./work-dir/:/work-dir/  public.ecr.aws/parikshit/s5cmd cp /work-dir/Mistral-7B-Instruct-v0.2/ s3://${ASSET_BUCKET}/${ASSET_BUCKET_PATH}/assets/Mistral-7B-Instruct-v0.2/


# Part 2 : Provision workshop resources

STACK_NAME=GenAIFSXWorkshopOnEKS
VSINSTANCE_NAME=VSCodeServerForEKS
ASSET_BUCKET_ZIPPATH=""
ASSET_BUCKET=${ASSET_BUCKET}
ASSET_BUCKET_PATH=genai-fsx-workshop-on-eks-auto

aws cloudformation validate-template --template-url https://${ASSET_BUCKET}.s3.amazonaws.com/${ASSET_BUCKET_PATH}/static/GenAIFSXWorkshopOnEKS.yaml > validate_cfn.txt


cat validate_cfn.txt


aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-url https://${ASSET_BUCKET}.s3.amazonaws.com/${ASSET_BUCKET_PATH}/static/GenAIFSXWorkshopOnEKS.yaml \
  --region $AWS_REGION \
  --parameters \
  ParameterKey=VSCodeUser,ParameterValue=participant \
  ParameterKey=InstanceName,ParameterValue=${VSINSTANCE_NAME} \
  ParameterKey=InstanceVolumeSize,ParameterValue=100 \
  ParameterKey=InstanceType,ParameterValue=t4g.medium \
  ParameterKey=InstanceOperatingSystem,ParameterValue=AmazonLinux-2023 \
  ParameterKey=HomeFolder,ParameterValue=environment \
  ParameterKey=DevServerPort,ParameterValue=8081 \
  ParameterKey=AssetZipS3Path,ParameterValue=${ASSET_BUCKET_ZIPPATH} \
  ParameterKey=Assets,ParameterValue=s3://${ASSET_BUCKET}/${ASSET_BUCKET_PATH}/assets/ \
  --disable-rollback \
  --capabilities CAPABILITY_NAMED_IAM


# Part 3: Access your workshop

echo "Now run quick-test-sponsored.sh script to test workshop"

