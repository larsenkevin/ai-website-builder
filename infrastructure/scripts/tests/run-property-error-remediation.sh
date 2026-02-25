#!/bin/bash
################################################################################
# Run Property Test: Error Remediation Guidance
#
# This script runs the property-based test for error remediation guidance.
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS_BIN="$SCRIPT_DIR/test_helper/bats-core/bin/bats"
TEST_FILE="$SCRIPT_DIR/property-error-remediation.bats"

echo "Property Test: Error Remediation Guidance"
echo "=========================================="
echo ""

# Check if BATS is installed
if [ ! -f "$BATS_BIN" ]; then
    echo "❌ BATS is not installed."
    echo ""
    echo "To install BATS, run:"
    echo "  bash $SCRIPT_DIR/setup-bats.sh"
    echo ""
    exit 1
fi

echo "✓ BATS is installed"
echo ""

# Check if test file exists
if [ ! -f "$TEST_FILE" ]; then
    echo "❌ Test file not found: $TEST_FILE"
    exit 1
fi

echo "✓ Test file found"
echo ""

# Run the test
echo "Running property test..."
echo ""

if "$BATS_BIN" "$TEST_FILE"; then
    echo ""
    echo "✓ All tests PASSED"
    exit 0
else
    echo ""
    echo "❌ Some tests FAILED"
    exit 1
fi
