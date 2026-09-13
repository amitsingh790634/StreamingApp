#!/usr/bin/env bash
# Build all five StreamingApp images and push them to Docker Hub.
# Usage: DOCKERHUB_USER=amitsingh790634 TAG=1.0.0 ./scripts/build-and-push.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USER_NAME="${DOCKERHUB_USER:-amitsingh790634}"
TAG="${TAG:-1.0.0}"

build() {
  local name="$1"
  shift
  echo "==> Building ${USER_NAME}/${name}:${TAG}"
  docker build -t "${USER_NAME}/${name}:${TAG}" "$@"
  docker push "${USER_NAME}/${name}:${TAG}"
}

build streaming-auth "${ROOT}/backend/authService"
build streaming-stream -f "${ROOT}/backend/streamingService/Dockerfile" "${ROOT}/backend"
build streaming-admin -f "${ROOT}/backend/adminService/Dockerfile" "${ROOT}/backend"
build streaming-chat -f "${ROOT}/backend/chatService/Dockerfile" "${ROOT}/backend"
build streaming-frontend \
  --build-arg REACT_APP_AUTH_API_URL=http://streamingapp.local/api \
  --build-arg REACT_APP_STREAMING_API_URL=http://streamingapp.local/api \
  --build-arg REACT_APP_STREAMING_PUBLIC_URL=http://streamingapp.local \
  --build-arg REACT_APP_ADMIN_API_URL=http://streamingapp.local/api/admin \
  --build-arg REACT_APP_CHAT_API_URL=http://streamingapp.local/api/chat \
  --build-arg REACT_APP_CHAT_SOCKET_URL=http://streamingapp.local \
  "${ROOT}/frontend"

echo "Pushed:"
echo "  https://hub.docker.com/r/${USER_NAME}/streaming-auth"
echo "  https://hub.docker.com/r/${USER_NAME}/streaming-stream"
echo "  https://hub.docker.com/r/${USER_NAME}/streaming-admin"
echo "  https://hub.docker.com/r/${USER_NAME}/streaming-chat"
echo "  https://hub.docker.com/r/${USER_NAME}/streaming-frontend"
