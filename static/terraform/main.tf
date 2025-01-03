terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }    
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

# variable "region2" {
#   type = string 
# }

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

provider "aws" {
  region = local.region
  alias  = "region1"
}

provider "aws" {
  region = "us-east-2" #var.region2
  alias  = "region2"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.this.token
}


data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

data "aws_availability_zones" "available" {
  provider = aws.region1
  state    = "available"
}

data "aws_caller_identity" "current" {}

locals {
  name   = "eksworkshop"
  region = "--AWS_REGION--"
  # region = "us-west-1"

  cluster_version = "--EKS_VERSION--"
  # cluster_version = "1.31"

  vpc_cidr = "10.0.0.0/16"
  # azs      = slice(data.aws_availability_zones.available.names, 0, length(data.aws_availability_zones.available.names))
  sorted_azs = sort(data.aws_availability_zones.available.names)
  azs      = slice(local.sorted_azs, 0, length(local.sorted_azs))

  tags = {
    Blueprint = local.name
  }
}



################################################################################
# EKS Cluster
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 20.22.0"

  providers = {
    aws = aws.region1
  }

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true
  authentication_mode            = "API"

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose","system"]
  }

  access_entries = {  
    super-admin = {
        principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/WSParticipantRole"

        policy_associations = {
          this = {
            policy_arn =  "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
  }

  cluster_addons = {
    # aws-ebs-csi-driver = { most_recent = true }
    # kube-proxy = { most_recent = true }
    # coredns    = { most_recent = true }
    eks-pod-identity-agent = {}
    # vpc-cni = {
    #   most_recent    = true
    #   before_compute = true
    #   configuration_values = jsonencode({
    #     env = {
    #       ENABLE_PREFIX_DELEGATION = "true"
    #       WARM_PREFIX_TARGET       = "1"
    #     }
    #   })
    # }
  }

  vpc_id     = module.vpc.vpc_id
  # subnet_ids = module.vpc.public_subnets
  subnet_ids = module.vpc.private_subnets

  create_cloudwatch_log_group   = false
  create_cluster_security_group = false
  create_node_security_group    = false

  # eks_managed_node_groups = {
  #   managed-ondemand = {
  #     node_group_name = "managed-ondemand"
  #     instance_types  = ["m4.xlarge", "m5.xlarge", "m5a.xlarge", "m5ad.xlarge", "m5d.xlarge", "t2.xlarge", "t3.xlarge", "t3a.xlarge"]

  #     create_security_group = false

  #     subnet_ids   = module.vpc.private_subnets
  #     max_size     = 2
  #     desired_size = 2
  #     min_size     = 2

  #     # Launch template configuration
  #     create_launch_template = true              # false will use the default launch template
  #     launch_template_os     = "amazonlinux2eks" # amazonlinux2eks or bottlerocket

  #     labels = {
  #       intent = "control-apps"
  #     }
  #   }
  # }

  tags = merge(local.tags, {
    "karpenter.sh/discovery" = local.name
  })
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = ">= 1.16.3"
  
  providers = {
    aws = aws.region1
  }

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  create_delay_dependencies = [for prof in module.eks.eks_managed_node_groups : prof.node_group_arn]

  #---------------------------------------
  # metrics server for EKS Cluster
  #---------------------------------------
  enable_metrics_server = true

  #---------------------------------------
  # ebs csi driver for EKS Cluster
  #---------------------------------------
  # eks_addons = {
  #   aws-ebs-csi-driver = {
  #     service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
  #   }
  # }

  #---------------------------------------
  # Karpenter Autoscaler for EKS Cluster
  #---------------------------------------
  # enable_karpenter = true
  # karpenter_enable_spot_termination          = true
  karpenter_enable_instance_profile_creation = true
  # karpenter = {
  #   chart_version       = "1.0.1"     # https://gallery.ecr.aws/karpenter/karpenter
  #   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  #   repository_password = data.aws_ecrpublic_authorization_token.token.password
  # }
 
  # karpenter_node = {
  #   iam_role_use_name_prefix = false
  #   iam_role_additional_policies = {
  #     AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  #   }
  # }

  #---------------------------------------
  # AWS Load Balancer Controller Add-on
  #---------------------------------------
  # enable_aws_load_balancer_controller = true
  # turn off the mutating webhook for services because if you are using
  # service.beta.kubernetes.io/aws-load-balancer-type: external
  # aws_load_balancer_controller = {
  #   set = [{
  #     name  = "enableServiceMutatorWebhook"
  #     value = "false"
  #   }]
  # }

## fsx CSI driver can be installed here in fugure as needed.
  # enable_aws_fsx_csi_driver = true
  # aws_fsx_csi_driver = {
  #   namespace     = "aws-fsx-csi-driver"
  #   chart_version = "1.6.0"
  #   role_policies = <ADDITIONAL_IAM_POLICY_ARN>
  # }

  #---------------------------------------
  # Prommetheus and Grafana stack
  #---------------------------------------
  #---------------------------------------------------------------
  # 1- Grafana port-forward `kubectl port-forward svc/kube-prometheus-stack-grafana 8080:80 -n kube-prometheus-stack`
  # 2- Grafana Admin user: admin
  # 3- Get sexret name from Terrafrom output: `terraform output grafana_secret_name`
  # 3- Get admin user password: `aws secretsmanager get-secret-value --secret-id <REPLACE_WIRTH_SECRET_ID> --region $AWS_REGION --query "SecretString" --output text`
  #---------------------------------------------------------------
  # enable_kube_prometheus_stack = true
  # kube_prometheus_stack = {
  #   values = [
  #     templatefile("${path.module}/helm-values/kube-prometheus.yaml", {
  #       storage_class_type = kubernetes_storage_class.default_gp3.id
  #     })
  #   ]
  #   chart_version = "48.1.1"
  #   set_sensitive = [
  #     {
  #       name  = "grafana.adminPassword"
  #       value = data.aws_secretsmanager_secret_version.admin_password_version.secret_string
  #     }
  #   ],
  # }

  tags = local.tags
  depends_on = [
    module.eks
  ]
}

#---------------------------------------------------------------
# Grafana Admin credentials resources
# Login to AWS secrets manager with the same role as Terraform to extract the Grafana admin password with the secret name as "grafana"
#---------------------------------------------------------------
data "aws_secretsmanager_secret_version" "admin_password_version" {
  secret_id  = aws_secretsmanager_secret.grafana.id
  depends_on = [aws_secretsmanager_secret_version.grafana]
}

resource "random_password" "grafana" {
  length           = 16
  special          = true
  override_special = "@_"
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "grafana" {
  name_prefix             = "${local.name}-oss-grafana"
  recovery_window_in_days = 0 # Set to zero for this example to force delete during Terraform destroy
}

resource "aws_secretsmanager_secret_version" "grafana" {
  secret_id     = aws_secretsmanager_secret.grafana.id
  secret_string = random_password.grafana.result
}

#---------------------------------------------------------------
# Data on EKS Kubernetes Addons
#---------------------------------------------------------------
module "data_addons" {
  source  = "aws-ia/eks-data-addons/aws"
  version = ">= 1.33.0" # ensure to update this to the latest/desired version

  oidc_provider_arn = module.eks.oidc_provider_arn

  #---------------------------------------------------------------
  # Neuron and NVIDIA Device Plugin Add-on
  #---------------------------------------------------------------
  enable_aws_neuron_device_plugin  = true
  aws_neuron_device_plugin_helm_config = {
    create_namespace=true
  }
  enable_nvidia_device_plugin = true
  nvidia_device_plugin_helm_config = {
    version =  "v0.16.1"
    name    = "nvidia-device-plugin"
    values  = [file("${path.module}/helm-values/nvidia-values.yaml")]
  }
  depends_on = [
    module.eks
  ]
}

#---------------------------------------------------------------
# GP3 Encrypted Storage Class
#---------------------------------------------------------------
resource "kubernetes_annotations" "disable_gp2" {
  annotations = {
    "storageclass.kubernetes.io/is-default-class" : "false"
  }
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }
  force = true

  depends_on = [module.eks]
}

resource "kubernetes_storage_class" "default_gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" : "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {
    fsType    = "ext4"
    encrypted = true
    type      = "gp3"
  }

  depends_on = [kubernetes_annotations.disable_gp2]
}



