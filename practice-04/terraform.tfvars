aws_region      = "ap-northeast-1"
instance_name   = "demo-web-server"
instance_type   = "t3.micro"
environment     = "dev"
vpc_id          = "vpc-xxxxxxxxx"
subnet_id       = "subnet-xxxxxxxxx"
root_volume_size = 20
allowed_ssh_cidr = ["0.0.0.0/0"]
