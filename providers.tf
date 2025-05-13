terraform {
  required_version = ">= 1.11.1, <2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.97.0, <6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.7.2, <4.0.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
