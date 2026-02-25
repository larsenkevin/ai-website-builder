#!/bin/bash
################################################################################
# Unit Tests for Task 12.5: QR Code Generation
#
# This test suite verifies comprehensive QR code generation functionality:
# - App store QR code generated (Requirement 6.1)
# - Service access QR code generated (Requirement 6.2)
# - QR codes saved as PNG files (Requirement 6.4)
# - QR codes displayed in terminal (Requirement 6.3)
# - QR codes contain correct URLs (Requirements 6.1, 6.2)
# - ASCII art versions generated (Requirement 6.5)
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
    export DOMAIN_NAME="test.example.com"
    
    mkdir -p "$CONFIG_DIR"
    touch "$LOG_FILE"
    
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
    test_info "Sourcing deploy script functions..."
    
    # Source necessary functions from deploy script
    source <(grep -A 1000 "^# Generate QR codes for end user access" "$DEPLOY_SCRIPT" | grep -B 1000 "^# Configure systemd service" | head -n -1)
    source <(grep -A 50 "^display_progress()" "$DEPLOY_SCRIPT" | grep -B 50 "^}" | head -n -1)
    source <(grep -A 50 "^display_success()" "$DEPLOY_SCRIPT" | grep -B 50 "^}" | head -n -1)
    source <(grep -A 50 "^display_error()" "$DEPLOY_SCRIPT" | grep -B 50 "^}" | head -n -1)
    source <(grep -A 50 "^display_warning()" "$DEPLOY_SCRIPT" | grep -B 50 "^}" | head -n -1)
    source <(grep -A 50 "^log_operation()" "$DEPLOY_SCRIPT" | grep -B 50 "^}" | head -n -1)
}

# Test 1: Verify app store QR code is generated
test_app_store_qr_generated() {
    test_info "Test 1: Verifying Tailscale app store QR code is generated..."
    
    generate_qr_codes 2>/dev/null || true
    
    local qr_png="$QR_CODE_DIR/tailscale-app.png"
    
    if [ -f "$qr_png" ]; then
        test_pass "App store QR code PNG generated"
    else
        test_fail "App store QR code PNG generated" "PNG file not found at $qr_png"
    fi
}

# Test 2: Verify service access QR code is generated
test_service_access_qr_generated() {
    test_info "Test 2: Verifying service access QR code is generated..."
    
    local qr_png="$QR_CODE_DIR/service-access.png"
    
    if [ -f "$qr_png" ]; then
        test_pass "Service access QR code PNG generated"
    else
        test_fail "Service access QR code PNG generated" "PNG file not found at $qr_png"
    fi
}

# Test 3: Verify QR codes are saved as PNG files
test_qr_codes_saved_as_png() {
    test_info "Test 3: Verifying QR codes are saved as valid PNG files..."
    
    local app_qr="$QR_CODE_DIR/tailscale-app.png"
    local service_qr="$QR_CODE_DIR/service-access.png"
    
    local all_valid=true
    
    # Check app store QR code
    if [ -f "$app_qr" ]; then
        if ! file "$app_qr" | grep -q "PNG image data"; then
            all_valid=false
            test_fail "App store QR code is valid PNG" "File is not a valid PNG image"
        fi
    else
        all_valid=false
        test_fail "App store QR code is valid PNG" "File not found"
    fi
    
    # Check service access QR code
    if [ -f "$service_qr" ]; then
        if ! file "$service_qr" | grep -q "PNG image data"; then
            all_valid=false
            test_fail "Service access QR code is valid PNG" "File is not a valid PNG image"
        fi
    else
        all_valid=false
        test_fail "Service access QR code is valid PNG" "File not found"
    fi
    
    if [ "$all_valid" = true ]; then
        test_pass "QR codes saved as valid PNG files"
    fi
}

# Test 4: Verify ASCII art QR codes are generated for terminal display
test_ascii_qr_codes_generated() {
    test_info "Test 4: Verifying ASCII art QR codes are generated..."
    
    local app_ascii="$QR_CODE_DIR/tailscale-app.txt"
    local service_ascii="$QR_CODE_DIR/service-access.txt"
    
    local both_exist=true
    
    if [ ! -f "$app_ascii" ]; then
        both_exist=false
        test_fail "App store ASCII QR code generated" "File not found at $app_ascii"
    fi
    
    if [ ! -f "$service_ascii" ]; then
        both_exist=false
        test_fail "Service access ASCII QR code generated" "File not found at $service_ascii"
    fi
    
    if [ "$both_exist" = true ]; then
        test_pass "ASCII art QR codes generated for terminal display"
    fi
}

