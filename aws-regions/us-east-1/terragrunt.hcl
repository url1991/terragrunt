generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "s3" {
    bucket         = "1lc-infrastructure-tf-state"
    key            = "terragrunt/us-east-1/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-west-1"
    encrypt        = true
  }
}
EOF
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
    region = "us-east-1"
}
EOF
}