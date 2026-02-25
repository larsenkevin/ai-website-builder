#!/usr/bin/env bats
# Test suite for Task 7.7: Security Measures Unit Tests
# Tests configuration file permissions, credential masking, and logging protection
# Requirements: 11.3, 11.4, 11.5

# Setup test environment
setup() {
    # Source the deploy script to get the security functions
    export LOG_FILE="/tmp/test-deploy-$(date +%s).log"
    export CONFIG_DIR="/tmp/test-config-$(date +%s)"
    export CONFIG_FILE="$CONFIG_DIR/config.env"
    export STATE_FILE="$CONFIG_DIR/.install-state"
    export REPOSITORY_PATH="/tmp/test-repo"
    export QR_CODE_DIR="$CONFIG_DIR/qr-codes"
    export SCRIPT_VERSION="1.0.0"
    
    # Set test configuration values
    export CLAUDE_API_KEY="sk-ant-api03-test1234567890abcdefghijklmnopqrstuvwxyz"
    export DOMAIN_NAME="test.example.com"
    export TAILSCALE_EMAIL="test@example.com"
    export INSTALL_DATE="2024-01-15T10:30:00Z"
    
    # Create test directories
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "$CONFIG_DIR"
    
    # Source the functions from deploy.sh
    source <(sed -n '/^# Mask sensitive value/,/^# Install system dependencies/p' infrastructure/scripts/deploy.sh | head -n -2)
}

# Cleanup after each test
teardown() {
    rm -f "$LOG_FILE"
    rm -rf "$CONFIG_DIR"
}

################################################################################
# Configuration File Permissions Tests (Requirement 11.3)
################################################################################

@test "Configuration file has 600 permissions after save" {
    # Call save_configuration to create the config file
    save_configuration
    
    # Check that file exists
    [ -f "$CONFIG_FILE" ]
    
    # Check file permissions (should be 600)
    local perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%A" "$CONFIG_FILE" 2>/dev/null)
    [ "$perms" = "600" ]
}

@test "Configuration file is owned by root:root" {
    # Skip if not running as root
    if [ "$(id -u)" -ne 0 ]; then
        skip "Test requires root privileges"
    fi
    
    # Call save_configuration to create the config file
    save_configuration
    
    # Check file ownership
    local owner=$(stat -c "%U:%G" "$CONFIG_FILE" 2>/dev/null || stat -f "%Su:%Sg" "$CONFIG_FILE" 2>/dev/null)
    [ "$owner" = "root:root" ]
}

@test "Configuration file permissions are verified after save" {
    # Call save_configuration
    run save_configuration
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Configuration file security verified"* ]]
}

################################################################################
# Configuration Directory Permissions Tests (Requirement 11.3)
################################################################################

@test "Configuration directory has 700 permissions" {
    # Call save_configuration to create the directory
    save_configuration
    
    # Check that directory exists
    [ -d "$CONFIG_DIR" ]
    
    # Check directory permissions (should be 700)
    local perms=$(stat -c "%a" "$CONFIG_DIR" 2>/dev/null || stat -f "%A" "$CONFIG_DIR" 2>/dev/null)
    [ "$perms" = "700" ]
}

@test "Configuration directory is owned by root:root" {
    # Skip if not running as root
    if [ "$(id -u)" -ne 0 ]; then
        skip "Test requires root privileges"
    fi
    
    # Call save_configuration to create the directory
    save_configuration
    
    # Check directory ownership
    local owner=$(stat -c "%U:%G" "$CONFIG_DIR" 2>/dev/null || stat -f "%Su:%Sg" "$CONFIG_DIR" 2>/dev/null)
    [ "$owner" = "root:root" ]
}

@test "Configuration directory permissions are set even if directory exists" {
    # Create directory with wrong permissions
    mkdir -p "$CONFIG_DIR"
    chmod 755 "$CONFIG_DIR"
    
    # Call save_configuration
    save_configuration
    
    # Check that permissions were corrected to 700
    local perms=$(stat -c "%a" "$CONFIG_DIR" 2>/dev/null || stat -f "%A" "$CONFIG_DIR" 2>/dev/null)
    [ "$perms" = "700" ]
}

################################################################################
# Credential Logging Protection Tests (Requirement 11.4)
################################################################################

@test "Claude API key is not logged in plain text" {
    # Log a message that contains an API key
    log_operation "Processing API key: $CLAUDE_API_KEY"
    
    # Check that the plain API key is NOT in the log file
    ! grep -q "$CLAUDE_API_KEY" "$LOG_FILE"
}

@test "Claude API key is masked in log file" {
    # Log a message that contains an API key
    log_operation "Processing API key: $CLAUDE_API_KEY"
    
    # Check that a masked version appears in the log
    grep -q "\*\*\*\*" "$LOG_FILE"
}

