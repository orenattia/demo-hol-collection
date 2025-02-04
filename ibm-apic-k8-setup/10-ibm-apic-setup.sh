#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#==================== Start Menu Section ====================
menu() {
    # Verify that all prerequisites have been installed.
    echo -e "# ${BLUE}=== -----------------------------------   ===${NC}"
    echo -e "# ${BLUE}=== Check that the prerequisites match:   ===${NC}"
    echo -e "# ${BLUE}=== -----------------------------------   ===${NC}"
    echo -e "# ${BLUE}=== 1) Sudo User with admin privileges    ===${NC}"
    echo -e "# ${BLUE}=== 2) Docker Engine Installed ?          ===${NC}"
    echo -e "# ${BLUE}=== 3) Kubectl Utility Installed ?        ===${NC}"
    echo -e "# ${BLUE}=== -----------------------------------   ===${NC}"

    echo -e "# ${BLUE}============================================="
    read -p "Please confirm that all of the prerequisites have been installed before proceeding? (Y/n): " choice
    echo -e "${NC}"
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        echo -e "${RED} Missing requirements, the deployment was canceled.${NC} "
        exit 1
    fi

    echo -e "To install IBM API Connect 10, please select the following version:"
    echo -e "   ${YELLOW}***Yellow indicates the tested version***${NC}"
    echo -e "1) ${BLUE}[Off-Line setup] ver 10.0.9.0 [Air-Gap Setup using Harbor Private Registry] ${NC}"
    echo -e "2) ${BLUE}[On-Line setup] ${YELLOW}ver 10.0.6.0 [default] ${BLUE} [Online Setup using IBM Registry] ${NC}"
    echo -e "3) ${BLUE}[On/Off setup] ${NC}ver 10.0.5.8"
    echo -e "4) Exit"
    
    read -p "Enter selection [2]: " selection

    # If no input (just Enter pressed), use default
    #selection=${selection:-1}
    selection=${selection:-2}
    
    case $selection in
        1)
            echo "Setting up IBM API Connect 10 version 10.0.9.0"
            #API Connect licenses - https://www.ibm.com/docs/en/api-connect/10.0.x?topic=requirements-api-connect-licenses
            #Download [apiconnect-operator-release-files_10.0.9.0.zip] - https://www.ibm.com/support/pages/ibm%C2%AE-api-connect-v10090-now-available
            #
            #Troubleshooting - When can not pull edb image [e.g pod/edb-operator-856d566969-gljsk 0/1 ImagePullBackOff]
            #   Pulling images from the IBM Entitled Registry - https://www.ibm.com/docs/en/datapower-operator/1.12?topic=features-entitled-registry
            export APIC_VERSION=10.0.9.0
            export LICENSE_KEY=L-WPTV-3V8RK2
            export CERT_MANAGER_VERSION="1.12.13"
            ;;
        2)
            echo "Setting up IBM API Connect 10 version 10.0.6.0"
            #API Connect licenses - https://www.ibm.com/docs/en/api-connect/10.0.x?topic=requirements-api-connect-licenses
            #Download [apiconnect-operator-release-files_10.0.6.0.zip] - https://www.ibm.com/support/pages/ibm%C2%AE-api-connect-v10060-now-available
            export APIC_VERSION=10.0.6.0
            export LICENSE_KEY=L-KZXM-S7SNCU
            export CERT_MANAGER_VERSION="1.9.1"
            ;;
        3)
            echo "Setting up IBM API Connect 10 version 10.0.5.8"
            #Download [apiconnect-operator-release-files_10.0.5.8.zip] - https://www.ibm.com/support/pages/ibm%C2%AE-api-connect-v10058-now-available
            export APIC_VERSION=10.0.5.8
            export LICENSE_KEY=L-VQYA-YNM22H
            export CERT_MANAGER_VERSION="1.12.13"
            ;;
        4)
            echo "Exit installation..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please select 1, 2, 3, or 4"
            menu
            ;;
    esac

    # Set IVM API Connect Components Deployment Profile Limits
    export MANAGEMENT_PROFILE="n1xc2.m16"
    export PORTAL_PROFILE="n1xc2.m8"
    export ANALYTICS_PROFILE="n1xc2.m16"
    export DATAPOWER_PROFILE="n1xc1.m8"
    # Display validated parameters
    echo -e "\n"
    echo -e "Deployment Profile Limits:"
    echo -e "├── Management Profile: ${YELLOW} ${MANAGEMENT_PROFILE} ${NC}"
    echo -e "├── Portal Profile:     ${YELLOW} ${PORTAL_PROFILE}     ${NC}"
    echo -e "├── Analytics Profile:  ${YELLOW} ${ANALYTICS_PROFILE}  ${NC}"
    echo -e "└── DataPower Profile:  ${YELLOW} ${DATAPOWER_PROFILE}  ${NC}"
    # Ask user for confirmation to continue
    echo -e " ${BLUE} "
    read -p "Do you agree to continue with the deployment settings as it is? (Y/n): " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        echo -e "${RED} Deployment aborted.${NC} "
        exit 1
    fi
    echo -e "${YELLOW} Proceeding with deployment...${NC} "
}

