output "instance_id" {
  value       = aws_instance.app.id
  description = "EC2 instance ID"
}

output "instance_public_ip" {
  value       = aws_instance.app.public_ip
  description = "Public IP address"
}

output "instance_private_ip" {
  value       = aws_instance.app.private_ip
  description = "Private IP address"
}

output "security_group_id" {
  value       = aws_security_group.app_sg.id
  description = "Security group ID"
}
