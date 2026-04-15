variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "cluster_name" {
  type    = string
  default = "demo-eks-cluster"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "node_desired_size" {
  type    = number
  default = 2
  validation {
    condition     = var.node_desired_size >= 1 && var.node_desired_size <= 10
    error_message = "Node desired size must be between 1 and 10."
  }
}

variable "node_max_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_instance_type" {
  type    = string
  default = "t3.micro"
}
