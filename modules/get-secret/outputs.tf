output "entries" {
  value     = { for e in data.yandex_lockbox_secret_version.this.entries : e.key => e.text_value }
  sensitive = true
}

