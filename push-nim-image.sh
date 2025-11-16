#!/bin/bash
set -e

# Check NGC API key
if [ -z "$NGC_API_KEY" ]; then
    echo "Error: NGC_API_KEY environment variable not set"
    echo "Get your key from https://ngc.nvidia.com"
    echo "Then run: export NGC_API_KEY='your-key'"
    exit 1
fi

cd terraform
export ACR_NAME=$(terraform output -raw acr_login_server | cut -d'.' -f1)
export ACR_PASSWORD=$(terraform output -raw acr_password)
cd ..

echo "Logging into NVIDIA NGC..."
echo "$NGC_API_KEY" | docker login nvcr.io --username '$oauthtoken' --password-stdin

echo "Pulling NVIDIA NIM image (this may take several minutes)..."
docker pull nvcr.io/nim/meta/llama3-8b-instruct:latest

echo "Logging into Azure Container Registry..."
docker login ${ACR_NAME}.azurecr.io -u ${ACR_NAME} -p "$ACR_PASSWORD"

echo "Tagging image for ACR..."
docker tag nvcr.io/nim/meta/llama3-8b-instruct:latest ${ACR_NAME}.azurecr.io/nim/llama3-8b:latest

echo "Pushing to ACR..."
docker push ${ACR_NAME}.azurecr.io/nim/llama3-8b:latest

echo "Done! Image available at: ${ACR_NAME}.azurecr.io/nim/llama3-8b:latest"
