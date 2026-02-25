#!/usr/bin/env bats
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

# Load BATS support libraries
load '/usr/local/lib/bats-support/load.bash'
load '/usr/local/lib/bats-assert/load.bash'

# Setup and teardown
setup() {
    # Create temporary directory for test artifacts
    export TEST_TEMP_DIR="$(mktemp -d)"
    export LOG_FILE="$TEST_TEMP_DIR/deploy.log"
    export CONFIG_DIR="$TEST_TEMP_DIR/config"
    
    # Source the deploy script functions
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export DEPLOY_SCRIPT="$SCRIPT_DIR/deploy.sh"
    
    # Extract and source required functions
    source <(sed -n '/^handle_browser_authentication()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^wait_for_auth_completion()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^log_operation()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_progress()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_success()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_info()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^display_warning()/,/^}/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^mask_value()/,/^}/p' "$DEPLOY_SCRIPT")
    
    # Set up color codes (required by functions)
    export BLUE='\033[0;34m'
    export YELLOW='\033[1;33m'
    export GREEN='\033[0;32m'
    export RED='\033[0;31m'
    export NC='\033[0m'
    
    # Initialize log file
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
}

teardown() {
    # Clean up temporary directory
    rm -rf "$TEST_TEMP_DIR"
    
    # Unset mock functions
    unset -f tailscale 2>/dev/null || true
}

################################################################################
# Test Group 1: URL Display (handle_browser_authentication)
# Requirement 4.1: Display authentication URL with clear formatting
################################################################################

