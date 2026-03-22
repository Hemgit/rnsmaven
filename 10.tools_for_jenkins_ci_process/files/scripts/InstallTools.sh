#!/bin/bash
set -euo pipefail

LOG=/tmp/devops.log

# Update system
yum update -y &>>"$LOG"

# Set Hostname
hostnamectl set-hostname app-server

# Add devops user
if ! id devops &>/dev/null; then
    useradd devops
    echo "devops" | passwd --stdin devops
fi

# Add devops and ec2-user to sudoers
grep -q '^devops' /etc/sudoers || echo 'devops ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
grep -q '^ec2-user' /etc/sudoers || echo 'ec2-user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Enable SSH password auth
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

# Install Java 11
amazon-linux-extras install java-openjdk11 -y &>>"$LOG"

# Install Git and utilities
yum install -y tree wget zip unzip gzip vim net-tools git bind-utils python2-pip jq &>>"$LOG"

# Configure Git
sudo -u devops git config --global user.name "devops"
sudo -u devops git config --global user.email "devops@gmail.com"

# Color prompt
curl -s https://gitlab.com/rns-app/linux-auto-scripts/-/raw/main/ps1.sh -o /etc/profile.d/ps1.sh
chmod +x /etc/profile.d/ps1.sh

# Idle shutdown cron
curl -s https://gitlab.com/rns-app/linux-auto-scripts/-/raw/main/idle.sh -o /boot/idle.sh
chmod +x /boot/idle.sh
chown devops:devops /boot/idle.sh
(crontab -l -u devops 2>/dev/null; echo '*/10 * * * * sh -x /boot/idle.sh &>/tmp/idle.out') | crontab -u devops -

# Verify installations
java -version &>>"$LOG"
git --version &>>"$LOG"

# Prepare /opt
chown -R devops:devops /opt

# ----------------------------
# Install Latest Tomcat 9
# ----------------------------
cd /opt || exit

# Detect latest Tomcat 9 version
LATEST=$(curl -s https://dlcdn.apache.org/tomcat/tomcat-9/ \
        | grep -oP 'v9\.\d+\.\d+/' | sort -V | tail -1 | tr -d 'v/')
TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-9/v${LATEST}/bin/apache-tomcat-${LATEST}.tar.gz"

echo "Downloading Tomcat from $TOMCAT_URL" &>>"$LOG"
wget --tries=5 --retry-connrefused -O apache-tomcat-latest.tar.gz "$TOMCAT_URL"

if [ ! -s apache-tomcat-latest.tar.gz ]; then
    echo "ERROR: Tomcat download failed!" >&2
    exit 1
fi

# Extract
mkdir -p /opt/tomcat
tar -xzf apache-tomcat-latest.tar.gz -C /opt/tomcat --strip-components=1
rm -f apache-tomcat-latest.tar.gz
chown -R devops:devops /opt/tomcat

# Create required directories
mkdir -p /opt/tomcat/temp /opt/tomcat/logs /opt/tomcat/work
chown -R devops:devops /opt/tomcat

# Get JAVA_HOME dynamically
JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

# Systemd service
cat >/etc/systemd/system/tomcat.service <<EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking
Environment=JAVA_HOME=${JAVA_HOME}
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
User=devops
Group=devops
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat
systemctl status tomcat --no-pager &>>"$LOG"

# ----------------------------
# Install Nginx
# ----------------------------
amazon-linux-extras install nginx1 -y &>>"$LOG"
systemctl enable nginx &>>"$LOG"
systemctl restart nginx &>>"$LOG"
systemctl status nginx --no-pager &>>"$LOG"

# ----------------------------
# Install MariaDB
# ----------------------------
yum install -y mariadb-server &>>"$LOG"
systemctl enable mariadb
systemctl start mariadb
systemctl status mariadb --no-pager &>>"$LOG"

echo "All tools installed successfully!"