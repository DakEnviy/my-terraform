output "user" {
  value = var.user
}

output "public_key" {
  value = tls_private_key.this.public_key_openssh
}

output "secret_id" {
  value = yandex_lockbox_secret.this.id
}

