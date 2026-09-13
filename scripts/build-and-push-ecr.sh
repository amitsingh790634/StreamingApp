#!/usr/bin/env bash
# Build every service image and push it to its dedicated ECR repository.
# Usage: AWS_REGION=ap-south-1 TAG=1.0.0 ./scripts/build-and-push-ecr.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGION="${AWS_REGION:-ap-south-1}"
TAG="${TAG:-1.0.0}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

push_one() {
  local repo="$1"
  shift
  docker build -t "${REGISTRY}/${repo}:${TAG}" "$@"
  docker push "${REGISTRY}/${repo}:${TAG}"
}

push_one streaming-auth "${ROOT}/backend/authService"
push_one streaming-stream -f "${ROOT}/backend/streamingService/Dockerfile" "${ROOT}/backend"
push_one streaming-admin -f "${ROOT}/backend/adminService/Dockerfile" "${ROOT}/backend"
push_one streaming-chat -f "${ROOT}/backend/chatService/Dockerfile" "${ROOT}/backend"
push_one streaming-frontend \
  --build-arg REACT_APP_AUTH_API_URL=http://streamingapp.local/api \
  --build-arg REACT_APP_STREAMING_API_URL=http://streamingapp.local/api \
  --build-arg REACT_APP_STREAMING_PUBLIC_URL=http://streamingapp.local \
  --build-arg REACT_APP_ADMIN_API_URL=http://streamingapp.local/api/admin \
  --build-arg REACT_APP_CHAT_API_URL=http://streamingapp.local/api/chat \
  --build-arg REACT_APP_CHAT_SOCKET_URL=http://streamingapp.local \
  "${ROOT}/frontend"

echo "Pushed images to ${REGISTRY} with tag ${TAG}"
