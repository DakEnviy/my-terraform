output "sa_id" {
  value = var.sa_id
}

output "id" {
  value = yandex_iam_service_account_key.this.id
}

output "public_key" {
  value = yandex_iam_service_account_key.this.public_key
}

output "private_key" {
  value     = yandex_iam_service_account_key.this.private_key
  sensitive = true
}

output "key_algorithm" {
  value = yandex_iam_service_account_key.this.key_algorithm
}

output "created_at" {
  value = yandex_iam_service_account_key.this.created_at
}

output "json" {
  value = jsonencode({
    service_account_id = var.sa_id
    id                 = yandex_iam_service_account_key.this.id
    public_key         = yandex_iam_service_account_key.this.public_key
    private_key        = yandex_iam_service_account_key.this.private_key
    key_algorithm      = yandex_iam_service_account_key.this.key_algorithm
    created_at         = yandex_iam_service_account_key.this.created_at
  })
  sensitive   = true
  description = "Service account key in json format like in command 'yc iam key create'"
}

