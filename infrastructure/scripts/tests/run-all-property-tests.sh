#!/bin/bash
################################################################################
# Run All Property Tests
#
# This script runs all property-based tests for the deployment script.
# It checks if BATS is installed and runs each property test file.
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS_BIN="$SCRIPT_DIR/test_helper/bats-core/bin/bats"

echo "Quick Start Deployment - All Property Tests"
echo "=============================================="
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

# List of property test files
PROPERTY_TESTS=(
    "property-config-validation.bats"
    "property-installation-mode.bats"
    "property-config-preservation.bats"
    "property-operation-logging.bats"
    "property-idempotency.bats"
    "property-credential-file-security.bats"
    "property-credential-logging-protection.bats"
    "property-credential-display-masking.bats"
    "property-qr-code-persistence.bats"
    "property-safe-resumption.bats"
    "property-error-remediation.bats"
)

# Track results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Run each property test
for test_file in "${PROPERTY_TESTS[@]}"; do
    if [ -f "$SCRIPT_DIR/$test_file" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Running: $test_file"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        if "$BATS_BIN" "$SCRIPT_DIR/$test_file"; then
            echo ""
            echo "✓ $test_file PASSED"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo ""
            echo "❌ $test_file FAILED"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
        
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        echo ""
    else
        echo "⚠ Skipping $test_file (file not found)"
        echo ""
    fi
done

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total test files: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✓ All property tests passed!"
    exit 0
else
    echo "❌ Some property tests failed. See output above for details."
    exit 1
fi
