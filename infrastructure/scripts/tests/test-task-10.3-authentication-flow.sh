#!/bin/bash
################################################################################
# Unit Tests for Task 10.3: Authentication Flow
#
# This test suite verifies the complete authentication flow including:
# - URL displayed correctly (handle_browser_authentication)
# - Timeout handled gracefully (wait_for_auth_completion)
# - Successful authentication continues deployment
# - Failed authentication shows error and retry
#
# Requirements: 4.1, 4.2, 4.3, 4.4
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/../deploy.sh"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Source the deploy script functions
source_deploy_script() {
    # Extract the functions we need
    source <(sed -n '/^handle_browser_authentication()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^wait_for_auth_completion()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^log_operation()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_progress()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_success()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_info()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_warning()/,/^}/p' "$DEPLOY_SCRIPT")
    
    # Set up required variables
    LOG_FILE="/tmp/test-deploy-10.3-$$.log"
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m'
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Task 10.3: Authentication Flow Unit Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Initialize test environment
source_deploy_script

################################################################################
# Test Group 1: URL Display (Requirement 4.1)
################################################################################

echo "Test Group 1: URL Display (Requirement 4.1)"
echo "────────────────────────────────────────────"
echo ""

################################################################################
# Test 1: URL displayed with clear formatting
################################################################################
test_start "Test 1: URL displayed with clear formatting"

test_url="https://login.tailscale.com/a/1234567890abcdef"
output=$(handle_browser_authentication "$test_url" 2>&1)

has_url=false
has_header=false
has_separator=false

if echo "$output" | grep -q "$test_url"; then
    has_url=true
fi

if echo "$output" | grep -q "Browser Authentication Required"; then
    has_header=true
fi

if echo "$output" | grep -q "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; then
    has_separator=true
fi

if [ "$has_url" = true ] && [ "$has_header" = true ] && [ "$has_separator" = true ]; then
    test_pass "Test 1: URL displayed with clear formatting"
else
    test_fail "Test 1: URL displayed with clear formatting" \
        "Missing elements - URL: $has_url, Header: $has_header, Separator: $has_separator"
fi

################################################################################
# Test 2: Step-by-step instructions displayed
################################################################################
test_start "Test 2: Step-by-step instructions displayed"

output=$(handle_browser_authentication "$test_url" 2>&1)

has_instructions_header=false
has_copy_step=false
has_open_step=false
has_complete_step=false
has_return_step=false

if echo "$output" | grep -q "Instructions:"; then
    has_instructions_header=true
fi

if echo "$output" | grep -q "Copy the URL"; then
    has_copy_step=true
fi

if echo "$output" | grep -q "Open it in your web browser"; then
    has_open_step=true
fi

if echo "$output" | grep -q "Complete the authentication"; then
    has_complete_step=true
fi

if echo "$output" | grep -q "Return to this terminal"; then
    has_return_step=true
fi

if [ "$has_instructions_header" = true ] && [ "$has_copy_step" = true ] && \
   [ "$has_open_step" = true ] && [ "$has_complete_step" = true ] && \
   [ "$has_return_step" = true ]; then
    test_pass "Test 2: Step-by-step instructions displayed"
else
    test_fail "Test 2: Step-by-step instructions displayed" \
        "Missing steps - Header: $has_instructions_header, Copy: $has_copy_step, Open: $has_open_step, Complete: $has_complete_step, Return: $has_return_step"
fi
