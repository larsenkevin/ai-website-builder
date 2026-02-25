#!/bin/bash
################################################################################
# Simple Test for Task 10.2: Authentication Completion Waiter
#
# This test verifies that the wait_for_auth_completion() function:
# 1. Polls Tailscale status to check authentication completion
# 2. Implements 5-minute timeout
# 3. Displays timeout message and retry option on timeout
# 4. Allows manual continuation if authentication completed out-of-band
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

# Source the deploy script to get access to functions
source_deploy_script() {
    # Extract the functions we need
    source <(sed -n '/^wait_for_auth_completion()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^log_operation()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_progress()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_success()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_info()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_warning()/,/^}/p' "$DEPLOY_SCRIPT")
    
    # Set up required variables
    LOG_FILE="/tmp/test-deploy-10.2-$.log"
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    NC='\033[0m'
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Task 10.2: Authentication Completion Waiter Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Initialize test environment
source_deploy_script

################################################################################
# Test 1: Function accepts timeout parameter
################################################################################
test_start "Test 1: Function accepts timeout parameter"

# Mock tailscale command to simulate successful authentication
tailscale() {
    if [ "$1" = "status" ]; then
        echo "100.64.0.1  hostname  user@  linux   -"
        return 0
    fi
}
export -f tailscale

# Run with short timeout (should succeed immediately with mocked tailscale)
timeout 10 bash -c "source_deploy_script; wait_for_auth_completion 5" > /dev/null 2>&1
exit_code=$?

if [ $exit_code -eq 0 ]; then
    test_pass "Test 1: Function accepts timeout parameter"
else
    test_fail "Test 1: Function accepts timeout parameter" "Function failed with exit code $exit_code"
fi

unset -f tailscale

################################################################################
# Test 2: Function polls Tailscale status
################################################################################
test_start "Test 2: Function polls Tailscale status"

# Mock tailscale command to track calls
TAILSCALE_CALLS=0
tailscale() {
    TAILSCALE_CALLS=$((TAILSCALE_CALLS + 1))
    if [ "$1" = "status" ]; then
        # Succeed after 2 calls
        if [ $TAILSCALE_CALLS -ge 2 ]; then
            echo "100.64.0.1  hostname  user@  linux   -"
            return 0
        else
            return 1
        fi
    fi
}
export -f tailscale
export TAILSCALE_CALLS

# Run with short timeout
timeout 30 bash -c "
    source_deploy_script
    TAILSCALE_CALLS=0
    tailscale() {
        TAILSCALE_CALLS=\$((TAILSCALE_CALLS + 1))
        if [ \"\$1\" = \"status\" ]; then
            if [ \$TAILSCALE_CALLS -ge 2 ]; then
                echo \"100.64.0.1  hostname  user@  linux   -\"
                return 0
            else
                return 1
            fi
        fi
    }
    export -f tailscale
    wait_for_auth_completion 30
" > /dev/null 2>&1
exit_code=$?

if [ $exit_code -eq 0 ]; then
    test_pass "Test 2: Function polls Tailscale status"
else
    test_fail "Test 2: Function polls Tailscale status" "Function did not poll successfully"
fi

unset -f tailscale
unset TAILSCALE_CALLS

################################################################################
# Test 3: Function implements timeout mechanism
################################################################################
test_start "Test 3: Function implements timeout mechanism"

# Mock tailscale to always fail (never authenticate)
tailscale() {
    if [ "$1" = "status" ]; then
        return 1
    fi
}
export -f tailscale

# Run with very short timeout and provide abort input
output=$(timeout 15 bash -c "
    source_deploy_script
    tailscale() {
        if [ \"\$1\" = \"status\" ]; then
            return 1
        fi
    }
    export -f tailscale
    echo '3' | wait_for_auth_completion 3
" 2>&1 || true)

# Check if timeout message was displayed
if echo "$output" | grep -q "Authentication Timeout"; then
    test_pass "Test 3: Function implements timeout mechanism"
else
    test_fail "Test 3: Function implements timeout mechanism" "Timeout message not displayed"
fi

unset -f tailscale

################################################################################
# Test 4: Function displays timeout message with options
################################################################################
test_start "Test 4: Function displays timeout message with options"

# Mock tailscale to always fail
tailscale() {
    if [ "$1" = "status" ]; then
        return 1
    fi
}
export -f tailscale

# Run with very short timeout and provide abort input
output=$(timeout 15 bash -c "
    source_deploy_script
    tailscale() {
        if [ \"\$1\" = \"status\" ]; then
            return 1
        fi
    }
    export -f tailscale
    echo '3' | wait_for_auth_completion 3
" 2>&1 || true)

# Check for retry option
has_retry=false
has_continue=false
has_abort=false

if echo "$output" | grep -q "Retry"; then
    has_retry=true
fi

if echo "$output" | grep -q "Continue"; then
    has_continue=true
fi

if echo "$output" | grep -q "Abort"; then
    has_abort=true
fi

if [ "$has_retry" = true ] && [ "$has_continue" = true ] && [ "$has_abort" = true ]; then
    test_pass "Test 4: Function displays timeout message with options"
else
    test_fail "Test 4: Function displays timeout message with options" \
        "Missing options - Retry: $has_retry, Continue: $has_continue, Abort: $has_abort"
fi

unset -f tailscale

################################################################################
# Test 5: Function allows manual continuation
################################################################################
test_start "Test 5: Function allows manual continuation"

# Mock tailscale to simulate authentication completed out-of-band
tailscale() {
    if [ "$1" = "status" ]; then
        # Initially fail during polling, but succeed when user chooses continue
        if [ "${MANUAL_CONTINUE:-false}" = "true" ]; then
            echo "100.64.0.1  hostname  user@  linux   -"
            return 0
        else
            return 1
        fi
    fi
}
export -f tailscale

# Run with very short timeout and provide continue input
output=$(timeout 15 bash -c "
    source_deploy_script
    tailscale() {
        if [ \"\$1\" = \"status\" ]; then
            if [ \"\${MANUAL_CONTINUE:-false}\" = \"true\" ]; then
                echo \"100.64.0.1  hostname  user@  linux   -\"
                return 0
            else
                return 1
            fi
        fi
    }
    export -f tailscale
    export MANUAL_CONTINUE=true
    echo '2' | wait_for_auth_completion 3
" 2>&1 || true)

# Check if manual continuation was accepted
if echo "$output" | grep -q "Continuing with deployment"; then
    test_pass "Test 5: Function allows manual continuation"
else
    test_fail "Test 5: Function allows manual continuation" "Manual continuation not working"
fi

unset -f tailscale

################################################################################
# Test 6: Function logs operations
################################################################################
test_start "Test 6: Function logs operations"

# Clear log file
> "$LOG_FILE"

# Mock tailscale to succeed immediately
tailscale() {
    if [ "$1" = "status" ]; then
        echo "100.64.0.1  hostname  user@  linux   -"
        return 0
    fi
}
export -f tailscale

timeout 10 bash -c "source_deploy_script; wait_for_auth_completion 5" > /dev/null 2>&1

# Check that log file was written to
if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
    if grep -q "wait_for_auth_completion called" "$LOG_FILE"; then
        test_pass "Test 6: Function logs operations"
    else
        test_fail "Test 6: Function logs operations" "Function call not logged"
    fi
else
    test_fail "Test 6: Function logs operations" "Log file not created or empty"
fi

unset -f tailscale

# Cleanup
rm -f "$LOG_FILE"

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
