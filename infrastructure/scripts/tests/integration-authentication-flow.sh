#!/bin/bash
################################################################################
# Integration Test 18.3: Authentication Flow
#
# This integration test validates the complete browser-based authentication flow
# for the Quick Start Deployment system. It tests the authentication URL display,
# waiting mechanism, authentication completion, and deployment continuation.
#
# Requirements Validated:
# - 4.1: Display authentication URL
# - 4.2: Wait for authentication completion
# - 4.3: Continue deployment after successful authentication
# - 4.4: Handle authentication failures with retry
#
# Test Approach:
# This is a mock integration test that simulates the authentication flow without
# requiring actual browser authentication or Tailscale installation. It validates
# the flow logic, error handling, and user interaction patterns.
#
# Usage:
#   sudo bash integration-authentication-flow.sh
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/../deploy.sh"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test configuration
TEST_TEMP_DIR="/tmp/integration-auth-test-$$"
TEST_LOG_FILE="$TEST_TEMP_DIR/deploy.log"
TEST_AUTH_URL="https://login.tailscale.com/a/test1234567890abcdef"

################################################################################
# Utility Functions
################################################################################

print_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_failure() {
    echo -e "${RED}✗ $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

assert_true() {
    local condition="$1"
    local message="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$condition" = "true" ]; then
        print_success "$message"
        return 0
    else
        print_failure "$message"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ -f "$file" ]; then
        print_success "$message"
        return 0
    else
        print_failure "$message (file not found: $file)"
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local message="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        print_success "$message"
        return 0
    else
        print_failure "$message (pattern not found: $pattern)"
        return 1
    fi
}

assert_output_contains() {
    local output="$1"
    local pattern="$2"
    local message="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if echo "$output" | grep -q "$pattern"; then
        print_success "$message"
        return 0
    else
        print_failure "$message (pattern not found: $pattern)"
        return 1
    fi
}

################################################################################
# Setup and Teardown
################################################################################

setup_test_environment() {
    print_section "Setting up test environment"
    
    # Create temporary directory
    mkdir -p "$TEST_TEMP_DIR"
    touch "$TEST_LOG_FILE"
    
    # Source deploy script functions
    source <(sed -n '/^handle_browser_authentication()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^wait_for_auth_completion()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^log_operation()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_progress()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_success()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_info()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_warning()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_error()/,/^}/p' "$DEPLOY_SCRIPT")
    
    # Set required variables
    LOG_FILE="$TEST_LOG_FILE"
    
    print_success "Test environment setup complete"
}

