variable "folder_id" {
  type     = string
  nullable = false
}

variable "name" {
  type     = string
  nullable = false
}

variable "user" {
  type        = string
  nullable    = false
  description = "User with whom this key is associated"
}

variable "kms_key_id" {
  type     = string
  nullable = false
}

