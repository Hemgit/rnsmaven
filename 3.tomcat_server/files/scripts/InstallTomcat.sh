

#! /bin/bash

# Install Nginx
amazon-linux-extras enable nginx1
echo "Installing Nginx..." &>>$LOG
yum install -y nginx &>>$LOG
systemctl enable nginx
systemctl start nginx
echo "Nginx installed and started."

# Global Variables
LOG=/tmp/devops.log

yum update -y
# Set Hostname Jenkins
hostnamectl set-hostname tomcat-server

# add the user devops
useradd devops
# set password : the below command will avoid re entering the password
echo "devops" | passwd --stdin devops
echo "devops" | passwd --stdin ec2-user
# modify the sudoers file at /etc/sudoers and add entry
echo 'devops     ALL=(ALL)      NOPASSWD: ALL' | sudo tee -a /etc/sudoers
echo 'ec2-user     ALL=(ALL)      NOPASSWD: ALL' | sudo tee -a /etc/sudoers
# this command is to add an entry to file : echo 'PasswordAuthentication yes' | sudo tee -a /etc/ssh/sshd_config
# the below sed command will find and replace words with spaces "PasswordAuthentication no" to "PasswordAuthentication yes"
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
service sshd restart

# Install Java
amazon-linux-extras install java-openjdk11 -y &>>$LOG

# Install Git SCM
yum install tree wget zip unzip gzip vim net-tools git bind-utils python2-pip jq -y &>>$LOG
git --version &>>$LOG

sudo su - devops -c "git config --global user.name 'devops'"
sudo su - devops -c "git config --global user.email 'devops@gmail.com'"

## Enable color prompt
curl -s https://gitlab.com/rns-app/linux-auto-scripts/-/raw/main/ps1.sh -o /etc/profile.d/ps1.sh
chmod +x /etc/profile.d/ps1.sh

## Enable idle shutdown
curl -s https://gitlab.com/rns-app/linux-auto-scripts/-/raw/main/idle.sh -o /boot/idle.sh
chmod +x /boot/idle.sh && chown devops:devops /boot/idle.sh
{ crontab -l -u devops; echo '*/10 * * * * sh -x /boot/idle.sh &>/tmp/idle.out'; } | crontab -u devops -

java -version &>>$LOG
git --version &>>$LOG

chown -R devops:devops /opt
# groupadd tomcat && useradd -M -s /bin/nologin -g tomcat -d /usr/local/tomcat tomcat


# Download and install the latest Tomcat 10.x
cd /opt/
TOMCAT_VERSION=$(curl -s https://tomcat.apache.org/download-10.cgi | grep -oP 'apache-tomcat-\K[0-9.]+(?=\.zip)' | head -1)
echo "Latest Tomcat version: $TOMCAT_VERSION"
wget https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz
tar -xvf apache-tomcat-${TOMCAT_VERSION}.tar.gz &>>$LOG
mv apache-tomcat-${TOMCAT_VERSION} tomcat
rm -f apache-tomcat-${TOMCAT_VERSION}.tar.gz

chown -R devops:devops /opt/tomcat/

# Verify the version of Tools
java -version
sudo bash /opt/tomcat/bin/version.sh


# Dynamically detect JAVA_HOME
JAVA_PATH=$(readlink -f /usr/bin/java)
JAVA_HOME_DIR=$(dirname $(dirname $JAVA_PATH))
cat <<EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=devops
Group=devops
Environment=JAVA_HOME=$JAVA_HOME_DIR
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx512M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Tomcat Configuration
cp /tmp/tomcat/manager/context.xml /opt/tomcat/webapps/manager/META-INF/
cp /tmp/tomcat/conf/tomcat-users.xml /opt/tomcat/conf/
cp /tmp/tomcat/conf/context.xml /opt/tomcat/conf/
cp /tmp/tomcat/lib/mysql-connector.jar /opt/tomcat/lib/
cp /tmp/tomcat/conf/server.xml /opt/tomcat/conf/

if [ -f /etc/systemd/system/tomcat.service ]; then
	systemctl daemon-reload
	systemctl start tomcat
	systemctl enable tomcat
else
	echo "/etc/systemd/system/tomcat.service not found. Skipping systemctl commands."
fi
