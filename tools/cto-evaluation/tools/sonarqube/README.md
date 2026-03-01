# SonarQube Configuration

This directory contains SonarQube configuration files for enhanced code analysis.

## Setup

### Local SonarQube Server

```bash
# Using Docker
docker run -d --name sonarqube -p 9000:9000 sonarqube:community

# Or using docker-compose
docker-compose -f tools/docker/docker-compose.yml --profile full up -d sonarqube
```

### Configure Environment

```bash
export SONARQUBE_URL=http://localhost:9000
export SONARQUBE_TOKEN=your_token_here
```

## Files

- `sonar-project.properties` - Default project configuration template

## Integration

The evaluation suite automatically detects and uses SonarQube if:

1. `SONARQUBE_URL` environment variable is set
2. SonarQube server is reachable
3. `SONARQUBE_TOKEN` is provided

## Quality Gates

SonarQube results contribute to the following evaluation categories:

- Code Quality
- Security
- Maintainability
- Technical Debt
