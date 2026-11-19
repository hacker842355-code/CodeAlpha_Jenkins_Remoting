# Inbound (agent-initiated) Jenkins Remoting agent. Runs as non-root user "jenkins".
FROM jenkins/inbound-agent:3283.v92c105e0f819-1-jdk17
USER root
RUN apt-get update && apt-get install -y --no-install-recommends git curl \
    && rm -rf /var/lib/apt/lists/*
USER jenkins
