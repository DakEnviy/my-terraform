# Constants
locals {
  zone           = "ru-central1-b"
  private_domain = "dakenviy.net"
  public_domain  = "dakenviy.tech"
}

# Aliases
locals {
  folder_id              = module.root_inputs.inputs.folder_id
  terraform_state_bucket = module.root_inputs.inputs.terraform_state_bucket
}

