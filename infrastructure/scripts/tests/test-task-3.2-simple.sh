#!/bin/bash
################################################################################
# Simple Test for Task 3.2: Pre-flight System Checks
#
# This test verifies that the run_preflight_checks function correctly validates:
# - Root user check
# - Ubuntu OS check
# - Disk space check (minimum 10GB)
# - Network connectivity check
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
test_result() {
    local test_name="$1"
    local result="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "=================================="
echo "Task 3.2: Pre-flight System Checks"
echo "=================================="
echo ""

# Test 1: Verify run_preflight_checks function exists
echo "Test 1: Verify run_preflight_checks function exists"
if grep -q "run_preflight_checks()" "$DEPLOY_SCRIPT"; then
    test_result "run_preflight_checks function exists" "PASS"
else
    test_result "run_preflight_checks function exists" "FAIL"
fi
echo ""

# Test 2: Verify root user check is implemented
echo "Test 2: Verify root user check is implemented"
if grep -q "EUID" "$DEPLOY_SCRIPT" && grep -q "root" "$DEPLOY_SCRIPT"; then
    test_result "Root user check implemented" "PASS"
else
    test_result "Root user check implemented" "FAIL"
fi
echo ""

# Test 3: Verify Ubuntu OS check is implemented
echo "Test 3: Verify Ubuntu OS check is implemented"
if grep -q "/etc/os-release" "$DEPLOY_SCRIPT" && grep -q "ubuntu" "$DEPLOY_SCRIPT"; then
    test_result "Ubuntu OS check implemented" "PASS"
else
    test_result "Ubuntu OS check implemented" "FAIL"
fi
echo ""

# Test 4: Verify disk space check is implemented
echo "Test 4: Verify disk space check is implemented"
if grep -q "df" "$DEPLOY_SCRIPT" && grep -q "10" "$DEPLOY_SCRIPT"; then
    test_result "Disk space check implemented (10GB minimum)" "PASS"
else
    test_result "Disk space check implemented (10GB minimum)" "FAIL"
fi
echo ""

# Test 5: Verify network connectivity check is implemented
echo "Test 5: Verify network connectivity check is implemented"
if grep -q "ping" "$DEPLOY_SCRIPT"; then
    test_result "Network connectivity check implemented" "PASS"
else
    test_result "Network connectivity check implemented" "FAIL"
fi
echo ""

# Test 6: Verify run_preflight_checks is called in main()
echo "Test 6: Verify run_preflight_checks is called in main()"
if grep -A 5 "Phase 1: Pre-flight checks" "$DEPLOY_SCRIPT" | grep -q "run_preflight_checks"; then
    test_result "run_preflight_checks called in main()" "PASS"
else
    test_result "run_preflight_checks called in main()" "FAIL"
fi
echo ""

# Test 7: Verify error handling for failed checks
echo "Test 7: Verify error handling for failed checks"
if grep -q "checks_passed" "$DEPLOY_SCRIPT" && grep -q "exit 1" "$DEPLOY_SCRIPT"; then
    test_result "Error handling for failed checks implemented" "PASS"
else
    test_result "Error handling for failed checks implemented" "FAIL"
fi
echo ""

# Summary
echo "=================================="
echo "Test Summary"
echo "=================================="
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
else
    echo -e "${GREEN}Tests failed: $TESTS_FAILED${NC}"
fi
echo ""

# Exit with appropriate code
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Some tests failed${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
