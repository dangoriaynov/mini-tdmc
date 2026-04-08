#!/bin/bash
set -e

echo "============================================"
echo "  Mini TDMC — QUICK START (all-in-one)"
echo "============================================"
echo ""
echo "  This runs all setup steps sequentially."
echo "  Total time: ~3-5 minutes"
echo ""

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

bash scripts/01-setup-cluster.sh
echo ""
bash scripts/02-build-images.sh
echo ""
bash scripts/03-deploy-all.sh
echo ""

echo "============================================"
echo "  ALL SERVICES RUNNING"
echo "============================================"
echo ""
echo "  Pods:"
kubectl get pods -n mini-tdmc-control-plane
echo ""
echo "  Custom Resource Definition:"
kubectl get crd | grep tdmc
echo ""
echo "  Run the demo:"
echo "    ./scripts/04-demo.sh"
echo ""
echo "  Browser access (port-forwards started automatically):"
echo "    Grafana (dashboards + metrics):  http://localhost:3000   (admin / admin)"
echo "    RabbitMQ Management (queues):    http://localhost:15672  (guest / guest)"
echo "    GraphQL Playground (API):        http://localhost:4000/graphql"
echo ""
echo "  Teardown:"
echo "    ./scripts/05-teardown.sh"
echo "============================================"
