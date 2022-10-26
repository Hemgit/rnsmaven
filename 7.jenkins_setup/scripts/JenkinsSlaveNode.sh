#! /bin/bash

hostnamectl set-hostname Jenkins-Slave

yum update -y
# Install Java 11
amazon-linux-extras install java-openjdk11 -y

yum install git -y

# add the user ansible
useradd devops
# set password : the below command will avoid re entering the password
echo "devops" | passwd --stdin devops
# modify the sudoers file at /etc/sudoers and add entry
echo 'devops     ALL=(ALL)      NOPASSWD: ALL' | sudo tee -a /etc/sudoers
echo 'ec2-user     ALL=(ALL)      NOPASSWD: ALL' | sudo tee -a /etc/sudoers
# this command is to add an entry to file : echo 'PasswordAuthentication yes' | sudo tee -a /etc/ssh/sshd_config
# the below sed command will find and replace words with spaces "PasswordAuthentication no" to "PasswordAuthentication yes"
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
service sshd restart

# Install Git SCM
yum install wget zip unzip gzip vim net-tools git bind-utils python2-pip jq -y &>>$LOG
git --version &>>$LOG

## Enable color prompt
curl -s https://gitlab.com/rns-app/linux-auto-scripts/-/raw/main/ps1.sh -o /etc/profile.d/ps1.sh
chmod +x /etc/profile.d/ps1.sh

## Enable idle shutdown
curl -s https://gitlab.com/rns-app/linux-auto-scripts/-/raw/main/idle.sh -o /boot/idle.sh
chmod +x /boot/idle.sh
{ crontab -l -u devops; echo '*/10 * * * * sh -x /boot/idle.sh &>/tmp/idle.out'; } | crontab -u devops -
