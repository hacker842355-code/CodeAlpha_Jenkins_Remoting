# CodeAlpha_Jenkins_Remoting — Task 2: Jenkins Remoting Project

A Jenkins **controller** that runs no builds, plus **Remoting agents** (amd64 and arm64) that connect to it and execute jobs. Everything is configured as code (JCasC + Job DSL) and runs with Docker Compose; the same agent can also run on any remote machine with only Java.

## Task requirements → where they are met
| Requirement | Implementation |
|---|---|
| Set up Jenkins Remoting to connect remote nodes | Inbound agents over WebSocket (`jenkins/inbound-agent`), `scripts/connect-remote-agent.sh` for real remote hosts |
| Distribute build load across machines securely | Pipeline runs stages in parallel on different agents; `-webSocket` over the controller's HTTP(S) port, secret per node, login required |
| Run jobs on various architectures | Labels `amd64` / `arm64`; `Jenkinsfile` runs both in parallel and prints `uname -m` |
| Improve security with node isolation | Controller `numExecutors: 0`; nodes in `EXCLUSIVE` mode; agents non-root with `cap_drop: ALL`, `no-new-privileges`, no Docker socket or shared volumes; TCP agent port disabled; agent-to-controller access control on; anonymous read off |
| Hands-on remote execution | Parallel demo job `remoting-demo` + artifacts per architecture |

## Architecture
```
Browser ──8080──> [ controller ]  <──WebSocket── [ agent-amd64 ]   labels: linux amd64
                  0 executors     <──WebSocket── [ agent-arm64 ]   labels: linux arm64
                                  <──WebSocket── [ any remote host: java -jar agent.jar ]
```

## Prerequisites
Docker Engine + Compose v2 (for the local demo). For arm64 on an x86 host: QEMU emulation (`docker run --privileged --rm tonistiigi/binfmt --install arm64`). Real remote host: Java 17+.

## Run (from this folder)
```bash
cp .env.example .env                       # set JENKINS_ADMIN_PASSWORD (long, random)
docker compose up -d --build               # 1. controller only
./scripts/fetch-agent-secrets.sh           # 2. reads node secrets from the controller into .env
docker compose --profile agents up -d --build   # 3. start both agents
```
Open http://localhost:8080 (user `admin`, your password). **Manage Jenkins → Nodes**: both agents should be online. Run job **remoting-demo**; the console shows `node=agent-amd64 arch=x86_64` and `node=agent-arm64 arch=aarch64`.

### Connect a real remote machine
1. Add a node in the UI (or in `jenkins.yaml`) with launch method **Inbound**, copy its secret.
2. On the remote host: `./scripts/connect-remote-agent.sh https://<controller-url> <node-name> <secret>`.
3. For anything beyond localhost, put the controller behind HTTPS (reverse proxy) and set the correct Jenkins URL.

### Use your own repo
Create a *Pipeline* job → "Pipeline script from SCM" → repo `CodeAlpha_Jenkins_Remoting` → `Jenkinsfile`.

## Security notes
- Change the admin password; never commit `.env`.
- `authorizationStrategy` is simple (any logged-in user is admin). For teams, add the Matrix Authorization plugin.
- Builds on agents can't reach controller files (Agent → Controller Security is enabled).
- Agents are untrusted-by-design: don't give them the Docker socket or credentials they don't need.

## Troubleshooting
| Symptom | Fix |
|---|---|
| Agents offline, log says `403` / `Invalid secret` | Re-run `fetch-agent-secrets.sh`, then `docker compose --profile agents up -d --force-recreate` |
| arm64 agent: `exec format error` | Install QEMU binfmt (see prerequisites) |
| Job stays "waiting for executor" | Label mismatch: nodes are EXCLUSIVE, so stages must request `amd64`/`arm64` |
| Plugin download fails during build | Check internet/proxy; pin or update versions in `controller/plugins.txt` |
| `fetch-agent-secrets.sh` can't read secret | Wait for "Jenkins is fully up", confirm admin password, check `docker logs jenkins-controller` for JCasC errors |

## Known limitations
Not run in the authoring environment (no Docker/network): JCasC keys, plugin versions and the secret-fetch script are written from documentation and need a first live run. Single local network; no TLS; no matrix authorization.
