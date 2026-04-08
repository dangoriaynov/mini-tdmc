#!/bin/bash
set -e

echo "============================================"
echo "  Mini TDMC — Step 3: Deploy All Services"
echo "============================================"
echo ""

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NS="mini-tdmc-control-plane"

# RabbitMQ
echo "[1/5] Deploying RabbitMQ..."
kubectl apply -f "$REPO_ROOT/k8s/base/rabbitmq.yaml"
echo "       Waiting for RabbitMQ to be ready..."
kubectl wait --for=condition=ready pod/rabbitmq-0 -n $NS --timeout=120s 2>/dev/null || true
echo ""

# Inventory Service (via Helm)
echo "[2/5] Deploying Inventory Service (Helm)..."
helm upgrade --install inventory "$REPO_ROOT/helm/mini-tdmc-inventory" -n $NS --wait --timeout=120s
echo ""

# Connector App
echo "[3/5] Deploying Connector App..."
kubectl apply -f "$REPO_ROOT/k8s/base/connector.yaml"
echo ""

# GraphQL Gateway
echo "[4/5] Deploying GraphQL Gateway..."
kubectl apply -f "$REPO_ROOT/k8s/base/gateway.yaml"
echo ""

# Observability
echo "[5/5] Deploying Prometheus + Grafana..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin \
  --wait --timeout=180s 2>/dev/null
kubectl apply -f "$REPO_ROOT/k8s/base/servicemonitor.yaml"
echo ""

# Wait for all pods
echo "Waiting for all pods to be ready..."
sleep 10
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mini-tdmc-inventory -n $NS --timeout=120s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=gateway -n $NS --timeout=60s 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=connector -n $NS --timeout=60s 2>/dev/null || true

echo ""
echo "============================================"
echo "  Step 3 COMPLETE — All services deployed"
# Kill any existing port-forwards
echo "Starting port-forwards (background)..."
pkill -f "port-forward.*monitoring-grafana" 2>/dev/null || true
pkill -f "port-forward.*svc/rabbitmq" 2>/dev/null || true
pkill -f "port-forward.*svc/gateway" 2>/dev/null || true

# Start all port-forwards
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 >/dev/null 2>&1 &
kubectl port-forward -n $NS svc/rabbitmq 15672:15672 >/dev/null 2>&1 &
kubectl port-forward -n $NS svc/gateway 4000:4000 >/dev/null 2>&1 &
sleep 2

echo ""
echo "============================================"
echo "  Step 3 COMPLETE — All services deployed"
echo "============================================"
echo ""
echo "  Pods:"
kubectl get pods -n $NS --no-headers | awk '{printf "    %-50s %s\n", $1, $3}'
echo ""
echo "  Browser access:"
echo "    Grafana (dashboards + metrics):  http://localhost:3000   (admin / admin)"
echo "    RabbitMQ Management (queues):    http://localhost:15672  (guest / guest)"
echo "    GraphQL Playground (API):        http://localhost:4000/graphql"
echo ""
echo "  Next: ./scripts/04-demo.sh"
echo "============================================"