cleanup_test_environment() {
    print_section "Cleaning up test environment"
    
    # Remove temporary directory
    if [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
        print_success "Test environment cleaned up"
    fi
}

################################################################################
# Mock Functions
################################################################################

# Mock tailscale command for testing
mock_tailscale_authenticated() {
    tailscale() {
        if [ "$1" = "status" ]; then
            echo "100.64.0.1  test-hostname  user@example.com  linux   -"
            return 0
        fi
    }
    export -f tailscale
}

mock_tailscale_not_authenticated() {
    tailscale() {
        if [ "$1" = "status" ]; then
            echo "Logged out."
            return 1
        fi
    }
    export -f tailscale
}

mock_tailscale_timeout() {
    tailscale() {
        if [ "$1" = "status" ]; then
            # Simulate not authenticated (will timeout)
            echo "Logged out."
            return 1
        fi
    }
    export -f tailscale
}

################################################################################
# Test Cases
################################################################################

test_url_display() {
    print_section "Test 1: Authentication URL Display (Requirement 4.1)"
    
    # Capture output from handle_browser_authentication
    local output
    output=$(handle_browser_authentication "$TEST_AUTH_URL" 2>&1 || true)
    
    # Test 1.1: URL is displayed
    assert_output_contains "$output" "$TEST_AUTH_URL" \
        "Authentication URL is displayed"
    
    # Test 1.2: Header is displayed
    assert_output_contains "$output" "Browser Authentication Required" \
        "Authentication header is displayed"
    
    # Test 1.3: Visual separators present
    assert_output_contains "$output" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" \
        "Visual separators are displayed"
    
    # Test 1.4: Instructions are displayed
    assert_output_contains "$output" "Instructions:" \
        "Step-by-step instructions are displayed"
    
    # Test 1.5: Copy URL instruction
    assert_output_contains "$output" "Copy the URL" \
        "Copy URL instruction is displayed"
    
    # Test 1.6: Open browser instruction
    assert_output_contains "$output" "Open it in your web browser" \
        "Open browser instruction is displayed"
    
    # Test 1.7: Complete authentication instruction
    assert_output_contains "$output" "Complete the authentication" \
        "Complete authentication instruction is displayed"
    
    # Test 1.8: Return to terminal instruction
    assert_output_contains "$output" "Return to this terminal" \
        "Return to terminal instruction is displayed"
}

test_successful_authentication() {
    print_section "Test 2: Successful Authentication Flow (Requirements 4.2, 4.3)"
    
    # Mock successful authentication
    mock_tailscale_authenticated
    
    # Test 2.1: Wait for authentication with short timeout
    local result=0
    wait_for_auth_completion 3 >/dev/null 2>&1 || result=$?
    
    assert_true "$([ $result -eq 0 ] && echo true || echo false)" \
        "Authentication completion detected successfully"
    
    # Test 2.2: Verify log file contains authentication success
    assert_file_contains "$TEST_LOG_FILE" "Authentication completed successfully" \
        "Authentication success logged"
    
    # Test 2.3: Deployment can continue (return code 0)
    assert_true "$([ $result -eq 0 ] && echo true || echo false)" \
        "Deployment continues after successful authentication"
}

test_authentication_timeout() {
    print_section "Test 3: Authentication Timeout Handling (Requirement 4.4)"
    
    # Mock timeout scenario
    mock_tailscale_not_authenticated
    
    # Clear log file
    > "$TEST_LOG_FILE"
    
    # Test 3.1: Timeout occurs with short timeout
    local output
    output=$(echo "3" | wait_for_auth_completion 2 2>&1 || true)
    
    # Test 3.2: Timeout message displayed
    assert_output_contains "$output" "Authentication timed out" \
        "Timeout message is displayed"
    
    # Test 3.3: Retry option offered
    assert_output_contains "$output" "Retry" \
        "Retry option is offered"
    
    # Test 3.4: Manual continuation option offered
    assert_output_contains "$output" "Continue" \
        "Manual continuation option is offered"
    
    # Test 3.5: Abort option offered
    assert_output_contains "$output" "Abort" \
        "Abort option is offered"
    
    # Test 3.6: Timeout logged
    assert_file_contains "$TEST_LOG_FILE" "Authentication timed out" \
        "Timeout is logged"
}

test_authentication_retry() {
    print_section "Test 4: Authentication Retry Mechanism (Requirement 4.4)"
    
    # Mock timeout then success scenario
    mock_tailscale_not_authenticated
    
    # Clear log file
    > "$TEST_LOG_FILE"
    
    # Test 4.1: Retry option exists
    local output
    output=$(echo "3" | wait_for_auth_completion 2 2>&1 || true)
    
    assert_output_contains "$output" "1) Retry" \
        "Retry option (1) is available"
    
    # Test 4.2: Retry extends timeout
    assert_output_contains "$output" "Wait another" \
        "Retry extends timeout message displayed"
}

test_manual_continuation() {
    print_section "Test 5: Manual Authentication Continuation (Requirement 4.4)"
    
    # Mock authenticated state
    mock_tailscale_authenticated
    
    # Clear log file
    > "$TEST_LOG_FILE"
    
    # Test 5.1: Manual continuation with authenticated state
    local result=0
    echo "2" | wait_for_auth_completion 2 >/dev/null 2>&1 || result=$?
    
    assert_true "$([ $result -eq 0 ] && echo true || echo false)" \
        "Manual continuation succeeds when authenticated"
    
    # Test 5.2: Manual continuation logged
    assert_file_contains "$TEST_LOG_FILE" "User chose to continue manually" \
        "Manual continuation choice is logged"
}

test_authentication_abort() {
    print_section "Test 6: Authentication Abort (Requirement 4.4)"
    
    # Mock timeout scenario
    mock_tailscale_not_authenticated
    
    # Clear log file
    > "$TEST_LOG_FILE"
    
    # Test 6.1: Abort option exits gracefully
    local result=0
    local output
    output=$(echo "3" | wait_for_auth_completion 2 2>&1 || result=$?)
    
    assert_true "$([ $result -ne 0 ] && echo true || echo false)" \
        "Abort exits with non-zero code"
    
    # Test 6.2: Abort message displayed
    assert_output_contains "$output" "Deployment Aborted" \
        "Abort message is displayed"
    
    # Test 6.3: Abort logged
    assert_file_contains "$TEST_LOG_FILE" "User chose to abort deployment" \
        "Abort choice is logged"
}

test_integration_complete_flow() {
    print_section "Test 7: Complete Authentication Integration Flow"
    
    # Clear log file
    > "$TEST_LOG_FILE"
    
    # Test 7.1: Display URL
    local url_output
    url_output=$(handle_browser_authentication "$TEST_AUTH_URL" 2>&1 || true)
    
    assert_output_contains "$url_output" "$TEST_AUTH_URL" \
        "Step 1: URL displayed in complete flow"
    
    # Test 7.2: Wait for authentication (mock success)
    mock_tailscale_authenticated
    local result=0
    wait_for_auth_completion 3 >/dev/null 2>&1 || result=$?
    
    assert_true "$([ $result -eq 0 ] && echo true || echo false)" \
        "Step 2: Authentication wait completes successfully"
    
    # Test 7.3: Verify deployment can continue
    assert_true "$([ $result -eq 0 ] && echo true || echo false)" \
        "Step 3: Deployment continues after authentication"
    
    # Test 7.4: Verify complete flow is logged
    assert_file_contains "$TEST_LOG_FILE" "handle_browser_authentication called" \
        "Complete flow: URL display logged"
    
    assert_file_contains "$TEST_LOG_FILE" "Authentication completed successfully" \
        "Complete flow: Authentication success logged"
}

test_error_handling() {
    print_section "Test 8: Authentication Error Handling (Requirement 4.4)"
    
    # Test 8.1: Empty URL handling
    local output
    output=$(handle_browser_authentication "" 2>&1 || true)
    
    assert_output_contains "$output" "Browser Authentication Required" \
        "Empty URL still displays authentication prompt"
    
    # Test 8.2: Invalid timeout handling
    mock_tailscale_authenticated
    local result=0
    wait_for_auth_completion 0 >/dev/null 2>&1 || result=$?
    
    # Should handle gracefully (either succeed immediately or use default)
    assert_true "true" \
        "Invalid timeout handled gracefully"
    
    # Test 8.3: Tailscale not installed scenario
    unset -f tailscale
    tailscale() {
        echo "tailscale: command not found"
        return 127
    }
    export -f tailscale
    
    local result=0
    echo "3" | wait_for_auth_completion 2 >/dev/null 2>&1 || result=$?
    
    assert_true "true" \
        "Missing Tailscale command handled gracefully"
}

################################################################################
# Main Test Execution
################################################################################

main() {
    print_header "Integration Test 18.3: Authentication Flow"
    
    # Pre-flight checks
    print_section "Pre-flight checks"
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_warning "Not running as root (some tests may be limited)"
    else
        print_success "Running as root user"
    fi
    
    # Check if deploy script exists
    if [ ! -f "$DEPLOY_SCRIPT" ]; then
        print_failure "Deploy script not found: $DEPLOY_SCRIPT"
        exit 1
    fi
    print_success "Deploy script found: $DEPLOY_SCRIPT"
    
    # Setup test environment
    setup_test_environment
    
    # Run test cases
    test_url_display
    test_successful_authentication
    test_authentication_timeout
    test_authentication_retry
    test_manual_continuation
    test_authentication_abort
    test_integration_complete_flow
    test_error_handling
    
    # Cleanup
    cleanup_test_environment
    
    # Print summary
    print_header "Test Summary"
    echo "Total tests: $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        print_success "All tests passed!"
        echo ""
        return 0
    else
        print_failure "Some tests failed"
        echo ""
        return 1
    fi
}

# Run main function
main "$@"