set_registry_info() {
    # Print menu header
    echo -e "# ${YELLOW}Select container registry type: ${NC}"
    echo -e "# --------------------------------------- "
    echo -e "#  1) ${YELLOW}IBM Entitled Registry [default]:${NC}"
    echo -e "#     ${YELLOW}    Registry URL: cp.icr.io${NC}"
    echo -e "#     ${YELLOW}    Registry Project Name: cp${NC}"
    echo -e "# "
    echo -e "#  NOTE! Get the entitlement key from: https://myibm.ibm.com/products-services/containerlibrary"
    echo -e "#  2) Private Container Registry ${RED}[Docker Private Registry is required!!!]${NC}"
    echo -e "# --------------------------------------- "
    echo
    # Prompt for selection
    read -p "Enter selection [1]: " selection

    # 
    read -p "Enter minikube profile name: " minikube_profile
    export MINIKUBE_PROFILE=$minikube_profile

    # Configure the administrator password for the Cluster Defualt Management subsystem.
    #
    # If select default IBM registry
    if [[ ${selection} -eq 1 ]]; then
        export REGISTRY_URL=cp.icr.io
        export REGISTRY_PROJECT=cp

        echo -e "\n"
        echo '# Get IBM Entitlement key from: https://myibm.ibm.com/products-services/containerlibrary'
        echo -e "# NOTE! - ${RED}*** Installing APIC ${YELLOW}10.0.7.0 or later${NC} ${RED}requires entering a docker private registry <PASSWORD> ***${NC}"
        echo -e "# NOTE! - ${RED}*** IF USING IBM REGISTRY use your own IBM Entitlement key***${NC}"
        echo -e "# ${YELLOW}Enter Container Registry Password:${NC}"
        read -p "" entitlement_key
        echo -e "\n"
        export IBM_ENTITLEMENT_KEY=$entitlement_key
        export REGISTRY_PASSWORD=$entitlement_key
        echo -e "#     ${YELLOW}Registry URL: ${REGISTRY_URL} ${NC}"
        echo -e "#     ${YELLOW}Registry Project Name: ${REGISTRY_PROJECT} ${NC}"
    fi
    #
    # If Private Container Registry is selected
    if [[ ${selection} -eq 2 ]]; then
        # Prompt for selection
        echo -e "#${YELLOW}"
        echo -e "#${RED}IMPORTENT!!! - Download the full image Containers${NC}"
        echo -e "#  ${RED}IBM® API Connect v10.0.9.0 for Containers ${NC}"
        #echo -e "#  ${RED}Link - https://www.ibm.com/support/fixcentral/swg/selectFixes?product=ibm%2FWebSphere%2FIBM+API+Connect&fixids=apiconnect-image-tool_10.0.9.0&source=SAR&function=fixId&parent=ibm/WebSphere ${NC}"
        read -p "Enter Private Registry URL: " private_registry_url
        read -p "Enter Private Registry Project Name: " private_registry_project_name
        read -p "Enter Private Registry User Name: " private_registry_user
        read -p "Enter Private Registry Password: " private_registry_password
        echo "Private Container Registry is selected"
        echo -e "#${NC}"
    fi   

    export REGISTRY_URL=$private_registry_url
    export REGISTRY_PROJECT=$private_registry_project_name
    export REGISTRY_USERNAME=$private_registry_user
    export REGISTRY_PASSWORD=$private_registry_password

    echo -e "#     ${YELLOW}Registry URL: ${REGISTRY_URL} ${NC}"
    echo -e "#     ${YELLOW}Registry Project Name: ${REGISTRY_PROJECT} ${NC}"
    echo -e "#     ${YELLOW}Registry Project User Name: ${REGISTRY_USERNAME} ${NC}"
    echo -e "#     ${YELLOW}Registry Project Password: ${REGISTRY_PASSWORD} ${NC}"     
}

