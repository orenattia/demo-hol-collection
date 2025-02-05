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
echo '   ######                                           ####      ####         ##                       '
echo '   ######                         ##                ####      ####         ##                       '
echo '     ##                           ##                  ##        ##                                  '
echo '     ##     ##.####    :#####.  #######    :####      ##        ##       ####     ##.####   :###:## '
echo '     ##     #######   ########  #######    ######     ##        ##       ####     #######  .####### '
echo '     ##     ###  :##  ##:  .:#    ##       #:  :##    ##        ##         ##     ###  :## ###  ### '
echo '     ##     ##    ##  ##### .     ##        :#####    ##        ##         ##     ##    ## ##.  .## '
echo '     ##     ##    ##  .######:    ##      .#######    ##        ##         ##     ##    ## ##    ## '
echo '     ##     ##    ##     .: ##    ##      ## .  ##    ##        ##         ##     ##    ## ##.  .## '
echo '     ##     ##    ##  #:.  :##    ##.     ##:  ###    ##:       ##:        ##     ##    ## ###  ### '
echo '   ######   ##    ##  ########    #####   ########    #####     #####   ########  ##    ## .####### '
echo '   ######   ##    ##  . ####      .####     ###.##    .####     .####   ########  ##    ##  :###:## '
echo '                                                                                                :## '
echo '                                                                                            ######  '
echo '                                                                                            :####:  '          
echo '                                                                                                    '  
echo '   :####:  ####                                                                                     '          
echo '   ######  ####                            ##                                                       '          
echo ' :##:  .#    ##                            ##                                                       '          
echo ' ##          ##      ##    ##   :#####.  #######    .####:    ##.####                               '          
echo ' ##.         ##      ##    ##  ########  #######   .######:   #######                               '          
echo ' ##          ##      ##    ##  ##:  .:#    ##      ##:  :##   ###.                                  '          
echo ' ##          ##      ##    ##  ##### .     ##      ########   ##                                    '          
echo ' ##.         ##      ##    ##  .######:    ##      ########   ##                                    '          
echo ' ##          ##      ##    ##     .: ##    ##      ##         ##                                    '          
echo ' :##:  .#    ##:     ##:  ###  #:.  :##    ##.     ###.  :#   ##                                    '          
echo '   ######    #####    #######  ########    #####   .#######   ##                                    '          
echo '   :####:    .####     ###.##  . ####      .####    .#####:   ##                                    '                                                                             
echo -e "${NC}\n"
echo -e "# ${GREEN}===============================${NC}"
echo -e "# ${GREEN}Installing Cluster             ${NC}"
echo -e "# ${GREEN}===============================${NC}"                               
echo -e "\n"

# Call main with all parameters
main "$@"

set -e
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
storagetype=shared
storageclass=standard

echo -e "\n"

echo -e "# ${YELLOW}-------------------------------${NC}"
echo -e "# ${YELLOW}Install DataPower operator     ${NC}"
echo -e "# ${YELLOW}-------------------------------${NC}"  
cp ${filespath}/ibm-datapower.yaml ${filespath}/ibm-datapower-new.yaml
eval "sed -i $SED_ARG  -e 's|namespace: default|namespace: '${apic_namespace}'|g' ${filespath}/ibm-datapower-new.yaml"
k apply -f ${filespath}/ibm-datapower-new.yaml -n ${apic_namespace}; sleep 60

# Wait for the condition, capturing the exit status
k wait --for=jsonpath='{.status.phase}'=Running pod -l app.kubernetes.io/name=datapower-operator --timeout=300s -n ${apic_namespace} || status=$?
# Check if the wait command was successful or timed out
if [[ $status -ne 0 ]]; then
  echo -e "${RED}Timeout occurred when query: [{.status.phase}'=Running datapower-operator]. Continuing script...${NC}"
  echo -e "Execute the following command: ${YELLOW} k wait --for=jsonpath='{.status.phase}'=Running pod -l app.kubernetes.io/name=datapower-operator --timeout=300s -n ${apic_namespace} ${NC}"
else
  echo -e "${YELLOW}datapower-operator is waiting.${NC}"
fi
# End Wait

