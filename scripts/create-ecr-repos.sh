#!/usr/bin/env bash
# Create one Amazon ECR repository per StreamingApp component.
# Usage: AWS_REGION=ap-south-1 ./scripts/create-ecr-repos.sh
set -euo pipefail

REGION="${AWS_REGION:-ap-south-1}"
REPOS=(streaming-auth streaming-stream streaming-admin streaming-chat streaming-frontend)

for repo in "${REPOS[@]}"; do
  if aws ecr describe-repositories --repository-names "$repo" --region "$REGION" >/dev/null 2>&1; then
    echo "exists  $repo"
  else
    aws ecr create-repository \
      --repository-name "$repo" \
      --image-scanning-configuration scanOnPush=true \
      --region "$REGION"
    echo "created $repo"
  fi
done

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
echo "Registry: ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
