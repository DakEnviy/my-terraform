module "bootstrap_vpn_outputs" {
  source = "../../modules/tfs3-outputs"

  bucket = local.terraform_state_bucket
  name   = "bootstrap-vpn"

  value = {
    zone               = local.zone
    public_subnet_id   = yandex_vpc_subnet.public.id
    public_domain      = local.public_domain
    public_dns_zone_id = yandex_dns_zone.public.id
    ca_bucket          = yandex_storage_bucket.ca.bucket
  }
}

module "bootstrap_cluster_outputs" {
  source = "../../modules/tfs3-outputs"

  bucket = local.terraform_state_bucket
  name   = "bootstrap-cluster"

  value = {
    zone                = local.zone
    network_id          = yandex_vpc_network.this.id
    private_subnet_id   = yandex_vpc_subnet.private.id
    private_domain      = local.private_domain
    private_dns_zone_id = yandex_dns_zone.private.id
    ca_bucket           = yandex_storage_bucket.ca.bucket
  }
}

