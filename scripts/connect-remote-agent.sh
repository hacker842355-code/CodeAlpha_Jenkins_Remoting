#!/usr/bin/env bash
# Run on ANY remote machine with Java 17+ to attach it as a Remoting agent (no Docker needed).
# Usage: scripts/connect-remote-agent.sh <controller-url> <node-name> <secret>
# First create the node in Jenkins: Manage Jenkins > Nodes > New Node > Permanent Agent (launch method: Inbound).
set -euo pipefail
URL="${1:?controller url, e.g. https://jenkins.example.com}"; NAME="${2:?node name}"; SECRET="${3:?secret}"
WORK="${WORK_DIR:-$HOME/jenkins-agent}"
mkdir -p "$WORK" && cd "$WORK"
curl -fsSO "$URL/jnlpJars/agent.jar"
exec java -jar agent.jar -url "$URL/" -name "$NAME" -secret "$SECRET" -webSocket -workDir "$WORK"
