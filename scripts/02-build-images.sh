#!/bin/bash
set -e

echo "============================================"
echo "  Mini TDMC — Step 2: Build Docker Images"
echo "============================================"
echo ""

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Build Inventory Service
echo "[1/3] Building Inventory Service (Spring Boot)..."
cd "$REPO_ROOT/services/inventory-service"
./mvnw clean package -DskipTests -q
docker build -t mini-tdmc/inventory-service:latest . -q
echo "       mini-tdmc/inventory-service:latest — $(docker images mini-tdmc/inventory-service:latest --format '{{.Size}}')"

# Build Gateway
echo "[2/3] Building GraphQL Gateway (Node.js)..."
cd "$REPO_ROOT/services/gateway"
npm install --silent 2>/dev/null
docker build -t mini-tdmc/gateway:latest . -q
echo "       mini-tdmc/gateway:latest — $(docker images mini-tdmc/gateway:latest --format '{{.Size}}')"

# Build Connector
echo "[3/3] Building Connector App (Node.js)..."
cd "$REPO_ROOT/services/connector-app"
npm install --silent 2>/dev/null
docker build -t mini-tdmc/connector:latest . -q
echo "       mini-tdmc/connector:latest — $(docker images mini-tdmc/connector:latest --format '{{.Size}}')"

cd "$REPO_ROOT"
echo ""
echo "============================================"
echo "  Step 2 COMPLETE — All images built"
echo ""
echo "  Images:"
docker images --filter "reference=mini-tdmc/*" --format "    {{.Repository}}:{{.Tag}}  {{.Size}}"
echo ""
echo "  Next: ./scripts/03-deploy-all.sh"
echo "============================================"
