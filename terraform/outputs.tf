output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.postgres_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.postgres_eip.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.postgres_server.private_ip
}

output "postgres_connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${var.db_user}:PASSWORD@${aws_eip.postgres_eip.public_ip}:5432/${var.db_name}"
  sensitive   = true
}

output "pgadmin_url" {
  description = "PgAdmin web interface URL"
  value       = "http://${aws_eip.postgres_eip.public_ip}:5050"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i /path/to/key.pem ubuntu@${aws_eip.postgres_eip.public_ip}"
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.postgres_sg.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.postgres_vpc.id
}

output "deployment_instructions" {
  description = "Instructions for connecting to the deployed resources"
  value = <<-EOT
    Your PostgreSQL Docker lab has been deployed!
    
    SSH Access:
      ssh -i /path/to/key.pem ubuntu@${aws_eip.postgres_eip.public_ip}
    
    After connecting, verify Docker is running:
      docker ps
    
    View logs:
      docker-compose logs -f
    
    Access PostgreSQL:
      docker-compose exec postgres psql -U ${var.db_user} -d ${var.db_name}
    
    PgAdmin Web UI:
      ${aws_eip.postgres_eip.public_ip}:5050
      Email: admin@example.com
      Password: admin
    
    PostgreSQL Connection Details:
      Host: ${aws_eip.postgres_eip.public_ip}
      Port: 5432
      Database: ${var.db_name}
      User: ${var.db_user}
  EOT
}
