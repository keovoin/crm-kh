FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 24 via nvm
ENV NVM_DIR=/usr/local/nvm
RUN mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install 24 \
    && nvm alias default 24 \
    && corepack enable \
    && BIN_DIR=$(dirname $(nvm which default)) \
    && ln -sf $BIN_DIR/node /usr/local/bin/node \
    && ln -sf $BIN_DIR/npm /usr/local/bin/npm \
    && ln -sf $BIN_DIR/npx /usr/local/bin/npx \
    && ln -sf $BIN_DIR/corepack /usr/local/bin/corepack

# Make yarn available globally
RUN corepack enable && corepack prepare yarn@4.13.0 --activate || true
