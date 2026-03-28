terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.10.0"
}

provider "aws" {
  region = var.aws_region

  # Allow `terraform plan` without real AWS credentials (local/mock mode).
  # This avoids STS/account lookups that would otherwise fail without an AWS account.
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "cloudops"
      ManagedBy   = "Terraform"
    }
  }
}
