terraform {
  backend "s3" {
    endpoint = "storage.yandexcloud.net"
    region   = "ru-central1"
    key      = "internal-vpn.tfstate"

    # bucket, access_key and secret_key provided by bin/init.sh

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

