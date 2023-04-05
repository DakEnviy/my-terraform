terraform {
  required_version = ">= 0.13"

  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }

    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.90.0"
    }
  }
}

