#!/bin/bash

# Minikube with K8 Utilities on Ubuntu 24.04

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

# Define minikube profiles
declare -A MINIKUBE_PROFILES=(
    ["apic"]="16 40960 containerd"
    ["appc"]="AppConnect - TBD..."
    ["dp"]="Datapower - TBD..."
)

# Function to select minikube profile
select_minikube_profile() {
    echo -e "${YELLOW}Select a Minikube Profile:${NC}"
    echo -e "${BLUE}1) API Connect  - 16 CPUs, 40GB RAM${NC}"
    echo -e "${BLUE}2) APP Connect  - TBD${NC}"
    echo -e "${BLUE}3) DataPower    - TBD${NC}"
    
    while true; do
        read -p "Enter profile number (1-3): " profile_choice
        case $profile_choice in
            1) selected_profile="apic"; 
                read -p "Enter Private Registry URL: " private_registry_url
                read -p "Enter Private Registry Project Name: " private_registry_project_name
                read -p "Enter Private Registry User Name: " private_registry_user
                read -p "Enter Private Registry Password: " private_registry_password

                export REGISTRY_URL=$private_registry_url
                export REGISTRY_PROJECT=$private_registry_project_name
                export REGISTRY_USERNAME=$private_registry_user
                export REGISTRY_PASSWORD=$private_registry_password

                minikube config set driver docker
                echo -e "${YELLOW}Starting Minikube with $selected_profile profile...${NC}"
                minikube -p ${REGISTRY_PROJECT} start --container-runtime=containerd --cni=cilium --memory=40960 --cpus=16 --insecure-registry=${REGISTRY_URL} --kubernetes-version=stable  --install-addons=true
                minikube -p ${REGISTRY_PROJECT} addons enable olm
                minikube -p ${REGISTRY_PROJECT} addons enable ingress
                minikube profile ${REGISTRY_PROJECT}

                # Create K8 namespace and secret to harbor
                kubectl create ns ${REGISTRY_PROJECT}
                kubectl create secret docker-registry hcr-secret --docker-server=${REGISTRY_URL}/${REGISTRY_PROJECT} --docker-username=${REGISTRY_USERNAME} --docker-password=${REGISTRY_PASSWORD} -n ${REGISTRY_PROJECT}
                # Configure ingress with namespace and secret
                minikube -p "${REGISTRY_PROJECT}" addons configure ingress <<< "${REGISTRY_PROJECT}/hcr-secret"
                minikube -p ${REGISTRY_PROJECT} addons disable ingress
                minikube -p ${REGISTRY_PROJECT} addons enable ingress
                minikube -p ${REGISTRY_PROJECT} addons enable olm
                minikube -p ${REGISTRY_PROJECT} addons list
                minikube profile list
            break;;
            2) selected_profile="appc"; 
            break;;
            3) selected_profile="dp"; 
            break;;
            *) echo -e "${RED}Invalid selection. Please choose 1-3.${NC}";;
        esac
    done
    
    # Read profile settings
    read -r cpus memory driver <<< "${MINIKUBE_PROFILES[$selected_profile]}"
    
    echo -e "${GREEN}Selected profile: $selected_profile${NC}"
    echo -e "${BLUE}CPUs: $cpus${NC}"
    echo -e "${BLUE}Memory: ${memory}MB${NC}"
    echo -e "${BLUE}Driver: $driver${NC}"
    
    # Enable additional addons for standard and performance profiles
    echo -e "${YELLOW}Enabling additional addons...${NC}"
    minikube addons enable metrics-server --profile $selected_profile
    minikube addons enable dashboard --profile $selected_profile
}

# Ensure the script is running in bash
if [ -z "$BASH_VERSION" ]; then
    echo -e "${RED}This script must be run in bash.${NC}"
    exit 1
fi

# Function to list all members of the sudo group with numbers
list_sudo_members() {
    getent group sudo | cut -d: -f4 | tr ',' '\n' | nl -v 1
}

# List all members of the sudo group with numbers
echo -e "${YELLOW}Select a Member of the sudo group: ${NC}"
list_sudo_members

# Prompt the user to select a specific user by entering the corresponding number
echo -e "${YELLOW}Enter the number of the sudo member you want to select ${NC}"
echo -e "${RED} ** To create a new sudo user enter [N]${NC} ${YELLOW}"
read -p " Line Number:" selected_number
echo -e " ${NC}"

# Get the list of sudo members
sudo_members=($(getent group sudo | cut -d: -f4 | tr ',' '\n'))

# Check if the selected number is valid
if [[ $selected_number -ge 1 && $selected_number -le ${#sudo_members[@]} ]]; then
    selected_sudo_user=${sudo_members[$selected_number-1]}
    echo -e "\n${YELLOW}You selected: ${GREEN} [${selected_sudo_user}] ${NC}"

    # Check if the selected user is a member of the sudo group
    if id -nG "$selected_sudo_user" | grep -qw "sudo"; then
        echo -e "${BLUE}User ${GREEN} [${selected_sudo_user}] ${BLUE}is part of the sudo group.${NC}"
    else
        echo -e "${RED}User ${selected_sudo_user} is not part of the sudo group.${NC}"
    fi
else
    echo -e "${RED}Invalid selection. Please enter a valid number or create a sudo user manually.${NC}"
    echo -e "${RED} 1) execute:${BLUE} usermod -aG sudo,docker [NEW_SUDO_USER] ${NC}"
    echo -e "${RED} 2) verify the user is attached to groups:${BLUE} groups [NEW_SUDO_USER]${NC}"
    echo -e "${RED}Next, execute the installation script again.${NC}\n"
    exit 1
fi

# Add the new user to the sudo group
sudo usermod -aG sudo,docker $selected_sudo_user

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo -e "${RED}curl is not installed. Please install curl and try again.${NC}"
    exit 1
fi

# Install Latest Stable kubectl Release
echo
echo -e "${YELLOW}kubectl Installation Start...${NC}"
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
if [ -z "$KUBECTL_VERSION" ]; then
    echo -e "${RED}Failed to retrieve kubectl version.${NC}"
    exit 1
fi
sudo curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download kubectl.${NC}"
    exit 1
fi
sudo install -o $selected_sudo_user -g $selected_sudo_user -m 0755 kubectl /usr/local/bin/kubectl
echo -e "${GREEN}kubectl Installation Done${NC}"

# Install Latest Stable helm3 Release
echo
echo -e "${YELLOW}helm3 Installation Start...${NC}"
sudo snap install helm --classic
echo -e "${GREEN}helm3 Installation Done${NC}"

# Install Latest Stable minikube Release
echo
echo -e "${YELLOW}minikube Installation Start...${NC}"
sudo curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download minikube.${NC}"
    exit 1
fi
sudo dpkg -i minikube_latest_amd64.deb

# Delete temporary files
echo
sudo rm minikube_latest_amd64.deb
sudo rm kubectl
echo -e "${RED}Delete temporary files!!! ${NC}"

# Verify the new user has been created and added to the sudo group
echo
echo -e "${GREEN}Minikube prerequisites completed successfully. ${NC}\n"

# Call the profile selection function
select_minikube_profile