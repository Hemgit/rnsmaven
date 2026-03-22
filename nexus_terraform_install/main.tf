terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = var.region
}

# Create Security Group
resource "aws_security_group" "Nexus_Sec_Group" {
  name        = "Nexus Security Group"
  description = "To allow inbound and outbound traffic to Nexus"

  dynamic "ingress" {
    iterator = port
    for_each = var.ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Nexus Security Group"
  }
}

data "aws_ami" "aws_linux_2_latest" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}

# Create an AWS EC2 Instance for Nexus
resource "aws_instance" "Nexus_Server" {
  ami                         = data.aws_ami.aws_linux_2_latest.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.Nexus_Sec_Group.id]
  associate_public_ip_address = true
  user_data                   = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname nexus-server
    useradd devops
    echo "devops" | passwd --stdin devops
    echo 'devops     ALL=(ALL)      NOPASSWD: ALL' | sudo tee -a /etc/sudoers
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    service sshd restart
    yum update -y
    yum install wget unzip -y
  EOF

  tags = {
    Name = "Nexus-Server"
  }

  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ip.txt"
  }
}

resource "null_resource" "install_nexus" {
  depends_on = [aws_instance.Nexus_Server]

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = aws_instance.Nexus_Server.public_ip
      user     = "devops"
      password = "devops"
    }

    inline = [
      "sudo yum install java-1.8.0-openjdk -y",
      "sudo groupadd ${var.nexus_group}",
      "sudo useradd -g ${var.nexus_group} -s /bin/bash -m ${var.nexus_user}",
      "sudo wget https://download.sonatype.com/nexus/3/nexus-${var.nexus_version}-unix.tar.gz -O ${var.nexus_install_dir}/nexus.tar.gz",
      "sudo tar -xzf ${var.nexus_install_dir}/nexus.tar.gz -C ${var.nexus_install_dir}",
      "sudo mv ${var.nexus_install_dir}/nexus-${var.nexus_version} ${var.nexus_dir}",
      "sudo mkdir -p ${var.nexus_data_dir}",
      "sudo chown -R ${var.nexus_user}:${var.nexus_group} ${var.nexus_dir} ${var.nexus_data_dir}",
      "sudo sed -i 's/^#run_as_user=.*/run_as_user=${var.nexus_user}/' ${var.nexus_dir}/bin/nexus.rc",
      "sudo sed -i 's/-Xms.*/-Xms1024m/' ${var.nexus_dir}/bin/nexus.vmoptions",
      "sudo sed -i 's/-Xmx.*/-Xmx1024m/' ${var.nexus_dir}/bin/nexus.vmoptions",
      "sudo sed -i 's/-XX:MaxDirectMemorySize=.*/-XX:MaxDirectMemorySize=1024m/' ${var.nexus_dir}/bin/nexus.vmoptions",
      "sudo sed -i 's/#application-host=.*/application-host=0.0.0.0/' ${var.nexus_dir}/etc/nexus.properties",
      "sudo bash -c 'cat > /etc/systemd/system/nexus.service <<EOF\n[Unit]\nDescription=Nexus Service\nAfter=network.target\n\n[Service]\nType=forking\nLimitNOFILE=65536\nUser=${var.nexus_user}\nGroup=${var.nexus_group}\nExecStart=${var.nexus_dir}/bin/nexus start\nExecStop=${var.nexus_dir}/bin/nexus stop\nRestart=on-abort\n\n[Install]\nWantedBy=multi-user.target\nEOF'",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable nexus",
      "sudo systemctl start nexus",
      "sleep 30",
      "curl -f http://localhost:8081 || echo 'Nexus may still be starting'"
    ]
  }
}