# Wait for the condition, capturing the exit status
k wait --for=condition=ready pod -l app.kubernetes.io/name=datapower-operator  --timeout=300s -n ${apic_namespace} || status=$?
# Check if the wait command was successful or timed out
if [[ $status -ne 0 ]]; then
  echo -e "${RED}Timeout occurred when query: [datapower-operator is in a Pending status]. Continuing script...${NC}"
  echo -e "Execute the following command: ${YELLOW} k wait --for=condition=ready pod -l app.kubernetes.io/name=datapower-operator --timeout=300s -n ${apic_namespace} ${NC}"
else
  echo -e "${YELLOW}datapower-operator is ready.${NC}"
fi
# End Wait

# Wait for the condition, capturing the exit status
k wait --for=jsonpath='{.status.phase}'=Running pod -l app.kubernetes.io/name=datapower-operator-conversion-webhook --timeout=300s -n ${apic_namespace} || status=$?
# Check if the wait command was successful or timed out
if [[ $status -ne 0 ]]; then
  echo -e "${RED}Timeout occurred when query: [{.status.phase}'=Running datapower-operator-conversion-webhook]. Continuing script...${NC}"
  echo -e "Execute the following command: ${YELLOW} k wait --for=jsonpath='{.status.phase}'=Running pod -l app.kubernetes.io/name=datapower-operator-conversion-webhook --timeout=300s -n ${apic_namespace} ${NC}"
else
  echo -e "${YELLOW}datapower-operator-conversion-webhook is waiting.${NC}"
fi
# End Wait

# Wait for the condition, capturing the exit status
k wait --for=condition=ready pod -l app.kubernetes.io/name=datapower-operator-conversion-webhook --timeout=300s -n ${apic_namespace} || status=$?
# Check if the wait command was successful or timed out
if [[ $status -ne 0 ]]; then
  echo -e "${RED}Timeout occurred when query: [datapower-operator-conversion-webhook is in a Pending status]. Continuing script...${NC}"
  echo -e "Execute the following command: ${YELLOW} k wait --for=condition=ready pod -l app.kubernetes.io/name=datapower-operator-conversion-webhook --timeout=300s -n ${apic_namespace} ${NC}"
else
  echo -e "${YELLOW}datapower-operator is ready.${NC}"
fi
# End Wait

k get pods -n ${apic_namespace}
echo -e "\n"

echo -e "# ${YELLOW}-------------------------------${NC}"
echo -e "# ${YELLOW}Deploy Management CR           ${NC}"
echo -e "# ${YELLOW}-------------------------------${NC}"  
cp ${filespath}/helper_files/management_cr.yaml ${filespath}/helper_files/management_cr_new.yaml
eval "sed -i $SED_ARG  -e 's|\$APP_PRODUCT_VERSION|'${APIC_VERSION}'|g' ${filespath}/helper_files/management_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$PROFILE|${MANAGEMENT_PROFILE}|g' ${filespath}/helper_files/management_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$SECRET_NAME|apic-registry-secret|g' ${filespath}/helper_files/management_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$DOCKER_REGISTRY|'${REGISTRY_URL}'/${REGISTRY_PROJECT}|g' ${filespath}/helper_files/management_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$STACK_HOST|'${NGINX_IP}'.nip.io|g' ${filespath}/helper_files/management_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$STORAGE_CLASS|'${storageclass}'|g' ${filespath}/helper_files/management_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|accept: false|accept: true|g' ${filespath}/helper_files/management_cr_new.yaml"
sed -i $SED_ARG -e "s/license: ''/license: ${LICENSE_KEY}/g" ${filespath}/helper_files/management_cr_new.yaml
sed -i $SED_ARG -e '/labels: {/i \
 \ annotations:\
  \ \ apiconnect-operator/backups-not-configured: "true"' ${filespath}/helper_files/management_cr_new.yaml
k apply -f ${filespath}/helper_files/management_cr_new.yaml -n ${apic_namespace}; sleep 30

echo "Starting to monitor management status..."
echo "Waiting for status to change from Pending to Running..."