setup_minikube()
{
    minikube -p ${REGISTRY_PROJECT} status && retVal=$? || retVal=$?

    # If Minikube is not installed, proceed with the installation
    if [[ ${retVal} -eq 127 ]]; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux installation steps
            echo "Installing Minikube on Linux..."
            
            # Install Minikube dependencies
            sudo apt update
            sudo apt install -y curl wget apt-transport-https
            
            # Download and install Minikube
            sudo curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
            sudo install minikube-linux-amd64 /usr/local/bin/minikube
            
            # Install kubectl
            sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
            sudo chmod +x kubectl
            sudo mv kubectl /usr/local/bin/

        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS installation steps
            echo "Installing Minikube on macOS..."

            # Install Minikube dependencies
            brew update
            brew install kubectl minikube
            brew install docker-machine-driver-vmware

        else
            echo "Unsupported OS. Please install Minikube manually."
            exit 1
        fi

        echo "# minikube returned value: [$retVal]"
        minikube -p ${REGISTRY_PROJECT} addons list

        echo "# after starting minikube returned value: [$retVal]"
    else
        echo "# minikube returned value: [$retVal]"
        case ${retVal} in
            0)  # Start Minikube with specified configurations
                minikube -p ${REGISTRY_PROJECT} delete 
                minikube -p ${REGISTRY_PROJECT} delete || true
                minikube -p ${REGISTRY_PROJECT} start --container-runtime=containerd --cni=cilium --memory=40960 --cpus=16 --insecure-registry=${REGISTRY_URL} --kubernetes-version=stable  --install-addons=true;;
            3)  minikube -p ${REGISTRY_PROJECT} start;;
            6)  minikube -p ${REGISTRY_PROJECT} start;;
            7)  minikube -p ${REGISTRY_PROJECT} start;;
            85) #minikube -p ${REGISTRY_PROJECT} delete --all || true
                #minikube -p ${REGISTRY_PROJECT} config set cpus 16
                #minikube -p ${REGISTRY_PROJECT} config set memory 49152
                #minikube -p ${REGISTRY_PROJECT} config set disk-size 48GB
                #minikube -p ${REGISTRY_PROJECT} start --network --driver='podman' --container-runtime=cri-o --insecure-registry=${REGISTRY_NAME}
                #minikube -p ${REGISTRY_PROJECT} start --memory 49152 --cpus 16 --vm-driver=vmware --container-runtime=docker --cni=bridge
                #minikube -p ${REGISTRY_PROJECT} stop
                #minikube -p ${REGISTRY_PROJECT} ssh 'echo "sysctl -w vm.max_map_count=262144" | sudo tee -a /var/lib/boot2docker/bootlocal.sh'
                #minikube -p ${REGISTRY_PROJECT} start
                #minikube -p ${REGISTRY_PROJECT} start --memory 40960 --cpus 16 --vm-driver=vmware --container-runtime=containerd --cni=bridge;;
                echo -e "Minikube is Running. ${RED}Deleteing Minikube...${NC}"
                minikube -p ${REGISTRY_PROJECT} delete || true
                echo -e "\n"
                echo -e "Minikube Installation is ${GREEN}Starting ...${NC}"
                minikube -p ${REGISTRY_PROJECT} start --container-runtime=containerd --cni=cilium --memory=40960 --cpus=16 --insecure-registry=${REGISTRY_URL} --kubernetes-version=stable  --install-addons=true;;
            *)  minikube -p ${REGISTRY_PROJECT} stop || true
                minikube -p ${REGISTRY_PROJECT} start;;
        esac

        minikube -p ${REGISTRY_PROJECT} addons enable metrics-server
        minikube -p ${REGISTRY_PROJECT} addons enable dashboard
        minikube -p ${REGISTRY_PROJECT} addons enable ingress
        minikube -p ${REGISTRY_PROJECT} addons enable ingress-dns
        #minikube -p ${REGISTRY_PROJECT} addons enable registry
        #minikube -p ${REGISTRY_PROJECT} addons enable registry-aliases
        minikube -p ${REGISTRY_PROJECT} addons enable olm

        # Check Minikube status
        minikube_status=$(minikube -p ${REGISTRY_PROJECT} status --format='{{.Host}}')
        if [[ "$minikube_status" == "Running" ]]; then
            retVal=85  # Success: Minikube is running, start deleteing Minikube...
        else    
            echo "Minikube is already installed. Exiting."
        fi
    fi
}

