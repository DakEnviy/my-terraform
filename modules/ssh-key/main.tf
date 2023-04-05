resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "yandex_lockbox_secret" "this" {
  folder_id = var.folder_id

  name        = "${var.name}-${var.user}-ssh-keys"
  description = "Ssh keys for ${var.user}@${var.name}"

  kms_key_id = var.kms_key_id
}

resource "yandex_lockbox_secret_version" "this" {
  secret_id = yandex_lockbox_secret.this.id

  entries {
    key        = "private_key"
    text_value = tls_private_key.this.private_key_openssh
  }

  entries {
    key        = "public_key"
    text_value = tls_private_key.this.public_key_openssh
  }
}

