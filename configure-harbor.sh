#!/bin/bash
set -e

echo "NIMBRIDGE - Harbor Configuration"
echo ""

# Get ACR password
cd terraform
ACR_PASSWORD=$(terraform output -raw acr_password)
cd ..

# Wait for Harbor to be ready
echo "Waiting for Harbor to be ready..."
kubectl wait --for=condition=ready pod -l component=core -n harbor --timeout=5m

# Configure registries via API
echo "Configuring Harbor registries..."
kubectl run harbor-config --rm -i --image=curlimages/curl --restart=Never -- sh -c "
HARBOR_URL='http://harbor-core.harbor.svc.cluster.local/api/v2.0'
HARBOR_USER='admin'
HARBOR_PASS='Nimbridge2024!'

echo 'Creating Docker Hub registry...'
curl -u \${HARBOR_USER}:\${HARBOR_PASS} -X POST \"\${HARBOR_URL}/registries\" \
  -H 'Content-Type: application/json' \
  -d '{
    \"name\": \"dockerhub\",
    \"type\": \"docker-hub\",
    \"url\": \"https://hub.docker.com\",
    \"insecure\": false
  }'

echo 'Creating NVIDIA NGC registry...'
curl -u \${HARBOR_USER}:\${HARBOR_PASS} -X POST \"\${HARBOR_URL}/registries\" \
  -H 'Content-Type: application/json' \
  -d '{
    \"name\": \"nvidia-ngc\",
    \"type\": \"docker-registry\",
    \"url\": \"https://nvcr.io\",
    \"insecure\": false
  }'

echo 'Creating Azure ACR registry...'
curl -u \${HARBOR_USER}:\${HARBOR_PASS} -X POST \"\${HARBOR_URL}/registries\" \
  -H 'Content-Type: application/json' \
  -d '{
    \"name\": \"azure-acr\",
    \"type\": \"azure-acr\",
    \"url\": \"https://acrnimbridge001.azurecr.io\",
    \"credential\": {
      \"access_key\": \"acrnimbridge001\",
      \"access_secret\": \"$ACR_PASSWORD\"
    },
    \"insecure\": false
  }'

echo 'Verifying registries...'
curl -u \${HARBOR_USER}:\${HARBOR_PASS} \"\${HARBOR_URL}/registries\"
"

echo ""
echo "Harbor configuration complete!"
echo "Login: admin / Nimbridge2024!"