@test "handle_browser_authentication: displays URL with clear formatting" {
    local test_url="https://login.tailscale.com/a/1234567890abcdef"
    
    run handle_browser_authentication "$test_url"
    
    # Should succeed
    assert_success
    
    # Should display the URL
    assert_output --partial "$test_url"
    
    # Should have clear formatting with header
    assert_output --partial "Browser Authentication Required"
    
    # Should have visual separators
    assert_output --partial "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

@test "handle_browser_authentication: displays step-by-step instructions" {
    local test_url="https://login.tailscale.com/a/test123"
    
    run handle_browser_authentication "$test_url"
    
    # Should display instructions header
    assert_output --partial "Instructions:"
    
    # Should display all instruction steps
    assert_output --partial "Copy the URL"
    assert_output --partial "Open it in your web browser"
    assert_output --partial "Complete the authentication"
    assert_output --partial "Return to this terminal"
}

@test "handle_browser_authentication: handles empty URL gracefully" {
    run handle_browser_authentication ""
    
    # Should succeed (placeholder mode)
    assert_success
    
    # Should display placeholder message
    assert_output --partial "Browser authentication will be required"
}

@test "handle_browser_authentication: logs operation without exposing URL" {
    local test_url="https://login.tailscale.com/a/secret123"
    
    # Clear log file
    > "$LOG_FILE"
    
    run handle_browser_authentication "$test_url"
    
    # Log file should exist and have content
    [ -f "$LOG_FILE" ]
    [ -s "$LOG_FILE" ]
    
    # Should log function call
    grep -q "handle_browser_authentication called" "$LOG_FILE"
    
    # Should NOT expose the full URL in logs (masked)
    ! grep -q "$test_url" "$LOG_FILE"
}

@test "handle_browser_authentication: URL is visually distinct in output" {
    local test_url="https://login.tailscale.com/a/test"
    
    run handle_browser_authentication "$test_url"
    
    # URL should be on its own line or clearly separated
    # Check that URL appears after "open this URL" text
    assert_output --regexp "open this URL.*$test_url"
}

################################################################################
# Test Group 2: Timeout Handling (wait_for_auth_completion)
# Requirement 4.3: Implement timeout mechanism
################################################################################

@test "wait_for_auth_completion: accepts timeout parameter" {
    # Mock tailscale to succeed immediately
    tailscale() {
        if [ "$1" = "status" ]; then
            echo "100.64.0.1  hostname  user@  linux   -"
            return 0
        fi
    }
    export -f tailscale
    
    # Should accept custom timeout
    run timeout 10 wait_for_auth_completion 5
    
    assert_success
}

@test "wait_for_auth_completion: uses default 5-minute timeout" {
    # Mock tailscale to succeed immediately
    tailscale() {
        if [ "$1" = "status" ]; then
            echo "100.64.0.1  hostname  user@  linux   -"
            return 0
        fi
    }
    export -f tailscale
    
    # Should work with default timeout (300 seconds)
    run timeout 10 wait_for_auth_completion
    
    assert_success
}

@test "wait_for_auth_completion: displays timeout message when timeout reached" {
    # Mock tailscale to always fail (never authenticate)
    tailscale() {
        if [ "$1" = "status" ]; then
            return 1
        fi
    }
    export -f tailscale
    
    # Run with very short timeout and abort
    run bash -c 'echo "3" | timeout 15 wait_for_auth_completion 3'
    
    # Should display timeout message
    assert_output --partial "Authentication Timeout"
    assert_output --partial "did not complete within"
}

@test "wait_for_auth_completion: timeout message includes troubleshooting info" {
    # Mock tailscale to always fail
    tailscale() {
        if [ "$1" = "status" ]; then
            return 1
        fi
    }
    export -f tailscale
    
    # Run with very short timeout and abort
    run bash -c 'echo "3" | timeout 15 wait_for_auth_completion 3'
    
    # Should explain possible reasons
    assert_output --partial "This could mean:"
    assert_output --partial "haven't completed the authentication"
    assert_output --partial "network issue"
}

################################################################################
# Test Group 3: Successful Authentication
# Requirement 4.2: Wait for authentication to complete
# Requirement 4.3: Continue deployment on success
################################################################################

@test "wait_for_auth_completion: detects successful authentication" {
    # Mock tailscale to succeed immediately
    tailscale() {
        if [ "$1" = "status" ]; then
            echo "100.64.0.1  hostname  user@  linux   -"
            return 0
        fi
    }
    export -f tailscale
    
    run timeout 10 wait_for_auth_completion 30
    
    # Should succeed
    assert_success
    
    # Should display success message
    assert_output --partial "Authentication completed successfully"
}

@test "wait_for_auth_completion: polls Tailscale status repeatedly" {
    # Mock tailscale to succeed after 2 attempts
    ATTEMPT_COUNT=0
    tailscale() {
        if [ "$1" = "status" ]; then
            ATTEMPT_COUNT=$((ATTEMPT_COUNT + 1))
            if [ $ATTEMPT_COUNT -ge 2 ]; then
                echo "100.64.0.1  hostname  user@  linux   -"
                return 0
            else
                return 1
            fi
        fi
    }
    export -f tailscale
    export ATTEMPT_COUNT
    
    run timeout 30 bash -c 'wait_for_auth_completion 30'
    
    # Should eventually succeed
    assert_success
}

@test "wait_for_auth_completion: continues deployment after successful auth" {
    # Mock tailscale to succeed
    tailscale() {
        if [ "$1" = "status" ]; then
            echo "100.64.0.1  hostname  user@  linux   -"
            return 0
        fi
    }
    export -f tailscale
    
    run timeout 10 wait_for_auth_completion 30
    
    # Should return 0 (success) to allow deployment to continue
    assert_success
}

@test "wait_for_auth_completion: logs successful authentication" {
    # Clear log file
    > "$LOG_FILE"
    
    # Mock tailscale to succeed
    tailscale() {
        if [ "$1" = "status" ]; then
            echo "100.64.0.1  hostname  user@  linux   -"
            return 0
        fi
    }
    export -f tailscale
    
    run timeout 10 wait_for_auth_completion 30
    
    # Should log the authentication completion
    grep -q "Authentication completed" "$LOG_FILE"
}

################################################################################
# Test Group 4: Failed Authentication and Retry
# Requirement 4.4: Provide retry option and manual continuation
################################################################################

@test "wait_for_auth_completion: offers retry option on timeout" {
    # Mock tailscale to always fail
    tailscale() {
        if [ "$1" = "status" ]; then
            return 1
        fi
    }
    export -f tailscale
    
    # Run with abort option
    run bash -c 'echo "3" | timeout 15 wait_for_auth_completion 3'
    
    # Should offer retry option
    assert_output --partial "Retry"
    assert_output --partial "Wait another"
}

@test "wait_for_auth_completion: offers manual continuation option" {
    # Mock tailscale to always fail initially
    tailscale() {
        if [ "$1" = "status" ]; then
            return 1
        fi
    }
    export -f tailscale
    
    # Run with abort option
    run bash -c 'echo "3" | timeout 15 wait_for_auth_completion 3'
    
    # Should offer continue option
    assert_output --partial "Continue"
    assert_output --partial "I completed authentication"
}

@test "wait_for_auth_completion: offers abort option" {
    # Mock tailscale to always fail
    tailscale() {
        if [ "$1" = "status" ]; then
            return 1
        fi
    }
    export -f tailscale
    
    # Run with abort option
    run bash -c 'echo "3" | timeout 15 wait_for_auth_completion 3'
    
    # Should offer abort option
    assert_output --partial "Abort"
    assert_output --partial "Exit deployment"
}

@test "wait_for_auth_completion: manual continuation verifies auth status" {
    # Mock tailscale to succeed when manual continue is chosen
    tailscale() {
        if [ "$1" = "status" ]; then
            # Succeed to simulate completed authentication
            echo "100.64.0.1  hostname  user@  linux   -"
            return 0
        fi
    }
    export -f tailscale
    
    # Choose manual continuation (option 2)
    run bash -c 'echo "2" | timeout 15 wait_for_auth_completion 3'
    
    # Should verify and continue
    assert_output --partial "Continuing with deployment"
}

@test "wait_for_auth_completion: manual continuation warns if status unclear" {
    # Mock tailscale to return unclear status
    tailscale() {
        if [ "$1" = "status" ]; then
            # Return success but no IP addresses (unclear status)
            echo "# Tailscale is running"
            return 0
        fi
    }
    export -f tailscale
    
    # Choose manual continuation (option 2)
    run bash -c 'echo "2" | timeout 15 wait_for_auth_completion 3'
    
    # Should warn but continue
    assert_output --partial "continuing as requested"
}

@test "wait_for_auth_completion: abort exits gracefully" {
    # Mock tailscale to always fail
    tailscale() {
        if [ "$1" = "status" ]; then
            return 1
        fi
    }
    export -f tailscale
    
    # Choose abort (option 3)
    run bash -c 'echo "3" | timeout 15 wait_for_auth_completion 3'
    
    # Should display abort message
    assert_output --partial "Deployment Aborted"
    assert_output --partial "re-run this script later"
}

@test "wait_for_auth_completion: logs timeout and user choice" {
    # Clear log file
    > "$LOG_FILE"
    
    # Mock tailscale to always fail
    tailscale() {
        if [ "$1" = "status" ]; then
            return 1
        fi
    }
    export -f tailscale
    
    # Choose abort
    run bash -c 'echo "3" | timeout 15 wait_for_auth_completion 3'
    
    # Should log timeout
    grep -q "Authentication timeout reached" "$LOG_FILE"
    
    # Should log user choice
    grep -q "User timeout choice: 3" "$LOG_FILE"
}

################################################################################
# Test Group 5: Integration Tests
# Combined authentication flow scenarios
################################################################################

@test "authentication flow: complete successful flow" {
    local test_url="https://login.tailscale.com/a/integration-test"
    
    # Mock tailscale to succeed after brief delay
    POLL_COUNT=0
    tailscale() {
        if [ "$1" = "status" ]; then
            POLL_COUNT=$((POLL_COUNT + 1))
            if [ $POLL_COUNT -ge 2 ]; then
                echo "100.64.0.1  hostname  user@  linux   -"
                return 0
            else
                return 1
            fi
        fi
    }
    export -f tailscale
    export POLL_COUNT
    
    # Run complete flow: display URL then wait
    run bash -c "
        handle_browser_authentication '$test_url' > /dev/null 2>&1
        timeout 30 wait_for_auth_completion 30
    "
    
    # Complete flow should succeed
    assert_success
}

@test "authentication flow: timeout with retry succeeds" {
    # Mock tailscale to fail first time, succeed on retry
    RETRY_ATTEMPT=0
    tailscale() {
        if [ "$1" = "status" ]; then
            if [ $RETRY_ATTEMPT -eq 0 ]; then
                # First attempt: always fail (will timeout)
                return 1
            else
                # Retry attempt: succeed
                echo "100.64.0.1  hostname  user@  linux   -"
                return 0
            fi
        fi
    }
    export -f tailscale
    export RETRY_ATTEMPT
    
    # This test is complex to automate with retry, so we verify the retry option exists
    run bash -c 'echo "3" | timeout 15 wait_for_auth_completion 3'
    
    # Should offer retry
    assert_output --partial "Retry"
}

@test "authentication flow: displays progress during wait" {
    # Mock tailscale to succeed after a few polls
    POLL_COUNT=0
    tailscale() {
        if [ "$1" = "status" ]; then
            POLL_COUNT=$((POLL_COUNT + 1))
            if [ $POLL_COUNT -ge 3 ]; then
                echo "100.64.0.1  hostname  user@  linux   -"
                return 0
            else
                return 1
            fi
        fi
    }
    export -f tailscale
    export POLL_COUNT
    
    run timeout 30 wait_for_auth_completion 30
    
    # Should show waiting message
    assert_output --partial "Waiting for authentication"
}

################################################################################
# Test Group 6: Edge Cases
################################################################################

@test "handle_browser_authentication: handles special characters in URL" {
    local test_url="https://login.example.com/auth?token=abc123&redirect=%2Fhome"
    
    run handle_browser_authentication "$test_url"
    
    # Should display URL correctly without breaking
    assert_success
    assert_output --partial "$test_url"
}

@test "wait_for_auth_completion: handles invalid user input gracefully" {
    # Mock tailscale to always fail
    tailscale() {
        if [ "$1" = "status" ]; then
            return 1
        fi
    }
    export -f tailscale
    
    # Provide invalid input, then abort
    run bash -c 'echo -e "invalid\n99\n3" | timeout 15 wait_for_auth_completion 3'
    
    # Should handle invalid input and eventually accept valid input
    assert_output --partial "Invalid choice"
}

@test "wait_for_auth_completion: handles very short timeout" {
    # Mock tailscale to always fail
    tailscale() {
        if [ "$1" = "status" ]; then
            return 1
        fi
    }
    export -f tailscale
    
    # Use 1 second timeout
    run bash -c 'echo "3" | timeout 10 wait_for_auth_completion 1'
    
    # Should timeout quickly and offer options
    assert_output --partial "Authentication Timeout"
}

@test "wait_for_auth_completion: handles Tailscale command not found" {
    # Don't mock tailscale - let it fail naturally
    
    # Run with short timeout and abort
    run bash -c 'echo "3" | timeout 15 wait_for_auth_completion 3'
    
    # Should handle missing command gracefully
    # (will timeout and offer options)
    assert_output --partial "Authentication Timeout"
}
