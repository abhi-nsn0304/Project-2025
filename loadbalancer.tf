provider "aws" {
  region = "us-east-2"
}

resource "aws_launch_template" "test_lc" {
  name          = "test_launch_configuration"
  image_id      = "ami-0b05d988257befbbe" # Example AMI ID, replace with a valid one
  instance_type = "t2.micro"
  #key_name        = "aws-testuser123" # Replace with your key pair name
  vpc_security_group_ids = [aws_security_group.alb_sg.id]

  user_data = base64encode(<<-EOF
  #!/bin/bash
  echo "Hello, World!" > /var/www/html/index.html
  nohup busybox httpd -f -p 80 &
  EOF
  )

  #Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "test_asg" {
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.test_lc.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.aws_lb_tg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "TestASGInstance"
    propagate_at_launch = true
  }
}

variable "server_port" {
  description = "The port on which the server will run"
  type        = number
  default     = 22
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_alb" "test_alb" {
  name               = "test-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false

  tags = {
    Name = "TestALB"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.test_alb.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_security_group"
  description = "Allow HTTP and HTTPS traffic to the ALB"
  # vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "aws_lb_tg" {
  name     = "test-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg_lg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100


  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.aws_lb_tg.arn
  }

}


# output "public_ip_ec2" {
#   description = "Public IP of the EC2 instance"
#   value       = aws_instance.test_instance.public_ip
# }

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_alb.test_alb.dns_name
}