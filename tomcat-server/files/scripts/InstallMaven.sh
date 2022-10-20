#!/bin/bash
set -e
sudo su -
# script to install maven

# todo: add method for checking if latest or automatically grabbing latest
mvn_version=${mvn_version:-3.6.3}
url="http://www.mirrorservice.org/sites/ftp.apache.org/maven/maven-3/${mvn_version}/binaries/apache-maven-${mvn_version}-bin.tar.gz"
install_dir="/opt/maven"

if [ -d ${install_dir} ]; then
    mv ${install_dir} ${install_dir}.$(date +"%Y%m%d")
fi

mkdir ${install_dir}
curl -fsSL ${url} | tar zx --strip-components=1 -C ${install_dir}

echo "export M2_HOME=${install_dir}" >> /home/ec2-user/.bashrc
echo 'export M2=$M2_HOME/bin' >> /home/ec2-user/.bashrc
echo 'export PATH=$M2:$PATH' >> /home/ec2-user/.bashrc

source /home/ec2-user/.bashrc

echo maven installed to ${install_dir}
mvn --version

printf "\n\nTo get mvn in your path, open a new shell or execute: source /etc/profile.d/maven.sh\n"
