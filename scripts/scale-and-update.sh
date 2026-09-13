#!/usr/bin/env bash
# Demonstrate replica scaling and a zero-downtime rolling update.
# Usage: ./scripts/scale-and-update.sh
set -euo pipefail

NAMESPACE="${1:-streamingapp}"
RELEASE="${2:-streamingapp}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Scale streaming to 4 replicas"
kubectl -n "$NAMESPACE" scale deploy/streaming --replicas=4
kubectl -n "$NAMESPACE" rollout status deploy/streaming --timeout=180s
kubectl -n "$NAMESPACE" get deploy/streaming

echo "==> Rolling update auth (maxUnavailable=0, maxSurge=1)"
helm upgrade "$RELEASE" "${ROOT}/helm/streamingapp" \
  --namespace "$NAMESPACE" \
  --reuse-values \
  --set services.auth.tag=1.0.0 \
  --wait
kubectl -n "$NAMESPACE" rollout status deploy/auth --timeout=180s

echo "==> Self-heal check — delete one auth pod"
POD="$(kubectl -n "$NAMESPACE" get pods -l app.kubernetes.io/component=auth -o jsonpath='{.items[0].metadata.name}')"
kubectl -n "$NAMESPACE" delete pod "$POD"
kubectl -n "$NAMESPACE" rollout status deploy/auth --timeout=180s
kubectl -n "$NAMESPACE" get pods -l app.kubernetes.io/component=auth
echo "Scale, update, and self-heal completed."
