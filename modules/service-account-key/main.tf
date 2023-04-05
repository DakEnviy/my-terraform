resource "yandex_iam_service_account_key" "this" {
  service_account_id = var.sa_id
  description        = var.description
  key_algorithm      = "RSA_4096"
}

