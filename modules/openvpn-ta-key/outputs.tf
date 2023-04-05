output "secret_id" {
  value = yandex_lockbox_secret.this.id
}

output "ta_key" {
  value     = data.external.this.result.ta_key
  sensitive = true
}

