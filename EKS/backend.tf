terraform {
  backend "s3" {
    bucket = "mytodoappbucket3198"
    key    = "eks/terraform.tfstate"
    region = "ap-south-1"
  }
}