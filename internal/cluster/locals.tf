# Constants
locals {
  k8s_version        = "1.23"
  gitlab_alb_address = "10.1.0.3"
}

# Aliases
locals {
  folder_id         = module.root_inputs.inputs.folder_id
  private_subnet_id = module.bootstrap_inputs.inputs.private_subnet_id
  private_domain    = module.bootstrap_inputs.inputs.private_domain
}