iteration=1
while true; do
    # Get the current status and state with timeout to avoid hanging
    if ! current_state=$(timeout 10s kubectl get mgmt -n ${apic_namespace} | grep 'management'); then
        echo -e "${RED}Error getting kubectl status. Retrying in 10 seconds...${NC}"
        sleep 10
        continue
    fi
    
    # Extract status
    status=$(echo "$current_state" | awk '{print $3}')
    
    # Clear screen for better visibility
    clear

    # Print current timestamp, iteration, and state
    let total_time=iteration*10
    # Convert seconds to minutes and remaining seconds
    minutes=$((total_time / 60))
    seconds=$((total_time % 60))

    echo -e "Iteration: ${RED} ${iteration}  ${NC}"
    echo -e "Last checked at: ${YELLOW} $(date '+%Y-%m-%d %H:%M:%S') ${NC}"
    echo -e "Current state: $(echo "$current_state")"
    
    # Check if status has changed to Running
    if [[ "$status" == "Running" ]]; then
        echo -e "\n✅ ${GREEN}Management is now Running!${NC}"
        echo "Final state: $current_state"
        break
    else
        printf "\nTotal processing time: ${RED} %02d:%02d ${NC}" $minutes $seconds
        echo -e "\n⏳ Still in ${RED}$status${NC} status. Checking again in 10 seconds..."
        echo -e "${YELLOW}Press Ctrl+C to stop monitoring${NC}"
    fi
    
    echo -e "\n"
    k get pods -n ${apic_namespace}

    # Increment iteration counter
    ((iteration++))
    # Wait for 10 seconds before next check
    sleep 10
done

k get ManagementCluster -n ${apic_namespace}
echo -e "\n"

echo -e "# ${YELLOW}-------------------------------${NC}"
echo -e "# ${YELLOW}Deploy DataPower CR            ${NC}"
echo -e "# ${YELLOW}-------------------------------${NC}"  
cp ${filespath}/helper_files/apigateway_cr.yaml ${filespath}/helper_files/apigateway_cr_new.yaml
eval "sed -i $SED_ARG -e's|\$APP_PRODUCT_VERSION|'${APIC_VERSION}'|g' ${filespath}/helper_files/apigateway_cr_new.yaml"
eval "sed -i $SED_ARG -e's|\$PROFILE|${DATAPOWER_PROFILE}|g' ${filespath}/helper_files/apigateway_cr_new.yaml"
eval "sed -i $SED_ARG -e's|\$SECRET_NAME|datapower-docker-local-cred|g' ${filespath}/helper_files/apigateway_cr_new.yaml"
eval "sed -i $SED_ARG -e's|\$DOCKER_REGISTRY|'${REGISTRY_URL}'/${REGISTRY_PROJECT}|g' ${filespath}/helper_files/apigateway_cr_new.yaml"
eval "sed -i $SED_ARG -e's|\$STACK_HOST|'${NGINX_IP}'.nip.io|g' ${filespath}/helper_files/apigateway_cr_new.yaml"
eval "sed -i $SED_ARG -e 's|\$STORAGE_CLASS|'${storageclass}'|g' ${filespath}/helper_files/apigateway_cr_new.yaml"
eval "sed -i $SED_ARG -e 's|\$ADMIN_USER_SECRET|datapower-admin-credentials|g' ${filespath}/helper_files/apigateway_cr_new.yaml"
eval "sed -i $SED_ARG -e 's|\$PLATFORM_CA_SECRET|ingress-ca|g' ${filespath}/helper_files/apigateway_cr_new.yaml"
eval "sed -i $SED_ARG -e 's|accept: false|accept: true|g' ${filespath}/helper_files/apigateway_cr_new.yaml"
sed -i $SED_ARG -e "s/license: ''/license: ${LICENSE_KEY}/g" ${filespath}/helper_files/apigateway_cr_new.yaml

cat <<EOF > ./custom-datapower-config.cfg
top;
EOF
echo '# Create File: custom-datapower-config.cfg'

k create configmap enable-webui-config --from-file=./custom-datapower-config.cfg --dry-run=client -o yaml | k apply -f - -n ${apic_namespace}
rm ./custom-datapower-config.cfg
echo '  additionalDomainConfig:' >> ${filespath}/helper_files/apigateway_cr_new.yaml
echo '  - name: "default"' >> ${filespath}/helper_files/apigateway_cr_new.yaml
echo '    dpApp:' >> ${filespath}/helper_files/apigateway_cr_new.yaml
echo '      config:' >> ${filespath}/helper_files/apigateway_cr_new.yaml
echo '      - "enable-webui-config"' >> ${filespath}/helper_files/apigateway_cr_new.yaml
echo '  webGUIManagementEnabled: true' >> ${filespath}/helper_files/apigateway_cr_new.yaml
k apply -f ${filespath}/helper_files/apigateway_cr_new.yaml -n ${apic_namespace}; sleep 30

