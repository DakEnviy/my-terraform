resource "yandex_lockbox_secret" "this" {
  folder_id = var.folder_id

  name        = "vpn-ta-key"
  description = "Key for VPN tls-crypt option"

  kms_key_id = var.kms_key_id
}

data "external" "this" {
  program = ["${path.module}/scripts/generate-vpn-ta-key.sh"]

  query = {
    secret_id = yandex_lockbox_secret.this.id
  }
}

resource "yandex_lockbox_secret_version" "this" {
  secret_id = yandex_lockbox_secret.this.id

  entries {
    key        = "ta_key"
    text_value = data.external.this.result.ta_key
  }
}

