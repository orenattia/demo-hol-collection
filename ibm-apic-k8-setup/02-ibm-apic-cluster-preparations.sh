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
        # DISABLED!!! <============================
        #usage
        exit 1
    fi

    # DISABLED!!! <============================
    # Display validated parameters
    #echo "Validated Parameters:"
    #echo "├── APIC Version: ${apic_version}"
    #echo "├── License Key: ${apic_license}"
    #echo "└── Cert Manager Version: ${CERT_MANAGER_VERSION}"
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
echo ' ######:                                                        ##                       '
echo ' #######:                                                       ##                       '
echo ' ##   :##                                                                                '
echo ' ##    ##   ##.####   .####:   ##.###:    :####     ##.####   ####     ##.####   :###:## '
echo ' ##   :##   #######  .######:  #######:   ######    #######   ####     #######  .####### '
echo ' #######:   ###.     ##:  :##  ###  ###   #:  :##   ###.        ##     ###  :## ###  ### '
echo ' ######:    ##       ########  ##.  .##    :#####   ##          ##     ##    ## ##.  .## '
echo ' ##         ##       ########  ##    ##  .#######   ##          ##     ##    ## ##    ## '
echo ' ##         ##       ##        ##.  .##  ## .  ##   ##          ##     ##    ## ##.  .## '
echo ' ##         ##       ###.  :#  ###  ###  ##:  ###   ##          ##     ##    ## ###  ### '
echo ' ##         ##       .#######  #######:  ########   ##       ########  ##    ## .####### '
echo ' ##         ##        .#####:  ##.###:     ###.##   ##       ########  ##    ##  :###:## '
echo '                               ##                                                    :## '
echo '                               ##                                                ######  '
echo '                               ##                                                :####:  '          
echo '                                                                                         '  
echo '   :####:  ####                                                                          '          
echo '   ######  ####                            ##                                            '          
echo ' :##:  .#    ##                            ##                                            '          
echo ' ##          ##      ##    ##   :#####.  #######    .####:    ##.####                    '          
echo ' ##.         ##      ##    ##  ########  #######   .######:   #######                    '          
echo ' ##          ##      ##    ##  ##:  .:#    ##      ##:  :##   ###.                       '          
echo ' ##          ##      ##    ##  ##### .     ##      ########   ##                         '          
echo ' ##.         ##      ##    ##  .######:    ##      ########   ##                         '          
echo ' ##          ##      ##    ##     .: ##    ##      ##         ##                         '          
echo ' :##:  .#    ##:     ##:  ###  #:.  :##    ##.     ###.  :#   ##                         '          
echo '   ######    #####    #######  ########    #####   .#######   ##                         '          
echo '   :####:    .####     ###.##  . ####      .####    .#####:   ##                         '                                                                             
echo -e "${NC}\n"
echo -e "# ${GREEN}===============================${NC}"
echo -e "# ${GREEN}Preparing Cluster              ${NC}"
echo -e "# ${GREEN}===============================${NC}"   
echo -e "\n"

set -e

# Call main with all parameters
main "$@"

current_dir="$(dirname "$0" 2> /dev/null)" || current_dir=.
export apic_namespace=apic
export filespath=${current_dir}/apiconnect-operator-release-files_${APIC_VERSION}
temp_out_path=${current_dir}/temp

# Detect OS and set sed argument
SED_ARG=""
if [[ "$(uname -s)" == "Darwin" ]]; then
    SED_ARG="''"
fi

############################
k () {
    minikube -p ${MINIKUBE_PROFILE} kubectl -- "$@"
}
############################
minikube -p ${MINIKUBE_PROFILE} update-context

echo -e "\n"
echo -e "# ${YELLOW}-------------------------------${NC}"
echo -e "# ${YELLOW}Create Private Registry Secret ${NC}"
echo -e "# ${YELLOW}-------------------------------${NC}"
#TBD OREN -->>>>>>>>>>>>>>>>>>
#k create ns ${apic_namespace} || true
#k create secret docker-registry hcr-secret --docker-server=${REGISTRY_URL}/${apic_namespace} --docker-username=${REGISTRY_USERNAME} --docker-password=${REGISTRY_PASSWORD} -n ${apic_namespace}
#echo -e "$apic_namespace/hcr-secret\n" | minikube -p $MINIKUBE_PROFILE addons configure ingress
#minikube -p ${MINIKUBE_PROFILE} addons disable ingress
#minikube -p ${MINIKUBE_PROFILE} addons enable ingress
#minikube -p ${MINIKUBE_PROFILE} addons list

echo -e "\n"
echo -e "# ${YELLOW}-------------------------------${NC}"
echo -e "# ${YELLOW}Prepare for APIC               ${NC}"
echo -e "# ${YELLOW}-------------------------------${NC}"
k create ns ${apic_namespace} || true
k config set-context --current --namespace=${apic_namespace}
k config view --minify --output 'jsonpath={..namespace}'
echo -e "\n"
if ! k get deployment ingress-nginx-controller -n ingress-nginx -o yaml | grep -q passthrough; then
  k patch deployment ingress-nginx-controller -n ingress-nginx --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-ssl-passthrough"}]'
fi
echo -e "\n"

