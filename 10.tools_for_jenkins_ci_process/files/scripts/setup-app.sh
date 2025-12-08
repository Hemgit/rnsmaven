#! /bin/bash

LOG=/tmp/devops.log

sleep 60

# Verify the Data Base
sudo systemctl status mariadb

# Verify the version of Tools
java -version

# Check if Tomcat directory exists
if [ -d "/opt/tomcat" ]; then
    sudo bash /opt/tomcat/bin/version.sh
else
    echo "ERROR: Tomcat directory not found at /opt/tomcat"
    exit 1
fi

# Tomcat Configuration
if [ -d "/tmp/tomcat" ]; then
    cp /tmp/tomcat/manager/context.xml /opt/tomcat/webapps/manager/META-INF/
    cp /tmp/tomcat/conf/tomcat-users.xml /opt/tomcat/conf/
    cp /tmp/tomcat/conf/context.xml /opt/tomcat/conf/
    cp /tmp/tomcat/lib/mysql-connector.jar /opt/tomcat/lib/
else
    echo "ERROR: Tomcat config files not found at /tmp/tomcat"
    exit 1
fi

# Restart the Tomcat SErver
sudo systemctl stop tomcat
sudo systemctl start tomcat
