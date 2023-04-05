module "root_inputs" {
  source = "../../modules/tfs3-inputs"

  bucket = var.inputs_bucket
  name   = "root-internal"
}

module "bootstrap_inputs" {
  source = "../../modules/tfs3-inputs"

  bucket = var.inputs_bucket
  name   = "bootstrap-vpn"
}

