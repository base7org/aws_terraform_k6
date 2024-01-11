terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
  }
}

provider "aws" {
  region  = var.site_region
  version = "5.31.0"
}

data "aws_availability_zones" "site_azs" {}