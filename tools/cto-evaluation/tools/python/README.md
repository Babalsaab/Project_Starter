# Python Tools Configuration

This directory contains configurations for Python analysis tools.

## Tools Used

- **Ruff** - Fast Python linter and formatter
- **Bandit** - Security linter for Python
- **Safety** - Dependency vulnerability checker

## Configuration

Python tool configurations are centralized in `/pyproject.toml` at the project root.

## Usage

### Lint Python files

```bash
ruff check .
```

### Format Python files

```bash
ruff format .
```

### Security scan

```bash
bandit -r . -c tools/python/bandit.yaml
```

### Check dependencies

```bash
safety check
```
