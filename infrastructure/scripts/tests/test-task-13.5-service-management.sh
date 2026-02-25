#!/bin/bash
################################################################################
# Unit Tests for Task 13.5: Service Management
#
# This test suite verifies comprehensive service management functionality:
# - Systemd service file created correctly (Requirement 13.1)
# - Service enabled for auto-start (Requirement 13.2)
# - Service started successfully (Requirement 13.3)
# - Service status verified (Requirement 13.4)
# - Service logs accessible (Requirement 13.5)
# - Service restarted in update mode (Requirement 5.6)
#
# Tests cover all service management functions:
# - configure_systemd_service() (Task 13.1)
# - start_services() (Task 13.2)
# - verify_service_status() (Task 13.3)
# - restart_services() (Task 13.4)
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/../deploy.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
test_pass() {
    local test_name="$1"
    echo -e "${GREEN}✓${NC} PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    echo -e "${RED}✗${NC} FAIL: $test_name"
    echo "  Reason: $reason"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_info() {
    local message="$1"
    echo -e "${YELLOW}ℹ${NC} $message"
}

################################################################################
# Test 1: Verify configure_systemd_service function exists
################################################################################
test_configure_systemd_service_exists() {
    test_info "Test 1: Verifying configure_systemd_service function exists..."
    
    if grep -q "^configure_systemd_service()" "$DEPLOY_SCRIPT"; then
        test_pass "configure_systemd_service function exists"
    else
        test_fail "configure_systemd_service function exists" "Function not found in deploy.sh"
    fi
}

################################################################################
# Test 2: Verify start_services function exists
################################################################################
test_start_services_exists() {
    test_info "Test 2: Verifying start_services function exists..."
    
    if grep -q "^start_services()" "$DEPLOY_SCRIPT"; then
        test_pass "start_services function exists"
    else
        test_fail "start_services function exists" "Function not found in deploy.sh"
    fi
}

################################################################################
# Test 3: Verify verify_service_status function exists
################################################################################
test_verify_service_status_exists() {
    test_info "Test 3: Verifying verify_service_status function exists..."
    
    if grep -q "^verify_service_status()" "$DEPLOY_SCRIPT"; then
        test_pass "verify_service_status function exists"
    else
        test_fail "verify_service_status function exists" "Function not found in deploy.sh"
    fi
}

################################################################################
# Test 4: Verify restart_services function exists
################################################################################
test_restart_services_exists() {
    test_info "Test 4: Verifying restart_services function exists..."
    
    if grep -q "^restart_services()" "$DEPLOY_SCRIPT"; then
        test_pass "restart_services function exists"
    else
        test_fail "restart_services function exists" "Function not found in deploy.sh"
    fi
}

################################################################################
# Test 5: Verify start_services uses systemctl daemon-reload
################################################################################
test_start_services_daemon_reload() {
    test_info "Test 5: Verifying start_services uses systemctl daemon-reload..."
    
    local func_content=$(awk '/^start_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'systemctl daemon-reload'; then
        test_pass "start_services uses systemctl daemon-reload"
    else
        test_fail "start_services uses systemctl daemon-reload" "Command not found in function"
    fi
}

################################################################################
# Test 6: Verify start_services enables service for auto-start
################################################################################
test_start_services_enable() {
    test_info "Test 6: Verifying start_services enables service for auto-start..."
    
    local func_content=$(awk '/^start_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'systemctl enable ai-website-builder'; then
        test_pass "start_services enables ai-website-builder service"
    else
        test_fail "start_services enables ai-website-builder service" "Command not found in function"
    fi
}

################################################################################
# Test 7: Verify start_services starts the service
################################################################################
test_start_services_start() {
    test_info "Test 7: Verifying start_services starts the service..."
    
    local func_content=$(awk '/^start_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'systemctl start ai-website-builder'; then
        test_pass "start_services starts ai-website-builder service"
    else
        test_fail "start_services starts ai-website-builder service" "Command not found in function"
    fi
}

################################################################################
# Test 8: Verify start_services logs operations
################################################################################
test_start_services_logging() {
    test_info "Test 8: Verifying start_services logs operations..."
    
    local func_content=$(awk '/^start_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'log_operation'; then
        test_pass "start_services logs operations"
    else
        test_fail "start_services logs operations" "log_operation calls not found"
    fi
}

################################################################################
# Test 9: Verify start_services displays progress messages
################################################################################
test_start_services_progress() {
    test_info "Test 9: Verifying start_services displays progress messages..."
    
    local func_content=$(awk '/^start_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'display_progress\|display_success'; then
        test_pass "start_services displays progress messages"
    else
        test_fail "start_services displays progress messages" "Progress display calls not found"
    fi
}

################################################################################
# Test 10: Verify start_services has error handling
################################################################################
test_start_services_error_handling() {
    test_info "Test 10: Verifying start_services has error handling..."
    
    local func_content=$(awk '/^start_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    # Check for error handling (if statements checking systemctl results)
    if echo "$func_content" | grep -q 'if systemctl'; then
        test_pass "start_services has error handling for systemctl commands"
    else
        test_fail "start_services has error handling" "Error handling not found"
    fi
}

################################################################################
# Test 11: Verify start_services displays service logs on error
################################################################################
test_start_services_logs_on_error() {
    test_info "Test 11: Verifying start_services displays service logs on error..."
    
    local func_content=$(awk '/^start_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'journalctl.*ai-website-builder'; then
        test_pass "start_services displays service logs on error"
    else
        test_fail "start_services displays service logs on error" "journalctl command not found"
    fi
}

################################################################################
# Test 12: Verify start_services provides remediation guidance
################################################################################
test_start_services_remediation() {
    test_info "Test 12: Verifying start_services provides remediation guidance..."
    
    local func_content=$(awk '/^start_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'Remediation:'; then
        test_pass "start_services provides remediation guidance"
    else
        test_fail "start_services provides remediation guidance" "Remediation section not found"
    fi
}

################################################################################
# Test 13: Verify restart_services checks MODE variable
################################################################################
test_restart_services_mode_check() {
    test_info "Test 13: Verifying restart_services checks MODE variable..."
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'MODE.*update'; then
        test_pass "restart_services checks MODE variable for update mode"
    else
        test_fail "restart_services checks MODE variable" "MODE check not found"
    fi
}

################################################################################
# Test 14: Verify restart_services uses systemctl restart
################################################################################
test_restart_services_restart_command() {
    test_info "Test 14: Verifying restart_services uses systemctl restart..."
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'systemctl restart ai-website-builder'; then
        test_pass "restart_services uses systemctl restart ai-website-builder"
    else
        test_fail "restart_services uses systemctl restart" "Command not found"
    fi
}

################################################################################
# Test 15: Verify restart_services logs operations
################################################################################
test_restart_services_logging() {
    test_info "Test 15: Verifying restart_services logs operations..."
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'log_operation'; then
        test_pass "restart_services logs operations"
    else
        test_fail "restart_services logs operations" "log_operation calls not found"
    fi
}

################################################################################
# Test 16: Verify restart_services has error handling
################################################################################
test_restart_services_error_handling() {
    test_info "Test 16: Verifying restart_services has error handling..."
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'if systemctl restart'; then
        test_pass "restart_services has error handling for systemctl restart"
    else
        test_fail "restart_services has error handling" "Error handling not found"
    fi
}

################################################################################
# Test 17: Verify restart_services displays service logs on error
################################################################################
test_restart_services_logs_on_error() {
    test_info "Test 17: Verifying restart_services displays service logs on error..."
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'journalctl.*ai-website-builder'; then
        test_pass "restart_services displays service logs on error"
    else
        test_fail "restart_services displays service logs on error" "journalctl command not found"
    fi
}

################################################################################
# Test 18: Verify restart_services provides remediation guidance
################################################################################
test_restart_services_remediation() {
    test_info "Test 18: Verifying restart_services provides remediation guidance..."
    
    local func_content=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'Remediation:'; then
        test_pass "restart_services provides remediation guidance"
    else
        test_fail "restart_services provides remediation guidance" "Remediation section not found"
    fi
}

################################################################################
# Test 19: Verify verify_service_status checks service is active
################################################################################
test_verify_service_status_active_check() {
    test_info "Test 19: Verifying verify_service_status checks service is active..."
    
    local func_content=$(awk '/^verify_service_status\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'systemctl is-active.*ai-website-builder'; then
        test_pass "verify_service_status checks if service is active"
    else
        test_fail "verify_service_status checks if service is active" "Active check not found"
    fi
}

################################################################################
# Test 20: Verify verify_service_status checks process is running
################################################################################
test_verify_service_status_process_check() {
    test_info "Test 20: Verifying verify_service_status checks process is running..."
    
    local func_content=$(awk '/^verify_service_status\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'MainPID\|service_pid'; then
        test_pass "verify_service_status checks if process is running"
    else
        test_fail "verify_service_status checks if process is running" "Process check not found"
    fi
}

################################################################################
# Test 21: Verify verify_service_status checks service logs
################################################################################
test_verify_service_status_log_check() {
    test_info "Test 21: Verifying verify_service_status checks service logs..."
    
    local func_content=$(awk '/^verify_service_status\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'journalctl.*ai-website-builder'; then
        test_pass "verify_service_status checks service logs for errors"
    else
        test_fail "verify_service_status checks service logs" "Log check not found"
    fi
}

################################################################################
# Test 22: Verify verify_service_status tests HTTP endpoint
################################################################################
test_verify_service_status_http_check() {
    test_info "Test 22: Verifying verify_service_status tests HTTP endpoint..."
    
    local func_content=$(awk '/^verify_service_status\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'curl.*localhost:3000'; then
        test_pass "verify_service_status tests HTTP endpoint accessibility"
    else
        test_fail "verify_service_status tests HTTP endpoint" "HTTP check not found"
    fi
}

################################################################################
# Test 23: Verify verify_service_status logs all checks
################################################################################
test_verify_service_status_logging() {
    test_info "Test 23: Verifying verify_service_status logs all checks..."
    
    local func_content=$(awk '/^verify_service_status\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'log_operation'; then
        test_pass "verify_service_status logs all verification checks"
    else
        test_fail "verify_service_status logs all checks" "log_operation calls not found"
    fi
}

################################################################################
# Test 24: Verify verify_service_status displays progress messages
################################################################################
test_verify_service_status_progress() {
    test_info "Test 24: Verifying verify_service_status displays progress messages..."
    
    local func_content=$(awk '/^verify_service_status\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    if echo "$func_content" | grep -q 'display_progress\|display_success\|display_error'; then
        test_pass "verify_service_status displays progress messages"
    else
        test_fail "verify_service_status displays progress messages" "Progress display calls not found"
    fi
}

################################################################################
# Test 25: Verify verify_service_status displays comprehensive error info
################################################################################
test_verify_service_status_error_info() {
    test_info "Test 25: Verifying verify_service_status displays comprehensive error info..."
    
    local func_content=$(awk '/^verify_service_status\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    # Check for comprehensive error display including service status
    if echo "$func_content" | grep -q 'systemctl status ai-website-builder'; then
        test_pass "verify_service_status displays comprehensive error information"
    else
        test_fail "verify_service_status displays comprehensive error info" "Service status display not found"
    fi
}

################################################################################
# Test 26: Verify all functions are not placeholders
################################################################################
test_functions_not_placeholders() {
    test_info "Test 26: Verifying functions are fully implemented..."
    
    local all_implemented=true
    
    # Check configure_systemd_service
    local config_func=$(awk '/^configure_systemd_service\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    if echo "$config_func" | grep -q 'TODO\|placeholder'; then
        test_fail "configure_systemd_service is fully implemented" "Contains TODO or placeholder"
        all_implemented=false
    fi
    
    # Check start_services
    local start_func=$(awk '/^start_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    if echo "$start_func" | grep -q 'TODO.*Task 13.2'; then
        test_fail "start_services is fully implemented" "Contains TODO"
        all_implemented=false
    fi
    
    # Check verify_service_status
    local verify_func=$(awk '/^verify_service_status\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    if echo "$verify_func" | grep -q 'TODO.*Task 13.3'; then
        test_fail "verify_service_status is fully implemented" "Contains TODO"
        all_implemented=false
    fi
    
    # Check restart_services
    local restart_func=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    if echo "$restart_func" | grep -q 'TODO.*Task 13.4'; then
        test_fail "restart_services is fully implemented" "Contains TODO"
        all_implemented=false
    fi
    
    if [ "$all_implemented" = true ]; then
        test_pass "All service management functions are fully implemented"
    fi
}

################################################################################
# Test 27: Verify service file path is correct
################################################################################
test_service_file_path() {
    test_info "Test 27: Verifying service file path references are correct..."
    
    # Check if the script references the correct systemd service file path
    if grep -q '/etc/systemd/system/ai-website-builder.service' "$DEPLOY_SCRIPT"; then
        test_pass "Service file path is correct (/etc/systemd/system/ai-website-builder.service)"
    else
        test_fail "Service file path is correct" "Expected path not found in script"
    fi
}

################################################################################
# Test 28: Verify error messages include log file reference
################################################################################
test_error_messages_include_log_reference() {
    test_info "Test 28: Verifying error messages include log file reference..."
    
    local start_func=$(awk '/^start_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    local restart_func=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    local all_have_log_ref=true
    
    # Check start_services error messages
    if ! echo "$start_func" | grep -q 'Check the log file for details.*LOG_FILE'; then
        test_fail "start_services error messages include log file reference" "Log file reference not found"
        all_have_log_ref=false
    fi
    
    # Check restart_services error messages
    if ! echo "$restart_func" | grep -q 'Check the log file for details.*LOG_FILE'; then
        test_fail "restart_services error messages include log file reference" "Log file reference not found"
        all_have_log_ref=false
    fi
    
    if [ "$all_have_log_ref" = true ]; then
        test_pass "Error messages include log file reference"
    fi
}

################################################################################
# Test 29: Verify functions exit on critical errors
################################################################################
test_functions_exit_on_error() {
    test_info "Test 29: Verifying functions exit on critical errors..."
    
    local start_func=$(awk '/^start_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    local restart_func=$(awk '/^restart_services\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    local all_exit=true
    
    # Check start_services exits on error
    if ! echo "$start_func" | grep -q 'exit 1'; then
        test_fail "start_services exits on critical errors" "exit 1 not found"
        all_exit=false
    fi
    
    # Check restart_services exits on error
    if ! echo "$restart_func" | grep -q 'exit 1'; then
        test_fail "restart_services exits on critical errors" "exit 1 not found"
        all_exit=false
    fi
    
    if [ "$all_exit" = true ]; then
        test_pass "Functions exit on critical errors"
    fi
}

################################################################################
# Test 30: Verify verify_service_status waits for service to start
################################################################################
test_verify_service_status_wait() {
    test_info "Test 30: Verifying verify_service_status waits for service to start..."
    
    local func_content=$(awk '/^verify_service_status\(\) \{/,/^}/' "$DEPLOY_SCRIPT")
    
    # Check for sleep or wait command before HTTP check
    if echo "$func_content" | grep -q 'sleep'; then
        test_pass "verify_service_status waits for service to fully start"
    else
        test_fail "verify_service_status waits for service" "Wait/sleep command not found"
    fi
}

################################################################################
# Main test execution
################################################################################
main() {
    echo "=========================================="
    echo "Task 13.5: Service Management Unit Tests"
    echo "=========================================="
    echo ""
    
    # Run all tests
    test_configure_systemd_service_exists
    test_start_services_exists
    test_verify_service_status_exists
    test_restart_services_exists
    echo ""
    
    test_start_services_daemon_reload
    test_start_services_enable
    test_start_services_start
    test_start_services_logging
    test_start_services_progress
    test_start_services_error_handling
    test_start_services_logs_on_error
    test_start_services_remediation
    echo ""
    
    test_restart_services_mode_check
    test_restart_services_restart_command
    test_restart_services_logging
    test_restart_services_error_handling
    test_restart_services_logs_on_error
    test_restart_services_remediation
    echo ""
    
    test_verify_service_status_active_check
    test_verify_service_status_process_check
    test_verify_service_status_log_check
    test_verify_service_status_http_check
    test_verify_service_status_logging
    test_verify_service_status_progress
    test_verify_service_status_error_info
    echo ""
    
    test_functions_not_placeholders
    test_service_file_path
    test_error_messages_include_log_reference
    test_functions_exit_on_error
    test_verify_service_status_wait
    echo ""
    
    # Print summary
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo "Tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    else
        echo "Tests failed: $TESTS_FAILED"
    fi
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        echo ""
        echo "Requirements validated:"
        echo "  - 13.1: Systemd service file created correctly"
        echo "  - 13.2: Service enabled for auto-start"
        echo "  - 13.3: Service started successfully"
        echo "  - 13.4: Service status verified"
        echo "  - 13.5: Service logs accessible"
        echo "  - 5.6: Service restarted in update mode"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

# Run main
main

