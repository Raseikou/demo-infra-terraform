terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws",
        version = "5.0.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "instance_01" {
  ami = data.aws_ssm_parameter.al2023.value
  instance_type = "t3.micro"
  security_groups = [aws_security_group.instances.name]
  user_data = <<-EOF
              #!/bin/bash
              mkdir -p /var/www/html
              echo "Hello, World!001" > /var/www/html/index.html
              cd /var/www/html
              python3 -m http.server 8080 &
              EOF
}

resource "aws_instance" "instance_02" {
  ami = data.aws_ssm_parameter.al2023.value
  instance_type = "t3.micro"
  security_groups = [aws_security_group.instances.name]
  user_data = <<-EOF
              #!/bin/bash
              mkdir -p /var/www/html
              echo "Hello, World!002" > /var/www/html/index.html
              cd /var/www/html
              python3 -m http.server 8080 &
              EOF
}

resource "aws_s3_bucket" "s3-for-terraform-demo" {
    bucket = "s3-for-terraform-demo-202406"
    force_destroy = true
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.s3-for-terraform-demo.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
  bucket = aws_s3_bucket.s3-for-terraform-demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "instances" {
  name = "instances-security-group"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.instances.id
  from_port = 8080
  to_port = 8080
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_alb_listener" "listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_alb_target_group" "instances" {
  name = "instances-target-group"
  port = 8080
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_alb_target_group_attachment" "attachment_01" {
  target_group_arn = aws_alb_target_group.instances.arn
  target_id = aws_instance.instance_01.id
  port = 8080
}

resource "aws_alb_target_group_attachment" "attachment_02" {
  target_group_arn = aws_alb_target_group.instances.arn
  target_id = aws_instance.instance_02.id
  port = 8080
}

resource "aws_lb_listener_rule" "rule01" {
    listener_arn = aws_alb_listener.listener.arn
    priority = 100
    action {
        type = "forward"
        target_group_arn = aws_alb_target_group.instances.arn
    }
    condition {
        path_pattern {
        values = ["*"]
        }
    }
}

resource "aws_security_group" "alb" {
  name = "alb-security-group"
}

resource "aws_security_group_rule" "alb_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_outbound" {
  type = "egress"
  security_group_id = aws_security_group.alb.id
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "load_balancer" {
  name = "alb-for-terraform-demo"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb.id]
  subnets = data.aws_subnets.default_subnet.ids
}

resource "aws_db_instance" "mysql" {
  identifier = "mysql-for-terraform-demo"
  allocated_storage = 20
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  username = "admin"
  password = "password1234"
  skip_final_snapshot = true
}