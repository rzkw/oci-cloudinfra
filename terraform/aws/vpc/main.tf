terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

resource "aws_vpc" "vpc-1" {
  cidr_block = "10.0.0.0/16"
}