set_cluster_ip() {
    local minikube_ip=$(minikube -p ${MINIKUBE_PROFILE} ip)
    local wan_ip=$(ip addr show eth1 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    local selected_ip=""

    # Print menu header
    echo -e "# Select cluster IP address: ${NC}"
    echo -e "# --------------------------------------- "
    echo -e "#  1) ${YELLOW}WAN IP (${wan_ip}) [default]${NC}"
    echo -e "#  2) Minikube IP (${minikube_ip}) "
    echo -e "#  3) Enter custom IP"
    echo -e "# --------------------------------------- "
    echo

    # Prompt for selection
    read -p "Enter selection [1]: " selection
    
    # Default to option 1 if Enter is pressed
    selection=${selection:-1}
    
    case $selection in
        1)
            selected_ip="${wan_ip}"
            echo "Using WAN IP: ${selected_ip}"
            ;;
        2)
            selected_ip="${minikube_ip}"
            echo "Using Minikube IP: ${selected_ip}"
            ;;
        3)
            # Custom IP input with validation
            while true; do
                read -p "Enter custom IP address: " custom_ip
                # Validate IP address format
                if [[ $custom_ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                    # Validate each octet
                    valid=true
                    IFS='.' read -ra ADDR <<< "$custom_ip"
                    for i in "${ADDR[@]}"; do
                        if [ $i -lt 0 ] || [ $i -gt 255 ]; then
                            valid=false
                            break
                        fi
                    done
                    if $valid; then
                        selected_ip="${custom_ip}"
                        echo "Using custom IP: ${selected_ip}"
                        break
                    fi
                fi
                echo "Invalid IP address format. Please try again."
            done
            ;;
        *)
            echo "Invalid selection. Using default Minikube IP: ${minikube_ip}"
            selected_ip="${minikube_ip}"
            ;;
    esac

    # Export the selected IP
    export NGINX_IP="${selected_ip}"

    return 0
}
#==================== End Menu Section ====================
echo -e "${YELLOW}\n"
echo '  :##:    ######:    ######     :####:             .###      .####.  '
echo '   ##     #######:   ######     ######             ####      ######  '
echo '  ####    ##   :##     ##     :##:  .#             #:##     :##  ##: '
echo '  ####    ##    ##     ##     ##                     ##     ##:  :## '
echo ' :#  #:   ##   :##     ##     ##.                    ##     ##    ## '
echo '  #::#    #######:     ##     ##                     ##     ##    ## '
echo ' ##  ##   ######:      ##     ##                     ##     ##    ## '
echo ' ######   ##           ##     ##.                    ##     ##    ## '
echo '.######.  ##           ##     ##                     ##     ##:  :## '
echo ':##  ##:  ##           ##     :##:  .#               ##     :##  ##: '
echo '###  ###  ##         ######     ######            ########   ######  '
echo '##:  :##  ##         ######     :####:            ########   .####.  '
echo '# ============================================='
echo '#      Welcome to IBM API Connect 10 SETUP     '
echo '# ============================================='
echo -e "${NC}\n"

# Call the menu function
menu
#  minikube quickly sets up a local Kubernetes cluster
echo -e "${GREEN} [Setup Minikube - local Kubernetes cluster] ${NC}"
echo '#'
echo '# =========================================================='
echo '# This script will guide you through the steps of setting up'         
echo -e "# APIC (API Connect ${YELLOW} $APIC_VERSION ${NC})       "
echo '# =========================================================='

