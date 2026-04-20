variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-northeast-1"
}

variable "instance_name" {
  type        = string
  description = "Name of the EC2 instance"
  default     = "demo-web-server"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t2.micro", "t2.small"], var.instance_type)
    error_message = "Instance type must be a valid burstable type."
  }
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the instance will be launched"
  nullable    = false
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the instance will be launched"
  nullable    = false
}

variable "root_volume_size" {
  type        = number
  description = "Root volume size in GB"
  default     = 20

  validation {
    condition     = var.root_volume_size >= 10 && var.root_volume_size <= 100
    error_message = "Root volume size must be between 10 and 100 GB."
  }
}

variable "allowed_ssh_cidr" {
  type        = list(string)
  description = "CIDR blocks allowed for SSH access"
  default     = ["0.0.0.0/0"] # This should be restricted in production!
}
