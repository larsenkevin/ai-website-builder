#!/bin/bash
################################################################################
# Simple Test for Task 12.1: QR Code Generator for Tailscale App Store
#
# This test verifies that the generate_qr_codes() function:
# - Creates the QR code directory
# - Generates a PNG QR code for Tailscale app store
# - Generates an ASCII art version
# - Sets correct file permissions
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/../deploy.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
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
    
    # Create temporary directory for testing
    export TEST_DIR=$(mktemp -d)
    export CONFIG_DIR="$TEST_DIR/etc/ai-website-builder"
    export QR_CODE_DIR="$CONFIG_DIR/qr-codes"
    export LOG_FILE="$TEST_DIR/test.log"
    
    mkdir -p "$CONFIG_DIR"
    
    test_info "Test directory: $TEST_DIR"
}

# Cleanup test environment
cleanup_test_env() {
    test_info "Cleaning up test environment..."
    if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Source the deploy script to get access to functions
source_deploy_script() {
    test_info "Sourcing deploy script..."
    
    # We need to source the script but avoid running main()
    # Extract only the functions we need
    source <(grep -A 1000 "^# Generate QR codes for end user access" "$DEPLOY_SCRIPT" | grep -B 1000 "^# Configure systemd service" | head -n -1)
    source <(grep -A 50 "^display_progress()" "$DEPLOY_SCRIPT" | grep -B 50 "^}" | head -n -1)
    source <(grep -A 50 "^display_success()" "$DEPLOY_SCRIPT" | grep -B 50 "^}" | head -n -1)
    source <(grep -A 50 "^display_error()" "$DEPLOY_SCRIPT" | grep -B 50 "^}" | head -n -1)
    source <(grep -A 50 "^display_warning()" "$DEPLOY_SCRIPT" | grep -B 50 "^}" | head -n -1)
    source <(grep -A 50 "^log_operation()" "$DEPLOY_SCRIPT" | grep -B 50 "^}" | head -n -1)
}

# Test 1: Verify generate_qr_codes function exists
test_function_exists() {
    test_info "Test 1: Checking if generate_qr_codes function exists..."
    
    if declare -f generate_qr_codes > /dev/null; then
        test_pass "generate_qr_codes function exists"
    else
        test_fail "generate_qr_codes function exists" "Function not found in deploy.sh"
    fi
}

# Test 2: Verify QR code directory is created
test_qr_directory_created() {
    test_info "Test 2: Checking if QR code directory is created..."
    
    # Run the function
    generate_qr_codes 2>/dev/null || true
    
    if [ -d "$QR_CODE_DIR" ]; then
        test_pass "QR code directory created"
    else
        test_fail "QR code directory created" "Directory not found at $QR_CODE_DIR"
    fi
}

# Test 3: Verify PNG QR code is generated
test_png_qr_code_generated() {
    test_info "Test 3: Checking if PNG QR code is generated..."
    
    local qr_png="$QR_CODE_DIR/tailscale-app.png"
    
    if [ -f "$qr_png" ]; then
        test_pass "PNG QR code generated"
    else
        test_fail "PNG QR code generated" "PNG file not found at $qr_png"
    fi
}

# Test 4: Verify PNG QR code is a valid image
test_png_qr_code_valid() {
    test_info "Test 4: Checking if PNG QR code is a valid image..."
    
    local qr_png="$QR_CODE_DIR/tailscale-app.png"
    
    if [ -f "$qr_png" ]; then
        # Check if file is a PNG by checking magic bytes
        if file "$qr_png" | grep -q "PNG image data"; then
            test_pass "PNG QR code is valid"
        else
            test_fail "PNG QR code is valid" "File is not a valid PNG image"
        fi
    else
        test_fail "PNG QR code is valid" "PNG file not found"
    fi
}

# Test 5: Verify ASCII art QR code is generated
test_ascii_qr_code_generated() {
    test_info "Test 5: Checking if ASCII art QR code is generated..."
    
    local qr_ascii="$QR_CODE_DIR/tailscale-app.txt"
    
    if [ -f "$qr_ascii" ]; then
        test_pass "ASCII art QR code generated"
    else
        test_fail "ASCII art QR code generated" "ASCII file not found at $qr_ascii"
    fi
}

# Test 6: Verify QR code directory permissions
test_qr_directory_permissions() {
    test_info "Test 6: Checking QR code directory permissions..."
    
    if [ -d "$QR_CODE_DIR" ]; then
        local perms=$(stat -c "%a" "$QR_CODE_DIR")
        if [ "$perms" = "700" ]; then
            test_pass "QR code directory has correct permissions (700)"
        else
            test_fail "QR code directory has correct permissions" "Expected 700, got $perms"
        fi
    else
        test_fail "QR code directory has correct permissions" "Directory not found"
    fi
}

# Test 7: Verify PNG file permissions
test_png_file_permissions() {
    test_info "Test 7: Checking PNG file permissions..."
    
    local qr_png="$QR_CODE_DIR/tailscale-app.png"
    
    if [ -f "$qr_png" ]; then
        local perms=$(stat -c "%a" "$qr_png")
        if [ "$perms" = "644" ]; then
            test_pass "PNG file has correct permissions (644)"
        else
            test_fail "PNG file has correct permissions" "Expected 644, got $perms"
        fi
    else
        test_fail "PNG file has correct permissions" "PNG file not found"
    fi
}

# Test 8: Verify function logs operations
test_function_logs_operations() {
    test_info "Test 8: Checking if function logs operations..."
    
    if [ -f "$LOG_FILE" ]; then
        if grep -q "FUNCTION: generate_qr_codes called" "$LOG_FILE"; then
            test_pass "Function logs operations"
        else
            test_fail "Function logs operations" "Expected log entry not found"
        fi
    else
        test_fail "Function logs operations" "Log file not found"
    fi
}

# Main test execution
main() {
    echo "=================================="
    echo "Task 12.1 QR Code Generator Test"
    echo "=================================="
    echo ""
    
    # Check if qrencode is installed
    if ! command -v qrencode &> /dev/null; then
        echo -e "${RED}ERROR: qrencode is not installed${NC}"
        echo "Please install it with: apt install qrencode"
        exit 1
    fi
    
    setup_test_env
    
    # Source the deploy script functions
    source_deploy_script
    
    # Run tests
    test_function_exists
    test_qr_directory_created
    test_png_qr_code_generated
    test_png_qr_code_valid
    test_ascii_qr_code_generated
    test_qr_directory_permissions
    test_png_file_permissions
    test_function_logs_operations
    
    # Cleanup
    cleanup_test_env
    
    # Print summary
    echo ""
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
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

# Run main
main
