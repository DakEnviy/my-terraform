module "init_inputs" {
  source = "../modules/tfs3-inputs"

  bucket = var.inputs_bucket
  name   = "init"
}

module "internal_folder" {
  source = "../modules/common-folder"

  cloud_id = module.init_inputs.inputs.cloud_id
  name     = "internal"
}

module "root_internal_outputs" {
  source = "../modules/tfs3-outputs"

  bucket = module.internal_folder.terraform_state_bucket
  name   = "root-internal"
  value  = module.internal_folder
}

module "prod_folder" {
  source = "../modules/common-folder"

  cloud_id = module.init_inputs.inputs.cloud_id
  name     = "prod"
}

module "root_prod_outputs" {
  source = "../modules/tfs3-outputs"

  bucket = module.prod_folder.terraform_state_bucket
  name   = "root-prod"
  value  = module.prod_folder
}

