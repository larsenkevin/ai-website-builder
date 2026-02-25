#!/bin/bash
# Simple test script for Task 2.3: Logging and Progress Display Utilities
# Tests the log_operation(), display_progress(), and handle_error() functions

set -e

# Setup test environment
export LOG_FILE="/tmp/test-deploy-$$.log"
export CONFIG_DIR="/tmp/test-config-$$"
export STATE_FILE="$CONFIG_DIR/.install-state"
export REPOSITORY_PATH="/tmp/test-repo"
export QR_CODE_DIR="$CONFIG_DIR/qr-codes"
export SCRIPT_VERSION="1.0.0"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_file_exists() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} File exists: $1"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} File does not exist: $1"
        ((TESTS_FAILED++))
    fi
}

assert_file_contains() {
    if grep -q "$2" "$1" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} File contains '$2'"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} File does not contain '$2'"
        ((TESTS_FAILED++))
    fi
}

assert_function_exists() {
    if type "$1" &>/dev/null; then
        echo -e "${GREEN}✓${NC} Function exists: $1"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Function does not exist: $1"
        ((TESTS_FAILED++))
    fi
}

# Create test log directory
mkdir -p "$(dirname "$LOG_FILE")"

# Source the logging functions from deploy.sh
# Extract only the function definitions we need
source <(awk '/^# Initialize logging/,/^# Placeholder Functions/' ../deploy.sh | head -n -2)

echo "Testing Task 2.3: Logging and Progress Display Utilities"
echo "=========================================================="
echo ""

# Test 1: Check if functions exist
echo "Test 1: Verify functions exist"
assert_function_exists "log_operation"
assert_function_exists "display_progress"
assert_function_exists "handle_error"
assert_function_exists "display_success"
assert_function_exists "display_warning"
assert_function_exists "display_info"
assert_function_exists "init_logging"
echo ""

# Test 2: Test log_operation()
echo "Test 2: log_operation() writes to log file"
log_operation "Test message"
assert_file_exists "$LOG_FILE"
assert_file_contains "$LOG_FILE" "Test message"
echo ""

# Test 3: Test log_operation() timestamp
echo "Test 3: log_operation() includes ISO 8601 timestamp"
log_operation "Timestamped message"
if grep -qE '\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' "$LOG_FILE"; then
    echo -e "${GREEN}✓${NC} Timestamp format is correct (ISO 8601)"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} Timestamp format is incorrect"
    ((TESTS_FAILED++))
fi
echo ""

# Test 4: Test display_progress()
echo "Test 4: display_progress() logs with PROGRESS prefix"
display_progress "Installing dependencies" > /dev/null 2>&1
assert_file_contains "$LOG_FILE" "PROGRESS: Installing dependencies"
echo ""

# Test 5: Test display_success()
echo "Test 5: display_success() logs with SUCCESS prefix"
display_success "Installation complete" > /dev/null 2>&1
assert_file_contains "$LOG_FILE" "SUCCESS: Installation complete"
echo ""

# Test 6: Test display_warning()
echo "Test 6: display_warning() logs with WARNING prefix"
display_warning "Proceeding without snapshot" > /dev/null 2>&1
assert_file_contains "$LOG_FILE" "WARNING: Proceeding without snapshot"
echo ""

# Test 7: Test display_info()
echo "Test 7: display_info() logs with INFO prefix"
display_info "Configuration loaded" > /dev/null 2>&1
assert_file_contains "$LOG_FILE" "INFO: Configuration loaded"
echo ""

# Test 8: Test init_logging()
echo "Test 8: init_logging() creates log file with session header"
rm -f "$LOG_FILE"  # Remove old log
init_logging > /dev/null 2>&1
assert_file_exists "$LOG_FILE"
assert_file_contains "$LOG_FILE" "Deployment started at"
assert_file_contains "$LOG_FILE" "Script version: $SCRIPT_VERSION"
echo ""

# Test 9: Test multiple log operations
echo "Test 9: Multiple log operations append to same file"
log_operation "First operation"
log_operation "Second operation"
log_operation "Third operation"
line_count=$(grep -c "operation" "$LOG_FILE")
if [ "$line_count" -eq 3 ]; then
    echo -e "${GREEN}✓${NC} All 3 operations logged correctly"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} Expected 3 operations, found $line_count"
    ((TESTS_FAILED++))
fi
echo ""

# Test 10: Test handle_error() structure
echo "Test 10: handle_error() contains remediation steps"
if declare -f handle_error | grep -q "Remediation:"; then
    echo -e "${GREEN}✓${NC} handle_error() contains 'Remediation:' section"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} handle_error() missing 'Remediation:' section"
    ((TESTS_FAILED++))
fi

if declare -f handle_error | grep -q "Check the log file"; then
    echo -e "${GREEN}✓${NC} handle_error() mentions log file"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} handle_error() doesn't mention log file"
    ((TESTS_FAILED++))
fi
echo ""

# Test 11: Verify log file path
echo "Test 11: Verify production log file path"
# Check the deploy.sh script for the correct path
if grep -q 'LOG_FILE="/var/log/ai-website-builder-deploy.log"' ../deploy.sh; then
    echo -e "${GREEN}✓${NC} Log file path is correct: /var/log/ai-website-builder-deploy.log"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} Log file path is incorrect"
    ((TESTS_FAILED++))
fi
echo ""

# Cleanup
rm -f "$LOG_FILE"
rm -rf "$CONFIG_DIR"

# Summary
echo "=========================================================="
echo "Test Summary"
echo "=========================================================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
