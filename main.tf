provider "aws" {
  region = "us-east-2"
}

variable "server_port" {
  description = "The port on which the server will run"
  type        = number
  default     = 22
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = "vpc-080a3577b16769c32" # Replace with your VPC ID

  ingress {
    description = "SSH from anywhere"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere, consider restricting this in production
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # All protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

}

resource "aws_instance" "test_instance" {
  ami                    = "ami-0b05d988257befbbe" # Example AMI ID, replace with a valid one
  instance_type          = "t2.micro"
  key_name               = "aws-testuser123" # Replace with your key pair name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  tags = {
    Name = "TestInstance"
  }
}

output "public_ip_ec2" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.test_instance.public_ip
}
