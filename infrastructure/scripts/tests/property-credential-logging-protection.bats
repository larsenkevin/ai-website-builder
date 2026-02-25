#!/usr/bin/env bats
################################################################################
# Property-Based Test: Credential Logging Protection
#
# **Validates: Requirements 11.4**
#
# Property 10: Credential Logging Protection
# For any sensitive credential value (Claude API key, Tailscale auth token),
# the script shall not write it to the log file in plain text; if logging is
# necessary, the value shall be masked.
#
# Feature: quick-start-deployment, Property 10: Credential Logging Protection
################################################################################

# Load BATS helpers
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Test configuration
ITERATIONS=100
TEST_LOG_FILE="/tmp/test-deploy-logging-protection-$$.log"
TEST_CONFIG_DIR="/tmp/test-config-logging-$$"
DEPLOY_SCRIPT="$(dirname "$BATS_TEST_DIRNAME")/deploy.sh"

################################################################################
# Setup and Teardown
################################################################################

setup() {
    # Set test environment variables
    export LOG_FILE="$TEST_LOG_FILE"
    export CONFIG_DIR="$TEST_CONFIG_DIR"
    export CONFIG_FILE="$CONFIG_DIR/config.env"
    export STATE_FILE="$CONFIG_DIR/.install-state"
    export REPOSITORY_PATH="/tmp/test-repo"
    export QR_CODE_DIR="$CONFIG_DIR/qr-codes"
    export SCRIPT_VERSION="1.0.0"
    
    # Create test directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$(dirname "$TEST_LOG_FILE")"
    
    # Source necessary functions from deploy.sh
    source <(sed -n '/^# Mask sensitive value for display/,/^# Initialize logging/p' "$DEPLOY_SCRIPT" | head -n -2)
    source <(sed -n '/^# Initialize logging/,/^# Placeholder Functions/p' "$DEPLOY_SCRIPT" | head -n -2)
    source <(sed -n '/^# Save configuration to secure file/,/^# Install system dependencies/p' "$DEPLOY_SCRIPT" | head -n -2)
}

teardown() {
    # Clean up test artifacts
    rm -f "$TEST_LOG_FILE"
    rm -rf "$TEST_CONFIG_DIR"
}

################################################################################
# Helper Functions
################################################################################

# Generate random API key
generate_random_api_key() {
    local iteration=$1
    echo "sk-ant-api03-$(openssl rand -hex 32)-iteration-${iteration}"
}

# Generate random auth token
generate_random_auth_token() {
    local iteration=$1
    echo "tskey-auth-$(openssl rand -hex 24)-iter-${iteration}"
}

# Check if plain text credential appears in log
credential_in_log() {
    local credential=$1
    grep -q "$credential" "$TEST_LOG_FILE"
}

# Check if masked version appears in log
masked_credential_in_log() {
    grep -q "\*\*\*\*" "$TEST_LOG_FILE"
}

# Count occurrences of credential in log
count_credential_occurrences() {
    local credential=$1
    grep -c "$credential" "$TEST_LOG_FILE" 2>/dev/null || echo "0"
}

################################################################################
# Property Tests
################################################################################

@test "Property 10: Claude API keys are never logged in plain text" {
    # Test that API keys are always masked in log files
    
    local test_iterations=100
    local protected_count=0
    
    for i in $(seq 1 $test_iterations); do
        # Generate random API key
        local api_key=$(generate_random_api_key "$i")
        export CLAUDE_API_KEY="$api_key"
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Log a message containing the API key
        log_operation "Processing API key: $api_key"
        
        # Verify plain text API key is NOT in log
        if ! credential_in_log "$api_key"; then
            protected_count=$((protected_count + 1))
        else
            echo "Iteration $i: API key found in plain text in log file"
            echo "API key: $api_key"
            echo "Log contents:"
            cat "$TEST_LOG_FILE"
            return 1
        fi
        
        # Verify masked version IS in log
        masked_credential_in_log || {
            echo "Iteration $i: No masked credential found in log"
            echo "Log contents:"
            cat "$TEST_LOG_FILE"
            return 1
        }
    done
    
    [ "$protected_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations protected credentials, got $protected_count"
        return 1
    }
}