# resource "aws_eks_access_entry" "karpenter_node_access_entry" {
#   provider          = aws.region1
#   cluster_name      = module.eks.cluster_name
#   principal_arn     = module.eks_blueprints_addons.karpenter.node_iam_role_arn
#   kubernetes_groups = []
#   type              = "EC2_LINUX"
#   lifecycle {
#     ignore_changes =  all 
#   }
#   depends_on = [
#     module.eks_blueprints_addons
#   ]
# }

# module "ebs_csi_driver_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = ">= 5.20"

#   role_name_prefix = "${module.eks.cluster_name}-ebs-csi-driver-"

#   attach_ebs_csi_policy = true

#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
#     }
#   }

#   tags = local.tags
#   depends_on = [
#     module.eks
#   ]
# }

################################################################################
# Network Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0.0"

  providers = {
    aws = aws.region1
  }

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = ["10.0.32.0/19", "10.0.64.0/19", "10.0.96.0/19"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
    "karpenter.sh/discovery"              = local.name
  }

  tags = local.tags
}


################################################################################
# Lustre S3 Buckets
################################################################################
resource "random_string" "random" {
  length  = 12
  special = false
  upper   = false
  numeric = true
}


# Region 1 Bucket
module "fsx-lustre-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"
  force_destroy = true

  providers = {
    aws = aws.region1
  }

  bucket_prefix="fsx-lustre-${random_string.random.id}"

}


