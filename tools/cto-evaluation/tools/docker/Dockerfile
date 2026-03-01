# =============================================================================
# CTO Evaluation Suite - Dockerfile
# =============================================================================
# Build: docker build -t cto-evaluation-suite -f tools/docker/Dockerfile .
# Run:   docker run -v /path/to/codebase:/codebase cto-evaluation-suite /codebase
# =============================================================================

FROM ubuntu:22.04

LABEL maintainer="CTO Evaluation Suite"
LABEL version="1.0.0"
LABEL description="Comprehensive codebase evaluation framework"

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    git \
    jq \
    cloc \
    shellcheck \
    python3 \
    python3-pip \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install Python tools
RUN pip3 install --no-cache-dir \
    ruff \
    bandit \
    safety

# Install Node.js tools
RUN npm install -g \
    eslint \
    @typescript-eslint/parser \
    @typescript-eslint/eslint-plugin

# Create working directory
WORKDIR /app

# Copy evaluation suite
COPY . /app/

# Make scripts executable
RUN chmod +x /app/evaluate /app/scripts/*.sh

# Set entrypoint
ENTRYPOINT ["/app/evaluate"]

# Default command (show help)
CMD ["--help"]