@test "Property 10: Multiple API keys in same message are all masked" {
    # Test that multiple credentials in one log message are all masked
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Generate multiple API keys
        local api_key1=$(generate_random_api_key "${i}a")
        local api_key2=$(generate_random_api_key "${i}b")
        local api_key3=$(generate_random_api_key "${i}c")
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Log message with multiple API keys
        log_operation "Keys: $api_key1 and $api_key2 and $api_key3"
        
        # Verify none of the plain text keys are in log
        ! credential_in_log "$api_key1" || {
            echo "Iteration $i: First API key found in plain text"
            return 1
        }
        
        ! credential_in_log "$api_key2" || {
            echo "Iteration $i: Second API key found in plain text"
            return 1
        }
        
        ! credential_in_log "$api_key3" || {
            echo "Iteration $i: Third API key found in plain text"
            return 1
        }
    done
}

@test "Property 10: API keys are masked in all logging functions" {
    # Test that all logging functions mask credentials
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        local api_key=$(generate_random_api_key "$i")
        export CLAUDE_API_KEY="$api_key"
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Test each logging function
        log_operation "Operation with key: $api_key"
        display_progress "Progress with key: $api_key"
        display_success "Success with key: $api_key"
        display_warning "Warning with key: $api_key"
        display_info "Info with key: $api_key"
        
        # Verify plain text key is not in log
        local occurrences=$(count_credential_occurrences "$api_key")
        [ "$occurrences" -eq 0 ] || {
            echo "Iteration $i: API key found $occurrences times in log"
            echo "Log contents:"
            cat "$TEST_LOG_FILE"
            return 1
        }
    done
}

@test "Property 10: save_configuration does not log credentials in plain text" {
    # Test that saving configuration masks credentials in logs
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Generate random credentials
        local api_key=$(generate_random_api_key "$i")
        export CLAUDE_API_KEY="$api_key"
        export DOMAIN_NAME="test-$i.example.com"
        export TAILSCALE_EMAIL="test-$i@example.com"
        export INSTALL_DATE=$(date -Iseconds)
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Save configuration (which logs operations)
        save_configuration >/dev/null 2>&1
        
        # Verify API key is not in log
        ! credential_in_log "$api_key" || {
            echo "Iteration $i: API key found in log after save_configuration"
            echo "Log contents:"
            cat "$TEST_LOG_FILE"
            return 1
        }
    done
}

@test "Property 10: Credentials with special characters are masked" {
    # Test that credentials containing special regex characters are masked
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        # Generate API key with special characters
        local api_key="sk-ant-api03-test_key-$i-with-special-chars_$(openssl rand -hex 16)"
        export CLAUDE_API_KEY="$api_key"
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Log message with API key
        log_operation "Processing key: $api_key"
        
        # Verify plain text key is not in log
        ! credential_in_log "$api_key" || {
            echo "Iteration $i: API key with special chars found in log"
            return 1
        }
    done
}

@test "Property 10: Very long API keys are masked" {
    # Test that long credentials are properly masked
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        # Generate very long API key
        local api_key="sk-ant-api03-$(openssl rand -hex 64)-iteration-${i}"
        export CLAUDE_API_KEY="$api_key"
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Log message with long API key
        log_operation "Long key: $api_key"
        
        # Verify plain text key is not in log
        ! credential_in_log "$api_key" || {
            echo "Iteration $i: Long API key found in log"
            return 1
        }
    done
}

@test "Property 10: Short API keys are masked" {
    # Test that even short credentials are masked
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        # Generate short API key
        local api_key="sk-ant-api03-short${i}"
        export CLAUDE_API_KEY="$api_key"
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Log message with short API key
        log_operation "Short key: $api_key"
        
        # Verify plain text key is not in log
        ! credential_in_log "$api_key" || {
            echo "Iteration $i: Short API key found in log"
            return 1
        }
    done
}

@test "Property 10: API keys in error messages are masked" {
    # Test that credentials in error contexts are masked
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        local api_key=$(generate_random_api_key "$i")
        export CLAUDE_API_KEY="$api_key"
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Log error message with API key
        log_operation "ERROR: Invalid API key: $api_key"
        
        # Verify plain text key is not in log
        ! credential_in_log "$api_key" || {
            echo "Iteration $i: API key found in error message"
            return 1
        }
    done
}

