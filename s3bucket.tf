resource "aws_s3_bucket" "new-bucket-created-with-terraform-test" {
  bucket = "new-bucket-created-with-terraform-test"

  tags = {
    Name        = "new-bucket-created-with-terraform-test"
    Environment = "Dev"
  }
}