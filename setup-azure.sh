#!/bin/bash
set -e

echo "NIMBRIDGE - Azure Infrastructure Setup"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Azure CLI not found. Installing..."
    sudo rm -f /etc/apt/sources.list.d/azure-cli.sources
    sudo apt-get update
    sudo apt-get install -y python3-pip
    pip3 install azure-cli --break-system-packages
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.local/bin:$PATH"
fi

# Login to Azure
echo "Logging in to Azure..."
az login --use-device-code

# Register Microsoft.App provider
echo "Registering Microsoft.App provider..."
az provider register --namespace Microsoft.App

# Wait for registration
echo "Waiting for provider registration..."
while [ "$(az provider show -n Microsoft.App --query registrationState -o tsv)" != "Registered" ]; do
    echo "Still registering..."
    sleep 10
done
echo "Provider registered"

# Terraform
cd terraform
echo "Initializing Terraform..."
terraform init

echo "Planning infrastructure..."
terraform plan

echo "Creating Azure resources..."
terraform apply -auto-approve

echo ""
echo "Azure infrastructure created"
echo "ACR Details:"
terraform output acr_login_server
terraform output acr_username
echo "Password: $(terraform output -raw acr_password)"
