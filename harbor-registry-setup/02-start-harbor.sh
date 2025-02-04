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

# Declare global variables
declare -g selected_profile=""
declare -a minikube_profiles
declare -a profile_statuses

# Function to list all active minikube profiles with numbers
list_minikube_profiles() {
    # First check if minikube is installed
    if ! command -v minikube &>/dev/null; then
        echo -e "${RED}Error: minikube is not installed${NC}"
        exit 1
    fi

    # Check if minikube profile list command succeeds and if there are any profiles
    if ! minikube profile list &>/dev/null || [ "$(minikube profile list | wc -l)" -le 2 ]; then
        echo -e "${RED} No Minikube profiles found. Exiting. ${NC}"
        echo -e "${RED}  For example execute:${BLUE} minikube -p <MINIKUBE_PROFILE> start --container-runtime=containerd --cni=cilium --memory=40960 --cpus=16 --insecure-registry=hcr.<YOUR_IP>.nip.io --kubernetes-version=stable ${NC}"
        echo -e "${RED}  Next, execute the installation script again.${NC}\n"
        exit 1
    fi

    # Clear existing arrays
    minikube_profiles=()
    profile_statuses=()

    # Initialize counter
    count=1

    # Enter Private Registry URL
    read -p "Enter Private Registry URL: " private_registry_url
    export REGISTRY_URL=$private_registry_url

    # Fetch the Minikube profile list and process it
    while IFS= read -r line; do
        # Extract the 8th column (Active Profile)
        active_profile=$(echo "$line" | awk -F '|' '{print $8}' | xargs)

        # Determine if the profile is active or stopped
        if [[ "$active_profile" == "OK" ]]; then
            status="${GREEN}active${NC}"
        else
            status="${RED}stopped${NC}"
        fi

        # Extract the profile name (2nd column)
        profile=$(echo "$line" | awk -F '|' '{print $2}' | xargs)

        # Add the profile and its status to the arrays
        minikube_profiles+=("$profile")
        profile_statuses+=("$status")

        # Print the profile with its status
        echo -e "${YELLOW}Available Minikube Profiles:${NC}"
        echo -e "$count. $profile [$status]"
        ((count++))
    done < <(minikube profile list | grep -v "|\-\-\-" | tail -n +2)
}

# Function to select and validate profile
select_profile() {
    while true; do
        echo -e "${YELLOW}Enter the number of the minikube profile you want to select (1-${#minikube_profiles[@]}): ${NC}"
        read -p " Line Number: " selected_number

        # Validate input is a number and within range
        if ! [[ "$selected_number" =~ ^[0-9]+$ ]] || [ "$selected_number" -lt 1 ] || [ "$selected_number" -gt "${#minikube_profiles[@]}" ]; then
            echo -e "${RED}Invalid selection. Please enter a number between 1 and ${#minikube_profiles[@]}.${NC}"
            continue
        fi

        # Adjust for zero-based array indexing
        selected_index=$((selected_number - 1))
        selected_profile=${minikube_profiles[$selected_index]}

        # Check if profile exists
        if ! minikube profile list | grep -q "$selected_profile"; then
            echo -e "${RED}Selected profile does not exist. Please try again.${NC}"
            continue
        fi

        # Check profile status
        profile_status=$(minikube status -p "$selected_profile" 2>/dev/null | grep "host:" | awk '{print $2}')

        if [ "$profile_status" = "Stopped" ]; then
            echo -e "${YELLOW}The selected profile '$selected_profile' is currently stopped.${NC}"
            read -p "Would you like to start it? (y/n): " start_response
            
            if [[ "$start_response" =~ ^[Yy]$ ]]; then
                echo -e "${BLUE}Starting Minikube profile '$selected_profile'...${NC}"
                if minikube start -p "$selected_profile"; then
                    echo -e "${GREEN}Successfully started Minikube profile '$selected_profile'${NC}"
                    return 0
                else
                    echo -e "${RED}Failed to start Minikube profile '$selected_profile'${NC}"
                    continue
                fi
            else
                echo -e "${YELLOW}Profile will remain stopped. Please select another profile.${NC}"
                continue
            fi
        else
            echo -e "${GREEN}Selected profile '$selected_profile' is already running.${NC}"
            return 0
        fi
    done
}

# Main execution
list_minikube_profiles
select_profile

if [ -z "$selected_profile" ]; then
    echo -e "${RED}No profile was selected. Exiting.${NC}"
    exit 1
fi

echo -e "${GREEN}Proceeding with profile: ${selected_profile}${NC}"

# Install Harbor
if [ -d "harbor" ]; then
    echo -e "${BLUE}Installing Harbor...${NC}"
    sudo harbor/install.sh
    #./install.sh --with-clair --with-chartmuseum

    # Verify installation
    echo -e "${BLUE}Verifying installation...${NC}"
    kubectl get pods    -A || true
    kubectl get pvc     -A || true
    kubectl get svc     -A || true
    kubectl get ingress -A || true

    echo -e "${GREEN}Harbor Installation Complete\n"
    echo -e "Please log out and log in or run the command 'newgrp docker' to use Docker without sudo\n"
    echo -e "Login to your harbor instance:\n docker login -u admin -p Harbor12345 $REGISTRY_URL ${NC}"
else
    echo -e "${RED}Harbor directory not found. Please ensure Harbor files are present in ./harbor directory${NC}"
    exit 1
fi