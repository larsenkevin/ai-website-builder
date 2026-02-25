#!/bin/bash
################################################################################
# Simple Test for Task 3.1: VM Snapshot Prompt
#
# This test verifies that the prompt_vm_snapshot() function:
# 1. Displays instructions for common cloud providers
# 2. Allows user to confirm snapshot creation or proceed without
# 3. Displays warning when proceeding without snapshot
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/../deploy.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
test_pass() {
    local test_name="$1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} PASS: $test_name"
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} FAIL: $test_name"
    echo "  Reason: $reason"
}

run_test() {
    local test_name="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
    echo ""
    echo "Running: $test_name"
}

################################################################################
# Test 1: Function exists and can be sourced
################################################################################

run_test "Test 1: prompt_vm_snapshot function exists"

# Source the deploy script functions (without running main)
if grep -q "^prompt_vm_snapshot()" "$DEPLOY_SCRIPT"; then
    test_pass "Test 1: prompt_vm_snapshot function exists"
else
    test_fail "Test 1: prompt_vm_snapshot function exists" "Function not found in deploy.sh"
fi

################################################################################
# Test 2: Function displays cloud provider instructions
################################################################################

run_test "Test 2: Function displays cloud provider instructions"

# Extract the function and check for cloud provider mentions
function_content=$(sed -n '/^prompt_vm_snapshot()/,/^}/p' "$DEPLOY_SCRIPT")

providers_found=0
if echo "$function_content" | grep -qi "AWS"; then
    providers_found=$((providers_found + 1))
fi
if echo "$function_content" | grep -qi "GCP\|Google Cloud"; then
    providers_found=$((providers_found + 1))
fi
if echo "$function_content" | grep -qi "Azure"; then
    providers_found=$((providers_found + 1))
fi
if echo "$function_content" | grep -qi "DigitalOcean"; then
    providers_found=$((providers_found + 1))
fi

if [ $providers_found -eq 4 ]; then
    test_pass "Test 2: All four cloud providers mentioned (AWS, GCP, Azure, DigitalOcean)"
else
    test_fail "Test 2: All four cloud providers mentioned" "Only found $providers_found out of 4 providers"
fi

################################################################################
# Test 3: Function prompts for user confirmation
################################################################################

run_test "Test 3: Function prompts for user confirmation"

if echo "$function_content" | grep -q "read"; then
    test_pass "Test 3: Function prompts for user input"
else
    test_fail "Test 3: Function prompts for user input" "No read command found"
fi

################################################################################
# Test 4: Function displays warning for proceeding without snapshot
################################################################################

run_test "Test 4: Function displays warning when proceeding without snapshot"

if echo "$function_content" | grep -qi "WARNING.*without.*snapshot\|Proceeding without"; then
    test_pass "Test 4: Warning message displayed for proceeding without snapshot"
else
    test_fail "Test 4: Warning message displayed" "No warning message found"
fi

################################################################################
# Test 5: Function logs operations
################################################################################

run_test "Test 5: Function logs operations"

log_calls=$(echo "$function_content" | grep -c "log_operation" || true)

if [ "$log_calls" -ge 3 ]; then
    test_pass "Test 5: Function logs operations (found $log_calls log_operation calls)"
else
    test_fail "Test 5: Function logs operations" "Expected at least 3 log_operation calls, found $log_calls"
fi

################################################################################
# Test 6: Function handles yes/no responses
################################################################################

run_test "Test 6: Function handles yes/no responses"

yes_handling=0
no_handling=0

if echo "$function_content" | grep -qE "\[Yy\]|\[Yy\]\[Ee\]\[Ss\]|yes"; then
    yes_handling=1
fi

if echo "$function_content" | grep -qE "\[Nn\]|\[Nn\]\[Oo\]|no"; then
    no_handling=1
fi

if [ $yes_handling -eq 1 ] && [ $no_handling -eq 1 ]; then
    test_pass "Test 6: Function handles both yes and no responses"
else
    test_fail "Test 6: Function handles yes/no responses" "Missing yes or no handling"
fi

################################################################################
# Test 7: Function includes snapshot instructions
################################################################################

run_test "Test 7: Function includes snapshot creation instructions"

if echo "$function_content" | grep -qi "snapshot"; then
    snapshot_mentions=$(echo "$function_content" | grep -ci "snapshot" || true)
    if [ "$snapshot_mentions" -ge 5 ]; then
        test_pass "Test 7: Function includes snapshot instructions (mentioned $snapshot_mentions times)"
    else
        test_fail "Test 7: Function includes snapshot instructions" "Snapshot mentioned only $snapshot_mentions times"
    fi
else
    test_fail "Test 7: Function includes snapshot instructions" "No snapshot mentions found"
fi

################################################################################
# Test Summary
################################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary for Task 3.1"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
else
    echo -e "Tests failed: $TESTS_FAILED"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
