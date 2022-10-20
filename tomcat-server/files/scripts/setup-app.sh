#! /bin/bash

sleep 45
java -version
mvn --version
git version
sh /opt/tomcat/bin/version.sh
cp /tmp/tomcat/manager/context.xml /opt/tomcat/webapps/manager/META-INF/
cp /tmp/tomcat/conf/tomcat-users.xml /opt/tomcat/conf/
cp /tmp/tomcat/conf/context.xml /opt/tomcat/conf/
cp /tmp/tomcat/lib/mysql-connector.jar /opt/tomcat/lib/
cd /opt/ && git clone https://gitlab.com/rns-app/student-app.git
source /home/ec2-user/.bashrc
cd student-app && mvn clean package
cp target/studentapp-*.war /opt/tomcat/webapps/student.war
sudo systemctl stop tomcat
sudo systemctl start tomcat
