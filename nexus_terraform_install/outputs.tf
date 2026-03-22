output "public_ip" {
  value = aws_instance.Nexus_Server.public_ip
}

output "private_ip" {
  value = aws_instance.Nexus_Server.private_ip
}