set -e

# Check if [logs] sub-folder exists 
mkdir -p logs

# Init Log timestamp 
output_log_time="logs/apic_$(date '+%Y%m%d%H%M%S')"

echo -e "# ${YELLOW}-------------------------------${NC}"
echo -e "# ${YELLOW}Collect General Setup In       ${NC}"
echo -e "# ${YELLOW}-------------------------------${NC}"
echo '#'
# Configure the cluster container registry details.
if ! set_registry_info; then
    echo -e "# ${RED} Error selecting cluster container registry details${NC}"
    exit 1
fi
#
echo -e "# "
echo -e "# "
echo -e "# ${YELLOW}-------------------------------${NC}"
echo -e "# ${YELLOW}Setup Minikube                 ${NC}"
echo -e "# ${YELLOW}-------------------------------${NC}"
# Setup Minikube Envierment
# TBD --> OREN <---------------------------------------------
#setup_minikube
#minikube -p $REGISTRY_PROJECT start --insecure-registry=$REGISTRY_URL



#
# Configure the cluster IP.
if ! set_cluster_ip; then
    echo -e "# ${RED} Error selecting cluster IP${NC}"
    exit 1
fi
echo -e "#    - Cluster IP address: ✅${GREEN} ${NGINX_IP} ${NC}"
echo -e "# ${YELLOW} Enter Management subsystem administrator password: ${NC}"
read -p "" admin_credentials
echo -e "# ${YELLOW}-------------------------------${NC}" 
echo -e "\n"
export ADMIN_CREDENTIALS=$admin_credentials

# Execute [Infrastructure Preparation] script with proper quoting and parameter handling
output_log="${output_log_time}-01-ibm-apic-infra-preparations.log"
echo -e "\n"
echo -e "Executed command: ./01-ibm-apic-infra-preparations.sh \
    \"${APIC_VERSION}\" \"${LICENSE_KEY}\" \"${CERT_MANAGER_VERSION}\" \
    \"${NGINX_IP}\" \"${IBM_ENTITLEMENT_KEY}\" \"${ADMIN_CREDENTIALS}\" \
    \"${MINIKUBE_PROFILE}\" \
    \"${REGISTRY_URL}\" \"${REGISTRY_PROJECT}\" \"${REGISTRY_USERNAME}\" \"${REGISTRY_PASSWORD}\" \
    \"${MANAGEMENT_PROFILE}\" \"${PORTAL_PROFILE}\" \"${ANALYTICS_PROFILE}\" \"${DATAPOWER_PROFILE}\""

script -a "${output_log}" -c "./01-ibm-apic-infra-preparations.sh \
    \"${APIC_VERSION}\" \"${LICENSE_KEY}\" \"${CERT_MANAGER_VERSION}\" \
    \"${NGINX_IP}\" \"${IBM_ENTITLEMENT_KEY}\" \"${ADMIN_CREDENTIALS}\" \
    \"${MINIKUBE_PROFILE}\" \
    \"${REGISTRY_URL}\" \"${REGISTRY_PROJECT}\" \"${REGISTRY_USERNAME}\" \"${REGISTRY_PASSWORD}\" \
    \"${MANAGEMENT_PROFILE}\" \"${PORTAL_PROFILE}\" \"${ANALYTICS_PROFILE}\" \"${DATAPOWER_PROFILE}\"" 2>&1
echo -e "${YELLOW}Output log file location: $output_log ${NC}"  
echo -e "\n"

# Check if [Infrastructure Preparation] script was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN} [INFO] ./01-ibm-apic-infra-preparations.sh executed successfully.${NC}"
else
    echo -e "${RED} [INFO] ./01-ibm-apic-infra-preparations.sh failed.${NC}" >&2
    exit 1
fi

