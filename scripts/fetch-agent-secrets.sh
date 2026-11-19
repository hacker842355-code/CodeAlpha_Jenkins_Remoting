#!/usr/bin/env bash
# Reads each agent's connection secret from the running controller and writes it to .env
# Run from the project folder after: docker compose up -d --build   (controller only)
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] || { echo ".env missing: cp .env.example .env"; exit 1; }
set -a; . ./.env; set +a
URL="${JENKINS_URL:-http://localhost:8080}"
echo "Waiting for controller at $URL ..."
for i in $(seq 1 60); do
  [ "$(curl -s -o /dev/null -w '%{http_code}' -u "admin:$JENKINS_ADMIN_PASSWORD" "$URL/api/json" || true)" = "200" ] && break
  sleep 5
done
for pair in "agent-amd64:AGENT_AMD64_SECRET" "agent-arm64:AGENT_ARM64_SECRET"; do
  node="${pair%%:*}"; var="${pair##*:}"
  secret=$(curl -fsS -u "admin:$JENKINS_ADMIN_PASSWORD" "$URL/computer/$node/jenkins-agent.jnlp" \
           | tr -d '\n\r' | grep -o '<argument>[0-9a-f]\{64\}</argument>' | head -n1 | sed 's:</\?argument>::g')
  [ -n "$secret" ] || { echo "Could not read secret for $node"; exit 1; }
  if grep -q "^$var=" .env; then sed -i.bak "s/^$var=.*/$var=$secret/" .env && rm -f .env.bak; else echo "$var=$secret" >> .env; fi
  echo "stored $var"
done
echo "Now run: docker compose --profile agents up -d --build"
