#!/bin/bash
################################################################################
# Simple Test for Task 12.2: QR Code Generator for Service Access URL
#
# This test verifies that the generate_qr_codes() function:
# - Generates a PNG QR code for service access URL
# - Generates an ASCII art version
# - Uses Tailscale hostname or domain name fallback
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
    export DOMAIN_NAME="example.com"
    
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

# Test 1: Verify service access PNG QR code is generated
test_service_access_png_generated() {
    test_info "Test 1: Checking if service access PNG QR code is generated..."
    
    # Run the function
    generate_qr_codes 2>/dev/null || true
    
    local qr_png="$QR_CODE_DIR/service-access.png"
    
    if [ -f "$qr_png" ]; then
        test_pass "Service access PNG QR code generated"
    else
        test_fail "Service access PNG QR code generated" "PNG file not found at $qr_png"
    fi
}

# Test 2: Verify service access PNG QR code is a valid image
test_service_access_png_valid() {
    test_info "Test 2: Checking if service access PNG QR code is a valid image..."
    
    local qr_png="$QR_CODE_DIR/service-access.png"
    
    if [ -f "$qr_png" ]; then
        # Check if file is a PNG by checking magic bytes
        if file "$qr_png" | grep -q "PNG image data"; then
            test_pass "Service access PNG QR code is valid"
        else
            test_fail "Service access PNG QR code is valid" "File is not a valid PNG image"
        fi
    else
        test_fail "Service access PNG QR code is valid" "PNG file not found"
    fi
}

# Test 3: Verify service access ASCII art QR code is generated
test_service_access_ascii_generated() {
    test_info "Test 3: Checking if service access ASCII art QR code is generated..."
    
    local qr_ascii="$QR_CODE_DIR/service-access.txt"
    
    if [ -f "$qr_ascii" ]; then
        test_pass "Service access ASCII art QR code generated"
    else
        test_fail "Service access ASCII art QR code generated" "ASCII file not found at $qr_ascii"
    fi
}

# Test 4: Verify service access PNG file permissions
test_service_access_png_permissions() {
    test_info "Test 4: Checking service access PNG file permissions..."
    
    local qr_png="$QR_CODE_DIR/service-access.png"
    
    if [ -f "$qr_png" ]; then
        local perms=$(stat -c "%a" "$qr_png")
        if [ "$perms" = "644" ]; then
            test_pass "Service access PNG file has correct permissions (644)"
        else
            test_fail "Service access PNG file has correct permissions" "Expected 644, got $perms"
        fi
    else
        test_fail "Service access PNG file has correct permissions" "PNG file not found"
    fi
}

# Test 5: Verify function logs service access URL generation
test_function_logs_service_access() {
    test_info "Test 5: Checking if function logs service access URL generation..."
    
    if [ -f "$LOG_FILE" ]; then
        if grep -q "Generating QR code for service access URL" "$LOG_FILE"; then
            test_pass "Function logs service access URL generation"
        else
            test_fail "Function logs service access URL generation" "Expected log entry not found"
        fi
    else
        test_fail "Function logs service access URL generation" "Log file not found"
    fi
}

# Test 6: Verify both QR codes are generated (Tailscale app + service access)
test_both_qr_codes_generated() {
    test_info "Test 6: Checking if both QR codes are generated..."
    
    local tailscale_qr="$QR_CODE_DIR/tailscale-app.png"
    local service_qr="$QR_CODE_DIR/service-access.png"
    
    if [ -f "$tailscale_qr" ] && [ -f "$service_qr" ]; then
        test_pass "Both QR codes generated (Tailscale app + service access)"
    else
        local missing=""
        [ ! -f "$tailscale_qr" ] && missing="tailscale-app.png"
        [ ! -f "$service_qr" ] && missing="$missing service-access.png"
        test_fail "Both QR codes generated" "Missing: $missing"
    fi
}

# Test 7: Verify service access URL is logged
test_service_access_url_logged() {
    test_info "Test 7: Checking if service access URL is logged..."
    
    if [ -f "$LOG_FILE" ]; then
        if grep -q "Service access URL:" "$LOG_FILE"; then
            test_pass "Service access URL is logged"
        else
            test_fail "Service access URL is logged" "Expected log entry not found"
        fi
    else
        test_fail "Service access URL is logged" "Log file not found"
    fi
}

# Main test execution
main() {
    echo "=================================="
    echo "Task 12.2 Service Access QR Code Test"
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
    test_service_access_png_generated
    test_service_access_png_valid
    test_service_access_ascii_generated
    test_service_access_png_permissions
    test_function_logs_service_access
    test_both_qr_codes_generated
    test_service_access_url_logged
    
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
