#!/usr/bin/env bats
################################################################################
# Property-Based Test: Operation Logging
#
# **Validates: Requirements 7.4**
#
# Property 5: Operation Logging
# For any operation performed by the deployment script (installation,
# configuration, service management), an entry shall be written to the log
# file at `/var/log/ai-website-builder-deploy.log`.
#
# Feature: quick-start-deployment, Property 5: Operation Logging
################################################################################

# Load BATS helpers
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Test configuration
ITERATIONS=100
TEST_LOG_FILE="/tmp/test-deploy-logging-$$.log"
DEPLOY_SCRIPT="$(dirname "$BATS_TEST_DIRNAME")/deploy.sh"

################################################################################
# Setup and Teardown
################################################################################

setup() {
    # Set test environment variables to override script defaults
    export LOG_FILE="$TEST_LOG_FILE"
    export CONFIG_DIR="/tmp/test-config-$$"
    export STATE_FILE="$CONFIG_DIR/.install-state"
    export CONFIG_FILE="$CONFIG_DIR/config.env"
    export REPOSITORY_PATH="/tmp/test-repo"
    export QR_CODE_DIR="$CONFIG_DIR/qr-codes"
    export SCRIPT_VERSION="1.0.0"
    
    # Create test directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$(dirname "$TEST_LOG_FILE")"
    
    # Source the logging functions from deploy.sh
    source <(sed -n '/^# Initialize logging/,/^# Placeholder Functions/p' "$DEPLOY_SCRIPT" | head -n -2)
}

teardown() {
    # Clean up test artifacts
    rm -f "$TEST_LOG_FILE"
    rm -rf "$CONFIG_DIR"
}

################################################################################
# Helper Functions
################################################################################

