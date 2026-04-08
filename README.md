# Mini TDMC — Tanzu Data Management Console (Learning Project)

A simplified implementation of VMware Tanzu Data Management Console architecture, built as a learning exercise to understand cloud-native patterns: Kubernetes, Helm, Terraform, GraphQL schema stitching, event-driven architecture with RabbitMQ, Custom Resources, and observability with Prometheus/Grafana.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Local K8s Cluster (OrbStack)                                    │
│                                                                 │
│  CONTROL PLANE NAMESPACE                                        │
│  ┌─────────────────────┐                                        │
│  │  GraphQL Yoga        │  ← Schema stitching gateway            │
│  │  Gateway :4000       │    (@graphql-tools/stitch)             │
│  └──────────┬──────────┘                                        │
│             │ delegates                                         │
│             ▼                                                   │
│  ┌─────────────────────┐     ┌──────────────┐                   │
│  │ Inventory Service    │────▶│ RabbitMQ      │                   │
│  │ (Spring Boot) :4001  │     │ (event bus)   │                   │
│  │                      │     └──────┬───────┘                   │
│  │ - GraphQL API        │            │                           │
│  │ - Micrometer metrics │            │ consumed by               │
│  └─────────────────────┘            ▼                           │
│                              ┌──────────────────┐               │
│                              │ Connector App     │               │
│                              │ (Node.js)         │               │
│                              │                   │               │
│                              │ RabbitMQ listener  │               │
│                              │ → creates K8s CRs │               │
│                              └────────┬─────────┘               │
│                                       │                         │
│  DATA PLANE NAMESPACE                 │ creates                 │
│  ┌────────────────────────────────────▼──────────────────────┐  │
│  │  PostgresInstance Custom Resources                         │  │
│  │  (CRD: tdmc.tanzu.vmware.com/v1)                          │  │
│  │                                                            │  │
│  │  $ kubectl get pgi -n mini-tdmc-data-plane                 │  │
│  │  NAME           PHASE   SERVICE      PLAN    AGE           │  │
│  │  pgi-f7853e80           POSTGRESQL   large   13s           │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                 │
│  MONITORING NAMESPACE                                           │
│  ┌──────────────────────────────────────┐                       │
│  │ Prometheus + Grafana                  │                       │
│  │ (kube-prometheus-stack)               │                       │
│  │ ServiceMonitor → scrapes /actuator/prometheus                │
│  └──────────────────────────────────────┘                       │
│                                                                 │
│  Provisioned by: Terraform    Packaged as: Helm charts          │
└─────────────────────────────────────────────────────────────────┘
```

## How This Maps to Real TDMC

| Mini TDMC Component | Real TDMC Equivalent |
|---------------------|---------------------|
| GraphQL Yoga Gateway | Tanzu Hub GraphQL API |
| Inventory Service | TDMC Control Plane (stores intent) |
| RabbitMQ | RabbitMQ event bus (entry point for all task flows) |
| Connector App | Per-service Connector (Postgres Connector, RabbitMQ Connector) |
| PostgresInstance CRD | Tanzu Postgres Operator CRDs |
| Separate namespaces | Separate K8s clusters (control plane vs data plane) |
| kube-prometheus-stack | Built-in Prometheus/Grafana monitoring |
| Helm charts + Terraform | Infrastructure-as-Code for fleet deployment |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| API Gateway | GraphQL Yoga v5, @graphql-tools/stitch (Node.js) |
| Backend | Spring Boot 3.5, Spring GraphQL, Spring AMQP (Java 21) |
| Event Bus | RabbitMQ 3.13 (TopicExchange, routing keys) |
| Data Plane | Kubernetes Custom Resources (CRD), @kubernetes/client-node |
| Observability | Prometheus, Grafana, Micrometer, ServiceMonitor CRDs |
| Packaging | Helm v4, custom charts with Go templating |
| Infrastructure | Terraform (K8s provider + Helm provider) |
| Container Runtime | OrbStack (Docker + K8s on macOS) |

## Prerequisites

- macOS with [OrbStack](https://orbstack.dev) (Docker + Kubernetes)
- Helm v4: `brew install helm`
- Terraform: `brew tap hashicorp/tap && brew install hashicorp/tap/terraform`
- Java 21: `brew install openjdk@21`
- Node.js 22: `brew install node@22`

## Quick Start

### 1. Provision infrastructure with Terraform

```bash
cd terraform
terraform init
terraform apply
```

Creates namespaces (`mini-tdmc-control-plane`, `mini-tdmc-data-plane`) and deploys the Inventory Service Helm chart.

### 2. Deploy remaining services

```bash
# RabbitMQ
kubectl apply -f k8s/base/rabbitmq.yaml

