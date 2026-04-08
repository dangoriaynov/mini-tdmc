#!/bin/bash
echo "============================================"
echo "  Mini TDMC — Teardown"
echo "============================================"
echo ""

echo "Stopping port-forwards..."
pkill -f "port-forward.*monitoring-grafana" 2>/dev/null || true
pkill -f "port-forward.*svc/rabbitmq" 2>/dev/null || true
pkill -f "port-forward.*svc/gateway" 2>/dev/null || true

echo "Removing observability stack..."
helm uninstall monitoring -n monitoring 2>/dev/null || true
kubectl delete namespace monitoring 2>/dev/null || true

echo "Removing application services..."
kubectl delete -f k8s/base/gateway.yaml 2>/dev/null || true
kubectl delete -f k8s/base/connector.yaml 2>/dev/null || true
kubectl delete -f k8s/base/rabbitmq.yaml 2>/dev/null || true
kubectl delete -f k8s/base/servicemonitor.yaml 2>/dev/null || true

echo "Removing Helm release..."
helm uninstall inventory -n mini-tdmc-control-plane 2>/dev/null || true

echo "Removing CRDs and CRs..."
kubectl delete postgresinstances --all -n mini-tdmc-data-plane 2>/dev/null || true
kubectl delete -f k8s/crds/postgresinstance-crd.yaml 2>/dev/null || true

echo "Destroying Terraform resources..."
cd terraform && terraform destroy -auto-approve 2>/dev/null || true
cd ..

echo ""
echo "============================================"
echo "  Teardown complete. Clean slate."
echo "============================================"
