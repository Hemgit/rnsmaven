variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "ports" {
  type    = list(number)
  default = [22, 80, 8080, 8000]
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

output "public_ip" {
  value = aws_instance.Docker_Server.public_ip
}
