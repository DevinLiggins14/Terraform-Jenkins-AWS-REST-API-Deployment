provider "aws" {
  region                   = "us-east-1"  # Set the desired region
  shared_credentials_files = ["~/.aws/credentials"]  # Path to credentials file
  profile                  = "demo-user"  # Specify the profile name to use
}
