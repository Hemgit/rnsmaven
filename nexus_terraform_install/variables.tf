variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "ports" {
  type    = list(number)
  default = [22, 8081]
}

variable "instance_type" {
  type    = string
  default = "t2.small"
}

variable "nexus_version" {
  type    = string
  default = "3.70.1-02"
}

variable "nexus_user" {
  type    = string
  default = "nexus"
}

variable "nexus_group" {
  type    = string
  default = "nexus"
}

variable "nexus_install_dir" {
  type    = string
  default = "/opt"
}

variable "nexus_dir" {
  type    = string
  default = "/opt/nexus"
}

variable "nexus_data_dir" {
  type    = string
  default = "/opt/sonatype-work"
}