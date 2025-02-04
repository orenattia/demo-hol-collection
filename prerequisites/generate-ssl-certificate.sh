#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if both parameters are provided
if [ $# -ne 1 ]; then
    echo -e "${RED}Usage: $0 <IP_ADDRESS>${NC}"
    echo -e "${RED}xample: $0 161.156.84.110${NC}"
    exit 1
fi

IP_ADDRESS=$1

HARBORREGISTRYNAME="hcr.${IP_ADDRESS}.nip.io"

# Print script parameters
echo -e "${YELLOW}Setting up certificates with following parameters:${NC}"
echo -e "${YELLOW}Harbor Registry Name: ${HARBORREGISTRYNAME} ${NC}"

# Create certificate directory
sudo mkdir -p cert
cd cert/

# Generate CA certificate private key
echo -e "${BLUE}Generating CA certificate private key... ${NC}"
sudo openssl genrsa -out ca.key 4096

# Generate the CA certificate
echo -e "${BLUE}Generating CA certificate... ${NC}"
sudo openssl req -x509 -new -nodes -sha512 -days 3650 \
    -subj "/C=CN/ST=Tel-Aviv/L=Tel-Aviv/O=demo/OU=Personal/CN=${HARBORREGISTRYNAME}" \
    -key ca.key -out ca.crt

# Generate server certificate private key
echo -e "${BLUE}Generating server certificate private key... ${NC}"
sudo openssl genrsa -out demo-apic.key 4096

# Generate certificate signing request (CSR)
echo -e "${BLUE}Generating certificate signing request... ${NC}"
sudo openssl req -sha512 -new \
    -subj "/C=CN/ST=Tel-Aviv/L=Tel-Aviv/O=demo/OU=Personal/CN=${HARBORREGISTRYNAME}" \
    -key demo-apic.key -out demo-apic.csr

# Generate v3.ext file
echo -e "${BLUE}Generating v3.ext file... ${NC}"
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=demo-apic.com
DNS.2=demo-apic
DNS.3=${HARBORREGISTRYNAME}
EOF

# Generate certificate for Harbor host
echo -e "${BLUE}Generating certificate for Harbor host... ${NC}"
sudo openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in demo-apic.csr -out demo-apic.crt

# Create certificates directory and copy files
echo -e "${BLUE}Creating certificates directory and copying files... ${NC}"
sudo mkdir -p /data/cert/
sudo cp demo-apic.crt /data/cert/
sudo cp demo-apic.key /data/cert/

# Convert certificate for Docker
echo -e "${BLUE}Converting certificate for Docker... ${NC}"
sudo openssl x509 -inform PEM -in demo-apic.crt -out demo-apic.cert

# Set up Docker certificates
echo -e "${BLUE}Setting up Docker certificates... ${NC}"
sudo mkdir -p /etc/docker/certs.d/${HARBORREGISTRYNAME}/
sudo cp demo-apic.cert /etc/docker/certs.d/${HARBORREGISTRYNAME}/
sudo cp demo-apic.key /etc/docker/certs.d/${HARBORREGISTRYNAME}/
sudo cp ca.crt /etc/docker/certs.d/${HARBORREGISTRYNAME}/

# Restart Docker
echo -e "${BLUE}Restarting Docker service... ${NC}"
sudo systemctl restart docker

echo -e "${YELLOW}Content of [cert/] folder:"
find 
echo -e "${GREEN}Certificate setup completed successfully! ${NC}"
echo -e "${GREEN}Certificates are available in: ${NC}"
echo -e "${GREEN}   [/data/cert/] ${NC}"
echo -e "${GREEN}   [/etc/docker/certs.d/${HARBORREGISTRYNAME}/] ${NC}"