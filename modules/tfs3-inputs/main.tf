data "aws_s3_object" "this" {
  bucket = var.bucket
  key    = "${var.name}-outputs.json"
}

