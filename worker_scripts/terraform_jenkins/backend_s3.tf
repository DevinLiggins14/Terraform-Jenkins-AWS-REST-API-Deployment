terraform {
  backend "s3" {
    bucket         = "dev-proj-1-jenkins-remote-state-bucket-123456"
    key            = "terraform/state"
    region         = "ap-south-1" # Update this to match the bucket's actual region
    encrypt        = true
  }
}