# PostgresInstance CRD
kubectl apply -f k8s/crds/postgresinstance-crd.yaml

# Connector App (with RBAC)
kubectl apply -f k8s/base/connector.yaml

# GraphQL Gateway
kubectl apply -f k8s/base/gateway.yaml

# Observability
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# ServiceMonitor for Inventory Service
kubectl apply -f k8s/base/servicemonitor.yaml
```

### 3. Test the full E2E flow

```bash
# Create a PostgreSQL instance via the GraphQL Gateway
kubectl run curl-test --rm -it --image=curlimages/curl --restart=Never \
  -n mini-tdmc-control-plane -- curl -s -X POST \
  http://gateway.mini-tdmc-control-plane.svc.cluster.local:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { createInstance(input: {name: \"my-postgres\", serviceType: \"POSTGRESQL\", plan: \"large\"}) { id name status } }"}'

# Verify the Custom Resource was created in the data plane
kubectl get pgi -n mini-tdmc-data-plane
```

### 4. Access Grafana

```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
# Open http://localhost:3000 (admin / prom-operator)
```

## Event Flow

1. Client sends `createInstance` GraphQL mutation to **Gateway** (:4000)
2. Gateway delegates to **Inventory Service** (:4001) via schema stitching
3. Inventory Service saves intent and publishes event to **RabbitMQ** (`tdmc.tasks` exchange, `instance.create` routing key)
4. **Connector App** consumes the event from RabbitMQ queue
5. Connector creates a `PostgresInstance` **Custom Resource** in the data plane namespace
6. (In real TDMC: Operator would reconcile the CR and provision the actual database)

## Project Structure

```
mini-tdmc/
├── services/
│   ├── inventory-service/       # Java/Spring Boot — Control Plane API
│   ├── connector-app/           # Node.js — RabbitMQ → K8s CRs bridge
│   └── gateway/                 # Node.js — GraphQL Yoga stitching gateway
├── k8s/
│   ├── base/                    # K8s manifests (deployments, services, RBAC)
│   └── crds/                    # Custom Resource Definitions
├── helm/
│   └── mini-tdmc-inventory/     # Helm chart for Inventory Service
├── terraform/                   # IaC — provisions namespaces + Helm releases
└── docs/
    └── superpowers/specs/       # Design specification
```

## Key Concepts Demonstrated

- **Control Plane / Data Plane separation** — different namespaces (in production: separate clusters)
- **Event-driven architecture** — RabbitMQ with TopicExchange and routing keys
- **GraphQL schema stitching** — gateway-driven composition (no downstream modifications)
- **Kubernetes Operators & CRDs** — extending K8s with custom resource types
- **RBAC** — ServiceAccount + ClusterRole for Connector's K8s API access
- **Observability** — Micrometer → Prometheus → Grafana pipeline with ServiceMonitor CRDs
- **Infrastructure as Code** — Terraform for provisioning, Helm for application packaging
- **Air-gapped deployment** — `helm package` + `docker save/load` workflow
- **Chaos debugging** — OOMKilled, ImagePullBackOff, CrashLoopBackOff diagnosis

## Author

Dan Goriaynov — built as interview preparation for Tanzu Division Senior SWE role.
