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

resource "aws_instance" "name" {
  ami = data.aws_ssm_parameter.al2023.value
  instance_type = "t3.micro"
}