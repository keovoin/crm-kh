FROM gitpod/workspace-full

# Install Node 24 via nvm (required by Twenty CRM)
RUN bash -c ". /home/gitpod/.nvm/nvm.sh && nvm install 24 && nvm alias default 24"

# Enable Corepack for Yarn 4
RUN bash -c ". /home/gitpod/.nvm/nvm.sh && corepack enable"

# Install Docker Compose (for Postgres + Redis)
RUN sudo apt-get update && sudo apt-get install -y \
    docker-compose-plugin \
    postgresql-client \
    && sudo rm -rf /var/lib/apt/lists/*
