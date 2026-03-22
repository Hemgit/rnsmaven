variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "ports" {
  type    = list(number)
  default = [22, 9000]
}

variable "instance_type" {
  type    = string
  default = "t2.small"
}

variable "sonarqube_version" {
  type    = string
  default = "9.9.3.79811"
}

variable "sonarqube_user" {
  type    = string
  default = "sonar"
}

variable "sonarqube_group" {
  type    = string
  default = "sonar"
}

variable "sonarqube_install_dir" {
  type    = string
  default = "/opt"
}

variable "sonarqube_dir" {
  type    = string
  default = "/opt/sonarqube"
}