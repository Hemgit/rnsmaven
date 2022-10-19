variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "cidr_block" {
  type    = list(string)
  default = ["172.20.0.0/16", "172.20.10.0/24", "0.0.0.0/0"]
}

variable "availability_zone" {
  type    = string
  default = "ap-south-1a"
}

variable "ports" {
  type    = list(number)
  default = [22, 80, 8080]
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "keypair_name" {
  type    = string
  default = "devops"
}

output "JenkinsMaster_Public_IP" {
  value = aws_instance.Jenkins_Master.public_ip
}

output "Jenkins_Slave_Public_IP" {
  value = aws_instance.Jenkins_Slave.public_ip
}

output "Jenkins_Slave_Private_IP" {
  value = aws_instance.Jenkins_Slave.private_ip
}
