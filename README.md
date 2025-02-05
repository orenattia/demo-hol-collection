# Installing IBM API Connect on Minikube

This guide provides step-by-step instructions to install IBM API Connect on Minikube.

## 1) Prerequisites Software and Hardware

Before proceeding, ensure you have the following installed:
- **Operating System**: Ubuntu 24.04 (At least *16 CPU* cores, *40GB RAM*, and *50GB* disk space)
- **IBM ID Cloud Account**: You must have an IBM ID Cloud account in order to download IBM API Connect for online installation. The key can be found at [IBM Entitlement KEY](https://myibm.ibm.com/products-services/containerlibrary).

## 2) Prerequisites Tools

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
     - Example: If your system's IP is `192.168.1.100`, the registry container name should be `hcr.192.168.1.100.nip.io`.

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

## 3) Configure Harbor Private Registry (when installing off-line installtion)

### 3.1) Configure Harbor Registry
To configure HTTPS, you must create SSL certificates. You can use certific
- **Execution**:
   - Run the script as a **sudo user** using the following command:
```bash
harbor-registry-setup/01-config-harbor.sh
```

### 3.2) Configure HTTPS Access to Harbor Registry
**Optional**
To configure HTTPS, you must create SSL certificates. You can use certificates that are signed by a trusted third-party CA, or you can use self-signed certificates. This section describes how to use OpenSSL to create a CA, and how to use your CA to sign a server certificate and a client certificate. You can use other CA providers, for example Let’s Encrypt.

You can create self-signed certificates if you don't have any SSL certificates by executing the following command:
```bash
harbor-registry-setup/generate-ssl-certificate.sh 123.123.11.22
```
As a result, all certificates will be generated in the [cert/] folder.

### 3.3) Start Harbor Registry
- **Execution**:
   - Run the script as a **sudo user** using the following command:
```bash
harbor-registry-setup/02-start-harbor.sh
```
- **Setting Harbor project and user via UI**:
   - Execute the following tasks from the Harbor UI:
      login to: [e.g. https://hcr.161.156.164.61.nip.io]
```bash
  - Create Harbor project
        Project name: apic
  - Create Harbor user
        User name: apic-cr
  - Attched Harbor user to project
      apic-cr --> apic
```
- **Verify Harbor installation**:
```bash
  kubectl get pods
  kubectl get pvc
  kubectl get svc
  kubectl get ingress
```
- **Verify access to the private docker repository**:
   - Execute the following command:
```bash
docker login https://hcr.<IP>.nip.io -u HARBOR_USER_NAME -P HARBOR_PASSWORD
```

#
## Conclusion

You have successfully installed IBM API Connect on Minikube. You can now start configuring APIs and managing services.

Let me know if you need any modifications!