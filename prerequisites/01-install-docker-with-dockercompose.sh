#!/bin/bash

# Docker & Docker Compose on Ubuntu 24.04

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure the script is running in bash
if [ -z "$BASH_VERSION" ]; then
    echo -e "${RED}This script must be run in bash.${NC}"
    exit 1
fi

#Install Latest Stable Docker Release
apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Verify the docker service status and start it
#systemctl status docker 
systemctl enable docker
systemctl stop docker 
echo -e "${RED} Docker stoped ${NC}\n"
systemctl start docker 
echo -e "${GREEN} Docker started ${NC}\n"

mkdir -p /etc/systemd/system/docker.service.d
groupadd docker
MAINUSER=$(logname)
usermod -aG docker $MAINUSER
systemctl daemon-reload
systemctl restart docker
echo -e "${GREEN}Docker Installation Done${NC}"

# Verify Docker Compose installation
./verify-dockercompose.sh

systemctl restart docker

echo -e "${GREEN}Docke & Docker Compose Installation Complete \n\nPlease log out and log in or run the command 'newgrp docker' to use Docker without sudo ${NC}"