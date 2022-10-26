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


## Enable color prompt
curl -s https://gitlab.com/rns-app/linux-auto-scripts/-/raw/main/ps1.sh -o /etc/profile.d/ps1.sh
chmod +x /etc/profile.d/ps1.sh

## Enable idle shutdown
curl -s https://gitlab.com/rns-app/linux-auto-scripts/-/raw/main/idle.sh -o /boot/idle.sh
chmod +x /boot/idle.sh
{ crontab -l -u ansible; echo '*/10 * * * * sh -x /boot/idle.sh &>/tmp/idle.out'; } | crontab -u ansible -
