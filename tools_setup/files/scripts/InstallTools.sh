#! /usr/bin/env bash

LOG=/tmp/stack.log

# Install the Java
yum update -y &>>$LOG
hostnamectl set-hostname deploy-server

amazon-linux-extras install java-openjdk11 -y &>>$LOG
yum install git -y &>>$LOG

java -version &>>$LOG
git --version &>>$LOG

chown -R ec2-user:ec2-user /opt

# Install the Tomcat Server
cd /opt/
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.68/bin/apache-tomcat-9.0.68.tar.gz
tar -xvf apache-tomcat-9.0.68.tar.gz &>>$LOG
mv apache-tomcat-9.0.68 tomcat
rm -f apache-tomcat-9.0.68.tar.gz

chown -R ec2-user:ec2-user /opt/tomcat/

echo '# Systemd unit file for tomcat
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target
[Service]
Type=forking
Environment=JAVA_HOME=/usr/lib/jvm/jre-11-openjdk-11.0.16.0.8-1.amzn2.0.1.x86_64/
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat/
Environment=CATALINA_BASE=/opt/tomcat/
Environment="CATALINA_OPTS=-Xms512M -Xmx512M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
# ExecStop=/bin/kill -15 $MAINPID
User=ec2-user
Group=ec2-user
[Install]
WantedBy=multi-user.target' > /etc/systemd/system/tomcat.service

systemctl daemon-reload
systemctl start tomcat
systemctl enable tomcat

# Install the Nginx Server

echo "Web Server Setup"

amazon-linux-extras install nginx1 -y &>>$LOG

# rm -rf /usr/share/nginx/html/* &>>$LOG

systemctl enable nginx &>>$LOG
systemctl restart nginx &>>$LOG

# Install Maria Db Database

yum install mariadb-server mysql -y

systemctl enable mariadb
systemctl start mariadb
