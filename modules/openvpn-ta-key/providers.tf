terraform {
  required_version = ">= 0.13"

  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.1"
    }

    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.90.0"
    }
  }
}

