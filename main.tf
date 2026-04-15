terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
}
# Dynamically resolve a recent Ubuntu AMI.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default"{
    filter {
      name = "vpc-id"
      values = [data.aws_vpc.default.id]
    }
}

resource "aws_security_group" "instance" {
    name = "terraform-lab-instance-sg"

    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_launch_template" "example"{
    image_id = data.aws_ami.ubuntu.id
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]
    user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
    )
    lifecycle {
      create_before_destroy = true
    }

}

resource "aws_autoscaling_group" "example" {
    launch_template {
      id = aws_launch_template.example.id
      version = "$Latest"
    }
    vpc_zone_identifier = data.aws_subnets.default.ids
    min_size = 2
    max_size = 4

    tag {
      key = "Name"
      value = "terraform-asg-example"
      propagate_at_launch = true
    }
  
}