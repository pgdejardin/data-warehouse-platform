
terraform {
  required_version = "~> 1.6"

  backend "s3" {
    region = "eu-west-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }
}

provider "aws" {
  # Configuration options
  region = var.region
}