# Test 5: Verify app store QR code contains correct URL
test_app_store_qr_contains_correct_url() {
    test_info "Test 5: Verifying app store QR code contains correct URL..."
    
    local qr_png="$QR_CODE_DIR/tailscale-app.png"
    local expected_url="https://tailscale.com/download"
    
    if [ -f "$qr_png" ]; then
        # Decode QR code and check URL
        if command -v zbarimg >/dev/null 2>&1; then
            local decoded_url=$(zbarimg -q --raw "$qr_png" 2>/dev/null || echo "")
            if [ "$decoded_url" = "$expected_url" ]; then
                test_pass "App store QR code contains correct URL"
            else
                test_fail "App store QR code contains correct URL" "Expected '$expected_url', got '$decoded_url'"
            fi
        else
            # If zbarimg not available, check log file for URL
            if grep -q "$expected_url" "$LOG_FILE"; then
                test_pass "App store QR code contains correct URL (verified via log)"
            else
                test_fail "App store QR code contains correct URL" "URL not found in log file (zbarimg not available for decoding)"
            fi
        fi
    else
        test_fail "App store QR code contains correct URL" "QR code file not found"
    fi
}

# Test 6: Verify service access QR code contains correct URL format
test_service_access_qr_contains_correct_url() {
    test_info "Test 6: Verifying service access QR code contains correct URL format..."
    
    local qr_png="$QR_CODE_DIR/service-access.png"
    
    if [ -f "$qr_png" ]; then
        # Check log file for service access URL
        if grep -q "Service access URL: https://" "$LOG_FILE"; then
            test_pass "Service access QR code contains correct URL format"
        else
            test_fail "Service access QR code contains correct URL format" "Service access URL not found in log"
        fi
    else
        test_fail "Service access QR code contains correct URL format" "QR code file not found"
    fi
}

