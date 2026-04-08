#!/bin/bash
set -e

echo "============================================"
echo "  Mini TDMC — Step 1: Cluster Setup"
echo "============================================"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "ERROR: Docker not found. Install OrbStack: https://orbstack.dev"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "ERROR: kubectl not found."; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "ERROR: Helm not found. Run: brew install helm"; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "ERROR: Terraform not found. Run: brew tap hashicorp/tap && brew install hashicorp/tap/terraform"; exit 1; }
echo "All prerequisites OK"
echo ""

# Check K8s is running
echo "Checking Kubernetes cluster..."
kubectl cluster-info >/dev/null 2>&1 || { echo "ERROR: K8s not running. Enable it in OrbStack settings."; exit 1; }
echo "Kubernetes is running:"
kubectl get nodes
echo ""

# Terraform (creates namespaces + deploys Inventory Service Helm chart)
echo "Provisioning infrastructure with Terraform..."
cd terraform
terraform init -input=false >/dev/null 2>&1
terraform apply -auto-approve
cd ..
echo ""

# Apply CRD
echo "Applying PostgresInstance CRD..."
kubectl apply -f k8s/crds/postgresinstance-crd.yaml
echo ""

# Deploy RabbitMQ early — Inventory Service needs it to start
echo "Deploying RabbitMQ (required before Inventory Service can connect)..."
kubectl apply -f k8s/base/rabbitmq.yaml
echo "  Waiting for RabbitMQ to be ready..."
kubectl wait --for=condition=ready pod/rabbitmq-0 -n mini-tdmc-control-plane --timeout=120s
echo ""

# Restart Inventory Service now that RabbitMQ is up
echo "Restarting Inventory Service (connecting to RabbitMQ)..."
kubectl rollout restart deployment/inventory-mini-tdmc-inventory -n mini-tdmc-control-plane 2>/dev/null || true
echo ""

echo "============================================"
echo "  Step 1 COMPLETE"
echo ""
echo "  Namespaces created:"
echo "    - mini-tdmc-control-plane"
echo "    - mini-tdmc-data-plane"
echo "  RabbitMQ: running"
echo "  Inventory Service: restarting (connecting to RabbitMQ)"
echo ""
echo "  Next: ./scripts/02-build-images.sh"
echo "============================================"
