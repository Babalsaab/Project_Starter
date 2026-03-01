# Contributing to CTO Codebase Evaluation Suite

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or suggest features
- Check existing issues before creating a new one
- Provide detailed information including OS, error messages, and steps to reproduce

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes on multiple platforms if possible
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Guidelines

#### Adding New Evaluation Categories

1. Create a new script in `scripts/` following the naming convention `XX-category-name.sh`
2. The script should accept two arguments: `$1` = codebase path, `$2` = output file
3. Output JSON with this structure:
   ```json
   {
     "category": "category_name",
     "score": 7.5,
     "findings": [],
     "metrics": {}
   }
   ```
4. Add the category to `run-full-evaluation.sh`
5. Add thresholds to `config/thresholds.yaml`

#### Code Style

- Use consistent indentation (2 spaces for YAML, 4 spaces for bash)
- Add comments for complex logic
- Keep functions focused and single-purpose

### Testing

Before submitting:

1. Test on your target OS
2. Run against a sample codebase
3. Verify the generated reports are correct

## Questions?

Open an issue with the "question" label.
