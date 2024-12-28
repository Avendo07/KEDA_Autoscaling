#!/bin/bash

# Get the home directory of the current user
HOME_DIR="$HOME"

# Define the kubeconfig file path
KUBECONFIG_PATH="$HOME_DIR/.kube/config"

# Check if the kubeconfig file exists
if [ -f "$KUBECONFIG_PATH" ]; then
    echo "Kubeconfig file found at: $KUBECONFIG_PATH"

    # Check if 'kubectl get nodes' works
    if ! kubectl get nodes > /dev/null 2>&1; then
        echo "Failed to retrieve nodes. Please check your cluster connection or kubeconfig."
        exit 1
    else
        echo "Successfully connected to the cluster. Nodes are accessible."
    fi
else
    echo "Kubeconfig file not found. Please ensure it exists at: $KUBECONFIG_PATH"
    exit 1
fi

# PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
# ARCHITECTURE=$(uname -m)
# HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | jq -r .tag_name)
# FILENAME=helm-$HELM_VERSION-$PLATFORM-$ARCHITECTURE

# echo "You are on $PLATFORM $ARCHITECTURE system, installing the correspoinding binaries"

# # Install Helm based on the platform
# if ! command -v helm &> /dev/null; then
#     echo "Helm not found, installing..."

#     if [ "$PLATFORM" == "darwin" ] || [ "$PLATFORM" == "linux" ]; then
#         # macOS platform
#         curl -LO https://get.helm.sh/helm-$FILENAME.tar.gz
#         if [ $? -ne 0 ]; then
#             echo "Error downloading Helm binary."
#             exit 1
#         fi

#         # Extract the Helm binary
#         tar -zxvf $FILENAME.tar.gz
#         if [ $? -ne 0 ]; then
#             echo "Error extracting Helm."
#             exit 1
#         fi

#         # Move Helm binary to /usr/local/bin
#         sudo mv $PLATFORM-$ARCHITECTURE/helm /usr/local/bin/helm
#         if [ $? -ne 0 ]; then
#             echo "Error moving Helm binary to /usr/local/bin."
#             exit 1
#         fi

#         # Clean up
#         rm -rf $PLATFORM-$ARCHITECTURE helm-$FILENAME.tar.gz
#         echo "Helm installed successfully"
#     else
#         echo "Unsupported platform: $PLATFORM, only supports Linux and Darwin systems as of now"
#         exit 1
#     fi
# else
#     echo "Helm is already installed."
# fi

if ! command -v helm &> /dev/null; then
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
else
    echo "Helm is already installed."
fi

echo "Adding the KEDA Helm repository..."
helm repo add kedacore https://kedacore.github.io/charts
if [ $? -ne 0 ]; then
    echo "Failed to add KEDA Helm repository. Exiting..."
    exit 1
fi

# Update Helm repositories to fetch the latest charts
echo "Updating Helm repositories..."
helm repo update
if [ $? -ne 0 ]; then
    echo "Failed to update Helm repositories. Exiting..."
    exit 1
fi

# Install KEDA into the default namespace (or specify another namespace)
echo "Installing KEDA into the cluster..."
helm install keda kedacore/keda --namespace keda --create-namespace > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Failed to install KEDA. Exiting..."
    exit 1
fi

# Verify KEDA installation
echo "Verifying KEDA installation..."
kubectl get pods -n keda
if [ $? -ne 0 ]; then
    echo "Failed to verify KEDA installation. Exiting..."
    exit 1
fi

echo "KEDA has been successfully installed!"

