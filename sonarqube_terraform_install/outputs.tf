output "public_ip" {
  value = aws_instance.SonarQube_Server.public_ip
}

output "private_ip" {
  value = aws_instance.SonarQube_Server.private_ip
}