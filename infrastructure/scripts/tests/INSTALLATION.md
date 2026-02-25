# BATS Installation and Test Execution Guide

## Quick Installation

To install BATS and run the property tests, execute these commands:

```bash
# Navigate to the tests directory
cd infrastructure/scripts/tests

# Create test helper directory
mkdir -p test_helper

# Clone BATS and helper libraries
git clone https://github.com/bats-core/bats-core.git test_helper/bats-core
git clone https://github.com/bats-core/bats-support.git test_helper/bats-support
git clone https://github.com/bats-core/bats-assert.git test_helper/bats-assert

# Make scripts executable
chmod +x setup-bats.sh property-idempotency.bats

# Run the property tests
./test_helper/bats-core/bin/bats property-idempotency.bats
```

## Alternative: Use the setup script

```bash
cd infrastructure/scripts/tests
bash setup-bats.sh
./test_helper/bats-core/bin/bats property-idempotency.bats
```

## Expected Output

When running the property tests, you should see output like:

```
 ✓ Property 7: Deployment idempotency - same configuration produces same state
 ✓ Property 7: Configuration file remains unchanged on re-run with same inputs
 ✓ Property 7: File permissions remain consistent across multiple deployments
 ✓ Property 7: State file correctly tracks installation mode across runs
 ✓ Property 7: Directory structure remains consistent across deployments

5 tests, 0 failures
```

## Test Details

Each test runs multiple iterations (10-30) with randomly generated valid configurations to verify the idempotency property holds across different inputs.

### Test Coverage

1. **Same configuration produces same state** (10 iterations)
   - Runs deployment 3 times with same config
   - Captures full system state after each run
   - Verifies all states are identical

2. **Configuration file remains unchanged** (20 iterations)
   - Verifies config file content doesn't change on re-runs
   - Uses MD5 hashing to detect any changes

3. **File permissions remain consistent** (20 iterations)
   - Verifies config file always has 600 permissions
   - Verifies config directory always has 700 permissions

4. **State file tracks installation mode** (30 iterations)
   - Verifies state file is created on fresh install
   - Verifies state file persists across updates
   - Verifies state file contains required fields

5. **Directory structure remains consistent** (20 iterations)
   - Verifies same files are created every time
   - Verifies directory structure doesn't change

## Running Specific Tests

To run a specific test by name:

```bash
./test_helper/bats-core/bin/bats property-idempotency.bats -f "Configuration file"
```

## Verbose Output

For detailed output showing each assertion:

```bash
./test_helper/bats-core/bin/bats property-idempotency.bats --verbose-run
```

## Troubleshooting

### Git not installed

If git is not available, you can download the repositories manually:
- https://github.com/bats-core/bats-core
- https://github.com/bats-core/bats-support
- https://github.com/bats-core/bats-assert

Extract them into the `test_helper/` directory.

### OpenSSL not available

The tests use `openssl rand -hex 16` to generate random test data. If openssl is not available, you can modify the `generate_valid_config()` function to use `/dev/urandom` or another random source.

### Permission errors

Make sure you have write permissions to `/tmp` directory, as the tests create temporary files there.
