variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "keypair_name" {
  type    = string
  default = "batch38"
}

variable "availability_zone" {
  type    = string
  default = "eu-west-1a"
}

variable "cidr_block" {
  type    = list(string)
  default = ["172.20.0.0/16", "172.20.10.0/24"]
}

variable "ports" {
  type    = list(number)
  default = [22, 80, 443, 8080, 8081, 9000]
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

output "public_ip" {
  value = aws_instance.Tomcat_Server.public_ip
}
