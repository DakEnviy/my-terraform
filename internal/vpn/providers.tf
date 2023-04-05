terraform {
  required_version = ">= 0.13"

  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.1"
    }

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

