#!/usr/bin/env bash
# Create the five public Docker Hub repositories so hub.docker.com/r/<user>/<name> does not 404.
# Usage:
#   export DOCKERHUB_USER=amitsingh790634
#   export DOCKERHUB_TOKEN=dckr_pat_...
#   ./scripts/create-dockerhub-repos.sh
set -euo pipefail

USER_NAME="${DOCKERHUB_USER:-amitsingh790634}"
TOKEN="${DOCKERHUB_TOKEN:-}"

if [ -z "$TOKEN" ]; then
  echo "Set DOCKERHUB_TOKEN to a Docker Hub Personal Access Token (Read, Write, Delete)."
  echo "Create one at: https://app.docker.com/settings/personal-access-tokens"
  exit 1
fi

LOGIN_JSON="$(curl -sS -X POST https://hub.docker.com/v2/users/login \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"${USER_NAME}\",\"password\":\"${TOKEN}\"}")"

JWT="$(printf '%s' "$LOGIN_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("token",""))')"
if [ -z "$JWT" ]; then
  echo "Docker Hub login failed:"
  echo "$LOGIN_JSON"
  exit 1
fi

create_repo() {
  local name="$1"
  local desc="$2"
  local resp code
  resp="$(curl -sS -w '\n%{http_code}' -X POST "https://hub.docker.com/v2/repositories/" \
    -H "Authorization: Bearer ${JWT}" \
    -H "Content-Type: application/json" \
    -d "{\"namespace\":\"${USER_NAME}\",\"name\":\"${name}\",\"description\":\"${desc}\",\"is_private\":false}")"
  code="$(printf '%s' "$resp" | tail -n1)"
  body="$(printf '%s' "$resp" | sed '$d')"
  if [ "$code" = "201" ] || [ "$code" = "200" ]; then
    echo "created  https://hub.docker.com/r/${USER_NAME}/${name}"
  elif echo "$body" | grep -qi 'already exists'; then
    echo "exists   https://hub.docker.com/r/${USER_NAME}/${name}"
  else
    echo "status ${code} for ${name}: ${body}"
  fi
}

create_repo streaming-auth "StreamingApp auth service (JWT, register, login)"
create_repo streaming-stream "StreamingApp catalogue and playback API"
create_repo streaming-admin "StreamingApp admin uploads and curation"
create_repo streaming-chat "StreamingApp Socket.IO + REST chat"
create_repo streaming-frontend "StreamingApp React SPA served by Nginx"