# Wait for the condition, capturing the exit status
k wait --for=jsonpath='{.status.phase}'=Running GatewayCluster -l app.kubernetes.io/name=gwv6 --timeout=1200s -n ${apic_namespace} || status=$?
# Check if the wait command was successful or timed out
if [[ $status -ne 0 ]]; then
  echo -e "${RED}Timeout occurred when query: [{.status.phase}'=Running GatewayCluster]. Continuing script...${NC}"
  echo -e "Execute the following command: ${YELLOW} k wait --for=jsonpath='{.status.phase}'=Running GatewayCluster -l app.kubernetes.io/name=gwv6 --timeout=1200s -n ${apic_namespace} ${NC}"
else
  echo -e "${YELLOW}GatewayCluster is waiting.${NC}"
fi
# End Wait

# Wait for the condition, capturing the exit status
k wait --for=condition=ready GatewayCluster -l app.kubernetes.io/name=gwv6 --timeout=1200s -n ${apic_namespace} || status=$?
# Check if the wait command was successful or timed out
if [[ $status -ne 0 ]]; then
  echo -e "${RED}Timeout occurred when query: [GatewayCluster is in a Pending status]. Continuing script...${NC}"
  echo -e "Execute the following command: ${YELLOW} k wait --for=condition=ready GatewayCluster -l app.kubernetes.io/name=gwv6 --timeout=1200s -n ${apic_namespace} ${NC}"
else
  echo -e "${YELLOW}GatewayCluster is ready.${NC}"
fi
# End Wait

k wait --selector=app.kubernetes.io/managed-by=datapower-operator --for=condition=ready --timeout=600s -n ${apic_namespace} --all pods
k get GatewayCluster -n ${apic_namespace}

k apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: gwv6-0-datapower-webgui
  namespace: ${apic_namespace}
  annotations:
    cloud.google.com/neg: '{"ingress":true}'
spec:
  selector:
    statefulset.kubernetes.io/pod-name: gwv6-0
  ports:
  - name: webgui-port
    protocol: TCP
    port: 9090
    targetPort: 9090
  type: LoadBalancer
  externalIPs:
  - ${NGINX_IP}
EOF

echo -e "\n"


echo -e "# ${YELLOW}-------------------------------${NC}"
echo -e "# ${YELLOW}Deploy Analytics CR            ${NC}"
echo -e "# ${YELLOW}-------------------------------${NC}"  
k apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: set-maxmapcount
  namespace: kube-system
  labels:
    k8s-app: set-maxmapcount
spec:
  selector:
    matchLabels:
      name: set-maxmapcount
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        name: set-maxmapcount
    spec:
      hostPID: true
      containers:
        - name: startup-script
          image: gcr.io/google-containers/startup-script:v2
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          env:
            - name: STARTUP_SCRIPT
              value: |
                #!/usr/bin/sh

                set -o errexit
                set -o pipefail
                set -o nounset

                sudo sysctl -w vm.max_map_count=262144
                sudo tee -a /var/lib/boot2docker/bootlocal.sh

                #sleep infinity
                #tail -f /dev/null
EOF

cp ${filespath}/helper_files/analytics_cr.yaml ${filespath}/helper_files/analytics_cr_new.yaml
eval "sed -i $SED_ARG  -e 's|\$APP_PRODUCT_VERSION|'${APIC_VERSION}'|g' ${filespath}/helper_files/analytics_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$PROFILE|${ANALYTICS_PROFILE}|g' ${filespath}/helper_files/analytics_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$SECRET_NAME|apic-registry-secret|g' ${filespath}/helper_files/analytics_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$DOCKER_REGISTRY|'${REGISTRY_URL}'/${REGISTRY_PROJECT}|g' ${filespath}/helper_files/analytics_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$STACK_HOST|'${NGINX_IP}'.nip.io|g' ${filespath}/helper_files/analytics_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$STORAGE_TYPE|'${storagetype}'|g' ${filespath}/helper_files/analytics_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$STORAGE_CLASS|'${storageclass}'|g' ${filespath}/helper_files/analytics_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$DATA_VOLUME_SIZE|50Gi|g' ${filespath}/helper_files/analytics_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|accept: false|accept: true|g' ${filespath}/helper_files/analytics_cr_new.yaml"
sed -i $SED_ARG -e "s/license: ''/license: ${LICENSE_KEY}/g" ${filespath}/helper_files/analytics_cr_new.yaml
k apply -f ${filespath}/helper_files/analytics_cr_new.yaml -n ${apic_namespace}; sleep 30
k wait --for=jsonpath='{.status.phase}'=Running AnalyticsCluster -l app.kubernetes.io/name=analytics --timeout=300s -n ${apic_namespace} || true
k wait --for=condition=ready AnalyticsCluster -l app.kubernetes.io/name=analytics --timeout=300s -n ${apic_namespace} || true
k get AnalyticsCluster -n ${apic_namespace}
echo -e "\n"


