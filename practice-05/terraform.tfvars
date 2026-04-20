aws_region       = "ap-northeast-1"
app_name         = "demo-app-server"
instance_type    = "t3.small"
environment      = "dev"
vpc_id           = "vpc-xxxxxxxxx"
subnet_id        = "subnet-xxxxxxxxx"
root_volume_size = 30
allowed_ssh_cidr = ["0.0.0.0/0"]
