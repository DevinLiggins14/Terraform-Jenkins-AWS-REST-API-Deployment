terraform {
  backend "s3" {
    bucket = "terraform-backend6"
    key    = "devops-project-1/terraform.tfstate"
    region = "us-east-1"
  }
}
