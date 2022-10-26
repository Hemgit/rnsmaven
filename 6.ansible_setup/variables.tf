variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "cidr_block" {
  type    = list(string)
  default = ["172.20.0.0/16", "172.20.10.0/24", "0.0.0.0/0"]
}

variable "availability_zone" {
  type    = string
  default = "eu-west-1a"
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

output "Ansible_Controller_Public_IP" {
  value = aws_instance.AnsibleController.public_ip
}

output "Ansible_WebServer_Private_IP" {
  value = aws_instance.Ansible_Web_Server.private_ip
}

output "Ansible_AppServer_Private_IP" {
  value = aws_instance.Ansible_App_Server.private_ip
}
