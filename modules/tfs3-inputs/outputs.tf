output "inputs" {
  value = jsondecode(data.aws_s3_object.this.body)
}

