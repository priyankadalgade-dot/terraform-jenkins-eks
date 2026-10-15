terraform {
  backend "s3" {
    bucket = "mytodoappbucket3198"
    key    = "jenkins/terraform.tfstate"
    region = "ap-south-1"
  }
}