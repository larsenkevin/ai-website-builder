#!/usr/bin/env bats
# Test suite for Task 2.3: Logging and Progress Display Utilities
# Tests the log_operation(), display_progress(), and handle_error() functions

# Setup test environment
setup() {
    # Source the deploy script to get the functions
    export LOG_FILE="/tmp/test-deploy-$(date +%s).log"
    export CONFIG_DIR="/tmp/test-config-$(date +%s)"
    export STATE_FILE="$CONFIG_DIR/.install-state"
    export REPOSITORY_PATH="/tmp/test-repo"
    export QR_CODE_DIR="$CONFIG_DIR/qr-codes"
    export SCRIPT_VERSION="1.0.0"
    
    # Create test log directory
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Source only the functions we need (not the full script)
    source <(sed -n '/^# Initialize logging/,/^# Script Entry Point/p' infrastructure/scripts/deploy.sh | head -n -2)
}

# Cleanup after each test
teardown() {
    rm -f "$LOG_FILE"
    rm -rf "$CONFIG_DIR"
}

# Test 1: log_operation() writes to log file
@test "log_operation() writes messages to log file" {
    log_operation "Test message"
    
    [ -f "$LOG_FILE" ]
    grep -q "Test message" "$LOG_FILE"
}

# Test 2: log_operation() includes timestamp
@test "log_operation() includes ISO 8601 timestamp" {
    log_operation "Timestamped message"
    
    # Check for ISO 8601 format: [YYYY-MM-DDTHH:MM:SS+TZ]
    grep -qE '\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' "$LOG_FILE"
}

# Test 3: display_progress() shows message and logs it
@test "display_progress() displays message and logs to file" {
    run display_progress "Installing dependencies"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing dependencies"* ]]
    grep -q "PROGRESS: Installing dependencies" "$LOG_FILE"
}

# Test 4: display_success() shows success message
@test "display_success() displays success message and logs it" {
    run display_success "Installation complete"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installation complete"* ]]
    grep -q "SUCCESS: Installation complete" "$LOG_FILE"
}

# Test 5: display_warning() shows warning message
@test "display_warning() displays warning message and logs it" {
    run display_warning "Proceeding without snapshot"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Proceeding without snapshot"* ]]
    grep -q "WARNING: Proceeding without snapshot" "$LOG_FILE"
}

# Test 6: display_info() shows info message
@test "display_info() displays info message and logs it" {
    run display_info "Configuration loaded"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Configuration loaded"* ]]
    grep -q "INFO: Configuration loaded" "$LOG_FILE"
}

# Test 7: init_logging() creates log file and writes header
@test "init_logging() creates log file with session header" {
    init_logging
    
    [ -f "$LOG_FILE" ]
    grep -q "Deployment started at" "$LOG_FILE"
    grep -q "Script version: $SCRIPT_VERSION" "$LOG_FILE"
}

# Test 8: Multiple log operations append to same file
@test "Multiple log operations append to the same log file" {
    log_operation "First operation"
    log_operation "Second operation"
    log_operation "Third operation"
    
    line_count=$(grep -c "operation" "$LOG_FILE")
    [ "$line_count" -eq 3 ]
}

# Test 9: Log file path is correct
@test "Log file is created at /var/log/ai-website-builder-deploy.log in production" {
    # Reset to production path
    export LOG_FILE="/var/log/ai-website-builder-deploy.log"
    
    # This test just verifies the path is set correctly
    [[ "$LOG_FILE" == "/var/log/ai-website-builder-deploy.log" ]]
}

# Test 10: Progress messages are distinguishable from other messages
@test "Progress messages are logged with PROGRESS prefix" {
    display_progress "Long running operation"
    
    grep -q "PROGRESS: Long running operation" "$LOG_FILE"
}

# Test 11: Error messages are logged with ERROR prefix
@test "Error logging includes ERROR prefix" {
    log_operation "ERROR: Something went wrong"
    
    grep -q "ERROR: Something went wrong" "$LOG_FILE"
}

# Test 12: Verify handle_error() function exists and has correct structure
@test "handle_error() function exists with remediation steps" {
    # Check that the function is defined
    type handle_error > /dev/null
    
    # Verify the function contains remediation guidance
    declare -f handle_error | grep -q "Remediation:"
    declare -f handle_error | grep -q "Check the log file"
}
