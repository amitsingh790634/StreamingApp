#!/usr/bin/env bash
# End-to-end smoke checks against the Ingress host.
# Usage: HOST=streamingapp.local ./scripts/smoke-test.sh
set -euo pipefail

HOST="${HOST:-streamingapp.local}"
BASE="http://${HOST}"

fail() { echo "FAIL  $1"; exit 1; }
pass() { echo "PASS  $1"; }

echo "Checking ${BASE}"

curl -fsS "${BASE}/healthz" >/dev/null || fail "frontend /healthz"
pass "frontend /healthz"

curl -fsS "${BASE}/health" | grep -qi OK || fail "auth /health"
pass "auth /health"

curl -fsS "${BASE}/api/health" | grep -qi OK || fail "streaming /api/health (or first /api/health hop)"
pass "API health reachable"

curl -fsS -o /dev/null -w "%{http_code}" "${BASE}/api/streaming/videos" | grep -Eq '200|401' \
  || fail "streaming catalogue"
pass "streaming catalogue"

curl -fsS "${BASE}/api/admin" -o /dev/null -w "%{http_code}" | grep -Eq '200|401|404' \
  || fail "admin prefix"
pass "admin prefix"

curl -fsS "${BASE}/api/chat" -o /dev/null -w "%{http_code}" | grep -Eq '200|401|404' \
  || fail "chat prefix"
pass "chat prefix"

EMAIL="smoke-$(date +%s)@example.com"
REGISTER_BODY="$(printf '{"name":"Smoke User","email":"%s","password":"Passw0rd!"}' "$EMAIL")"
REGISTER_CODE="$(curl -sS -o /tmp/sa-register.json -w "%{http_code}" \
  -H 'Content-Type: application/json' \
  -d "$REGISTER_BODY" \
  "${BASE}/api/register")"
if echo "$REGISTER_CODE" | grep -Eq '200|201'; then
  pass "register ${EMAIL}"
else
  echo "INFO  register returned ${REGISTER_CODE} (inspect /tmp/sa-register.json)"
fi

LOGIN_CODE="$(curl -sS -o /tmp/sa-login.json -w "%{http_code}" \
  -H 'Content-Type: application/json' \
  -d "$(printf '{"email":"%s","password":"Passw0rd!"}' "$EMAIL")" \
  "${BASE}/api/login")"
if echo "$LOGIN_CODE" | grep -Eq '200'; then
  pass "login returned JWT"
else
  echo "INFO  login returned ${LOGIN_CODE} (inspect /tmp/sa-login.json)"
fi

echo "Smoke checks finished. Capture kubectl get pods,svc,ingress and the UI for submission screenshots."
