#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#==================== Start Init Section ====================
readonly SCRIPT_NAME=$(basename "$0")
readonly REQUIRED_PARAMS=15

# Function to display usage information
usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} <apic_version> <apic_license> <cert_manager_version>

Parameters:
    apic_version         - IBM API Connect version (e.g., 10.0.8.0)
    apic_license         - Valid IBM API Connect license key
    cert_manager_version - Certificate Manager version (e.g., 1.12.0)

Example:
    ${SCRIPT_NAME} 10.0.8.0 L-VQYA-YNM22H 1.12.0

Note: All parameters are required.
EOF
}

# Function to verify the existence of prerequisites
verify_prerequisites() {
    echo -e "# ${YELLOW}Check if Kubectl is installed... ${NC}"
    setup_kubectl

    echo -e "# ${YELLOW}Check if Docker is installed... ${NC}"
    setup_docker
}

# Function to validate parameters
validate_parameters() {
    local apic_version="$1"
    local apic_license="$2"
    local cert_manager_version="$3"
    local nginx_ip="$4"
    local ibm_entitlement_key="$5"
    local admin_credentials="$6"
    local has_error=false

    # Check if correct number of parameters are provided
    if [[ $# -ne ${REQUIRED_PARAMS} ]]; then
        echo -e "${RED}Error: Expected ${REQUIRED_PARAMS} parameters, but got $# ${NC}"
        has_error=true
    fi

    # Validate APIC version format (x.x.x.x)
    if ! [[ ${apic_version} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid APIC version format. Expected format: x.x.x.x ${NC}"
        has_error=true
    fi

    # Validate license key format (L-XXXX-XXXXXX)
    if ! [[ ${apic_license} =~ ^L-[A-Z0-9]{4}-[A-Z0-9]{6}$ ]]; then
        echo -e "${RED}Error: Invalid license key format. Expected format: L-XXXX-XXXXXX ${NC}"
        has_error=true
    fi

    # Validate cert manager version format (x.x.x)
    if ! [[ ${CERT_MANAGER_VERSION} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid cert manager version format. Expected format: x.x.x ${NC}"
        has_error=true
    fi

    # If any validation failed, show usage and exit
    if [[ ${has_error} == true ]]; then
        echo
        usage
        exit 1
    fi

    # Display validated parameters
    echo "Validated Parameters:"
    echo "├── APIC Version: ${apic_version}"
    echo "├── License Key: ${apic_license}"
    echo "└── Cert Manager Version: ${CERT_MANAGER_VERSION}"
}

setup_docker(){
    # Check if Docker is installed
    if command -v docker &> /dev/null
    then
        echo -e "# ✅${GREEN}Docker is installed.${NC}"
    else
        echo -e "# ${YELLOW}Docker is not installed.${NC} ${RED}Installing kubectl...${NC}"

        # Add Docker Official GPG Key
        sudo apt update
        sudo apt install ca-certificates curl -y
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add Docker Official APT Repository
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Install Docker
        sudo apt update
        sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

        # Add the current user to the Docker group
        sudo usermod -aG docker $USER && newgrp docker

        echo -e "# ✅${GREEN}Docker installed and user added to Docker group successfully.${NC}"
    fi

    echo -e "\n"

    # Verify the Docker service status and start it
    #sudo systemctl status docker
    sudo systemctl start docker
    sudo systemctl enable docker
}

setup_kubectl(){
    # Check if kubectl is installed
    if command -v kubectl &> /dev/null
    then
        echo -e "# ✅${GREEN}Kubectl is installed.${NC}"
    else
        echo -e "# ${YELLOW}Kubectl is not installed.${NC} ${RED}Installing kubectl...${NC}"
        
        # Detect the operating system
        OS=$(uname -s)
        
        case $OS in
            Linux*)
                # Install kubectl on Linux
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                ;;
            Darwin*)
                # Install kubectl 
                brew install kubectl
                ;;
            *)
                echo -e "# ${RED}Unsupported operating system: $OS ${NC}"
                exit 1
                ;;
        esac
        
        echo -e "# ✅${GREEN}Kubectl installed successfully.${NC}"
    fi

    echo -e "\n"
}

# Main execution
main() {
    # Trap errors
    set -e
    trap 'echo "Error: Script failed on line $LINENO"' ERR

    # Validate parameters
    validate_parameters "$@"

    # Export validated parameters for use in other scripts
    export APIC_VERSION="$1"
    export LICENSE_KEY="$2"
    export CERT_MANAGER_VERSION="$3"
    export NGINX_IP="$4"
    export IBM_ENTITLEMENT_KEY="$5"
    export ADMIN_CREDENTIALS="$6"
    export MINIKUBE_PROFILE="$7"
    export REGISTRY_URL="$8"
    export REGISTRY_PROJECT="$9"
    export REGISTRY_USERNAME="$10"
    export REGISTRY_PASSWORD="$11"
}
#==================== End Init Section ====================
echo -e "${YELLOW}\n"
echo ' ######               :####                                                                                                                  '
echo ' ######               #####                                   ##                                                                             '
echo '   ##                 ##                                      ##                                                                             '
echo '   ##     ##.####   #######    ##.####   :####     :#####.  #######    ##.####   ##    ##     ####:  #######   ##    ##   ##.####   .####:   '                   
echo '   ##     #######   #######    #######   ######   ########  #######    #######   ##    ##   #######  #######   ##    ##   #######  .######:  '                   
echo '   ##     ###  :##    ##       ###.      #:  :##  ##:  .:#    ##       ###.      ##    ##   ##:  :#    ##      ##    ##   ###.     ##:  :##  '                   
echo '   ##     ##    ##    ##       ##         :#####  ##### .     ##       ##        ##    ##  ##.         ##      ##    ##   ##       ########  '                   
echo '   ##     ##    ##    ##       ##       .#######  .######:    ##       ##        ##    ##  ##          ##      ##    ##   ##       ########  '                   
echo '   ##     ##    ##    ##       ##       ## .  ##     .: ##    ##       ##        ##    ##  ##.         ##      ##    ##   ##       ##        '                   
echo '   ##     ##    ##    ##       ##       ##:  ###  #:.  :##    ##.      ##        ##:  ###   ##:  .#    ##.     ##:  ###   ##       ###.  :#  '                   
echo ' ######   ##    ##    ##       ##       ########  ########    #####    ##         #######   #######    #####    #######   ##       .#######  '                   
echo ' ######   ##    ##    ##       ##         ###.##  . ####      .####    ##          ###.##     ####:    .####     ###.##   ##        .#####:  '
echo '                                                                                                                                             '
echo ' #######:                                                                ##        ##                                                        '                  
echo ' ##   :##                                                                ##                                                                  '                  
echo ' ##    ##   ##.####   .####:   ##.###:    :####     ##.####   :####    #######   ####      .####.   ##.####                                  '                  
echo ' ##   :##   #######  .######:  #######:   ######    #######   ######   #######   ####     .######.  #######                                  '                  
echo ' #######:   ###.     ##:  :##  ###  ###   #:  :##   ###.      #:  :##    ##        ##     ###  ###  ###  :##                                 '                  
echo ' ######:    ##       ########  ##.  .##    :#####   ##         :#####    ##        ##     ##.  .##  ##    ##                                 '                  
echo ' ##         ##       ########  ##    ##  .#######   ##       .#######    ##        ##     ##    ##  ##    ##                                 '                  
echo ' ##         ##       ##        ##.  .##  ## .  ##   ##       ## .  ##    ##        ##     ##.  .##  ##    ##                                 '                  
echo ' ##         ##       ###.  :#  ###  ###  ##:  ###   ##       ##:  ###    ##.       ##     ###  ###  ##    ##                                 '                  
echo ' ##         ##       .#######  #######:  ########   ##       ########    #####  ########  .######.  ##    ##                                 '                  
echo ' ##         ##        .#####:  ##.###:     ###.##   ##         ###.##    .####  ########   .####.   ##    ##                                 '
echo '                               ##                                                                                                            '
echo '                               ##                                                                                                            '
echo '                               ##                                                                                                            '
echo -e "${NC}\n"                                                                                                         
echo -e "# ${GREEN}===============================${NC}"
echo -e "# ${GREEN}Infrastructure Preparation     ${NC}"
echo -e "# ${GREEN}===============================${NC}"   
echo -e "\n"

set -e

# verify the existence of prerequisites
verify_prerequisites

# Call main with all parameters
main "$@"

current_dir="$(dirname "$0" 2> /dev/null)" || current_dir=.
export apic_namespace=apic
export filespath=${current_dir}/apiconnect-operator-release-files_${APIC_VERSION}

temp_out_path=${current_dir}/logs
mkdir ${temp_out_path} || true
temp_out_path=${current_dir}/temp
mkdir ${temp_out_path} || true

