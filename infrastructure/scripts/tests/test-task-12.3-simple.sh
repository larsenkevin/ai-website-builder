#!/bin/bash
################################################################################
# Simple Test for Task 12.3: QR Code Display Function
#
# This test verifies that the display_qr_codes_terminal() function:
# - Exists in deploy.sh
# - Displays QR codes with formatted borders
# - Includes descriptive labels
# - Logs operations
################################################################################

set -euo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/../deploy.sh"
TEST_DIR="/tmp/test-task-12.3-$$"
TEST_LOG="$TEST_DIR/test.log"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
test_pass() {
    local test_name="$1"
    echo -e "${GREEN}✓${NC} PASS: $test_name"
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    echo -e "${RED}✗${NC} FAIL: $test_name"
    echo "  Reason: $reason"
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
}

test_info() {
    local message="$1"
    echo -e "${YELLOW}ℹ${NC} $message"
}

# Setup test environment
setup_test_env() {
    test_info "Setting up test environment..."
    
    # Create test directory
    mkdir -p "$TEST_DIR"
    mkdir -p "$TEST_DIR/qr-codes"
    
    # Create mock QR code ASCII art files
    cat > "$TEST_DIR/qr-codes/tailscale-app.txt" << 'EOF'
█████████████████████████████████
█████████████████████████████████
████ ▄▄▄▄▄ █▀█ █▄▄▀▄█ ▄▄▄▄▄ ████
████ █   █ █▀▀▀█ ▀▄ █ █   █ ████
████ █▄▄▄█ █▀ █▀▀█▄▀█ █▄▄▄█ ████
████▄▄▄▄▄▄▄█▄▀ ▀▄█ █▄▄▄▄▄▄▄████
████▄▀ ▄▀ ▄  ▄▀▀▄▀▄▄▀▀▀▄█▄▀████
████▄ ▄▄  ▄▀▄▄ ▄ ▄▀▄▀▀▀▄▀▀█████
████ ▄▄▄▄▄ █▄█  ▀▄▀ ▀ ▀▄█ ▀████
████ █   █ █  █▀▀▄▀▄▄▄▄▀▀▀█████
████ █▄▄▄█ █ ▄▀▄ ▄▀▄▀▀▀▄▀▀█████
████▄▄▄▄▄▄▄█▄▄███▄█▄██▄██▄█████
█████████████████████████████████
█████████████████████████████████
EOF
    
    cat > "$TEST_DIR/qr-codes/service-access.txt" << 'EOF'
█████████████████████████████████
█████████████████████████████████
████ ▄▄▄▄▄ █▀█ █▄▄▀▄█ ▄▄▄▄▄ ████
████ █   █ █▀▀▀█ ▀▄ █ █   █ ████
████ █▄▄▄█ █▀ █▀▀█▄▀█ █▄▄▄█ ████
████▄▄▄▄▄▄▄█▄▀ ▀▄█ █▄▄▄▄▄▄▄████
████▄▀ ▄▀ ▄  ▄▀▀▄▀▄▄▀▀▀▄█▄▀████
████▄ ▄▄  ▄▀▄▄ ▄ ▄▀▄▀▀▀▄▀▀█████
████ ▄▄▄▄▄ █▄█  ▀▄▀ ▀ ▀▄█ ▀████
████ █   █ █  █▀▀▄▀▄▄▄▄▀▀▀█████
████ █▄▄▄█ █ ▄▀▄ ▄▀▄▀▀▀▄▀▀█████
████▄▄▄▄▄▄▄█▄▄███▄█▄██▄██▄█████
█████████████████████████████████
█████████████████████████████████
EOF
    
    # Create mock config file
    cat > "$TEST_DIR/config.env" << 'EOF'
CLAUDE_API_KEY=sk-ant-test123
DOMAIN_NAME=example.com
TAILSCALE_EMAIL=test@example.com
EOF
    
    # Create mock log file
    touch "$TEST_LOG"
    
    test_info "Test environment created at: $TEST_DIR"
}

# Cleanup test environment
cleanup_test_env() {
    test_info "Cleaning up test environment..."
    rm -rf "$TEST_DIR"
}

# Source the deploy script functions
source_deploy_script() {
    test_info "Sourcing deploy script..."
    
    # Export test environment variables
    export QR_CODE_DIR="$TEST_DIR/qr-codes"
    export CONFIG_FILE="$TEST_DIR/config.env"
    export LOG_FILE="$TEST_LOG"
    
    # Source only the functions we need (avoid running main)
    source <(grep -A 1000 "^# Display QR codes in terminal" "$DEPLOY_SCRIPT" | grep -B 1000 "^# Configure systemd service" | head -n -1)
    
    # Source utility functions
    source <(grep -A 50 "^# Color Codes for Output" "$DEPLOY_SCRIPT" | head -60)
    source <(grep -A 100 "^# Logging and Output Functions" "$DEPLOY_SCRIPT" | head -120)
}

# Test 1: Verify display_qr_codes_terminal function exists
test_function_exists() {
    test_info "Test 1: Checking if display_qr_codes_terminal function exists..."
    
    if declare -f display_qr_codes_terminal > /dev/null; then
        test_pass "display_qr_codes_terminal function exists"
    else
        test_fail "display_qr_codes_terminal function exists" "Function not found in deploy.sh"
    fi
}

