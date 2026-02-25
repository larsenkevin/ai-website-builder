#!/bin/bash
################################################################################
# Simple Test for Task 11.3: Domain Verification Function
#
# This test verifies that the verify_domain_accessibility() function:
# - Checks DNS resolution with dig command
# - Verifies HTTP accessibility with curl
# - Verifies HTTPS accessibility with curl
# - Displays verification results
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
# Test 1: Verify function exists in deploy.sh
################################################################################

run_test "Test 1: verify_domain_accessibility function exists"

if grep -q "^verify_domain_accessibility()" "$DEPLOY_SCRIPT"; then
    test_pass "Function verify_domain_accessibility exists in deploy.sh"
else
    test_fail "Function verify_domain_accessibility exists in deploy.sh" "Function not found"
fi

################################################################################
# Test 2: Function checks DNS resolution
################################################################################

run_test "Test 2: Function checks DNS resolution with dig"

if grep -A 50 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "dig.*\$DOMAIN_NAME"; then
    test_pass "Function uses dig command for DNS resolution"
else
    test_fail "Function uses dig command for DNS resolution" "dig command not found in function"
fi

################################################################################
# Test 3: Function checks HTTP accessibility
################################################################################

run_test "Test 3: Function checks HTTP accessibility with curl"

if grep -A 100 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "curl.*http://.*\$DOMAIN_NAME"; then
    test_pass "Function uses curl for HTTP accessibility check"
else
    test_fail "Function uses curl for HTTP accessibility check" "HTTP curl check not found"
fi

################################################################################
# Test 4: Function checks HTTPS accessibility
################################################################################

run_test "Test 4: Function checks HTTPS accessibility with curl"

if grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "curl.*https://.*\$DOMAIN_NAME"; then
    test_pass "Function uses curl for HTTPS accessibility check"
else
    test_fail "Function uses curl for HTTPS accessibility check" "HTTPS curl check not found"
fi

################################################################################
# Test 5: Function displays verification results
################################################################################

run_test "Test 5: Function displays verification results"

if grep -A 200 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "Domain verification"; then
    test_pass "Function displays verification results"
else
    test_fail "Function displays verification results" "Verification result display not found"
fi

################################################################################
# Test 6: Function logs operations
################################################################################

run_test "Test 6: Function logs operations"

if grep -A 200 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "log_operation"; then
    test_pass "Function logs operations"
else
    test_fail "Function logs operations" "log_operation calls not found"
fi

################################################################################
# Test 7: Function handles missing commands gracefully
################################################################################

run_test "Test 7: Function handles missing commands gracefully"

# Check if function checks for command availability
if grep -A 200 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "command -v"; then
    test_pass "Function checks for command availability"
else
    test_fail "Function checks for command availability" "Command availability checks not found"
fi

################################################################################
# Test 8: Function provides troubleshooting guidance on failure
################################################################################

run_test "Test 8: Function provides troubleshooting guidance on failure"

if grep -A 200 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q -E "(DNS|firewall|nginx|propagation)"; then
    test_pass "Function provides troubleshooting guidance"
else
    test_fail "Function provides troubleshooting guidance" "Troubleshooting guidance not found"
fi

################################################################################
# Test Summary
################################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary for Task 11.3"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
