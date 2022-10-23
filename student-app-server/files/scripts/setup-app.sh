#! /bin/bash

LOG=/tmp/stack.log

sleep 60

# Verify the Data Base
sudo systemctl status mariadb

# Verify the version of Tools
java -version
sudo bash /opt/tomcat/bin/version.sh

# Load Application Schema
cd /tmp/ && git clone https://gitlab.com/rns-app/student-app.git
sleep 15
mysql -uroot < /tmp/student-app/dbscript/studentapp.sql
# mysql -ustudent -pstudent1

# Nginx Setup

sudo rm -rf /usr/share/nginx/html/*
cd /tmp/ && git clone https://gitlab.com/rns-app/static-project.git
sudo cp -R /tmp/static-project/iPortfolio/* /usr/share/nginx/html

sudo sed -i -e '/location \/student/,+3 d' -e '/^        error_page 404/ i \\t location /student { \n\t\tproxy_pass http://localhost:8080/student;\n\t}\n' /etc/nginx/nginx.conf

sudo systemctl enable nginx
sudo systemctl restart nginx

# Tomcat Configuration
cp /tmp/tomcat/manager/context.xml /opt/tomcat/webapps/manager/META-INF/
cp /tmp/tomcat/conf/tomcat-users.xml /opt/tomcat/conf/
cp /tmp/tomcat/conf/context.xml /opt/tomcat/conf/
cp /tmp/tomcat/lib/mysql-connector.jar /opt/tomcat/lib/

# Restart the Tomcat SErver
sudo systemctl stop tomcat
sudo systemctl start tomcat

# Setup the Maven Path Variable
install_dir="/opt/maven"
echo "export M2_HOME=${install_dir}" >> /home/devops/.bashrc
echo 'export M2=$M2_HOME/bin' >> /home/devops/.bashrc
echo 'export PATH=$M2:$PATH' >> /home/devops/.bashrc

source /home/devops/.bashrc

echo maven installed to ${install_dir}
mvn --version

printf "\n\nTo get mvn in your path, open a new shell or execute: source /etc/profile.d/maven.sh\n"


# Deploy the Application

# Clone App and Deploy it to Tomcat SErver
cd /opt/
cp -R /tmp/student-app /opt/
#cd /opt/ && git clone https://gitlab.com/rns-app/student-app.git
#source /home/ec2-user/.bashrc

sudo su - devops -c "cd /opt/student-app && mvn clean package -DskipTests"
cp /opt/student-app/target/studentapp*.war /opt/tomcat/webapps/student.war
