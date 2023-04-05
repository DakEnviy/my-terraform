resource "yandex_vpc_network" "this" {
  folder_id = local.folder_id

  name        = "internal-nets"
  description = "Main internal network"
}

resource "yandex_vpc_subnet" "public" {
  folder_id = local.folder_id

  name        = "internal-nets-public-${local.zone}"
  description = "Public internal subnet for zone ${local.zone}"

  network_id = yandex_vpc_network.this.id
  zone       = local.zone

  v4_cidr_blocks = ["10.0.0.0/24"]
}

resource "yandex_vpc_subnet" "private" {
  folder_id = local.folder_id

  name        = "internal-nets-private-${local.zone}"
  description = "Private internal subnet for zone ${local.zone}"

  network_id = yandex_vpc_network.this.id
  zone       = local.zone

  v4_cidr_blocks = ["10.1.0.0/24"]

  route_table_id = yandex_vpc_route_table.nat.id
}

resource "yandex_vpc_gateway" "nat" {
  folder_id = local.folder_id

  name        = "nat"
  description = "This gateway using by private subnet to access internet"

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nat" {
  folder_id = local.folder_id

  name        = "nat"
  description = "This route table using by private subnet to access internet"

  network_id = yandex_vpc_network.this.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

