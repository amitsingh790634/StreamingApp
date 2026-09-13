#!/usr/bin/env bash
# Provision an Amazon EKS cluster with eksctl.
# Usage: ./scripts/create-eks-cluster.sh [cluster-name]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${1:-streamingapp-eks}"
REGION="${AWS_REGION:-ap-south-1}"

eksctl create cluster -f "${ROOT}/infra/eks-cluster.yaml" \
  --name "$CLUSTER_NAME" \
  --region "$REGION"

aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

echo "Installing ingress-nginx..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/aws/deploy.yaml
kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=180s

echo "Cluster ${CLUSTER_NAME} is ready. Next: ./scripts/deploy.sh"