echo -e "# ${YELLOW}-------------------------------${NC}"
echo -e "# ${YELLOW}Install and verify cert manager${NC}"
echo -e "# ${YELLOW}-------------------------------${NC}"
k apply -f ${filespath}/helper_files/cert-manager-${CERT_MANAGER_VERSION}.yaml; sleep 30
k wait --for=jsonpath='{.status.phase}'=Running pod -l app=cert-manager --timeout=90s -n cert-manager
k wait --for=condition=ready pod -l app=cert-manager --timeout=90s -n cert-manager
k wait --for=jsonpath='{.status.phase}'=Running pod -l app=webhook --timeout=90s -n cert-manager
k wait --for=condition=ready pod -l app=webhook --timeout=90s -n cert-manager
k get pods -n cert-manager
OS=$(uname -s | tr A-Z a-z); ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/'); curl -fsSL https://github.com/cert-manager/cmctl/releases/latest/download/cmctl_${OS}_${ARCH} -o ${temp_out_path}/cmctl
chmod +x ${temp_out_path}/cmctl
${temp_out_path}/cmctl check api
echo -e "\n"

echo -e "# ${YELLOW}-------------------------------${NC}"
echo -e "# ${YELLOW}Create Prereq secrets          ${NC}"
echo -e "# ${YELLOW}-------------------------------${NC}"
k create secret docker-registry apic-registry-secret \
    --docker-server=${REGISTRY_URL} \
    --docker-username=${REGISTRY_USERNAME} \
    --docker-password=${REGISTRY_PASSWORD} \
    -n ${apic_namespace} --dry-run=client -o yaml | k apply -f - -n ${apic_namespace}
k create secret docker-registry datapower-docker-local-cred \
    --docker-server=${REGISTRY_URL} \
    --docker-username=${REGISTRY_USERNAME} \
    --docker-password=${REGISTRY_PASSWORD} \
    -n ${apic_namespace} --dry-run=client -o yaml | k apply -f - -n ${apic_namespace}
k create secret generic datapower-admin-credentials \
    --from-literal=password=$ADMIN_CREDENTIALS \
    -n ${apic_namespace} --dry-run=client -o yaml | k apply -f - -n ${apic_namespace}
echo -e "\n"
k get secret -n ${apic_namespace}

echo -e "# ${YELLOW}-------------------------------${NC}"
echo -e "# ${YELLOW}Create APIC creds              ${NC}"
echo -e "# ${YELLOW}-------------------------------${NC}"
cp ${filespath}/ibm-apiconnect-crds.yaml ${filespath}/ibm-apiconnect-crds-new.yaml
# Get the list of CRDs from the specified YAML file
crds=$(kubectl get -f "${filespath}/ibm-apiconnect-crds-new.yaml" -o name 2>/dev/null || true)
# Check if any CRDs were found
if [[ -n "$crds" ]]; then
    # Loop through each CRD and delete it
    for crd in $crds; do
        #echo "Delete CRD --> [$crd]"
        kubectl delete "$crd" || true
    done
    sleep 30
else
    echo "No CRDs found to delete."
fi
k apply --server-side --force-conflicts -f ${filespath}/ibm-apiconnect-crds-new.yaml; sleep 30 
k wait --for=condition="established" --timeout=90s -f ${filespath}/ibm-apiconnect-crds-new.yaml
echo -e "\n"

echo -e "# ${YELLOW}-------------------------------${NC}"
echo -e "# ${YELLOW}Create APIC operator           ${NC}"
echo -e "# ${YELLOW}-------------------------------${NC}"
cp ${filespath}/ibm-apiconnect.yaml ${filespath}/ibm-apiconnect-new.yaml
eval "sed -i $SED_ARG -e 's|REPLACE-DOCKER-REGISTRY|'${REGISTRY_URL}/${REGISTRY_PROJECT}'|g' ${filespath}/ibm-apiconnect-new.yaml"

#eval "sed -i $SED_ARG  -e 's|DEFAULT_IMAGE_PULL_SECRET|apic-registry-secret|g' ${filespath}/ibm-apiconnect-new.yaml"
eval "sed -i $SED_ARG  -e 's|DEFAULT_IMAGE_PULL_SECRET|hcr-secret|g' ${filespath}/ibm-apiconnect-new.yaml"

eval "sed -i $SED_ARG  -e 's|namespace: default|namespace: '${apic_namespace}'|g' ${filespath}/ibm-apiconnect-new.yaml"
eval "sed -i $SED_ARG  -e 's|name: default|name: '${apic_namespace}'|g' ${filespath}/ibm-apiconnect-new.yaml"
k apply -f ${filespath}/ibm-apiconnect-new.yaml -n ${apic_namespace}; sleep 60
k wait --for=jsonpath='{.status.phase}'=Running pod -l app.kubernetes.io/component=apiconnect-operator --timeout=90s -n ${apic_namespace}
k wait --for=condition=ready pod -l app.kubernetes.io/component=apiconnect-operator --timeout=90s -n ${apic_namespace}
k get pods -n ${apic_namespace}
echo -e "\n"

echo -e "# ${YELLOW}---------------------------------${NC}"
echo -e "# ${YELLOW}Configure issuer and common certs${NC}"
echo -e "# ${YELLOW}---------------------------------${NC}"
k apply -f ${filespath}/helper_files/ingress-issuer-v1.yaml -n ${apic_namespace}; sleep 30
k wait --for=condition="ready" --timeout=90s -f ${filespath}/helper_files/ingress-issuer-v1.yaml
echo -e "\n"