# Region 2 Bucket
module "fsx-lustre-bucket-2ndregion" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2" 
  force_destroy = true

  providers = {
    aws = aws.region2
  }

  bucket_prefix="fsx-lustre-2ndregion-${random_string.random.id}"
}

## S3 Cross region replication Role :
resource "aws_iam_role" "s3-cross-region-replication-role" {
  name = "s3-cross-region-replication-role-${random_string.random.id}"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "s3.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_policy" "s3-cross-region-replication-policy" {
  name = "s3-cross-region-replication-policy-${random_string.random.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${module.fsx-lustre-bucket.s3_bucket_id}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${module.fsx-lustre-bucket.s3_bucket_id}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${module.fsx-lustre-bucket-2ndregion.s3_bucket_id}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "s3-cross-region-replication-policy-attachment" {
  name       = "s3-bucket-replication-${random_string.random.id}"
  roles      = [aws_iam_role.s3-cross-region-replication-role.name]
  policy_arn = aws_iam_policy.s3-cross-region-replication-policy.arn
}

## Security Group for Lustre

resource "aws_security_group" "FSxLSecurityGroup01" {
  name        = "FSxLSecurityGroup01"
  provider    = aws.region1
  description = "Security Group for FSx for Lustre Storage Access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow Lustre traffic between FSx for Lustre file servers"
    from_port        = 988
    to_port          = 988
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allows Lustre traffic between FSx for Lustre file servers"
    from_port        = 1018
    to_port          = 1023
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description = "Allows Lustre traffic between FSx for Lustre file servers"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

}



################################################################################
# FSx Lustre filesystem for static provisioning
################################################################################

resource "aws_fsx_lustre_file_system" "fsx_lustre" {
  provider    = aws.region1
  file_system_type_version = "2.15"
  storage_capacity = 1200
  deployment_type = "PERSISTENT_2"
  per_unit_storage_throughput = 250
  subnet_ids       = [module.vpc.private_subnets[0]]
  security_group_ids = [aws_security_group.FSxLSecurityGroup01.id]
  depends_on = [
    module.fsx-lustre-bucket,
    aws_security_group.FSxLSecurityGroup01
  ]
}


resource "aws_fsx_data_repository_association" "fsx_lustre_association" {
  file_system_id       = aws_fsx_lustre_file_system.fsx_lustre.id
  data_repository_path = "s3://${module.fsx-lustre-bucket.s3_bucket_id}"
  file_system_path     = "/"
  batch_import_meta_data_on_create = true

  s3 {
    auto_export_policy {
      events = ["NEW", "CHANGED", "DELETED"]
    }

    auto_import_policy {
      events = ["NEW", "CHANGED", "DELETED"]
    }
  }
  depends_on = [    
    module.fsx-lustre-bucket,
    aws_fsx_lustre_file_system.fsx_lustre
  ]
}


resource "helm_release" "fsx_csi_driver" {
  name       = "aws-fsx-csi-driver"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-fsx-csi-driver"
  chart      = "aws-fsx-csi-driver"
  version    = "1.9.0" 
  set {
    name  = "csi.enableFSxNInstances"
    value = true
  }
  depends_on = [
    module.eks
  ]
}


################################################################################
# Kubernetes Manifests
################################################################################

resource "kubectl_manifest" "neuron-healthcheck-system-namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: neuron-healthcheck-system
    YAML
  depends_on = [
    module.eks
  ]
}

