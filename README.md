# NIMBRIDGE

Hybrid Kubernetes and Azure platform for AI inference using NVIDIA NIM models.

## Prerequisites

- Debian/Ubuntu server with Kubernetes cluster (Kind, K3s, or similar)
- Azure account (free tier works)
- NVIDIA NGC account and API key (get one at https://ngc.nvidia.com)
- Git and basic command line knowledge

## Setup Steps

### 1. Setup Azure Infrastructure

This creates the Azure Container Registry and Container Apps environment.
```bash
./setup-azure.sh
```

What it does:
- Installs Azure CLI if needed
- Authenticates with Azure
- Registers required providers
- Creates infrastructure with Terraform

### 2. Push NVIDIA NIM Image to ACR

Get your NGC API key from https://ngc.nvidia.com, then:
```bash
export NGC_API_KEY="your-ngc-api-key"
./push-nim-image.sh
```

This pulls the Llama3-8B NIM model from NVIDIA and pushes it to your Azure Container Registry.

### 3. Deploy Harbor on Kubernetes

Harbor acts as a proxy-cache for Docker Hub, NVIDIA NGC, and Azure ACR.
```bash
./setup-harbor.sh
```

Wait for all Harbor pods to be running:
```bash
kubectl get pods -n harbor
```

### 4. Configure Harbor Registries

Once Harbor is running, configure the proxy-cache registries:
```bash
./configure-harbor.sh
```

This configures three registries in Harbor:
- Docker Hub
- NVIDIA NGC
- Azure Container Registry

## Project Structure
```
Nimbridge/
├── README.md
├── setup-azure.sh           # Step 1: Azure infrastructure
├── push-nim-image.sh        # Step 2: Push NIM image
├── setup-harbor.sh          # Step 3: Deploy Harbor
├── configure-harbor.sh      # Step 4: Configure registries
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── providers.tf
└── helm/
    └── harbor/
        └── values.yaml
```

## What Gets Created

### Azure Resources
- Resource Group (rg-nimbridge)
- Container Registry (acrnimbridge001)
- Log Analytics Workspace
- Container App Environment

Estimated cost: ~8€/month when idle (covered by free credits)

### Kubernetes Resources
- Harbor registry (namespace: harbor)
- 3 proxy-cache endpoints (Docker Hub, NGC, ACR)

## Troubleshooting

### Azure CLI installation fails
```bash
sudo rm -f /etc/apt/sources.list.d/azure-cli.sources
sudo apt update
```

### Provider registration hangs
```bash
az provider register --namespace Microsoft.App --wait
```

### Harbor pods stuck in Pending
Check your storage class:
```bash
kubectl get storageclass
```

Update `helm/harbor/values.yaml` with the correct storage class name.

### Kind cluster port mapping
If using Kind, ensure ports 80/443 are mapped in your cluster config.

## Verification

Check Azure resources:
```bash
cd terraform
terraform output
```

Check Harbor status:
```bash
kubectl get pods -n harbor
```

Check Harbor registries:
```bash
kubectl run test --rm -it --image=curlimages/curl --restart=Never -- \
  curl -u admin:Nimbridge2024! \
  http://harbor-core.harbor.svc.cluster.local/api/v2.0/registries
```

## Next Steps

The next phase involves:
- Creating an API Gateway on Kubernetes
- Deploying NVIDIA NIM to Azure Container Apps with GPU
- Testing end-to-end AI inference

## Cleanup

Remove Harbor:
```bash
helm uninstall harbor -n harbor
kubectl delete namespace harbor
```

Remove Azure resources:
```bash
cd terraform
terraform destroy
```

## Notes

- Harbor admin credentials: `admin` / `Nimbridge2024!`
- All scripts are idempotent and can be re-run safely
- Azure resources incur costs after free credits are exhausted
- NVIDIA NIM images are large (several GB)

## License

MIT
