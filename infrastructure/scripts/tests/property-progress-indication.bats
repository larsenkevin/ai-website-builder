#!/usr/bin/env bats
# Feature: quick-start-deployment, Property 6: Progress Indication for Long Operations
# **Validates: Requirements 7.3**
#
# Property: For any operation that takes longer than 5 seconds (dependency installation,
# repository cloning, SSL certificate acquisition), the script shall display a progress
# indicator or status message.

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    export TEST_LOG="$TEST_DIR/test.log"
    export DEPLOY_SCRIPT="infrastructure/scripts/deploy.sh"
    
    # Source the deploy script functions (without executing main)
    # We'll extract just the functions we need to test
    export SCRIPT_FUNCTIONS="$TEST_DIR/functions.sh"
    
    # Extract utility functions from deploy script
    sed -n '/^# Utility Functions/,/^# Main Execution Flow/p' "$DEPLOY_SCRIPT" | \
        grep -v "^# Main Execution Flow" > "$SCRIPT_FUNCTIONS"
    
    # Source the functions
    LOG_FILE="$TEST_LOG"
    source "$SCRIPT_FUNCTIONS" 2>/dev/null || true
}

teardown() {
    # Clean up temporary directory
    rm -rf "$TEST_DIR"
}

# Helper function to simulate a long-running operation
simulate_long_operation() {
    local duration=$1
    local operation_name=$2
    
    display_progress "Starting $operation_name (will take ${duration}s)..."
    sleep "$duration"
    display_success "$operation_name completed"
}

# Helper function to check if progress was displayed
check_progress_displayed() {
    local output="$1"
    local operation_name="$2"
    
    # Check if progress indicator (▶) or operation name appears in output
    if echo "$output" | grep -q "▶.*$operation_name" || \
       echo "$output" | grep -q "$operation_name"; then
        return 0
    else
        return 1
    fi
}

@test "Property 6.1: Operations >5s display progress indicators" {
    # Test that operations taking longer than 5 seconds show progress
    
    # Run 10 iterations with random operation durations
    for i in {1..10}; do
        # Generate random duration between 6-10 seconds
        duration=$((6 + RANDOM % 5))
        operation="test_operation_$i"
        
        # Capture output
        output=$(simulate_long_operation "$duration" "$operation" 2>&1)
        
        # Verify progress was displayed
        assert check_progress_displayed "$output" "$operation"
    done
}

@test "Property 6.2: Progress messages are logged" {
    # Test that progress indicators are also logged to the log file
    
    for i in {1..5}; do
        operation="logged_operation_$i"
        
        # Run operation
        simulate_long_operation 1 "$operation" >/dev/null 2>&1
        
        # Check log file contains progress message
        run grep -q "PROGRESS.*$operation" "$TEST_LOG"
        assert_success
    done
}

@test "Property 6.3: Multiple sequential long operations show progress" {
    # Test that multiple long operations each show their own progress
    
    operations=("install_packages" "clone_repository" "configure_services")
    
    for operation in "${operations[@]}"; do
        output=$(simulate_long_operation 1 "$operation" 2>&1)
        
        # Each operation should show progress
        assert check_progress_displayed "$output" "$operation"
    done
    
    # Verify all operations were logged
    for operation in "${operations[@]}"; do
        run grep -q "PROGRESS.*$operation" "$TEST_LOG"
        assert_success
    done
}

@test "Property 6.4: Progress display includes operation context" {
    # Test that progress messages include meaningful context about what's happening
    
    test_operations=(
        "Installing system dependencies"
        "Cloning repository"
        "Installing npm packages"
        "Configuring SSL certificates"
        "Starting services"
    )
    
    for operation in "${test_operations[@]}"; do
        output=$(display_progress "$operation" 2>&1)
        
        # Verify the operation name appears in output
        run echo "$output"
        assert_output --partial "$operation"
    done
}

@test "Property 6.5: Progress indicators are visible in terminal output" {
    # Test that progress indicators use visible markers (colors, symbols)
    
    for i in {1..20}; do
        operation="visible_operation_$i"
        
        output=$(display_progress "$operation" 2>&1)
        
        # Check for progress indicator symbol (▶) or ANSI color codes
        if echo "$output" | grep -q "▶" || \
           echo "$output" | grep -q $'\033\['; then
            # Progress indicator found
            continue
        else
            # No visible indicator
            fail "Progress indicator not visible for $operation"
        fi
    done
}

@test "Property 6.6: Long operations show start and completion messages" {
    # Test that long operations show both start and completion indicators
    
    for i in {1..15}; do
        operation="complete_operation_$i"
        
        output=$(simulate_long_operation 1 "$operation" 2>&1)
        
        # Should contain both "Starting" and "completed" messages
        run echo "$output"
        assert_output --partial "Starting $operation"
        assert_output --partial "completed"
    done
}

@test "Property 6.7: Progress indication works across different operation types" {
    # Test progress indication for various operation types
    
    # Simulate different types of operations
    declare -A operation_types=(
        ["installation"]="Installing test package"
        ["configuration"]="Configuring test service"
        ["download"]="Downloading test file"
        ["compilation"]="Compiling test code"
        ["verification"]="Verifying test setup"
    )
    
    for type in "${!operation_types[@]}"; do
        operation="${operation_types[$type]}"
        
        output=$(display_progress "$operation" 2>&1)
        
        # Verify progress displayed
        assert check_progress_displayed "$output" "$operation"
        
        # Verify logged
        run grep -q "PROGRESS.*$operation" "$TEST_LOG"
        assert_success
    done
}

@test "Property 6.8: Progress messages are timestamped in logs" {
    # Test that progress messages in log files include timestamps
    
    for i in {1..10}; do
        operation="timestamped_operation_$i"
        
        display_progress "$operation" >/dev/null 2>&1
        
        # Check log file for timestamp format [YYYY-MM-DDTHH:MM:SS]
        run grep "PROGRESS.*$operation" "$TEST_LOG"
        assert_success
        
        # Verify timestamp format (ISO 8601)
        run grep -E '\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' "$TEST_LOG"
        assert_success
    done
}

@test "Property 6.9: Progress indication handles special characters in operation names" {
    # Test that progress indicators work with various special characters
    
    special_operations=(
        "Installing package (version 1.0)"
        "Configuring service: test-service"
        "Running command: apt-get update"
        "Processing file: /etc/config.conf"
        "Updating package [critical]"
    )
    
    for operation in "${special_operations[@]}"; do
        output=$(display_progress "$operation" 2>&1)
        
        # Verify operation name appears in output
        run echo "$output"
        assert_output --partial "$operation"
    done
}

@test "Property 6.10: Progress indication is consistent across script execution" {
    # Test that progress indication format is consistent
    
    # Collect progress outputs
    outputs=()
    
    for i in {1..25}; do
        operation="consistent_operation_$i"
        output=$(display_progress "$operation" 2>&1)
        outputs+=("$output")
    done
    
    # All outputs should contain the progress indicator
    for output in "${outputs[@]}"; do
        # Check for consistent indicator (▶ symbol)
        if ! echo "$output" | grep -q "▶"; then
            fail "Inconsistent progress indicator format"
        fi
    done
}