# Test 2: Verify function can be called without errors
test_function_callable() {
    test_info "Test 2: Testing if function can be called..."
    
    # Capture output
    local output=$(display_qr_codes_terminal 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        test_pass "Function executes without errors"
    else
        test_fail "Function executes without errors" "Exit code: $exit_code"
    fi
}

# Test 3: Verify function displays formatted borders
test_formatted_borders() {
    test_info "Test 3: Checking for formatted borders..."
    
    local output=$(display_qr_codes_terminal 2>&1)
    
    # Check for box drawing characters
    if echo "$output" | grep -q "┌─"; then
        test_pass "Function displays formatted borders (top)"
    else
        test_fail "Function displays formatted borders (top)" "Top border not found"
    fi
    
    if echo "$output" | grep -q "└─"; then
        test_pass "Function displays formatted borders (bottom)"
    else
        test_fail "Function displays formatted borders (bottom)" "Bottom border not found"
    fi
    
    if echo "$output" | grep -q "│"; then
        test_pass "Function displays formatted borders (sides)"
    else
        test_fail "Function displays formatted borders (sides)" "Side borders not found"
    fi
}

# Test 4: Verify function includes descriptive labels
test_descriptive_labels() {
    test_info "Test 4: Checking for descriptive labels..."
    
    local output=$(display_qr_codes_terminal 2>&1)
    
    # Check for Tailscale app label
    if echo "$output" | grep -q "Scan to Install Tailscale App"; then
        test_pass "Function includes Tailscale app label"
    else
        test_fail "Function includes Tailscale app label" "Label not found"
    fi
    
    # Check for service access label
    if echo "$output" | grep -q "Scan to Access AI Website Builder"; then
        test_pass "Function includes service access label"
    else
        test_fail "Function includes service access label" "Label not found"
    fi
}

# Test 5: Verify function displays both QR codes
test_both_qr_codes() {
    test_info "Test 5: Checking if both QR codes are displayed..."
    
    local output=$(display_qr_codes_terminal 2>&1)
    
    # Check for Tailscale URL
    if echo "$output" | grep -q "https://tailscale.com/download"; then
        test_pass "Function displays Tailscale app URL"
    else
        test_fail "Function displays Tailscale app URL" "URL not found"
    fi
    
    # Check for service URL (should contain domain or hostname)
    if echo "$output" | grep -q "https://"; then
        test_pass "Function displays service access URL"
    else
        test_fail "Function displays service access URL" "URL not found"
    fi
}

# Test 6: Verify function logs operations
test_logging() {
    test_info "Test 6: Checking if function logs operations..."
    
    # Clear log file
    > "$TEST_LOG"
    
    # Run function
    display_qr_codes_terminal >/dev/null 2>&1
    
    if [ -f "$TEST_LOG" ]; then
        if grep -q "FUNCTION: display_qr_codes_terminal called" "$TEST_LOG"; then
            test_pass "Function logs operations"
        else
            test_fail "Function logs operations" "Log entry not found"
        fi
    else
        test_fail "Function logs operations" "Log file not created"
    fi
}

# Test 7: Verify function displays QR code directory path
test_qr_code_directory_display() {
    test_info "Test 7: Checking if QR code directory path is displayed..."
    
    local output=$(display_qr_codes_terminal 2>&1)
    
    if echo "$output" | grep -q "QR code images saved to:"; then
        test_pass "Function displays QR code directory path"
    else
        test_fail "Function displays QR code directory path" "Directory path not found"
    fi
}

# Test 8: Verify function handles missing QR code files gracefully
test_missing_files() {
    test_info "Test 8: Testing graceful handling of missing QR code files..."
    
    # Remove QR code files
    rm -f "$TEST_DIR/qr-codes/tailscale-app.txt"
    rm -f "$TEST_DIR/qr-codes/service-access.txt"
    
    # Run function (should not fail)
    local output=$(display_qr_codes_terminal 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        test_pass "Function handles missing files gracefully"
    else
        test_fail "Function handles missing files gracefully" "Exit code: $exit_code"
    fi
    
    # Restore files for other tests
    setup_test_env
}

# Main test execution
main() {
    echo "=================================="
    echo "Task 12.3 QR Code Display Test"
    echo "=================================="
    echo ""
    
    # Setup
    setup_test_env
    source_deploy_script
    
    # Run tests
    test_function_exists
    echo ""
    
    test_function_callable
    echo ""
    
    test_formatted_borders
    echo ""
    
    test_descriptive_labels
    echo ""
    
    test_both_qr_codes
    echo ""
    
    test_logging
    echo ""
    
    test_qr_code_directory_display
    echo ""
    
    test_missing_files
    echo ""
    
    # Cleanup
    cleanup_test_env
    
    # Summary
    echo "=================================="
    echo "Test Summary"
    echo "=================================="
    echo "Tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    else
        echo "Tests failed: $TESTS_FAILED"
    fi
    echo ""
    
    # Exit with appropriate code
    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main
main "$@"
