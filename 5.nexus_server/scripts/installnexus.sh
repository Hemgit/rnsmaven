#!/bin/bash
set -e

# Variables
NEXUS_USER=devops
NEXUS_HOME=/opt/nexus3
TMP_DIR=/tmp
LOG=/home/$NEXUS_USER/install_nexus.log

# Ensure log file is writable
mkdir -p /home/$NEXUS_USER
touch $LOG
chown $NEXUS_USER:$NEXUS_USER $LOG

echo "Starting Nexus installation" | tee -a $LOG

# Detect latest Nexus 3 version
echo "Detecting latest Nexus version..." | tee -a $LOG
LATEST_VERSION=$(curl -s https://download.sonatype.com/nexus/3/latest | grep -Eo 'nexus-3\.[0-9]+\.[0-9]+-[0-9]+-unix\.tar\.gz' | head -1)
if [ -z "$LATEST_VERSION" ]; then
    echo "Failed to detect latest Nexus version" | tee -a $LOG
    exit 1
fi
DOWNLOAD_URL="https://download.sonatype.com/nexus/3/$LATEST_VERSION"
echo "Latest Nexus version detected: $LATEST_VERSION" | tee -a $LOG

# Download Nexus tarball
echo "Downloading Nexus $LATEST_VERSION..." | tee -a $LOG
sudo wget -q --show-progress $DOWNLOAD_URL -O $TMP_DIR/nexus.tar.gz
if [ $? -ne 0 ]; then
  echo "Download Nexus -- FAILURE" | tee -a $LOG
  exit 1
fi
echo "Download Nexus -- SUCCESS" | tee -a $LOG

# Extract Nexus
echo "Extracting Nexus..." | tee -a $LOG
sudo tar -xzf $TMP_DIR/nexus.tar.gz -C $TMP_DIR
EXTRACTED_DIR=$(tar -tf $TMP_DIR/nexus.tar.gz | head -1 | cut -f1 -d"/")

# Move Nexus to /opt
echo "Moving Nexus to $NEXUS_HOME..." | tee -a $LOG
sudo mv $TMP_DIR/$EXTRACTED_DIR $NEXUS_HOME

# Ownership
sudo chown -R $NEXUS_USER:$NEXUS_USER $NEXUS_HOME
sudo mkdir -p $NEXUS_HOME/sonatype-work
sudo chown -R $NEXUS_USER:$NEXUS_USER $NEXUS_HOME/sonatype-work

# Configure nexus.rc
echo 'run_as_user="'$NEXUS_USER'"' | sudo tee $NEXUS_HOME/bin/nexus.rc

# Setup systemd service
sudo bash -c "cat <<EOF > /etc/systemd/system/nexus.service
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=$NEXUS_HOME/bin/nexus start
ExecStop=$NEXUS_HOME/bin/nexus stop
User=$NEXUS_USER
Group=$NEXUS_USER
Restart=on-abort
TimeoutSec=600

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus

echo "Nexus installation completed successfully!" | tee -a $LOG