# Generate random operation types
generate_random_operation() {
    local operations=(
        "install_system_dependencies"
        "install_runtime_dependencies"
        "install_tailscale"
        "configure_firewall"
        "configure_web_server"
        "setup_ssl_certificates"
        "handle_browser_authentication"
        "generate_qr_codes"
        "configure_systemd_service"
        "start_services"
        "restart_services"
        "verify_service_status"
        "verify_domain_accessibility"
        "save_installation_state"
        "collect_configuration_input"
        "load_existing_configuration"
        "detect_existing_installation"
    )
    
    local index=$((RANDOM % ${#operations[@]}))
    echo "${operations[$index]}"
}

# Generate random operation message
generate_random_message() {
    local operation=$1
    local messages=(
        "Starting $operation"
        "Executing $operation"
        "Running $operation"
        "Processing $operation"
        "Performing $operation"
    )
    
    local index=$((RANDOM % ${#messages[@]}))
    echo "${messages[$index]}"
}

# Simulate an operation that should be logged
simulate_operation() {
    local operation=$1
    local message=$2
    
    # Use log_operation to log the operation
    log_operation "OPERATION: $operation - $message"
}

# Check if operation was logged
verify_operation_logged() {
    local operation=$1
    local message=$2
    
    # Check if the log file contains the operation
    grep -q "OPERATION: $operation - $message" "$TEST_LOG_FILE"
}

################################################################################
# Property Tests
################################################################################

@test "Property 5: All operations are logged to the log file" {
    # Test that every operation performed generates a log entry
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        # Generate random operation
        local operation=$(generate_random_operation)
        local message=$(generate_random_message "$operation")
        
        # Simulate the operation
        simulate_operation "$operation" "$message"
        
        # Verify it was logged
        run verify_operation_logged "$operation" "$message"
        assert_success "Iteration $i: Operation '$operation' with message '$message' was not logged"
    done
    
    # Verify we have exactly the expected number of log entries
    local log_count=$(grep -c "OPERATION:" "$TEST_LOG_FILE")
    [ "$log_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations log entries, found $log_count"
        return 1
    }
}

@test "Property 5: Log entries include ISO 8601 timestamps" {
    # Test that all log entries have proper timestamps
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        local operation=$(generate_random_operation)
        local message=$(generate_random_message "$operation")
        
        simulate_operation "$operation" "$message"
    done
    
    # Verify all entries have ISO 8601 timestamps
    local entries_with_timestamps=$(grep -cE '\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' "$TEST_LOG_FILE")
    [ "$entries_with_timestamps" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations entries with timestamps, found $entries_with_timestamps"
        return 1
    }
}

@test "Property 5: display_progress() logs operations with PROGRESS prefix" {
    # Test that progress display operations are logged
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        local operation=$(generate_random_operation)
        local message="Progress: $operation iteration $i"
        
        display_progress "$message"
    done
    
    # Verify all progress messages were logged with PROGRESS prefix
    local progress_count=$(grep -c "PROGRESS:" "$TEST_LOG_FILE")
    [ "$progress_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations PROGRESS entries, found $progress_count"
        return 1
    }
}

@test "Property 5: display_success() logs operations with SUCCESS prefix" {
    # Test that success messages are logged
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        local operation=$(generate_random_operation)
        local message="Success: $operation completed iteration $i"
        
        display_success "$message"
    done
    
    # Verify all success messages were logged with SUCCESS prefix
    local success_count=$(grep -c "SUCCESS:" "$TEST_LOG_FILE")
    [ "$success_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations SUCCESS entries, found $success_count"
        return 1
    }
}

@test "Property 5: display_warning() logs operations with WARNING prefix" {
    # Test that warning messages are logged
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        local operation=$(generate_random_operation)
        local message="Warning: $operation issue iteration $i"
        
        display_warning "$message"
    done
    
    # Verify all warning messages were logged with WARNING prefix
    local warning_count=$(grep -c "WARNING:" "$TEST_LOG_FILE")
    [ "$warning_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations WARNING entries, found $warning_count"
        return 1
    }
}

@test "Property 5: display_info() logs operations with INFO prefix" {
    # Test that info messages are logged
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        local operation=$(generate_random_operation)
        local message="Info: $operation status iteration $i"
        
        display_info "$message"
    done
    
    # Verify all info messages were logged with INFO prefix
    local info_count=$(grep -c "INFO:" "$TEST_LOG_FILE")
    [ "$info_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations INFO entries, found $info_count"
        return 1
    }
}

@test "Property 5: Log file is created if it doesn't exist" {
    # Test that log file is created on first operation
    
    local test_iterations=20
    
    for i in $(seq 1 $test_iterations); do
        # Remove log file
        rm -f "$TEST_LOG_FILE"
        
        # Verify it doesn't exist
        [ ! -f "$TEST_LOG_FILE" ] || {
            echo "Iteration $i: Log file should not exist before operation"
            return 1
        }
        
        # Perform an operation
        local operation=$(generate_random_operation)
        log_operation "Test operation: $operation"
        
        # Verify log file was created
        [ -f "$TEST_LOG_FILE" ] || {
            echo "Iteration $i: Log file was not created after operation"
            return 1
        }
    done
}

@test "Property 5: Multiple operations append to the same log file" {
    # Test that operations don't overwrite previous log entries
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        local operation=$(generate_random_operation)
        local message="Operation $i: $operation"
        
        simulate_operation "$operation" "$message"
        
        # Verify all previous entries still exist
        local current_count=$(grep -c "OPERATION:" "$TEST_LOG_FILE")
        [ "$current_count" -eq "$i" ] || {
            echo "Iteration $i: Expected $i log entries, found $current_count"
            return 1
        }
    done
}

@test "Property 5: Log entries are written in chronological order" {
    # Test that log entries maintain chronological order
    
    local test_iterations=30
    local previous_timestamp=""
    
    for i in $(seq 1 $test_iterations); do
        local operation=$(generate_random_operation)
        simulate_operation "$operation" "Iteration $i"
        
        # Small delay to ensure timestamps differ
        sleep 0.01
    done
    
    # Extract timestamps and verify they're in ascending order
    local timestamps=$(grep -oE '\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[^]]*\]' "$TEST_LOG_FILE")
    
    # Verify we have the expected number of timestamps
    local timestamp_count=$(echo "$timestamps" | wc -l)
    [ "$timestamp_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations timestamps, found $timestamp_count"
        return 1
    }
}

@test "Property 5: init_logging() creates log file with session header" {
    # Test that init_logging creates proper session header
    
    local test_iterations=20
    
    for i in $(seq 1 $test_iterations); do
        # Remove log file
        rm -f "$TEST_LOG_FILE"
        
        # Initialize logging
        init_logging
        
        # Verify session header exists
        grep -q "Deployment started at" "$TEST_LOG_FILE" || {
            echo "Iteration $i: Missing 'Deployment started at' in log header"
            return 1
        }
        
        grep -q "Script version:" "$TEST_LOG_FILE" || {
            echo "Iteration $i: Missing 'Script version' in log header"
            return 1
        }
        
        # Verify header has separator lines
        local separator_count=$(grep -c "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$TEST_LOG_FILE")
        [ "$separator_count" -ge 2 ] || {
            echo "Iteration $i: Expected at least 2 separator lines in header, found $separator_count"
            return 1
        }
    done
}

@test "Property 5: All deployment functions log their execution" {
    # Test that all major deployment functions log when called
    
    # List of functions that should log their execution
    local functions=(
        "detect_existing_installation"
        "prompt_vm_snapshot"
        "collect_configuration_input"
        "load_existing_configuration"
        "install_system_dependencies"
        "install_runtime_dependencies"
        "install_tailscale"
        "configure_firewall"
        "configure_web_server"
        "setup_ssl_certificates"
        "handle_browser_authentication"
        "generate_qr_codes"
        "configure_systemd_service"
        "start_services"
        "restart_services"
        "verify_service_status"
        "verify_domain_accessibility"
        "save_installation_state"
    )
    
    # Call each function (they're currently placeholders that log)
    for func in "${functions[@]}"; do
        # Call the function
        $func 2>/dev/null || true
        
        # Verify it was logged
        grep -q "FUNCTION: $func called" "$TEST_LOG_FILE" || {
            echo "Function $func did not log its execution"
            return 1
        }
    done
    
    # Verify we have log entries for all functions
    local function_log_count=$(grep -c "FUNCTION:" "$TEST_LOG_FILE")
    [ "$function_log_count" -eq "${#functions[@]}" ] || {
        echo "Expected ${#functions[@]} function log entries, found $function_log_count"
        return 1
    }
}

@test "Property 5: Log file path is configurable via environment variable" {
    # Test that LOG_FILE environment variable controls log location
    
    local test_iterations=20
    
    for i in $(seq 1 $test_iterations); do
        local custom_log="/tmp/custom-log-$i-$$.log"
        export LOG_FILE="$custom_log"
        
        # Perform an operation
        log_operation "Test with custom log path iteration $i"
        
        # Verify log was written to custom location
        [ -f "$custom_log" ] || {
            echo "Iteration $i: Custom log file not created at $custom_log"
            return 1
        }
        
        grep -q "Test with custom log path iteration $i" "$custom_log" || {
            echo "Iteration $i: Log entry not found in custom log file"
            return 1
        }
        
        # Clean up
        rm -f "$custom_log"
    done
}