echo -e "# ${YELLOW}-------------------------------${NC}"
echo -e "# ${YELLOW}Deploy Portal CR               ${NC}"
echo -e "# ${YELLOW}-------------------------------${NC}"  
cp ${filespath}/helper_files/portal_cr.yaml ${filespath}/helper_files/portal_cr_new.yaml
eval "sed -i $SED_ARG  -e 's|\$APP_PRODUCT_VERSION|'${APIC_VERSION}'|g' ${filespath}/helper_files/portal_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$PROFILE|${PORTAL_PROFILE}|g' ${filespath}/helper_files/portal_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$SECRET_NAME|apic-registry-secret|g' ${filespath}/helper_files/portal_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$DOCKER_REGISTRY|'${REGISTRY_URL}'/${REGISTRY_PROJECT}|g' ${filespath}/helper_files/portal_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$STACK_HOST|'${NGINX_IP}'.nip.io|g' ${filespath}/helper_files/portal_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$STORAGE_CLASS|'${storageclass}'|g' ${filespath}/helper_files/portal_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$PLATFORM_CA_SECRET|ingress-ca|g' ${filespath}/helper_files/portal_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|\$CONSUMER_CA_SECRET|ingress-ca|g' ${filespath}/helper_files/portal_cr_new.yaml"
eval "sed -i $SED_ARG  -e 's|accept: false|accept: true|g' ${filespath}/helper_files/portal_cr_new.yaml"
sed -i $SED_ARG -e "s/license: ''/license: ${LICENSE_KEY}/g" ${filespath}/helper_files/portal_cr_new.yaml
k apply -f ${filespath}/helper_files/portal_cr_new.yaml -n ${apic_namespace}; sleep 30

# Wait for the condition, capturing the exit status
k wait --for=jsonpath='{.status.phase}'=Running PortalCluster -l app.kubernetes.io/name=portal --timeout=300s -n ${apic_namespace} || status=$?
# Check if the wait command was successful or timed out
if [[ $status -ne 0 ]]; then
  echo -e "${RED}Timeout occurred when query: [{.status.phase}'=Running PortalCluster]. Continuing script...${NC}"
  echo -e "${RED}Execute the following command: ${NC} ${YELLOW} k wait --for=jsonpath='{.status.phase}'=Running PortalCluster -l app.kubernetes.io/name=portal --timeout=300s -n ${apic_namespace} ${NC}"
else
  echo -e "${YELLOW}PortalCluster is waiting.${NC}"
fi
# End Wait

# Wait for the condition, capturing the exit status
k wait --for=condition=ready PortalCluster -l app.kubernetes.io/name=portal --timeout=300s -n ${apic_namespace} || status=$?
# Check if the wait command was successful or timed out
if [[ $status -ne 0 ]]; then
   echo -e "${RED}Timeout occurred when query: [PortalCluster is in a Pending status]. Continuing script...${NC}"
   echo -e "${RED}Execute the following command: ${NC} ${YELLOW} k wait --for=condition=ready PortalCluster -l app.kubernetes.io/name=portal --timeout=300s -n ${apic_namespace} ${NC}"
else
  echo -e "${YELLOW}PortalCluster is ready.${NC}"
fi
# End Wait

k get PortalCluster -n ${apic_namespace}
echo -e "\n"

echo -e "# ${YELLOW}===========================${NC}"
echo -e "# ${GREEN}===      Ver: $APIC_VERSION${NC}"
echo -e "# ${GREEN}===      ✅ Done ${NC}"
echo -e "# ${YELLOW}===========================${NC}"


