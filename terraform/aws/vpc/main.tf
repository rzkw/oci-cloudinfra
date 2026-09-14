

resource "aws_vpc" "vpc-1" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "dev" {
  vpc_id     = aws_vpc.vpc-1.id
  cidr_block = "10.0.0.0/24"
}