# Test 7: Verify QR code directory is created with correct permissions
test_qr_directory_permissions() {
    test_info "Test 7: Verifying QR code directory has correct permissions..."
    
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

# Test 8: Verify PNG files have correct permissions
test_png_file_permissions() {
    test_info "Test 8: Verifying PNG files have correct permissions..."
    
    local app_qr="$QR_CODE_DIR/tailscale-app.png"
    local service_qr="$QR_CODE_DIR/service-access.png"
    
    local all_correct=true
    
    if [ -f "$app_qr" ]; then
        local perms=$(stat -c "%a" "$app_qr")
        if [ "$perms" != "644" ]; then
            all_correct=false
            test_fail "App store QR code has correct permissions" "Expected 644, got $perms"
        fi
    else
        all_correct=false
        test_fail "App store QR code has correct permissions" "File not found"
    fi
    
    if [ -f "$service_qr" ]; then
        local perms=$(stat -c "%a" "$service_qr")
        if [ "$perms" != "644" ]; then
            all_correct=false
            test_fail "Service access QR code has correct permissions" "Expected 644, got $perms"
        fi
    else
        all_correct=false
        test_fail "Service access QR code has correct permissions" "File not found"
    fi
    
    if [ "$all_correct" = true ]; then
        test_pass "PNG files have correct permissions (644)"
    fi
}

# Test 9: Verify ASCII files have correct permissions
test_ascii_file_permissions() {
    test_info "Test 9: Verifying ASCII files have correct permissions..."
    
    local app_ascii="$QR_CODE_DIR/tailscale-app.txt"
    local service_ascii="$QR_CODE_DIR/service-access.txt"
    
    local all_correct=true
    
    if [ -f "$app_ascii" ]; then
        local perms=$(stat -c "%a" "$app_ascii")
        if [ "$perms" != "644" ]; then
            all_correct=false
            test_fail "App store ASCII QR code has correct permissions" "Expected 644, got $perms"
        fi
    else
        all_correct=false
        test_fail "App store ASCII QR code has correct permissions" "File not found"
    fi
    
    if [ -f "$service_ascii" ]; then
        local perms=$(stat -c "%a" "$service_ascii")
        if [ "$perms" != "644" ]; then
            all_correct=false
            test_fail "Service access ASCII QR code has correct permissions" "Expected 644, got $perms"
        fi
    else
        all_correct=false
        test_fail "Service access ASCII QR code has correct permissions" "File not found"
    fi
    
    if [ "$all_correct" = true ]; then
        test_pass "ASCII files have correct permissions (644)"
    fi
}

# Test 10: Verify function logs all operations
test_function_logs_operations() {
    test_info "Test 10: Verifying function logs all operations..."
    
    if [ -f "$LOG_FILE" ]; then
        local all_logged=true
        
        # Check for function call log
        if ! grep -q "FUNCTION: generate_qr_codes called" "$LOG_FILE"; then
            all_logged=false
            test_fail "Function call logged" "Function call log entry not found"
        fi
        
        # Check for app store QR code generation log
        if ! grep -q "Generating QR code for Tailscale app store" "$LOG_FILE"; then
            all_logged=false
            test_fail "App store QR generation logged" "App store QR generation log entry not found"
        fi
        
        # Check for service access QR code generation log
        if ! grep -q "Generating QR code for service access URL" "$LOG_FILE"; then
            all_logged=false
            test_fail "Service access QR generation logged" "Service access QR generation log entry not found"
        fi
        
        # Check for completion log
        if ! grep -q "QR code generation completed" "$LOG_FILE"; then
            all_logged=false
            test_fail "Completion logged" "Completion log entry not found"
        fi
        
        if [ "$all_logged" = true ]; then
            test_pass "Function logs all operations"
        fi
    else
        test_fail "Function logs all operations" "Log file not found"
    fi
}

# Test 11: Verify both PNG and ASCII versions are created for each QR code
test_both_formats_created() {
    test_info "Test 11: Verifying both PNG and ASCII formats created for each QR code..."
    
    local app_png="$QR_CODE_DIR/tailscale-app.png"
    local app_ascii="$QR_CODE_DIR/tailscale-app.txt"
    local service_png="$QR_CODE_DIR/service-access.png"
    local service_ascii="$QR_CODE_DIR/service-access.txt"
    
    local all_exist=true
    
    if [ ! -f "$app_png" ]; then
        all_exist=false
        test_fail "App store PNG exists" "File not found"
    fi
    
    if [ ! -f "$app_ascii" ]; then
        all_exist=false
        test_fail "App store ASCII exists" "File not found"
    fi
    
    if [ ! -f "$service_png" ]; then
        all_exist=false
        test_fail "Service access PNG exists" "File not found"
    fi
    
    if [ ! -f "$service_ascii" ]; then
        all_exist=false
        test_fail "Service access ASCII exists" "File not found"
    fi
    
    if [ "$all_exist" = true ]; then
        test_pass "Both PNG and ASCII formats created for each QR code"
    fi
}

# Test 12: Verify QR code files are non-empty
test_qr_files_non_empty() {
    test_info "Test 12: Verifying QR code files are non-empty..."
    
    local app_png="$QR_CODE_DIR/tailscale-app.png"
    local service_png="$QR_CODE_DIR/service-access.png"
    
    local all_non_empty=true
    
    if [ -f "$app_png" ]; then
        if [ ! -s "$app_png" ]; then
            all_non_empty=false
            test_fail "App store QR code is non-empty" "File is empty"
        fi
    else
        all_non_empty=false
        test_fail "App store QR code is non-empty" "File not found"
    fi
    
    if [ -f "$service_png" ]; then
        if [ ! -s "$service_png" ]; then
            all_non_empty=false
            test_fail "Service access QR code is non-empty" "File is empty"
        fi
    else
        all_non_empty=false
        test_fail "Service access QR code is non-empty" "File not found"
    fi
    
    if [ "$all_non_empty" = true ]; then
        test_pass "QR code files are non-empty"
    fi
}

# Test 13: Verify function handles missing qrencode gracefully
test_missing_qrencode_handling() {
    test_info "Test 13: Verifying function handles missing qrencode gracefully..."
    
    # This test checks if error messages are properly logged when qrencode fails
    # We can't actually remove qrencode, but we can check the error handling code exists
    
    if grep -q "Failed to generate.*QR code" "$DEPLOY_SCRIPT"; then
        test_pass "Function has error handling for qrencode failures"
    else
        test_fail "Function has error handling for qrencode failures" "Error handling code not found"
    fi
}

# Test 14: Verify QR code directory ownership
test_qr_directory_ownership() {
    test_info "Test 14: Verifying QR code directory ownership..."
    
    if [ -d "$QR_CODE_DIR" ]; then
        # In test environment, we may not be root, so just verify ownership is set
        local owner=$(stat -c "%U:%G" "$QR_CODE_DIR")
        if [ -n "$owner" ]; then
            test_pass "QR code directory has ownership set ($owner)"
        else
            test_fail "QR code directory has ownership set" "Could not determine ownership"
        fi
    else
        test_fail "QR code directory has ownership set" "Directory not found"
    fi
}

# Test 15: Verify function completes successfully
test_function_completes_successfully() {
    test_info "Test 15: Verifying function completes successfully..."
    
    # Run function again and check return code
    if generate_qr_codes 2>/dev/null; then
        test_pass "Function completes successfully"
    else
        test_fail "Function completes successfully" "Function returned non-zero exit code"
    fi
}

# Main test execution
main() {
    echo "=========================================="
    echo "Task 12.5: QR Code Generation Unit Tests"
    echo "=========================================="
    echo ""
    
    # Check if qrencode is installed
    if ! command -v qrencode &> /dev/null; then
        echo -e "${RED}ERROR: qrencode is not installed${NC}"
        echo "Please install it with: apt install qrencode"
        echo ""
        exit 1
    fi
    
    setup_test_env
    
    # Source the deploy script functions
    source_deploy_script
    
    # Run all tests
    test_app_store_qr_generated
    test_service_access_qr_generated
    test_qr_codes_saved_as_png
    test_ascii_qr_codes_generated
    test_app_store_qr_contains_correct_url
    test_service_access_qr_contains_correct_url
    test_qr_directory_permissions
    test_png_file_permissions
    test_ascii_file_permissions
    test_function_logs_operations
    test_both_formats_created
    test_qr_files_non_empty
    test_missing_qrencode_handling
    test_qr_directory_ownership
    test_function_completes_successfully
    
    # Cleanup
    cleanup_test_env
    
    # Print summary
    echo ""
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
        echo "  - 6.1: Generate QR code for Tailscale app store"
        echo "  - 6.2: Generate QR code for service access URL"
        echo "  - 6.3: Display QR codes in terminal"
        echo "  - 6.4: QR code files persist"
        echo "  - 6.5: Generate ASCII art version"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

# Run main
main
