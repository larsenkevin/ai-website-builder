#!/bin/bash
################################################################################
# Run Property Test: Safe Resumption After Partial Failure
#
# This script runs the property-based test for safe resumption after failure.
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS_BIN="$SCRIPT_DIR/test_helper/bats-core/bin/bats"

echo "Property Test: Safe Resumption After Partial Failure"
echo "======================================================"
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

# Run the property test
echo "Running property-safe-resumption.bats..."
echo ""

if "$BATS_BIN" "$SCRIPT_DIR/property-safe-resumption.bats"; then
    echo ""
    echo "✓ Property test PASSED"
    exit 0
else
    echo ""
    echo "❌ Property test FAILED"
    exit 1
fi
