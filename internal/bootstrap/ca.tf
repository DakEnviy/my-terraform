resource "yandex_storage_bucket" "ca" {
  folder_id = local.folder_id

  bucket_prefix         = "ca-"
  default_storage_class = "COLD"
  acl                   = "public-read"

  force_destroy = true
}

