terraform {
  required_version = ">= 0.13"

  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.66.1"
    }

    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.90.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
  }
}

# AWS provider is used only for retrieving s3 objects
provider "aws" {
  region = "ru-central1"

  endpoints {
    s3 = "https://storage.yandexcloud.net"
  }

  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

provider "kubernetes" {
  host                   = yandex_kubernetes_cluster.this.master[0].internal_v4_endpoint
  cluster_ca_certificate = yandex_kubernetes_cluster.this.master[0].cluster_ca_certificate

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "yc"
    args        = ["managed-kubernetes", "create-token"]
  }
}

provider "helm" {
  kubernetes {
    host                   = yandex_kubernetes_cluster.this.master[0].internal_v4_endpoint
    cluster_ca_certificate = yandex_kubernetes_cluster.this.master[0].cluster_ca_certificate

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "yc"
      args        = ["managed-kubernetes", "create-token"]
    }
  }

  registry {
    url      = "oci://cr.yandex"
    username = "json_key"
    password = module.internal_sa_secret.entries.sa_key
  }
}

