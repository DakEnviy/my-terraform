resource "yandex_storage_bucket" "this" {
  count = var.create_bucket ? 1 : 0

  folder_id = var.folder_id

  access_key = var.storage_access_key
  secret_key = var.storage_secret_key

  bucket_prefix         = "${var.name}-outputs-"
  default_storage_class = "COLD"

  force_destroy = true
}

resource "yandex_storage_object" "this" {
  access_key = var.storage_access_key
  secret_key = var.storage_secret_key

  bucket = var.create_bucket ? yandex_storage_bucket.this[0].bucket : var.bucket
  key    = "${var.name}-outputs.json"

  content_type = "application/json"
  content      = jsonencode(var.value)
}

