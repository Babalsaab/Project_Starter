# Docker Configuration for CTO Evaluation Suite

This directory contains Docker-related configurations for running the evaluation suite in containers.

## Files

- `Dockerfile` - Main Dockerfile for building the evaluation suite image
- `docker-compose.yml` - Compose file for running with dependencies

## Usage

### Build the image

```bash
docker build -t cto-evaluation-suite -f tools/docker/Dockerfile .
```

### Run evaluation in container

```bash
docker run -v /path/to/codebase:/codebase cto-evaluation-suite /codebase
```

### Using docker-compose

```bash
docker-compose -f tools/docker/docker-compose.yml run evaluate /codebase
```
