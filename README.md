# Installing IBM API Connect on Minikube
This guide provides step-by-step instructions to install IBM API Connect on Minikube.

## 1) Prerequisites Software and Hardware
Before proceeding, ensure you have the following installed:
- **Operating System**: Ubuntu 24.04 (At least *16 CPU* cores, *40GB RAM*, and *50GB* disk space)
- **IBM ID Cloud Account**: You must have an IBM ID Cloud account in order to download IBM API Connect for online installation. The key can be found at [IBM Entitlement KEY](https://myibm.ibm.com/products-services/containerlibrary).

## 2) Prerequisites Tool
This section provides step-by-step instructions to execute the provided scripts for setting up Docker, Docker Compose, Minikube, and Kubernetes utilities. Ensure you follow the steps carefully.

---

### Step 1: Execute the Docker and Docker Compose Installation Script
1. **Prerequisites**:
   - Ensure you have `root` privileges on the system.
   - Verify that the script `01-install-docker-with-dockercompose.sh` is present in the current directory and is executable.

2. **Required Harbor Network Ports**
   - Harbor requires that the following ports be open on the target host.
     Execute the following iptables commands:
         sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
         sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
         sudo iptables -A INPUT -p tcp --dport 4443 -j ACCEPT
3. **Execution**:
   - Run the script as the **root user** using the following command:
     ```bash
     cd demo-hol-collections/prerequisites/
     sudo ./01-install-docker-with-dockercompose.sh
     ```
   - This script will install Docker and Docker Compose on your system.

4. **Verification**:
   - After the script completes, verify the installation by checking the Docker version:
     ```bash
     docker --version
     ```
   - Verify Docker Compose installation:
     ```bash
     docker-compose --version
     ```

---

### Step 2: Execute the Minikube and Kubernetes Utilities Installation Script
1. **Prerequisites**:
   - Ensure Docker is installed and running (as verified in Step 1).
   - Ensure you are logged in as a **sudo user** (non-root user with `sudo` privileges).
   - Prepare the registry container name in the format `hcr.<IP>.nip.io`. Replace `<IP>` with the actual IP address of your system.
Example: If your system's IP is `192.168.1.100`, the registry container name should be `hcr.192.168.1.100.nip.io`.

2. **Execution**:
   - Run the script as a **sudo user** using the following command:
     ```bash
     cd demo-hol-collections/prerequisites/
     sudo ./02-install-minikube-with-k8utilities.sh
     ```
   - This script will install `Minikube` and essential Kubernetes utilities (e.g., `kubectl`, `helm`, etc.).

3. **Verification**:
   - After the script completes, verify the Minikube installation:
     ```bash
     minikube version
     ```
   - Verify Kubernetes utilities:
     ```bash
     kubectl version --client
     helm3 version
     ```

---

### Additional Notes
- **Registry Container Name**: Ensure the registry container name is correctly formatted and matches the IP address of your system. This is crucial for Minikube to interact with the local Docker registry.
- **Troubleshooting**:
  - If any script fails, check the logs for errors and ensure all prerequisites are met.
  - For Minikube issues, refer to the [Minikube documentation](https://minikube.sigs.k8s.io/docs/).
- **Security**: Always ensure scripts are obtained from trusted sources to avoid security risks.

---

## 3) Configure Registry 

### 3.1) Configure API Connect using IBM Public Registry - (On-Line) 
When installing online, make sure you successfully ping the IBM Public Registry URL by executing: ping cp.icr.io.
If this URL still doesn't resolve, try updating the DNS, for example setup DNS on IBM Cloud: 
   - Update DNS:
     ```bash
     sudo nano /etc/systemd/resolved.conf
     - update --> DNS=8.8.8.8 8.8.4.4
     ```
   - Restart systemd-resolved:
     ```bash
      systemctl restart systemd-resolved
      - Test it by execute: ping cp.icr.io
     ```

### 3.2) Configure API Connect with Harbor Private Registry - (Air-Gap) 
This section provides step-by-step instructions to configuer Harbor private registry.
Make sure to get the offline **IBM® API Connect v10.0.9.0 for Containers** images before setting up the air-gap installation.
The following link is now available: [IBM® API Connect v10.0.9.0 is now available](https://www.ibm.com/support/pages/ibm%C2%AE-api-connect-v10090-now-available). 
The file apiconnect-image-tool_10.0.1.9.tar.gz can be downloaded.
Make sure you properly follow the instructions.

Ensure you follow the steps carefully.

#### 3.2.1) Configure Harbor Private Registry - (Air-Gap)
To configure HTTPS, you must create SSL certificates. You can use certific
**Execution**:
- Run the script as a **sudo user** using the following command:
  ```bash
  harbor-registry-setup/01-config-harbor.sh
  ```

#### 3.2.2) Configure HTTPS Access to Harbor Private Registry (Air-Gap)
**Optional**
To configure HTTPS, you must create SSL certificates. You can use certificates that are signed by a trusted third-party CA, or you can use self-signed certificates. This section describes how to use OpenSSL to create a CA, and how to use your CA to sign a server certificate and a client certificate. You can use other CA providers, for example Let’s Encrypt.

You can create self-signed certificates if you don't have any SSL certificates by executing the following command:
```bash
harbor-registry-setup/generate-ssl-certificate.sh 123.123.11.22
```
As a result, all certificates will be generated in the [cert/] folder.

#### 3.2.3) Start Harbor Private Registry (Air-Gap)
**Execution**:
Run the script as a **sudo user** using the following command:
  ```bash
  harbor-registry-setup/02-start-harbor.sh
  ```
**Setting Harbor project and user via UI**:
Execute the following tasks from the Harbor UI:
      login to: [e.g. https://hcr.161.156.164.61.nip.io]
  ```bash
    - Create Harbor project
          Project name: apic
    - Create Harbor user
          User name: apic-cr
    - Attched Harbor user to project
        apic-cr --> apic
  ```
**Verify Harbor installation**:
  ```bash
    kubectl get pods
    kubectl get pvc
    kubectl get svc
    kubectl get ingress
  ```
**Verify access to the private docker repository**:
  Execute the following command:
  ```bash
  docker login https://hcr.<IP>.nip.io -u HARBOR_USER_NAME -P HARBOR_PASSWORD
  ```

## 4) Installing API Connect 
This section provides step-by-step instructions to installing API Connect 10.x. 
Ensure you follow the steps carefully.

### 4.1) Setup APIC
When installing online, make sure you successfully ping the IBM Public Registry URL by executing: ping cp.icr.io.
**Execution**:
   - Run the script as the **sudo user** using the following command:
     ```bash
     cd demo-hol-collections/ibm-apic-k8-setup/
     sudo ./10-main-apic-setup.sh
     ```
---

### 4.2) Customization APIC Installation Parameters
When installing online, make sure you successfully ping the IBM Public Registry URL by executing: ping cp.icr.io.
   - Verify all requirements software was installed:
     ```bash
     Please confirm that all of the prerequisites have been installed before proceeding? (Y/n): Y
     ```

   - Select APIC installtion version and setup mode:
     ```bash
      To install IBM API Connect 10, please select the following version:
      1) [Off-Line setup] ver 10.0.9.0 [Air-Gap Setup using Harbor Private Registry] 
      2) [On-Line setup] ver 10.0.6.0 [default]  [Online Setup using IBM Registry] 
      3) [On/Off setup] ver 10.0.5.8 
      4) Exit
      Enter selection [2]: 1
     ```

   - Confirm deployment profile:
     ```bash
      Deployment Profile Limits:
      ├── Management Profile:  n1xc2.m16 
      ├── Portal Profile:      n1xc2.m8     
      ├── Analytics Profile:   n1xc2.m16  
      └── DataPower Profile:   n1xc1.m8  

      Do you agree to continue with the deployment settings as it is? (Y/n):  Y
     ```

   - Select container registry type:
     ```bash
      Select container registry type: 
       1) IBM Entitled Registry [default]:
              Registry URL: cp.icr.io
             Registry Project Name: cp
      
       NOTE! Get the entitlement key from: https://myibm.ibm.com/products-services/containerlibrary
       2) Private Container Registry [Docker Private Registry is required!!!]
      Enter selection [1]: 2
     ```

   - Select minikube profile:
     ```bash
      Enter minikube profile name: MINIKUBE_PROFILE
     ```

   - Select minikube profile:
     ```bash
      #IMPORTENT!!! - Download the full image Containers
      #  IBM® API Connect v10.0.9.0 for Containers 
      Enter Private Registry URL: hcr.158.176.5.141.nip.io
      Enter Private Registry Project Name: HARBOR_PROJECT_NAME
      Enter Private Registry User Name: HARBOR_USER_NAME
      Enter Private Registry Password: HARBOR_PASSWORD
     ```

   - Select minikube profile:
     ```bash
      # -------------------------------
      # Setup Minikube                 
      # -------------------------------
      Device "eth1" does not exist.
      # Select cluster IP address: 
      # --------------------------------------- 
      #  1) WAN IP (158.176.5.141) [default]
      #  2) Minikube IP (192.168.49.2) 
      #  3) Enter custom IP
      # --------------------------------------- 

      Enter selection [1]: 1
     ```

   - Set APIC admin password:
     ```bash
      Enter Management subsystem administrator password: APIC_ADMIN_PASSWORD
     ```

### 4.3) Installation Verification

  - When installation completes successfully, you'll receive confirmation messages:
    ```bash
    # ===========================
    # ===      Ver: 10.0.9.0
    # ===      ✅ Done 
    # ===========================
    Script done.
    Output log file location: logs/apic_20250206141245-03-ibm-apic-cluster-installation.log 
    ```

#### Key Verification Steps
- Confirm version compatibility
- Check installation log for detailed diagnostics
- Validate all prerequisite software installations

#### Troubleshooting
- Review log file for any potential configuration issues
- Ensure all system requirements are met before installation

---
#
## Conclusion

You have successfully installed IBM API Connect on Minikube. You can now start configuring APIs and managing services.

Let me know if you need any modifications!

## Acknowledgments 🙏

A heartfelt thank you to my colleague **Yaniv Yuzis** for guiding me through the development of this technological solution. Your unwavering support and profound insights were instrumental in transforming our challenge into a meaningful technological contribution.

**With deepest gratitude,**
Oren Attia