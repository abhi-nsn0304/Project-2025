provider "aws" {
  region = "us-east-2"
}

  resource "aws_security_group" "allow_ssh" {
    name        = "allow_ssh"
    description = "Allow SSH inbound traffic"
    vpc_id      = "vpc-080a3577b16769c32" # Replace with your VPC ID
  }

resource "aws_instance" "test_instance" {
  ami           = "ami-0b05d988257befbbe" # Example AMI ID, replace with a valid one
  instance_type = "t2.micro"

  tags = {
    Name = "TestInstance"
  }
}
