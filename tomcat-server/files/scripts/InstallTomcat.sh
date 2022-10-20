#! /bin/bash

# Global Variables
LOG=/tmp/stack.log

# Set Hostname Jenkins
hostnamectl set-hostname build-server

# Install Java
amazon-linux-extras install java-openjdk11 -y &>>$LOG

# Install Git SCM
yum install git -y &>>$LOG

java -version &>>$LOG
git --version &>>$LOG

chown -R ec2-user:ec2-user /opt
# groupadd tomcat && useradd -M -s /bin/nologin -g tomcat -d /usr/local/tomcat tomcat

cd /opt/
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.65/bin/apache-tomcat-9.0.65.tar.gz
tar -xvf apache-tomcat-9.0.65.tar.gz &>>$LOG
mv apache-tomcat-9.0.65 tomcat
rm -f apache-tomcat-9.0.65.tar.gz

chown -R ec2-user:ec2-user /opt/tomcat/

echo '# Systemd unit file for tomcat
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target
[Service]
Type=forking
Environment=JAVA_HOME=/usr/lib/jvm/jre-11-openjdk-11.0.13.0.8-1.amzn2.0.3.x86_64/
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

# script to install maven

# todo: add method for checking if latest or automatically grabbing latest
mvn_version=${mvn_version:-3.6.3}
url="http://www.mirrorservice.org/sites/ftp.apache.org/maven/maven-3/${mvn_version}/binaries/apache-maven-${mvn_version}-bin.tar.gz"
install_dir="/opt/maven"

if [ -d ${install_dir} ]; then
    mv ${install_dir} ${install_dir}.$(date +"%Y%m%d")
fi

mkdir ${install_dir}
chown -R ec2-user:ec2-user ${install_dir}
curl -fsSL ${url} | tar zx --strip-components=1 -C ${install_dir}

echo "export M2_HOME=${install_dir}" >> /home/ec2-user/.bashrc
echo 'export M2=$M2_HOME/bin' >> /home/ec2-user/.bashrc
echo 'export PATH=$M2:$PATH' >> /home/ec2-user/.bashrc

source /home/ec2-user/.bashrc

echo maven installed to ${install_dir}
mvn --version

printf "\n\nTo get mvn in your path, open a new shell or execute: source /etc/profile.d/maven.sh\n"

## Web Server Installation
echo "WEB SERVER SETUP"
# sudo yum install nginx -y &>>$LOG
amazon-linux-extras install nginx1 -y &>>$LOG

rm -rf  /usr/share/nginx/html/* &>>$LOG
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
