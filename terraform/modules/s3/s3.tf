resource "aws_s3_bucket" "evmosd-binaries" {
  bucket = "evmosd-binaries"

  tags = {
    Name        = "evmosd-binaries"
  }
}