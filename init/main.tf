# Aliases
locals {
  cloud_id = data.yandex_resourcemanager_cloud.cloud.cloud_id
}

data "yandex_resourcemanager_cloud" "cloud" {
  name = var.cloud_name
}

module "root_folder" {
  source = "../modules/common-folder"

  cloud_id = local.cloud_id
  name     = "root"
}

resource "yandex_resourcemanager_cloud_iam_member" "admin" {
  cloud_id = local.cloud_id
  member   = "serviceAccount:${module.root_folder.sa_id}"
  role     = "admin"
}

module "root_sa_secret" {
  source = "../modules/get-secret"

  secret_id = module.root_folder.sa_secret_id

  # Wait for secret version creation in common-folder module
  depends_on = [module.root_folder]
}

module "init_root_outputs" {
  source = "../modules/tfs3-outputs"

  bucket = module.root_folder.terraform_state_bucket
  name   = "init"
  value  = module.root_folder

  storage_access_key = module.root_sa_secret.entries.storage_access_key
  storage_secret_key = module.root_sa_secret.entries.storage_secret_key
}

