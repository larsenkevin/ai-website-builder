#!/bin/bash
################################################################################
# BATS Test Framework Setup Script
#
# This script installs BATS (Bash Automated Testing System) and its helper
# libraries for property-based testing of the deployment script.
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_HELPER_DIR="$SCRIPT_DIR/test_helper"

echo "Setting up BATS test framework..."

# Create test helper directory
mkdir -p "$TEST_HELPER_DIR"

# Install bats-core
if [ ! -d "$TEST_HELPER_DIR/bats-core" ]; then
    echo "Installing bats-core..."
    git clone https://github.com/bats-core/bats-core.git "$TEST_HELPER_DIR/bats-core"
else
    echo "bats-core already installed"
fi

# Install bats-support
if [ ! -d "$TEST_HELPER_DIR/bats-support" ]; then
    echo "Installing bats-support..."
    git clone https://github.com/bats-core/bats-support.git "$TEST_HELPER_DIR/bats-support"
else
    echo "bats-support already installed"
fi

# Install bats-assert
if [ ! -d "$TEST_HELPER_DIR/bats-assert" ]; then
    echo "Installing bats-assert..."
    git clone https://github.com/bats-core/bats-assert.git "$TEST_HELPER_DIR/bats-assert"
else
    echo "bats-assert already installed"
fi

echo ""
echo "BATS test framework setup complete!"
echo ""
echo "To run the property tests:"
echo "  $TEST_HELPER_DIR/bats-core/bin/bats $SCRIPT_DIR/property-idempotency.bats"
echo ""
