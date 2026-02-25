# Deployment Script Property-Based Tests

This directory contains property-based tests for the Quick Start Deployment script using BATS (Bash Automated Testing System).

## Overview

Property-based tests verify that universal properties hold true across many different inputs and scenarios. Unlike unit tests that check specific examples, property tests generate random inputs and verify that certain invariants always hold.

## Test Files

- `property-idempotency.bats` - Tests for deployment idempotency (Property 7)
- `setup-bats.sh` - Script to install BATS and its helper libraries

## Setup

Before running the tests, you need to install BATS and its dependencies:

```bash
cd infrastructure/scripts/tests
bash setup-bats.sh
```

This will clone the following repositories into `test_helper/`:
- `bats-core` - The BATS test framework
- `bats-support` - Helper functions for BATS tests
- `bats-assert` - Assertion functions for BATS tests

## Running Tests

### Run all property tests

```bash
./test_helper/bats-core/bin/bats property-idempotency.bats
```

### Run a specific test

```bash
./test_helper/bats-core/bin/bats property-idempotency.bats -f "Configuration file remains unchanged"
```

### Run with verbose output

```bash
./test_helper/bats-core/bin/bats property-idempotency.bats --verbose-run
```

## Property Tests

### Property 7: Deployment Idempotency

**Validates: Requirements 8.1, 8.2, 8.3, 8.5**

This property verifies that executing the deployment script multiple times with the same configuration produces the same end state:
- Same services running
- Same configuration values stored
- Same files present
- Same file permissions

The test includes multiple sub-properties:

1. **Same configuration produces same state** - Verifies that running deployment 2-3 times produces identical system states
2. **Configuration file remains unchanged** - Verifies config file content doesn't change on re-runs
3. **File permissions remain consistent** - Verifies permissions are set correctly every time (600 for config, 700 for directory)
4. **State file tracks installation mode** - Verifies state file is created and maintained correctly
5. **Directory structure remains consistent** - Verifies the same files and directories are created every time

## Test Configuration

- **Iterations**: Each test runs multiple iterations (10-30) to verify the property holds across different inputs
- **Test isolation**: Each iteration uses a fresh test environment
- **Mock execution**: Tests use mock deployment execution to avoid requiring full system setup

## Notes

- Tests use mock deployment execution to avoid requiring full Ubuntu VM setup
- Tests verify the core idempotency properties without actually installing services
- For full integration testing, see the integration test suite (to be implemented)
- Property tests are designed to run quickly while still providing strong correctness guarantees

## Troubleshooting

### BATS not found

If you get "command not found" errors, make sure you've run `setup-bats.sh` first.

### Permission denied

Make sure the test scripts are executable:

```bash
chmod +x setup-bats.sh property-idempotency.bats
```

### Test failures

Check the test output for specific failure messages. Each test includes detailed error messages indicating which iteration failed and why.