# ---- kubeops ----
# resource "kubectl_manifest" "kube_ops_view_deployment" {
#   yaml_body = <<-YAML
#     apiVersion: apps/v1
#     kind: Deployment
#     metadata:
#       labels:
#         application: kube-ops-view
#         component: frontend
#       name: kube-ops-view
#     spec:
#       replicas: 1
#       selector:
#         matchLabels:
#           application: kube-ops-view
#           component: frontend
#       template:
#         metadata:
#           labels:
#             application: kube-ops-view
#             component: frontend
#         spec:
#           nodeSelector:
#             intent: control-apps
#           serviceAccountName: kube-ops-view
#           containers:
#           - name: service
#             image: hjacobs/kube-ops-view:20.4.0
#             ports:
#             - containerPort: 8080
#               protocol: TCP
#             readinessProbe:
#               httpGet:
#                 path: /health
#                 port: 8080
#               initialDelaySeconds: 5
#               timeoutSeconds: 1
#             livenessProbe:
#               httpGet:
#                 path: /health
#                 port: 8080
#               initialDelaySeconds: 30
#               periodSeconds: 30
#               timeoutSeconds: 10
#               failureThreshold: 5
#             resources:
#               limits:
#                 cpu: 400m
#                 memory: 400Mi
#               requests:
#                 cpu: 400m
#                 memory: 400Mi
#             securityContext:
#               readOnlyRootFilesystem: true
#               runAsNonRoot: true
#               runAsUser: 1000
#   YAML

#   depends_on = [
#     module.eks
#   ]
# }

# resource "kubectl_manifest" "kube_ops_view_sa" {
#   yaml_body = <<-YAML
#     apiVersion: v1
#     kind: ServiceAccount
#     metadata:
#       name: kube-ops-view
#   YAML

#   depends_on = [
#     module.eks
#   ]
# }

# resource "kubectl_manifest" "kube_ops_view_clusterrole" {
#   yaml_body = <<-YAML
#     kind: ClusterRole
#     apiVersion: rbac.authorization.k8s.io/v1
#     metadata:
#       name: kube-ops-view
#     rules:
#     - apiGroups: [""]
#       resources: ["nodes", "pods"]
#       verbs:
#         - list
#     - apiGroups: ["metrics.k8s.io"]
#       resources: ["nodes", "pods"]
#       verbs:
#         - get
#         - list
#   YAML

#   depends_on = [
#     module.eks
#   ]
# }

# resource "kubectl_manifest" "kube_ops_view_clusterrole_binding" {
#   yaml_body = <<-YAML
#     kind: ClusterRoleBinding
#     apiVersion: rbac.authorization.k8s.io/v1
#     metadata:
#       name: kube-ops-view
#     roleRef:
#       apiGroup: rbac.authorization.k8s.io
#       kind: ClusterRole
#       name: kube-ops-view
#     subjects:
#     - kind: ServiceAccount
#       name: kube-ops-view
#       namespace: default
#   YAML

#   depends_on = [
#     module.eks
#   ]
# }

