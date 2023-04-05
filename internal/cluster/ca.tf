data "aws_s3_object" "ca_cert" {
  bucket = module.bootstrap_inputs.inputs.ca_bucket
  key    = "ca.crt"
}

