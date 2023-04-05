resource "yandex_dns_recordset" "gitlab" {
  zone_id = module.bootstrap_inputs.inputs.private_dns_zone_id
  type    = "A"
  name    = "gitlab.${local.private_domain}."
  data    = [local.gitlab_alb_address]
  ttl     = 600
}

resource "yandex_dns_recordset" "gitlab_kas" {
  zone_id = module.bootstrap_inputs.inputs.private_dns_zone_id
  type    = "A"
  name    = "kas.${local.private_domain}."
  data    = [local.gitlab_alb_address]
  ttl     = 600
}

resource "yandex_dns_recordset" "gitlab_minio" {
  zone_id = module.bootstrap_inputs.inputs.private_dns_zone_id
  type    = "A"
  name    = "minio.${local.private_domain}."
  data    = [local.gitlab_alb_address]
  ttl     = 600
}

resource "yandex_dns_recordset" "gitlab_registry" {
  zone_id = module.bootstrap_inputs.inputs.private_dns_zone_id
  type    = "A"
  name    = "registry.${local.private_domain}."
  data    = [local.gitlab_alb_address]
  ttl     = 600
}

resource "yandex_dns_recordset" "gitlab_shell" {
  zone_id = module.bootstrap_inputs.inputs.private_dns_zone_id
  type    = "A"
  name    = "git.${local.private_domain}."
  data    = [data.kubernetes_service.gitlab_shell.status[0].load_balancer[0].ingress[0].ip]
  ttl     = 600
}

data "yandex_cm_certificate_content" "gitlab" {
  folder_id = local.folder_id

  name = "gitlab"
}

resource "kubernetes_namespace" "gitlab" {
  metadata {
    name = "gitlab"
  }

  depends_on = [yandex_kubernetes_node_group.this]
}

resource "kubernetes_secret" "gitlab_ca" {
  metadata {
    namespace = kubernetes_namespace.gitlab.metadata[0].name
    name      = "internal-ca"
  }

  data = {
    "ca.crt" = data.aws_s3_object.ca_cert.body
  }

  depends_on = [kubernetes_namespace.gitlab]
}

resource "kubernetes_secret" "gitlab_certs" {
  metadata {
    namespace = kubernetes_namespace.gitlab.metadata[0].name
    name      = "gitlab-certs"
  }

  data = {
    "ca.crt"                               = data.aws_s3_object.ca_cert.body
    "gitlab.${local.private_domain}.crt"   = join("", data.yandex_cm_certificate_content.gitlab.certificates)
    "kas.${local.private_domain}.crt"      = join("", data.yandex_cm_certificate_content.gitlab.certificates)
    "minio.${local.private_domain}.crt"    = join("", data.yandex_cm_certificate_content.gitlab.certificates)
    "registry.${local.private_domain}.crt" = join("", data.yandex_cm_certificate_content.gitlab.certificates)
  }

  depends_on = [kubernetes_namespace.gitlab]
}

resource "helm_release" "gitlab" {
  # Copy from https://charts.gitlab.io/gitlab
  chart   = "${path.module}/helm/gitlab"
  version = "7.0.4"

  namespace = kubernetes_namespace.gitlab.metadata[0].name
  name      = "gitlab"

  timeout           = 900 # 15 minutes
  atomic            = true
  dependency_update = true
  max_history       = 1
  wait_for_jobs     = true
  cleanup_on_fail   = true

  values = [
    yamlencode({
      global = {
        edition = "ce"
        hosts = {
          domain = local.private_domain
        }
        certificates = {
          customCAs = [{ secret = kubernetes_secret.gitlab_ca.metadata[0].name }]
        }
        ingress = {
          enabled  = true
          class    = "none" # It should be none string to use YC ALB
          provider = "yc"
          annotations = {
            "ingress.alb.yc.io/group-name"            = "gitlab"
            "ingress.alb.yc.io/subnets"               = local.private_subnet_id
            "ingress.alb.yc.io/internal-alb-subnet"   = local.private_subnet_id
            "ingress.alb.yc.io/internal-ipv4-address" = local.gitlab_alb_address
          }
          configureCertmanager = false
          tls = {
            secretName = "yc-certmgr-cert-id-${data.yandex_cm_certificate_content.gitlab.id}"
          }
        }
      }
      nginx-ingress = {
        enabled = false
      }
      certmanager = {
        install = false
      }
      gitlab = {
        kas = {
          enabled = true
          ingress = {
            annotations = {
              "ingress.alb.yc.io/upgrade-types" = "WebSocket"
            }
          }
          service = {
            type = "NodePort"
          }
        }
        webservice = {
          enabled = true
          service = {
            type = "NodePort"
          }
        }
        gitlab-shell = {
          enabled = true
          service = {
            type = "LoadBalancer"
            annotations = {
              "yandex.cloud/load-balancer-type" = "internal"
              "yandex.cloud/subnet-id"          = local.private_subnet_id
            }
          }
        }
      }
      registry = {
        enabled = true
        service = {
          type = "NodePort"
        }
      }
      minio = {
        serviceType = "NodePort"
      }
      gitlab-runner = {
        certsSecretName = kubernetes_secret.gitlab_certs.metadata[0].name
        runners = {
          config = <<EOT
            [[runners]]
              pre_get_sources_script = """
                cp /etc/gitlab-runner/certs/ca.crt /usr/local/share/ca-certificates/ca.crt
                update-ca-certificates --fresh >/dev/null
              """
              [runners.kubernetes]
                image = "ubuntu:22.04"
                privileged = true
                image_pull_secrets = ["registry-credentials"]
              [[runners.kubernetes.volumes.empty_dir]]
                name = "docker-certs"
                mount_path = "/certs/client"
                medium = "Memory"
              [[runners.kubernetes.volumes.secret]]
                name = "${kubernetes_secret.gitlab_certs.metadata[0].name}"
                mount_path = "/etc/gitlab-runner/certs"
              [runners.cache]
                Type = "s3"
                Path = "gitlab-runner"
                Shared = true
                [runners.cache.s3]
                  ServerAddress = "minio.${local.private_domain}"
                  BucketName = "runner-cache"
                  BucketLocation = "us-east-1"
                  Insecure = false
          EOT
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.gitlab,
    kubernetes_secret.gitlab_ca,
    kubernetes_secret.gitlab_certs,
    helm_release.yc_alb_ingress_controller,
  ]
}

data "kubernetes_service" "gitlab_shell" {
  metadata {
    namespace = kubernetes_namespace.gitlab.metadata[0].name
    name      = "${helm_release.gitlab.name}-gitlab-shell"
  }

  depends_on = [helm_release.gitlab]
}

