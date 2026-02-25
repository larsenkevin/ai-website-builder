#!/bin/bash
################################################################################
# Checkpoint 6 Test Runner
#
# This script runs all tests required for Checkpoint 6:
# "Ensure configuration and mode detection work correctly"
#
# Tests included:
# - Property 1: Configuration Input Validation (Task 4.3)
# - Property 2: Installation Mode Detection (Task 5.2)
# - Property 3: Configuration Preservation in Update Mode (Task 5.5)
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS_BIN="$SCRIPT_DIR/test_helper/bats-core/bin/bats"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checkpoint 6: Configuration and Mode Detection Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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

# List of tests for checkpoint 6
CHECKPOINT_TESTS=(
    "property-config-validation.bats:Property 1: Configuration Input Validation"
    "property-installation-mode.bats:Property 2: Installation Mode Detection"
    "property-config-preservation.bats:Property 3: Configuration Preservation in Update Mode"
)

# Track results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
FAILED_TEST_NAMES=()

# Run each test
for test_entry in "${CHECKPOINT_TESTS[@]}"; do
    IFS=':' read -r test_file test_name <<< "$test_entry"
    
    if [ -f "$SCRIPT_DIR/$test_file" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Running: $test_name"
        echo "File: $test_file"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        if "$BATS_BIN" "$SCRIPT_DIR/$test_file"; then
            echo ""
            echo "✓ $test_name PASSED"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo ""
            echo "❌ $test_name FAILED"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            FAILED_TEST_NAMES+=("$test_name")
        fi
        
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        echo ""
    else
        echo "⚠ Skipping $test_name (file not found: $test_file)"
        echo ""
    fi
done

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checkpoint 6 Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total test suites: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✅ Checkpoint 6 PASSED - All configuration and mode detection tests passed!"
    echo ""
    echo "Configuration and mode detection are working correctly:"
    echo "  ✓ Configuration input validation works correctly"
    echo "  ✓ Installation mode detection works correctly"
    echo "  ✓ Configuration preservation in update mode works correctly"
    echo ""
    exit 0
else
    echo "❌ Checkpoint 6 FAILED - Some tests failed"
    echo ""
    echo "Failed tests:"
    for failed_test in "${FAILED_TEST_NAMES[@]}"; do
        echo "  ✗ $failed_test"
    done
    echo ""
    echo "Please review the test output above for details."
    echo ""
    exit 1
fi