# Execute [Cluster Preparing] script with proper quoting and parameter handling
output_log="${output_log_time}-02-ibm-apic-cluster-preparations.log"
echo -e "\n"
echo -e "Executed command: ./02-ibm-apic-cluster-preparations.sh \
    \"${APIC_VERSION}\" \"${LICENSE_KEY}\" \"${CERT_MANAGER_VERSION}\" \
    \"${NGINX_IP}\" \"${IBM_ENTITLEMENT_KEY}\" \"${ADMIN_CREDENTIALS}\" \
    \"${MINIKUBE_PROFILE}\" \
    \"${REGISTRY_URL}\" \"${REGISTRY_PROJECT}\" \"${REGISTRY_USERNAME}\" \"${REGISTRY_PASSWORD}\" \
    \"${MANAGEMENT_PROFILE}\" \"${PORTAL_PROFILE}\" \"${ANALYTICS_PROFILE}\" \"${DATAPOWER_PROFILE}\""

script -a "${output_log}" -c "./02-ibm-apic-cluster-preparations.sh \
    \"${APIC_VERSION}\" \"${LICENSE_KEY}\" \"${CERT_MANAGER_VERSION}\" \
    \"${NGINX_IP}\" \"${IBM_ENTITLEMENT_KEY}\" \"${ADMIN_CREDENTIALS}\" \
    \"${MINIKUBE_PROFILE}\" \
    \"${REGISTRY_URL}\" \"${REGISTRY_PROJECT}\" \"${REGISTRY_USERNAME}\" \"${REGISTRY_PASSWORD}\" \
    \"${MANAGEMENT_PROFILE}\" \"${PORTAL_PROFILE}\" \"${ANALYTICS_PROFILE}\" \"${DATAPOWER_PROFILE}\"" 2>&1
echo -e "${YELLOW}Output log file location: $output_log ${NC}"  
echo -e "\n"

# Check if [Cluster Preparing] script was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN} [INFO] ./02-ibm-apic-cluster-preparations.sh executed successfully.${NC}"
else
    echo -e "${RED} [INFO] ./02-ibm-apic-cluster-preparations.sh failed.${NC}" >&2
    exit 1
fi

# Execute [Cluster Installation] script with proper quoting and parameter handling
output_log="${output_log_time}-03-ibm-apic-cluster-installation.log"
echo -e "\n"
echo -e "Executed command: ./03-ibm-apic-cluster-installation.sh \
   \"${APIC_VERSION}\" \"${LICENSE_KEY}\" \"${CERT_MANAGER_VERSION}\" \
   \"${NGINX_IP}\" \"${IBM_ENTITLEMENT_KEY}\" \"${ADMIN_CREDENTIALS}\" \
   \"${MINIKUBE_PROFILE}\" \
   \"${REGISTRY_URL}\" \"${REGISTRY_PROJECT}\" \"${REGISTRY_USERNAME}\" \"${REGISTRY_PASSWORD}\" \
   \"${MANAGEMENT_PROFILE}\" \"${PORTAL_PROFILE}\" \"${ANALYTICS_PROFILE}\" \"${DATAPOWER_PROFILE}\""

script -a "${output_log}" -c "./03-ibm-apic-cluster-installation.sh \
   \"${APIC_VERSION}\" \"${LICENSE_KEY}\" \"${CERT_MANAGER_VERSION}\" \
   \"${NGINX_IP}\" \"${IBM_ENTITLEMENT_KEY}\" \"${ADMIN_CREDENTIALS}\" \
   \"${MINIKUBE_PROFILE}\" \
   \"${REGISTRY_URL}\" \"${REGISTRY_PROJECT}\" \"${REGISTRY_USERNAME}\" \"${REGISTRY_PASSWORD}\" \
   \"${MANAGEMENT_PROFILE}\" \"${PORTAL_PROFILE}\" \"${ANALYTICS_PROFILE}\" \"${DATAPOWER_PROFILE}\"" 2>&1
echo -e "${YELLOW}Output log file location: $output_log ${NC}"  
echo -e "\n"

# Check if [Cluster Installation] script was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN} [INFO] 03-ibm-apic-cluster-installation.sh executed successfully.${NC}"
else
    echo -e "${RED} [INFO] 03-ibm-apic-cluster-installation.sh failed.${NC}" >&2
    exit 1
fi

echo "Output log file location: $output_log" 
echo -e "\n✅ ${GREEN} [INFO] All scripts executed successfully. ${NC}"
