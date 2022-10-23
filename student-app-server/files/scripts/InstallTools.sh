#! /bin/bash

# Global Variables
LOG=/tmp/stack.log

# Set Hostname Jenkins
hostnamectl set-hostname app-server

# add the user devops
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

sudo su - devops -c "mkdir /home/devops/.ssh && touch /home/devops/.ssh/authorized_keys"

echo
# echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCbnWctm0AvXkHiNfTJS3oPaEvSrVAuiXUQW62HSTBwv/FHiDyZ8ZLIu4Cck1dOtieC7zRVp8xYlSHqCAXHOTdFU3cCXAJEpjjhc0ZJLkcAJyanrZENi6jSMWqFkaPzKz6QpAsL37FGkiVbfrd3MiRgKa4MVm5fa8V0docEQk2biX+U14oBcTcP7pfLtBYuPoxlWokDbXTPaCgHPoIB5dArynhbqbiswVWiSaknPlxQPQV0HBooVK/JEEP+3VHXX8GzBPoJeyQHUi0I2QicEQWB1XxO+YWtLAT2EDoYAQXtqruhbrZQnEIfIUR2StDfVaZjQWfyTQL/2sZciz6Alh9j devops@app-server' >/home/devops/.ssh/authorized_keys
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDNlYPls4Bdas3S5g9LsPZCELcD3lp7ROoAZj6JWwloqDHaNn17pSMgKo76FluBHkAmvLefGhY232Zc7yU1E4IhGA72NMI7fYhHebLXIQverb75Vd//KY78bUmP/WSYNpcYSgx5DD7D8fQIi8EiJ0NqyE/pEGGhclpbqzXLISwboSvVNbveKxwu1rao4xcbmyTP9r6qWWPe6fhlCpOwfFLDOxbRPpe3qqP4cdqpS5hmEgIwgo8qzxJq9fItRZd5+5ruuxhvW1qzFPBBdvhdNDdIg0K5PDPsSdznbBfkf+Nw2RRtgyQZKvh93A/q6ljQ7VbN53tVz6ALaWLZItW33rS2TcbkrL5+dWBq6HifjRAlAwpQ+2oQT7RvZqp5tgiZiABAsDHbsSZH6A1fOARDXrs2svM5+WQxNqZbdcvL3o1r7nlyYiciswVKPCFtpDP36WGvTvpykXmatUxIzZNzYJGr+lYF7ut90KnJkzs2aN5niARLYdOXgjYfHceiSsF0zVE= devops' >/home/devops/.ssh/authorized_keys

# Install Java
amazon-linux-extras install java-openjdk11 -y &>>$LOG

# Install Git SCM
yum install git -y &>>$LOG

java -version &>>$LOG
git --version &>>$LOG

chown -R devops:devops /opt
# groupadd tomcat && useradd -M -s /bin/nologin -g tomcat -d /usr/local/tomcat tomcat

cd /opt/
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.68/bin/apache-tomcat-9.0.68.tar.gz
tar -xvf apache-tomcat-9.0.68.tar.gz &>>$LOG
mv apache-tomcat-9.0.68 tomcat
rm -f apache-tomcat-9.0.68.tar.gz

chown -R devops:devops /opt/tomcat/

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
User=devops
Group=devops
[Install]
WantedBy=multi-user.target' > /etc/systemd/system/tomcat.service

systemctl daemon-reload
systemctl start tomcat
systemctl enable tomcat

# script to install maven

# todo: add method for checking if latest or automatically grabbing latest
mvn_version=${mvn_version:-3.6.3}
url="http://www.mirrorservice.org/sites/ftp.apache.org/maven/maven-3/${mvn_version}/binaries/apache-maven-${mvn_version}-bin.tar.gz"
install_dir="/opt/maven"

if [ -d ${install_dir} ]; then
    mv ${install_dir} ${install_dir}.$(date +"%Y%m%d")
fi

mkdir ${install_dir}
chown -R devops:devops ${install_dir}
curl -fsSL ${url} | tar zx --strip-components=1 -C ${install_dir}

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
