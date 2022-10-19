terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "MyLab-VPC" {
  cidr_block = var.cidr_block[0]

  tags = {
    Name = "MyLab-VPC"
  }
}

resource "aws_subnet" "MyLab-Subnet1" {
  vpc_id            = aws_vpc.MyLab-VPC.id
  cidr_block        = var.cidr_block[1]
  availability_zone = var.availability_zone
  tags = {
    Name = "MyLab-Subnet1"
  }
}

resource "aws_internet_gateway" "MyLab-IntGW" {
  vpc_id = aws_vpc.MyLab-VPC.id

  tags = {
    Name = "MyLab-InternetGW"
  }
}

resource "aws_route_table" "MyLab-RouteTable" {
  vpc_id = aws_vpc.MyLab-VPC.id

  route {
    cidr_block = var.cidr_block[2]
    gateway_id = aws_internet_gateway.MyLab-IntGW.id
  }

  tags = {
    Name = "MyLab-RouteTable"
  }
}

resource "aws_route_table_association" "MyLab-Assn" {
  subnet_id      = aws_subnet.MyLab-Subnet1.id
  route_table_id = aws_route_table.MyLab-RouteTable.id
}
