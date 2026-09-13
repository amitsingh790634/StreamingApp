#!/usr/bin/env bash
# Install or upgrade StreamingApp with Helm.
# Usage: ./scripts/deploy.sh [namespace] [release]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="${1:-streamingapp}"
RELEASE="${2:-streamingapp}"
VALUES_FILE="${VALUES_FILE:-${ROOT}/helm/streamingapp/values.yaml}"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

helm upgrade --install "$RELEASE" "${ROOT}/helm/streamingapp" \
  --namespace "$NAMESPACE" \
  --values "$VALUES_FILE" \
  --wait \
  --timeout 8m

kubectl -n "$NAMESPACE" get pods,svc,ingress
echo "Deployed ${RELEASE} in ${NAMESPACE}."
echo "Add the Ingress host to /etc/hosts if you are on Kind/Minikube, then open http://streamingapp.local"
