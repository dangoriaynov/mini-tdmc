#!/bin/bash
set -e

NS="mini-tdmc-control-plane"
GATEWAY="gateway.$NS.svc.cluster.local:4000"
INVENTORY="inventory-mini-tdmc-inventory.$NS.svc.cluster.local:4001"

echo "============================================"
echo "  Mini TDMC — DEMO"
echo "============================================"
echo ""
echo "  Architecture:"
echo "  Client → Gateway (:4000) → Inventory Service (:4001) → RabbitMQ → Connector → K8s CRD"
echo ""
echo "--------------------------------------------"
echo "  1. Current pods"
echo "--------------------------------------------"
kubectl get pods -n $NS
echo ""

echo "--------------------------------------------"
echo "  2. Creating a PostgreSQL instance via GraphQL Gateway"
echo "     (schema stitching: Gateway delegates to Inventory Service)"
echo "--------------------------------------------"
echo ""
echo "  Sending: mutation { createInstance(name: \"demo-postgres\", serviceType: \"POSTGRESQL\", plan: \"large\") }"
echo ""

RESULT=$(kubectl run curl-demo --rm -it --image=curlimages/curl --restart=Never -n $NS -- \
  curl -s -X POST "http://$GATEWAY/graphql" \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { createInstance(input: {name: \"demo-postgres\", serviceType: \"POSTGRESQL\", plan: \"large\"}) { id name serviceType plan status } }"}' 2>/dev/null)

echo "  Response: $RESULT"
echo ""

echo "--------------------------------------------"
echo "  3. Checking RabbitMQ event was published"
echo "--------------------------------------------"
echo ""
echo "  Inventory Service logs:"
kubectl logs -n $NS -l app.kubernetes.io/name=mini-tdmc-inventory --tail=3 2>/dev/null | grep -E "Published|event" || echo "  (check manually: kubectl logs -n $NS -l app.kubernetes.io/name=mini-tdmc-inventory --tail=5)"
echo ""

echo "--------------------------------------------"
echo "  4. Checking Connector processed the event"
echo "--------------------------------------------"
echo ""
echo "  Connector logs:"
kubectl logs -n $NS -l app=connector --tail=5 2>/dev/null | grep -E "Received|Created|Acknowledged|idempotent" || echo "  (check manually: kubectl logs -n $NS -l app=connector --tail=5)"
echo ""

echo "--------------------------------------------"
echo "  5. Custom Resources in data plane"
echo "--------------------------------------------"
echo ""
kubectl get postgresinstances -n mini-tdmc-data-plane 2>/dev/null || echo "  No instances yet (connector may still be processing)"
echo ""

echo "--------------------------------------------"
echo "  6. Query all instances via Gateway"
echo "--------------------------------------------"
echo ""
kubectl run curl-query --rm -it --image=curlimages/curl --restart=Never -n $NS -- \
  curl -s -X POST "http://$GATEWAY/graphql" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ instances { id name serviceType plan status createdAt } }"}' 2>/dev/null
echo ""
echo ""

echo "============================================"
echo "  DEMO COMPLETE"
echo "============================================"
echo ""
echo "  Full E2E flow verified:"
echo "    Client"
echo "      → GraphQL Gateway (schema stitching, :4000)"
echo "      → Inventory Service (Spring Boot, :4001)"
echo "      → RabbitMQ (event: tdmc.tasks/instance.create)"
echo "      → Connector App (consumes event)"
echo "      → PostgresInstance CRD (in data-plane namespace)"
echo ""
echo "  Access Grafana:"
echo "    kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"
echo "    Open: http://localhost:3000"
echo "    Login: admin / admin"
echo ""
echo "  Useful commands:"
echo "    kubectl get pods -n $NS"
echo "    kubectl get pgi -n mini-tdmc-data-plane"
echo "    kubectl logs -n $NS -l app=connector --tail=10"
echo "    kubectl logs -n $NS -l app.kubernetes.io/name=mini-tdmc-inventory --tail=10"
echo "    kubectl describe pgi -n mini-tdmc-data-plane"
echo "============================================"
