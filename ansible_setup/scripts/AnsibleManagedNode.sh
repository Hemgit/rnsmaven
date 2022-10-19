#! /bin/bash

hostnamectl set-hostname ansible-target

# add the user ansible
useradd ansible
# set password : the below command will avoid re entering the password
echo "ansible" | passwd --stdin ansible
# modify the sudoers file at /etc/sudoers and add entry
echo 'ansible     ALL=(ALL)      NOPASSWD: ALL' | sudo tee -a /etc/sudoers
echo 'ec2-user     ALL=(ALL)      NOPASSWD: ALL' | sudo tee -a /etc/sudoers
# this command is to add an entry to file : echo 'PasswordAuthentication yes' | sudo tee -a /etc/ssh/sshd_config
# the below sed command will find and replace words with spaces "PasswordAuthentication no" to "PasswordAuthentication yes"
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
service sshd restart
