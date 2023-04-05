# Aliases
locals {
  folder_id          = yandex_resourcemanager_folder.this.id
  sa_id              = yandex_iam_service_account.this.id
  storage_access_key = yandex_iam_service_account_static_access_key.this.access_key
  storage_secret_key = yandex_iam_service_account_static_access_key.this.secret_key
}

resource "yandex_resourcemanager_folder" "this" {
  cloud_id = var.cloud_id

  name        = var.name
  description = "Folder for ${var.name} infrastracture"
}

resource "yandex_iam_service_account" "this" {
  folder_id = local.folder_id

  name        = "${var.name}-deployer"
  description = "Service account to manage ${var.name} resources"
}

resource "yandex_resourcemanager_folder_iam_member" "admin" {
  folder_id = local.folder_id

  member = "serviceAccount:${local.sa_id}"
  role   = "admin"
}

module "sa_key" {
  source = "../service-account-key"

  sa_id       = local.sa_id
  description = "Main key for automation"
}

resource "yandex_iam_service_account_static_access_key" "this" {
  service_account_id = local.sa_id
  description        = "For access to terraform state object storage"
}

resource "yandex_storage_bucket" "terraform_state" {
  folder_id = local.folder_id

  access_key = local.storage_access_key
  secret_key = local.storage_secret_key

  bucket_prefix         = "terraform-state-"
  default_storage_class = "COLD"

  force_destroy = true
}

resource "yandex_kms_symmetric_key" "aes_key" {
  folder_id = local.folder_id

  name              = "aes-key"
  description       = "Key for encrypting base things"
  default_algorithm = "AES_256"
}

resource "yandex_lockbox_secret" "sa_secret" {
  folder_id = local.folder_id

  name        = "sa-secret"
  description = "Secret for the ${yandex_iam_service_account.this.name} keys"

  kms_key_id = yandex_kms_symmetric_key.aes_key.id
}

resource "yandex_lockbox_secret_version" "sa_secret" {
  secret_id = yandex_lockbox_secret.sa_secret.id

  entries {
    key        = "sa_key"
    text_value = module.sa_key.json
  }

  entries {
    key        = "storage_access_key"
    text_value = local.storage_access_key
  }

  entries {
    key        = "storage_secret_key"
    text_value = local.storage_secret_key
  }
}

