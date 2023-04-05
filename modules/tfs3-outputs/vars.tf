variable "name" {
  type        = string
  nullable    = false
  description = "Using for naming bucket (<name>-outputs-*) and outputs file (<name>-outputs.json)"
}

variable "value" {
  type     = map(any)
  nullable = false
}

variable "create_bucket" {
  type        = bool
  default     = false
  description = "Flag which tells to create new bucket for storing outputs file"
}

variable "bucket" {
  type        = string
  default     = null
  description = "Bucket where outputs file will be created (required if create_bucket is false)"
}

variable "folder_id" {
  type        = string
  default     = null
  description = "Folder where bucket will be created (required if create_bucket is true)"
}

variable "storage_access_key" {
  type    = string
  default = null
}

variable "storage_secret_key" {
  type    = string
  default = null
}