# resource "kubectl_manifest" "kube_ops_view_service" {
#   yaml_body = <<-YAML
#     apiVersion: v1
#     kind: Service
#     metadata:
#       labels:
#         application: kube-ops-view
#         component: frontend
#       name: kube-ops-view
#       annotations:
#         service.beta.kubernetes.io/aws-load-balancer-type: external
#         service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
#         service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
#     spec:
#       selector:
#         application: kube-ops-view
#         component: frontend
#       type: LoadBalancer
#       ports:
#       - port: 80
#         protocol: TCP
#         targetPort: 8080
#   YAML

#   depends_on = [
#     module.eks
#   ]
# }

# ---- karpenter nodepool ----
# resource "kubectl_manifest" "nodepool_default" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.sh/v1
#     kind: NodePool
#     metadata:
#       name: default
#     spec:
#       template:
#         spec:
#           requirements:
#             - key: kubernetes.io/arch
#               operator: In
#               values: ["amd64"]
#             - key: kubernetes.io/os
#               operator: In
#               values: ["linux"]
#             - key: karpenter.sh/capacity-type
#               operator: In
#               values: ["on-demand"]
#             - key: karpenter.k8s.aws/instance-category
#               operator: In
#               values: ["c", "m", "r"]
#             - key: karpenter.k8s.aws/instance-generation
#               operator: Gt
#               values: ["4"]
#           nodeClassRef:
#             group: karpenter.k8s.aws
#             kind: EC2NodeClass
#             name: default
#       limits:
#         cpu: 1000
#       disruption:
#         consolidationPolicy: WhenEmpty
#         consolidateAfter: 180s
#       weight: 100
#   YAML

#   depends_on = [
#     module.eks_blueprints_addons
#   ]
# }

# ---- karpenter ec2nodeclass ----
# resource "kubectl_manifest" "ec2nodeclass_default" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.k8s.aws/v1
#     kind: EC2NodeClass
#     metadata:
#       name: default
#     spec:
#       amiFamily: AL2 
#       role: "Karpenter-eksworkshop" 
#       subnetSelectorTerms:          
#         - tags:
#             karpenter.sh/discovery: "eksworkshop"
#       securityGroupSelectorTerms:
#         - tags:
#             karpenter.sh/discovery: "eksworkshop"
#       amiSelectorTerms:
#         - alias: al2@v20240917
#   YAML

#   depends_on = [
#     module.eks_blueprints_addons
#   ]
# }




################################################################################
# loading FSx Lustre filesystem with Mistral model
################################################################################

# ---- karpenter nodepool for sysprep ----
# resource "kubectl_manifest" "nodepool_sysprep" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.sh/v1
#     kind: NodePool
#     metadata:
#       name: sysprep
#     spec:
#       template:
#         spec:
#           requirements:
#             - key: kubernetes.io/arch
#               operator: In
#               values: ["amd64"]
#             - key: kubernetes.io/os
#               operator: In
#               values: ["linux"]
#             - key: karpenter.sh/capacity-type
#               operator: In
#               values: ["on-demand"]
#             - key: eks.amazonaws.com/instance-category
#               operator: In
#               values: ["c", "m", "r"]
#             - key: eks.amazonaws.com/instance-generation
#               operator: Gt
#               values: ["4"]
#           nodeClassRef:
#             group: eks.amazonaws.com
#             kind: NodeClass
#             name: sysprep
#       limits:
#         cpu: 1000
#       disruption:
#         consolidationPolicy: WhenEmpty
#         # expireAfter: 720h # 30 * 24h = 720h
#         consolidateAfter: 180s
#       weight: 100
#   YAML

#   depends_on = [
#     module.eks_blueprints_addons
#   ]
# }

