#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check and install Docker Compose
check_and_install_docker_compose() {
    # Find all docker-compose locations
    docker_compose_paths=$(find / -name docker-compose 2>/dev/null)
    
    # If no paths found, set to empty
    if [ -z "$docker_compose_paths" ]; then
        echo -e "${RED}No docker-compose found in system.${NC}"
        install_docker_compose
        return
    fi
    
    # Iterate through found paths
    for path in $docker_compose_paths; do
        echo "Checking path: $path"
        
        # Try to get version
        version_output=$($path --version 2>&1)
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Successfully found working Docker Compose at $path ${NC}"
            echo -e "${GREEN}Version: $version_output ${NC}"
        else
            echo -e "${BLUE}Path $path seems invalid. Attempting cleanup.${NC}"
            # Remove symlinks or broken links
            if [ -L "$path" ]; then
                sudo rm "$path"
            fi
        fi
    done
    
    # If no working path found, reinstall
    install_docker_compose
}

# Function to install Docker Compose
install_docker_compose() {
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    
    # Download latest version
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Make executable
    sudo chmod +x /usr/local/bin/docker-compose
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Docker Compose successfully installed!${NC}"
    else
        echo -e "${RED}Installation failed. Please check system requirements.${NC}"
        exit 1
    fi
}

# Main script execution
check_and_install_docker_compose