@test "Multiple API keys in same log message are all masked" {
    local api_key1="sk-ant-api03-key1234567890abcdefghijklmnopqrstuvwxyz"
    local api_key2="sk-ant-api03-key9876543210zyxwvutsrqponmlkjihgfedcba"
    
    # Log a message with multiple API keys
    log_operation "Keys: $api_key1 and $api_key2"
    
    # Check that neither plain key is in the log
    ! grep -q "$api_key1" "$LOG_FILE"
    ! grep -q "$api_key2" "$LOG_FILE"
}

@test "Log file does not contain sensitive credentials after save_configuration" {
    # Save configuration (which logs operations)
    save_configuration
    
    # Check that the plain API key is NOT in the log file
    ! grep -q "$CLAUDE_API_KEY" "$LOG_FILE"
}

@test "Credentials are masked when logging configuration operations" {
    # Initialize logging
    init_logging
    
    # Log operation with API key
    log_operation "User provided Claude API key: $CLAUDE_API_KEY"
    
    # Verify the actual key is not in the log
    ! grep -q "$CLAUDE_API_KEY" "$LOG_FILE"
    
    # Verify masked version is present
    grep -q "User provided Claude API key:" "$LOG_FILE"
}

################################################################################
# Credential Display Masking Tests (Requirement 11.5)
################################################################################

@test "mask_value() masks all but last 4 characters" {
    local test_value="sk-ant-api03-1234567890abcdefghijklmnopqrstuvwxyz"
    
    run mask_value "$test_value"
    
    [ "$status" -eq 0 ]
    # Should end with last 4 chars
    [[ "$output" == *"wxyz" ]]
    # Should contain asterisks
    [[ "$output" == *"***"* ]]
    # Should NOT contain the full value
    [[ "$output" != "$test_value" ]]
}

@test "mask_value() handles short values correctly" {
    local test_value="short"
    
    run mask_value "$test_value"
    
    [ "$status" -eq 0 ]
    # Should end with last char for short values
    [[ "$output" == *"t" ]]
    # Should contain asterisks
    [[ "$output" == *"*"* ]]
}

@test "mask_value() masks Claude API key correctly" {
    run mask_value "$CLAUDE_API_KEY"
    
    [ "$status" -eq 0 ]
    # Should show last 4 characters
    [[ "$output" == *"wxyz" ]]
    # Should have asterisks for the rest
    [[ "$output" == *"***"* ]]
    # Length should match original
    [ ${#output} -eq ${#CLAUDE_API_KEY} ]
}

@test "Masked API key is displayed in update mode prompt" {
    # This test verifies the mask_value function is used correctly
    # The actual prompt display is tested in integration tests
    
    local masked=$(mask_value "$CLAUDE_API_KEY")
    
    # Verify masked value doesn't contain the full key
    [[ "$masked" != "$CLAUDE_API_KEY" ]]
    
    # Verify it contains masking characters
    [[ "$masked" == *"*"* ]]
}

@test "mask_value() produces consistent output" {
    local test_value="sk-ant-api03-consistencytest1234567890"
    
    local result1=$(mask_value "$test_value")
    local result2=$(mask_value "$test_value")
    
    [ "$result1" = "$result2" ]
}

@test "mask_value() handles empty string gracefully" {
    run mask_value ""
    
    [ "$status" -eq 0 ]
    # Empty string should return empty or minimal output
    [ ${#output} -le 1 ]
}

@test "Credentials in configuration file are not masked (file is secured by permissions)" {
    # Save configuration
    save_configuration
    
    # The config file should contain the actual credentials (not masked)
    # because the file itself is protected by 600 permissions
    grep -q "CLAUDE_API_KEY=$CLAUDE_API_KEY" "$CONFIG_FILE"
}

################################################################################
# Integration Tests - Security Measures Working Together
################################################################################

@test "Complete security workflow: save, verify permissions, check logging" {
    # Initialize logging
    init_logging
    
    # Save configuration (which should secure files and mask logs)
    save_configuration
    
    # Verify file permissions
    local file_perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%A" "$CONFIG_FILE" 2>/dev/null)
    [ "$file_perms" = "600" ]
    
    # Verify directory permissions
    local dir_perms=$(stat -c "%a" "$CONFIG_DIR" 2>/dev/null || stat -f "%A" "$CONFIG_DIR" 2>/dev/null)
    [ "$dir_perms" = "700" ]
    
    # Verify credentials not in log
    ! grep -q "$CLAUDE_API_KEY" "$LOG_FILE"
    
    # Verify config file contains actual credentials
    grep -q "CLAUDE_API_KEY=$CLAUDE_API_KEY" "$CONFIG_FILE"
}

@test "Security measures prevent unauthorized access to credentials" {
    # Save configuration
    save_configuration
    
    # Verify only owner can read the config file
    local perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%A" "$CONFIG_FILE" 2>/dev/null)
    [ "$perms" = "600" ]
    
    # Verify only owner can access the config directory
    local dir_perms=$(stat -c "%a" "$CONFIG_DIR" 2>/dev/null || stat -f "%A" "$CONFIG_DIR" 2>/dev/null)
    [ "$dir_perms" = "700" ]
}
