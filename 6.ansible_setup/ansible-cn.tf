# Create an AWS EC2 Instance to host Ansible Controller (Control node)

resource "aws_security_group" "MyLab_Sec_Group" {
  name        = "MyLab Security Group"
  description = "Allow inbound and outbound traffic"
  vpc_id      = aws_vpc.MyLab-VPC.id

  dynamic "ingress" {
    iterator = port
    for_each = var.ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = [var.cidr_block[2]]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_trafic"
  }
}

data "aws_ami" "aws-linux-2-latest" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}

resource "aws_instance" "AnsibleController" {
  ami           = data.aws_ami.aws-linux-2-latest.id
  instance_type = var.instance_type
  key_name = var.keypair_name
  vpc_security_group_ids = [aws_security_group.MyLab_Sec_Group.id]
  subnet_id = aws_subnet.MyLab-Subnet1.id
  associate_public_ip_address = true
  user_data = file("./scripts/InstallAnsibleCN.sh")

  tags = {
    Name = "Ansible-ControlNode"
  }
}

resource "aws_instance" "Ansible_Web_Server" {
  ami           = data.aws_ami.aws-linux-2-latest.id
  instance_type = var.instance_type
  key_name = var.keypair_name
  vpc_security_group_ids = [aws_security_group.MyLab_Sec_Group.id]
  subnet_id = aws_subnet.MyLab-Subnet1.id
  associate_public_ip_address = true
  user_data = file("./scripts/AnsibleManagedNode.sh")

  tags = {
    Name = "Ansible-WebServer"
  }
}

resource "aws_instance" "Ansible_App_Server" {
  ami           = data.aws_ami.aws-linux-2-latest.id
  instance_type = var.instance_type
  key_name = var.keypair_name
  vpc_security_group_ids = [aws_security_group.MyLab_Sec_Group.id]
  subnet_id = aws_subnet.MyLab-Subnet1.id
  associate_public_ip_address = true
  user_data = file("./scripts/AnsibleManagedNode.sh")

  tags = {
    Name = "Ansible-AppServer"
  }
}
