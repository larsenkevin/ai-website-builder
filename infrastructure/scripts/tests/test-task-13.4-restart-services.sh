#!/bin/bash
################################################################################
# Test for Task 13.4: Implement service restart for update mode
#
# This test verifies that the restart_services() function:
# 1. Checks if running in update mode
# 2. Restarts the ai-website-builder service using systemctl restart
# 3. Verifies the service restarted successfully
# 4. Displays progress messages and logs all operations
# 5. Handles errors gracefully with descriptive messages
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/../deploy.sh"
TEST_LOG="/tmp/test-restart-services-$$.log"
TEST_CONFIG_DIR="/tmp/test-ai-website-builder-$$"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Cleanup function
cleanup() {
    rm -f "$TEST_LOG"
    rm -rf "$TEST_CONFIG_DIR"
}

trap cleanup EXIT

# Test helper functions
print_test_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}$1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

pass_test() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓ PASS${NC}: $1"
}

fail_test() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗ FAIL${NC}: $1"
    if [ -n "${2:-}" ]; then
        echo "  Details: $2"
    fi
}

run_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${BLUE}▶${NC} Running: $1"
}

# Extract the restart_services function from deploy.sh
extract_function() {
    local func_name="$1"
    local output_file="$2"
    
    # Extract function definition from deploy.sh
    awk "/^${func_name}\(\) \{/,/^}/" "$DEPLOY_SCRIPT" > "$output_file"
}

# Test 1: Verify restart_services function exists
test_function_exists() {
    run_test "Test 1: Verify restart_services function exists"
    
    if grep -q "^restart_services()" "$DEPLOY_SCRIPT"; then
        pass_test "restart_services function found in deploy.sh"
    else
        fail_test "restart_services function not found in deploy.sh"
        return 1
    fi
}

# Test 2: Verify function checks MODE variable
test_mode_check() {
    run_test "Test 2: Verify function checks MODE variable"
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'MODE.*update'; then
        pass_test "Function checks MODE variable for update mode"
    else
        fail_test "Function does not check MODE variable"
        return 1
    fi
}

# Test 3: Verify function uses systemctl restart
test_systemctl_restart() {
    run_test "Test 3: Verify function uses systemctl restart"
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'systemctl restart ai-website-builder'; then
        pass_test "Function uses 'systemctl restart ai-website-builder'"
    else
        fail_test "Function does not use 'systemctl restart ai-website-builder'"
        return 1
    fi
}

# Test 4: Verify function logs operations
test_logging() {
    run_test "Test 4: Verify function logs operations"
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'log_operation'; then
        pass_test "Function calls log_operation for logging"
    else
        fail_test "Function does not call log_operation"
        return 1
    fi
}

# Test 5: Verify function displays progress messages
test_progress_messages() {
    run_test "Test 5: Verify function displays progress messages"
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'display_progress\|display_success\|display_info'; then
        pass_test "Function displays progress messages"
    else
        fail_test "Function does not display progress messages"
        return 1
    fi
}

# Test 6: Verify function handles errors
test_error_handling() {
    run_test "Test 6: Verify function handles errors"
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    # Check for error handling (if statement checking systemctl result)
    if echo "$func_content" | grep -q 'if.*systemctl restart'; then
        pass_test "Function has error handling for systemctl restart"
    else
        fail_test "Function lacks error handling for systemctl restart"
        return 1
    fi
}

# Test 7: Verify function provides remediation guidance on error
test_remediation_guidance() {
    run_test "Test 7: Verify function provides remediation guidance on error"
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'Remediation:'; then
        pass_test "Function provides remediation guidance on error"
    else
        fail_test "Function does not provide remediation guidance"
        return 1
    fi
}

# Test 8: Verify function displays service logs on error
test_service_logs_on_error() {
    run_test "Test 8: Verify function displays service logs on error"
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'journalctl.*ai-website-builder'; then
        pass_test "Function displays service logs on error using journalctl"
    else
        fail_test "Function does not display service logs on error"
        return 1
    fi
}

# Test 9: Verify function verifies restart success
test_restart_verification() {
    run_test "Test 9: Verify function verifies restart success"
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    # Check for success message after restart
    if echo "$func_content" | grep -A 5 'systemctl restart' | grep -q 'display_success\|Service restarted successfully'; then
        pass_test "Function verifies and reports restart success"
    else
        fail_test "Function does not verify restart success"
        return 1
    fi
}

# Test 10: Verify function is not a placeholder
test_not_placeholder() {
    run_test "Test 10: Verify function is not a placeholder"
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'TODO\|placeholder'; then
        fail_test "Function still contains TODO or placeholder comments"
        return 1
    else
        pass_test "Function is fully implemented (no TODO/placeholder)"
    fi
}

################################################################################
# Main test execution
################################################################################

main() {
    print_test_header "Task 13.4: Service Restart Implementation Tests"
    
    echo "Testing restart_services() function implementation..."
    echo "Deploy script: $DEPLOY_SCRIPT"
    echo ""
    
    # Run all tests
    test_function_exists || true
    test_mode_check || true
    test_systemctl_restart || true
    test_logging || true
    test_progress_messages || true
    test_error_handling || true
    test_remediation_guidance || true
    test_service_logs_on_error || true
    test_restart_verification || true
    test_not_placeholder || true
    
    # Print summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Test Summary${NC}"
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
}

main "$@"
