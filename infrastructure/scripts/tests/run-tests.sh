#!/bin/bash
################################################################################
# Test Runner Script
#
# This script checks if BATS is installed and runs the property tests.
# If BATS is not installed, it provides installation instructions.
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS_BIN="$SCRIPT_DIR/test_helper/bats-core/bin/bats"

echo "Quick Start Deployment - Property Test Runner"
echo "=============================================="
echo ""

# Check if BATS is installed
if [ ! -f "$BATS_BIN" ]; then
    echo "❌ BATS is not installed."
    echo ""
    echo "To install BATS, run:"
    echo "  bash $SCRIPT_DIR/setup-bats.sh"
    echo ""
    echo "Or install manually:"
    echo "  cd $SCRIPT_DIR"
    echo "  mkdir -p test_helper"
    echo "  git clone https://github.com/bats-core/bats-core.git test_helper/bats-core"
    echo "  git clone https://github.com/bats-core/bats-support.git test_helper/bats-support"
    echo "  git clone https://github.com/bats-core/bats-assert.git test_helper/bats-assert"
    echo ""
    exit 1
fi

echo "✓ BATS is installed"
echo ""

# Run the property tests
echo "Running property-based tests for deployment idempotency..."
echo ""

"$BATS_BIN" "$SCRIPT_DIR/property-idempotency.bats" "$@"

exit_code=$?

echo ""
if [ $exit_code -eq 0 ]; then
    echo "✓ All property tests passed!"
else
    echo "❌ Some property tests failed. See output above for details."
fi

exit $exit_code
