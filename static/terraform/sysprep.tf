
variable "create_one_off_job" {
  description = "Set to true to create the one-off Kubernetes Job."
  type        = bool
  default     = false
}

# ---- FSx CSI  driver for sysprep ----
resource "helm_release" "fsx_csi_driver" {
  count = var.create_one_off_job ? 1 : 0 # Only create if true
  name       = "aws-fsx-csi-driver"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-fsx-csi-driver"
  chart      = "aws-fsx-csi-driver"
  version    = "1.11.0" 
  set {
    name  = "csi.enableFSxNInstances"
    value = true
  }
  depends_on = [
    module.eks
  ]
}

# ---- k8s job for sysprep ----
resource "kubernetes_job" "sysprep" {
  count = var.create_one_off_job ? 1 : 0 # Only create if true
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

  lifecycle {
    replace_triggered_by = [
      kubectl_manifest.sysprep_pvc
    ]
  }

  depends_on = [
    kubectl_manifest.sysprep_pvc,
    module.eks_blueprints_addons,
    aws_fsx_data_repository_association.fsx_lustre_association,
    helm_release.fsx_csi_driver
  ]
}

# ---- PVC for sysprep ----
resource "kubectl_manifest" "sysprep_pvc" {
  count = var.create_one_off_job ? 1 : 0 # Only create if true
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
    kubectl_manifest.sysprep_pv,
    helm_release.fsx_csi_driver
  ]
}

# ---- PV for sysprep ----
resource "kubectl_manifest" "sysprep_pv" {
  count = var.create_one_off_job ? 1 : 0 # Only create if true
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
    aws_fsx_lustre_file_system.fsx_lustre,
    helm_release.fsx_csi_driver
  ]
}
