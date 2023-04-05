module "internal_sa_secret" {
  source = "../../modules/get-secret"

  secret_id = module.root_inputs.inputs.sa_secret_id
}

