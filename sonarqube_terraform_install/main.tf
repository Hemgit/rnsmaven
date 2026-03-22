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
resource "aws_security_group" "SonarQube_Sec_Group" {
  name        = "SonarQube Security Group"
  description = "To allow inbound and outbound traffic to SonarQube"

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
    Name = "SonarQube Security Group"
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

# Create an AWS EC2 Instance for SonarQube
resource "aws_instance" "SonarQube_Server" {
  ami                         = data.aws_ami.aws_linux_2_latest.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.SonarQube_Sec_Group.id]
  associate_public_ip_address = true
  user_data                   = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname sonarqube-server
    useradd devops
    echo "devops" | passwd --stdin devops
    echo 'devops     ALL=(ALL)      NOPASSWD: ALL' | sudo tee -a /etc/sudoers
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    service sshd restart
    yum update -y
    yum install wget unzip -y
  EOF

  tags = {
    Name = "SonarQube-Server"
  }

  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ip.txt"
  }
}

resource "null_resource" "install_sonarqube" {
  depends_on = [aws_instance.SonarQube_Server]

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = aws_instance.SonarQube_Server.public_ip
      user     = "devops"
      password = "devops"
    }

    inline = [
      # Install Java
      "sudo yum install java-17-amazon-corretto -y",
      
      # Create swap for low-memory instances
      "sudo bash -c 'if [ ! -f /swapfile ]; then fallocate -l 1G /swapfile; chmod 0600 /swapfile; mkswap /swapfile; swapon /swapfile; fi'",
      "echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab > /dev/null",
      
      # Configure system parameters
      "sudo sysctl -w vm.max_map_count=262144",
      "sudo sysctl -w fs.file-max=65536",
      "echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf > /dev/null",
      "echo 'fs.file-max=65536' | sudo tee -a /etc/sysctl.conf > /dev/null",
      
      # Create sonar user and group
      "sudo bash -c 'groupadd ${var.sonarqube_group} 2>/dev/null || true'",
      "sudo bash -c 'useradd -g ${var.sonarqube_group} -s /bin/bash -m ${var.sonarqube_user} 2>/dev/null || true'",
      
      # Set limits for sonar user
      "echo 'sonar soft nofile 65536' | sudo tee -a /etc/security/limits.conf > /dev/null",
      "echo 'sonar hard nofile 65536' | sudo tee -a /etc/security/limits.conf > /dev/null",
      "echo 'sonar soft nproc 4096' | sudo tee -a /etc/security/limits.conf > /dev/null",
      "echo 'sonar hard nproc 4096' | sudo tee -a /etc/security/limits.conf > /dev/null",
      
      # Download and extract SonarQube
      "sudo rm -rf ${var.sonarqube_install_dir}/sonarqube-${var.sonarqube_version} ${var.sonarqube_dir} 2>/dev/null || true",
      "sudo wget -q -P ${var.sonarqube_install_dir} https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${var.sonarqube_version}.zip",
      "sudo unzip -q ${var.sonarqube_install_dir}/sonarqube-${var.sonarqube_version}.zip -d ${var.sonarqube_install_dir}",
      "sudo mv ${var.sonarqube_install_dir}/sonarqube-${var.sonarqube_version} ${var.sonarqube_dir}",
      "sudo chown -R ${var.sonarqube_user}:${var.sonarqube_group} ${var.sonarqube_dir}",
      
      # Configure RUN_AS_USER
      "sudo sed -i 's/^#RUN_AS_USER=.*/RUN_AS_USER=${var.sonarqube_user}/' ${var.sonarqube_dir}/bin/linux-x86-64/sonar.sh",
      
      # Configure JVM memory for t2.small
      "sudo sed -i 's/wrapper.java.maxmemory=.*/wrapper.java.maxmemory=256/' ${var.sonarqube_dir}/conf/wrapper.conf 2>/dev/null || true",
      "echo 'sonar.es.javaOpts=-Xms256m -Xmx256m' | sudo tee -a ${var.sonarqube_dir}/conf/sonar.properties > /dev/null",
      "echo 'sonar.web.javaOpts=-Xms256m -Xmx256m' | sudo tee -a ${var.sonarqube_dir}/conf/sonar.properties > /dev/null",
      "echo 'sonar.ce.javaOpts=-Xms256m -Xmx256m' | sudo tee -a ${var.sonarqube_dir}/conf/sonar.properties > /dev/null",
      "sudo sed -i 's/-Xms512m/-Xms256m/g; s/-Xmx512m/-Xmx256m/g' ${var.sonarqube_dir}/elasticsearch/config/jvm.options 2>/dev/null || true",
      
      # Create systemd service file
      "sudo tee /etc/systemd/system/sonar.service > /dev/null <<'SYSTEMD_EOF'\n[Unit]\nDescription=SonarQube Service\nAfter=network.target\n\n[Service]\nType=forking\nExecStart=${var.sonarqube_dir}/bin/linux-x86-64/sonar.sh start\nExecStop=${var.sonarqube_dir}/bin/linux-x86-64/sonar.sh stop\nUser=${var.sonarqube_user}\nGroup=${var.sonarqube_group}\nRestart=always\nLimitNOFILE=65536\nLimitNPROC=4096\nEnvironment=\"SONAR_JAVA_PATH=/usr/lib/jvm/java-17-amazon-corretto/bin/java\"\nEnvironment=\"SONAR_ELASTICSEARCH_BOOTSTRAP_CHECKS_DISABLED=true\"\nEnvironment=\"ES_JAVA_OPTS=-Xms256m -Xmx256m\"\n\n[Install]\nWantedBy=multi-user.target\nSYSTEMD_EOF",
      
      # Start SonarQube service
      "sudo systemctl daemon-reload",
      "sudo systemctl enable sonar",
      "sudo systemctl start sonar",
      
      # Wait for SonarQube to start
      "sleep 45",
      "for i in {1..20}; do curl -s http://localhost:9000 > /dev/null && echo 'SonarQube is up!' && break; sleep 10; done"
    ]
  }
}