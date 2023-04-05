data "yandex_cm_certificate_content" "vpn" {
  folder_id = local.folder_id

  name = "vpn-server"
}

data "aws_s3_object" "ca_cert" {
  bucket = module.bootstrap_inputs.inputs.ca_bucket
  key    = "ca.crt"
}

data "aws_s3_object" "ca_crl" {
  bucket = module.bootstrap_inputs.inputs.ca_bucket
  key    = "crl.pem"
}

module "vpn_ta_key" {
  source = "../../modules/openvpn-ta-key"

  folder_id  = local.folder_id
  kms_key_id = module.root_inputs.inputs.aes_key_id
}

resource "yandex_vpc_address" "vpn" {
  folder_id = local.folder_id

  name = "vpn-address"

  external_ipv4_address {
    zone_id = module.bootstrap_inputs.inputs.zone
  }
}

resource "yandex_dns_recordset" "vpn" {
  zone_id = module.bootstrap_inputs.inputs.public_dns_zone_id
  type    = "A"
  name    = "vpn.${module.bootstrap_inputs.inputs.public_domain}."
  data    = [yandex_vpc_address.vpn.external_ipv4_address[0].address]
  ttl     = 600
}

module "vpn_ssh_key" {
  source = "../../modules/ssh-key"

  folder_id = local.folder_id

  name = "vpn"
  user = "johndoe"

  kms_key_id = module.root_inputs.inputs.aes_key_id
}

resource "yandex_compute_instance" "vpn" {
  folder_id = local.folder_id

  name        = "vpn"
  description = "VM for vpn and other basic network stuff"
  hostname    = "vpn"

  platform_id = "standard-v3" # Intel Ice Lake

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = local.image_id

      type = "network-ssd"
      size = 20
    }
  }

  zone = module.bootstrap_inputs.inputs.zone

  network_interface {
    subnet_id      = module.bootstrap_inputs.inputs.public_subnet_id
    nat_ip_address = yandex_vpc_address.vpn.external_ipv4_address[0].address

    ip_address = "10.0.0.3"
    nat        = true
  }

  metadata = {
    ssh-keys = "${module.vpn_ssh_key.user}:${module.vpn_ssh_key.public_key}"

    user-data = templatefile("${path.module}/files/vpn/user-data.yaml.tftpl", {
      user           = module.vpn_ssh_key.user
      public_ssh_key = module.vpn_ssh_key.public_key
      ca_bucket      = module.bootstrap_inputs.inputs.ca_bucket

      setup_sh                = filebase64("${path.module}/files/vpn/setup.sh")
      update_crl_sh           = filebase64("${path.module}/files/vpn/update-crl.sh")
      etc_default_ufw         = filebase64("${path.module}/files/vpn/etc/default/ufw")
      etc_ufw_before_rules    = filebase64("${path.module}/files/vpn/etc/ufw/before.rules")
      etc_openvpn_server_conf = filebase64("${path.module}/files/vpn/etc/openvpn/server/server.conf")

      ca_cert     = base64encode(data.aws_s3_object.ca_cert.body)
      ca_crl      = base64encode(data.aws_s3_object.ca_crl.body)
      server_key  = base64encode(data.yandex_cm_certificate_content.vpn.private_key)
      server_cert = base64encode(data.yandex_cm_certificate_content.vpn.certificates[0])
      ta_key      = base64encode(module.vpn_ta_key.ta_key)
    })
  }

  allow_stopping_for_update = true
}

