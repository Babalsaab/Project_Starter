# Tests Directory

This directory contains tests for the CTO Evaluation Suite.

## Running Tests

```bash
# Run all tests
./tests/run-tests.sh

# Run with verbose output
./tests/run-tests.sh --verbose
```

## Test Structure

- `run-tests.sh` - Main test runner script
- `unit/` - Unit tests for individual scripts
- `integration/` - Integration tests for full evaluation workflow

## Adding New Tests

1. Create a test script in the appropriate directory
2. Make it executable: `chmod +x tests/your-test.sh`
3. Test scripts should exit with:
   - `0` on success
   - `1` on failure
   - Test output should go to stdout/stderr

## CI Integration

Tests are automatically run in the CI pipeline via GitHub Actions.
See `.github/workflows/ci.yml` for details.
