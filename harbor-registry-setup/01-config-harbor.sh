#!/bin/bash

# Harbor on Ubuntu 24.04

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

# Menu for IP, FQDN, or Custom IP
PS3='Would you like to install Harbor based on IP or FQDN or CustomIP? '
select option in IP FQDN CustomIP; do
    case $option in
        IP)
            IPorFQDN=$(hostname -I | awk '{print $1}')  # Get the first IP address
            break
            ;;
        FQDN)
            IPorFQDN=$(hostname -f)  # Get the fully qualified domain name
            break
            ;;
        CustomIP)
            read -p "Enter custom IP address: " custom_ip
            if [[ -n "$custom_ip" ]]; then
                IPorFQDN="$custom_ip"
                break
            else
                echo -e "${RED}Custom IP cannot be empty. Please try again.${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Invalid option. Please select 1 (IP), 2 (FQDN), or 3 (CustomIP).${NC}"
            ;;
    esac
done

# Verify that IPorFQDN is set
if [[ -z "$IPorFQDN" ]]; then
    echo -e "${RED}Error: IPorFQDN is empty. Exiting.${NC}"
    exit 1
fi

# Output the result
echo -e "${YELLOW}Selected IP or FQDN: $IPorFQDN ${NC}"

# Harbor Registry Name
HARBORREGISTRYNAME="hcr.${IPorFQDN}.nip.io"
export REGISTRY_URL=$HARBORREGISTRYNAME
echo -e "${YELLOW}Harbor Registry Name: $REGISTRY_URL ${NC}"

# Housekeeping
sudo apt update -y
sudo swapoff --all
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
#sudo ufw disable # Do Not Do This In Production
echo -e "${BLUE}Housekeeping Done${NC}"

# Config Docker Insecure Registries Entries
sudo tee /etc/docker/daemon.json >/dev/null <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "insecure-registries": ["$REGISTRY_URL:443","$REGISTRY_URL:80","$IPorFQDN:443","$IPorFQDN:80","0.0.0.0/0"],
  "tls" : false,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo groupadd docker
MAINUSER=$(logname)
sudo usermod -aG docker $MAINUSER
sudo systemctl daemon-reload
echo -e "${GREEN}Docker Installation Done${NC}"

# Verify Docker Compose installation
../prerequisites/verify-dockercompose.sh

# Extract the download URL using wget
DOWNLOAD_URL="https://github.com/goharbor/harbor/releases/download/v2.12.2/harbor-offline-installer-v2.12.2.tgz"
HARBORFILENAME=$(basename "$DOWNLOAD_URL")
sudo rm "$HARBORFILENAME" || true
sudo wget https://github.com/goharbor/harbor/releases/download/v2.12.2/harbor-offline-installer-v2.12.2.tgz
echo -e "${YELLOW}Harbor Download URL: $DOWNLOAD_URL ${NC}"
echo -e "${YELLOW}Harbor Installer File Name: $HARBORFILENAME ${NC}"

# Get current user
CURRENT_USER=$(whoami)
# Change ownership
sudo chown "$CURRENT_USER:$CURRENT_USER" "$HARBORFILENAME"
# Use sudo to run as target user
sudo -u "$CURRENT_USER" tar -xzvf "$HARBORFILENAME"

cd harbor/
HARBOR_PATH=`pwd`
echo -e "\n${BLUE}Harbor Path: $HARBOR_PATH ${NC}\n"

# Config Harbor YAML file
cd $HARBOR_PATH
sudo cp harbor.yml.tmpl harbor.yml
sudo sed -i "s/reg.mydomain.com/$REGISTRY_URL/g" harbor.yml
sudo sed -i 's|/your/certificate/path|/data/cert/demo-apic.crt|g; s|/your/private/key/path|/data/cert/demo-apic.key|g' harbor.yml

sudo ./prepare
sudo systemctl restart docker
sudo docker-compose down -v
sudo docker-compose up -d

echo -e "${GREEN}Harbor Configuration Complete ${NC}"
