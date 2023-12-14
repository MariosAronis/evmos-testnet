resource "aws_s3_bucket" "evmosd_binaries" {
  bucket = "evmosd_binaries"

  tags = {
    Name        = "evmosd_binaries"
  }
}