terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "local_file" "inventory" {
  filename  = "./files/hosts"
  content   = "[webserver]\nweb ansible_host=${aws_instance.Ansible_Web_Server.private_ip}\n[appserver]\napp ansible_host=${aws_instance.Ansible_App_Server.private_ip}\n[centos]\nweb\napp"
}

resource "local_file" "private_ips" {
  depends_on = [
    null_resource.wait_for_instance
  ]

  filename  = "./scripts/private_ips.txt"
  content   = "${aws_instance.Ansible_Web_Server.private_ip}\n${aws_instance.Ansible_App_Server.private_ip}\n"
}
