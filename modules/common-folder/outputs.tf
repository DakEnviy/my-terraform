output "cloud_id" {
  value = var.cloud_id
}

output "folder_id" {
  value = local.folder_id
}

output "sa_id" {
  value = local.sa_id
}

output "terraform_state_bucket" {
  value = yandex_storage_bucket.terraform_state.bucket
}

output "aes_key_id" {
  value = yandex_kms_symmetric_key.aes_key.id
}

output "sa_secret_id" {
  value = yandex_lockbox_secret.sa_secret.id
}

