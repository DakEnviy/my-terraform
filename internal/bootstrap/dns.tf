resource "yandex_dns_zone" "private" {
  folder_id = local.folder_id

  zone             = "${local.private_domain}."
  public           = false
  private_networks = [yandex_vpc_network.this.id]
}

resource "yandex_dns_zone" "public" {
  folder_id = local.folder_id

  zone   = "${local.public_domain}."
  public = true
}

