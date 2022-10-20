#!/bin/bash

# Global Variables
LOG=/tmp/stack.log

## Web Server Installation
echo "WEB SERVER SETUP"
# sudo yum install nginx -y &>>$LOG
amazon-linux-extras install nginx1 -y &>>$LOG

sudo rm -rf  /usr/share/nginx/html/* &>>$LOG
echo "Remove old Web Content\t\t"
cd /tmp/
git clone https://gitlab.com/rns-app/static-project.git
cp -R static-project/iPortfolio/* /usr/share/nginx/html/
echo "Download New Web Content\t"

sed -i -e '/location \/student/,+3 d' -e '/^        error_page 404/ i \\t location /student { \n\t\tproxy_pass http://localhost:8080/student;\n\t}\n' /etc/nginx/nginx.conf
echo "Update Configuration File\t"

systemctl enable nginx &>>$LOG
systemctl restart nginx &>>$LOG
echo "Starting Nginx Service\t\t"
