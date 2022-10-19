#! /bin/bash

hostnamectl set-hostname ansible-controller

# install ansible
yum-config-manager --enable epel
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install epel-release-latest-7.noarch.rpm
yum update -y
yum install python python-devel python-pip openssl ansible git -y

sudo su -
# add the user ansible
sudo useradd ansible
# set password : the below command will avoid re entering the password
sudo echo "ansible" | passwd --stdin ansible

# Generate SSH Key for Passwordless configurations
yes '' | ssh-keygen -N '' -f /home/ansible/.ssh/id_rsa > /dev/null

# modify the sudoers file at /etc/sudoers and add entry
echo 'ansible     ALL=(ALL)      NOPASSWD: ALL' | sudo tee -a /etc/sudoers
echo 'ec2-user     ALL=(ALL)      NOPASSWD: ALL' | sudo tee -a /etc/sudoers
# this command is to add an entry to file : echo 'PasswordAuthentication yes' | sudo tee -a /etc/ssh/sshd_config
# the below sed command will find and replace words with spaces "PasswordAuthentication no" to "PasswordAuthentication yes"
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo service sshd restart

