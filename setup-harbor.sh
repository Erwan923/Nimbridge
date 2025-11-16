#!/bin/bash
set -e

echo "NIMBRIDGE - Harbor Setup"
echo ""

# Add Harbor Helm repo
echo "Adding Harbor Helm repository..."
helm repo add harbor https://helm.goharbor.io
helm repo update

# Create namespace
echo "Creating harbor namespace..."
kubectl create namespace harbor --dry-run=client -o yaml | kubectl apply -f -

# Create values file
cat > /tmp/harbor-values.yaml << 'VALUESEOF'
expose:
  type: ingress
  ingress:
    hosts:
      core: harbor.nimbridge.local
    className: nginx
  tls:
    enabled: false

externalURL: http://harbor.nimbridge.local

persistence:
  enabled: true
  persistentVolumeClaim:
    registry:
      size: 50Gi
      storageClass: "standard"
    database:
      size: 5Gi
      storageClass: "standard"
    redis:
      size: 2Gi
      storageClass: "standard"

harborAdminPassword: "Nimbridge2024!"

database:
  type: internal

redis:
  type: internal
VALUESEOF

# Install Harbor
echo "Installing Harbor..."
helm install harbor harbor/harbor -f /tmp/harbor-values.yaml -n harbor

# Wait for pods
echo "Waiting for Harbor pods to be ready..."
kubectl wait --for=condition=ready pod -l app=harbor -n harbor --timeout=5m || true

echo ""
echo "Harbor installation complete!"
echo "Configure registries with: ./configure-harbor.sh"
