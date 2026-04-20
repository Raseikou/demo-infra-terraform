output "app_instance_id" {
  value       = aws_instance.app.id
  description = "The EC2 instance ID for the application"
}

output "app_instance_public_ip" {
  value       = aws_instance.app.public_ip
  description = "The public IP address of the application server"
}

output "app_instance_private_ip" {
  value       = aws_instance.app.private_ip
  description = "The private IP address of the application server"
}

output "app_security_group_id" {
  value       = aws_security_group.app_sg.id
  description = "The security group ID for the application"
}
