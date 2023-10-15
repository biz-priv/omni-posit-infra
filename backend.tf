terraform {
  backend "s3" {
    bucket         = "bce-terraform-state-store-test"
    key            = "terraform-state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}