# ---- karpenter nodeclass for sysprep ----
# resource "kubectl_manifest" "nodeclass_sysprep" {
#   yaml_body = <<-YAML
#     apiVersion: eks.amazonaws.com/v1
#     kind: NodeClass
#     metadata:
#       name: sysprep
#     spec:
#       # amiFamily: AL2 # Amazon Linux 2
#       ephemeralStorage:
#         size: "100Gi"    # Range: 1-59000Gi or 1-64000G or 1-58Ti or 1-64T
#         iops: 10000      # Range: 3000-16000
#         throughput: 1000 # Range: 125-1000
#       role: "${module.eks.node_iam_role_name}"
#       subnetSelectorTerms:          
#         - tags:
#             karpenter.sh/discovery: "eksworkshop"
#       securityGroupSelectorTerms:
#         - tags:
#             karpenter.sh/discovery: "eksworkshop"
#   YAML

#   depends_on = [
#     module.eks_blueprints_addons
#   ]
# }


# ---- k8s job for sysprep ----
resource "kubernetes_job" "sysprep" {
  metadata {
    name = "sysprep"
  }
  spec {
    template {
      metadata {
        labels = {
          app = "sysprep"
        }
      }
      spec {
        # node_selector = {
        #   "karpenter.sh/nodepool" = "sysprep"
        # }
        restart_policy = "OnFailure"
        init_container {
          name    = "sysprep"
          image   = "public.ecr.aws/parikshit/lustre-client:latest"
          command = ["/bin/bash"]
          args    = ["-c","echo 'sysprep started' >> /work-dir/sysprep `date` && find /work-dir/Mistral-7B-Instruct-v0.2 -type f -print0 | xargs -0 -n 1 -P 8 lfs hsm_restore && echo 'sysprep done' >> /work-dir/sysprep `date`"]
          volume_mount {
            name       = "persistent-storage"
            mount_path = "/work-dir"
          }
        }
        container {
          name    = "validate"
          image   = "public.ecr.aws/parikshit/lustre-client:latest"
          command = ["/bin/bash"]
          args    = ["-c","echo 'sysprep-validation started' >> /work-dir/sysprep `date` && find /work-dir/Mistral-7B-Instruct-v0.2 -type f -print0 | xargs -0 -n 1 -P 8 lfs hsm_action >> /work-dir/sysprep && echo 'sysprep-validation done' >> /work-dir/sysprep `date`"]
          volume_mount {
            name       = "persistent-storage"
            mount_path = "/work-dir"
          }
        }
        volume {
          name = "persistent-storage"
          persistent_volume_claim {
            claim_name = "fsx-lustre-claim-sysprep"
          }
        }
      }
    }
    completions = 1
  }
  wait_for_completion = true 
  timeouts {
    create = "30m"
  }
  depends_on = [
    kubectl_manifest.sysprep_pvc,
    module.eks_blueprints_addons,
    aws_fsx_data_repository_association.fsx_lustre_association
  ]
}

# ---- PVC for sysprep ----
resource "kubectl_manifest" "sysprep_pvc" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: fsx-lustre-claim-sysprep
    spec:
      accessModes:
        - ReadWriteMany
      storageClassName: ""
      resources:
        requests:
          storage: 1200Gi
      volumeName: fsx-pv-sysprep
  YAML

  depends_on = [
    kubectl_manifest.sysprep_pv
  ]
}

# ---- PV for sysprep ----
resource "kubectl_manifest" "sysprep_pv" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: fsx-pv-sysprep
    spec:
      persistentVolumeReclaimPolicy: Retain
      capacity:
        storage: 1200Gi
      volumeMode: Filesystem
      accessModes:
        - ReadWriteMany
      mountOptions:
        - flock
      csi:
        driver: fsx.csi.aws.com
        volumeHandle: ${aws_fsx_lustre_file_system.fsx_lustre.id}
        volumeAttributes:
          dnsname: ${aws_fsx_lustre_file_system.fsx_lustre.dns_name}
          mountname: ${aws_fsx_lustre_file_system.fsx_lustre.mount_name}
  YAML

  depends_on = [
    aws_fsx_lustre_file_system.fsx_lustre
  ]
}


#---------------------------------------------------------------
# Outputs
#---------------------------------------------------------------

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "eks_node_iam_role_name" {
  description = "IAM role name for EKS nodes"
  value       = module.eks.node_iam_role_name
}