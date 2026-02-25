#!/bin/bash
################################################################################
# Simple Test for Task 10.1: Browser Authentication Handler
#
# This test verifies that the handle_browser_authentication() function:
# 1. Displays a clickable authentication URL with clear formatting
# 2. Displays instructions for the user to open the URL in browser
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/../deploy.sh"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_start() {
    local test_name="$1"
    echo -e "${YELLOW}▶ Running: $test_name${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    local test_name="$1"
    echo -e "${GREEN}✓ PASSED: $test_name${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    echo -e "${RED}✗ FAILED: $test_name${NC}"
    echo -e "${RED}  Reason: $reason${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Source the deploy script to get access to functions
# We need to prevent main() from running, so we'll source in a subshell
source_deploy_script() {
    # Extract only the functions we need, not the main execution
    source <(sed -n '/^handle_browser_authentication()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^log_operation()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_info()/,/^}/p' "$DEPLOY_SCRIPT")
    
    # Set up required variables
    LOG_FILE="/tmp/test-deploy-10.1-$$.log"
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Task 10.1: Browser Authentication Handler Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Initialize test environment
source_deploy_script

################################################################################
# Test 1: Function handles empty URL (placeholder mode)
################################################################################
test_start "Test 1: Function handles empty URL gracefully"

output=$(handle_browser_authentication "" 2>&1)

if echo "$output" | grep -q "Browser authentication will be required"; then
    test_pass "Test 1: Function handles empty URL gracefully"
else
    test_fail "Test 1: Function handles empty URL gracefully" "Expected placeholder message not found"
fi

################################################################################
# Test 2: Function displays authentication URL with clear formatting
################################################################################
test_start "Test 2: Function displays authentication URL with clear formatting"

test_url="https://login.tailscale.com/a/1234567890abcdef"
output=$(handle_browser_authentication "$test_url" 2>&1)

# Check for key elements in the output
has_url=false
has_formatting=false
has_instructions=false

if echo "$output" | grep -q "$test_url"; then
    has_url=true
fi

if echo "$output" | grep -q "Browser Authentication Required"; then
    has_formatting=true
fi

if echo "$output" | grep -q "Instructions:"; then
    has_instructions=true
fi

if [ "$has_url" = true ] && [ "$has_formatting" = true ] && [ "$has_instructions" = true ]; then
    test_pass "Test 2: Function displays authentication URL with clear formatting"
else
    test_fail "Test 2: Function displays authentication URL with clear formatting" \
        "Missing elements - URL: $has_url, Formatting: $has_formatting, Instructions: $has_instructions"
fi

################################################################################
# Test 3: Function displays instructions for browser authentication
################################################################################
test_start "Test 3: Function displays instructions for browser authentication"

output=$(handle_browser_authentication "$test_url" 2>&1)

# Check for specific instruction steps
has_copy_instruction=false
has_open_instruction=false
has_complete_instruction=false
has_return_instruction=false

if echo "$output" | grep -q "Copy the URL"; then
    has_copy_instruction=true
fi

if echo "$output" | grep -q "Open it in your web browser"; then
    has_open_instruction=true
fi

if echo "$output" | grep -q "Complete the authentication"; then
    has_complete_instruction=true
fi

if echo "$output" | grep -q "Return to this terminal"; then
    has_return_instruction=true
fi

if [ "$has_copy_instruction" = true ] && [ "$has_open_instruction" = true ] && \
   [ "$has_complete_instruction" = true ] && [ "$has_return_instruction" = true ]; then
    test_pass "Test 3: Function displays instructions for browser authentication"
else
    test_fail "Test 3: Function displays instructions for browser authentication" \
        "Missing instruction steps - Copy: $has_copy_instruction, Open: $has_open_instruction, Complete: $has_complete_instruction, Return: $has_return_instruction"
fi

################################################################################
# Test 4: Function logs operation without exposing URL
################################################################################
test_start "Test 4: Function logs operation appropriately"

# Clear log file
> "$LOG_FILE"

output=$(handle_browser_authentication "$test_url" 2>&1)

# Check that log file was written to
if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
    # Check that the log contains the function call
    if grep -q "handle_browser_authentication called" "$LOG_FILE"; then
        # Check that the URL is NOT in the log (masked)
        if ! grep -q "$test_url" "$LOG_FILE"; then
            test_pass "Test 4: Function logs operation appropriately"
        else
            test_fail "Test 4: Function logs operation appropriately" "URL should be masked in log"
        fi
    else
        test_fail "Test 4: Function logs operation appropriately" "Function call not logged"
    fi
else
    test_fail "Test 4: Function logs operation appropriately" "Log file not created or empty"
fi

# Cleanup
rm -f "$LOG_FILE"

################################################################################
# Test 5: Function displays URL in a visually distinct way
################################################################################
test_start "Test 5: Function displays URL in a visually distinct way"

output=$(handle_browser_authentication "$test_url" 2>&1)

# Check for visual separators (lines of equals or dashes)
has_separator=false

if echo "$output" | grep -q "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; then
    has_separator=true
fi

if [ "$has_separator" = true ]; then
    test_pass "Test 5: Function displays URL in a visually distinct way"
else
    test_fail "Test 5: Function displays URL in a visually distinct way" "No visual separators found"
fi

################################################################################
# Test Summary
################################################################################
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
else
    echo "Tests failed: $TESTS_FAILED"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Exit with appropriate code
if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