@test "Property 10: Credentials are masked across multiple log entries" {
    # Test that credentials remain masked across multiple log operations
    
    local test_iterations=20
    
    for i in $(seq 1 $test_iterations); do
        local api_key=$(generate_random_api_key "$i")
        export CLAUDE_API_KEY="$api_key"
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Log multiple messages with the same API key
        for j in {1..10}; do
            log_operation "Message $j with key: $api_key"
        done
        
        # Verify plain text key never appears
        local occurrences=$(count_credential_occurrences "$api_key")
        [ "$occurrences" -eq 0 ] || {
            echo "Iteration $i: API key found $occurrences times across multiple entries"
            return 1
        }
    done
}

@test "Property 10: Masked credentials show last 4 characters" {
    # Test that masked credentials include last 4 characters for identification
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        local api_key=$(generate_random_api_key "$i")
        export CLAUDE_API_KEY="$api_key"
        
        # Get last 4 characters
        local last_four="${api_key: -4}"
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Log message with API key
        log_operation "Processing key: $api_key"
        
        # Verify last 4 characters appear in log (for identification)
        grep -q "$last_four" "$TEST_LOG_FILE" || {
            echo "Iteration $i: Last 4 characters not found in masked credential"
            echo "Expected to find: $last_four"
            echo "Log contents:"
            cat "$TEST_LOG_FILE"
            return 1
        }
        
        # But full key should not appear
        ! credential_in_log "$api_key" || {
            echo "Iteration $i: Full API key found in log"
            return 1
        }
    done
}

@test "Property 10: init_logging does not expose credentials" {
    # Test that logging initialization doesn't leak credentials
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        local api_key=$(generate_random_api_key "$i")
        export CLAUDE_API_KEY="$api_key"
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Initialize logging
        init_logging
        
        # Verify API key is not in log
        ! credential_in_log "$api_key" || {
            echo "Iteration $i: API key found after init_logging"
            return 1
        }
    done
}

@test "Property 10: Credentials in environment variables are not logged" {
    # Test that environment variables containing credentials are not logged
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        local api_key=$(generate_random_api_key "$i")
        export CLAUDE_API_KEY="$api_key"
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Log message that might reference environment variable
        log_operation "Using CLAUDE_API_KEY from environment: $CLAUDE_API_KEY"
        
        # Verify plain text key is not in log
        ! credential_in_log "$api_key" || {
            echo "Iteration $i: API key from environment variable found in log"
            return 1
        }
    done
}

@test "Property 10: Partial API key matches are masked" {
    # Test that even partial credential strings are masked
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        local api_key=$(generate_random_api_key "$i")
        export CLAUDE_API_KEY="$api_key"
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Log message with API key
        log_operation "Key value: $api_key"
        
        # Verify no substring of the key (longer than 10 chars) appears
        local key_length=${#api_key}
        local substring_length=$((key_length - 10))
        
        if [ $substring_length -gt 10 ]; then
            local substring="${api_key:0:$substring_length}"
            ! grep -q "$substring" "$TEST_LOG_FILE" || {
                echo "Iteration $i: Partial API key found in log"
                return 1
            }
        fi
    done
}

@test "Property 10: Credentials are masked regardless of log message format" {
    # Test that credentials are masked in various message formats
    
    local test_iterations=20
    
    for i in $(seq 1 $test_iterations); do
        local api_key=$(generate_random_api_key "$i")
        export CLAUDE_API_KEY="$api_key"
        
        # Clear log file
        > "$TEST_LOG_FILE"
        
        # Log in various formats
        log_operation "API_KEY=$api_key"
        log_operation "api_key: $api_key"
        log_operation "Key is $api_key here"
        log_operation "$api_key"
        log_operation "[$api_key]"
        log_operation "{key: $api_key}"
        
        # Verify plain text key never appears
        local occurrences=$(count_credential_occurrences "$api_key")
        [ "$occurrences" -eq 0 ] || {
            echo "Iteration $i: API key found in various formats"
            echo "Log contents:"
            cat "$TEST_LOG_FILE"
            return 1
        }
    done
}
