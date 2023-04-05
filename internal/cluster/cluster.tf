resource "yandex_kubernetes_cluster" "this" {
  folder_id = local.folder_id

  name        = "internal"
  description = "Main cluster for internal applications"

  service_account_id      = module.root_inputs.inputs.sa_id
  node_service_account_id = module.root_inputs.inputs.sa_id

  kms_provider {
    key_id = module.root_inputs.inputs.aes_key_id
  }

  release_channel = "REGULAR"

  network_id         = module.bootstrap_inputs.inputs.network_id
  cluster_ipv4_range = "10.2.0.0/16"
  service_ipv4_range = "10.3.0.0/16"

  master {
    version = local.k8s_version

    zonal {
      zone      = module.bootstrap_inputs.inputs.zone
      subnet_id = module.bootstrap_inputs.inputs.private_subnet_id
    }

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        start_time = "04:00"
        duration   = "3h"
      }
    }
  }
}

module "main_ssh_key" {
  source = "../../modules/ssh-key"

  folder_id = local.folder_id

  name = "main"
  user = "johndoe"

  kms_key_id = module.root_inputs.inputs.aes_key_id
}

resource "yandex_kubernetes_node_group" "this" {
  cluster_id = yandex_kubernetes_cluster.this.id
  version    = local.k8s_version

  name        = "main"
  description = "Main node group for internal applications"

  instance_template {
    name = "main-{instance.index}"

    platform_id = "standard-v3" # Intel Ice Lake

    resources {
      cores  = 2
      memory = 8
    }

    boot_disk {
      type = "network-hdd"
      size = 60
    }

    network_interface {
      subnet_ids = [module.bootstrap_inputs.inputs.private_subnet_id]
    }

    container_runtime {
      type = "containerd"
    }

    metadata = {
      ssh-keys = "${module.main_ssh_key.user}:${module.main_ssh_key.public_key}"
    }
  }

  scale_policy {
    auto_scale {
      min     = 1
      max     = 3
      initial = 1
    }
  }

  deploy_policy {
    max_expansion   = 1
    max_unavailable = 1
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "07:00"
      duration   = "3h"
    }

    maintenance_window {
      day        = "friday"
      start_time = "04:00"
      duration   = "4h30m"
    }
  }
}

