#!/usr/bin/env bats
# Test suite for Task 4.4: Configuration Validation Unit Tests
# Tests validation of Claude API key, domain name, and email inputs
# Requirements: 3.4, 3.5

# Setup test environment
setup() {
    # Source the deploy script to get the validation functions
    export LOG_FILE="/tmp/test-deploy-$(date +%s).log"
    export CONFIG_DIR="/tmp/test-config-$(date +%s)"
    export STATE_FILE="$CONFIG_DIR/.install-state"
    export REPOSITORY_PATH="/tmp/test-repo"
    export QR_CODE_DIR="$CONFIG_DIR/qr-codes"
    export SCRIPT_VERSION="1.0.0"
    
    # Create test log directory
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Source the validation functions from deploy.sh
    source <(sed -n '/^# Validate Claude API key format/,/^# Install system dependencies/p' infrastructure/scripts/deploy.sh | head -n -2)
}

# Cleanup after each test
teardown() {
    rm -f "$LOG_FILE"
    rm -rf "$CONFIG_DIR"
}

################################################################################
# Claude API Key Validation Tests
################################################################################

@test "Valid Claude API key is accepted" {
    run validate_claude_api_key "sk-ant-api03-1234567890abcdefghijklmnopqrstuvwxyz"
    
    [ "$status" -eq 0 ]
}

@test "Valid Claude API key with longer format is accepted" {
    run validate_claude_api_key "sk-ant-api03-AbCdEfGhIjKlMnOpQrStUvWxYz0123456789_-ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    [ "$status" -eq 0 ]
}

@test "Empty Claude API key is rejected" {
    run validate_claude_api_key ""
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot be empty"* ]]
}

@test "Claude API key without sk-ant- prefix is rejected" {
    run validate_claude_api_key "invalid-api-key-format"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"must start with 'sk-ant-'"* ]]
}

@test "Claude API key that is too short is rejected" {
    run validate_claude_api_key "sk-ant-short"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"too short"* ]]
}

@test "Malformed Claude API key with special characters is rejected" {
    run validate_claude_api_key "not-a-valid-key-at-all"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"must start with 'sk-ant-'"* ]]
}

################################################################################
# Domain Name Validation Tests
################################################################################

@test "Valid domain name is accepted" {
    run validate_domain_name "example.com"
    
    [ "$status" -eq 0 ]
}

@test "Valid subdomain is accepted" {
    run validate_domain_name "app.example.com"
    
    [ "$status" -eq 0 ]
}

@test "Valid multi-level subdomain is accepted" {
    run validate_domain_name "api.staging.example.com"
    
    [ "$status" -eq 0 ]
}

@test "Valid domain with hyphens is accepted" {
    run validate_domain_name "my-app.example-site.com"
    
    [ "$status" -eq 0 ]
}

@test "Empty domain name is rejected" {
    run validate_domain_name ""
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot be empty"* ]]
}

@test "Domain without TLD is rejected" {
    run validate_domain_name "localhost"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"top-level domain"* ]]
}

@test "Malformed domain with spaces is rejected" {
    run validate_domain_name "my domain.com"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid domain name format"* ]]
}

@test "Malformed domain with invalid characters is rejected" {
    run validate_domain_name "my_domain!.com"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid domain name format"* ]]
}

@test "Domain starting with hyphen is rejected" {
    run validate_domain_name "-example.com"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid domain name format"* ]]
}

@test "Domain ending with hyphen is rejected" {
    run validate_domain_name "example-.com"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid domain name format"* ]]
}

################################################################################
# Email Validation Tests
################################################################################

@test "Valid email is accepted" {
    run validate_email "user@example.com"
    
    [ "$status" -eq 0 ]
}

@test "Valid email with subdomain is accepted" {
    run validate_email "user@mail.example.com"
    
    [ "$status" -eq 0 ]
}

@test "Valid email with plus addressing is accepted" {
    run validate_email "user+tag@example.com"
    
    [ "$status" -eq 0 ]
}

@test "Valid email with dots is accepted" {
    run validate_email "first.last@example.com"
    
    [ "$status" -eq 0 ]
}

@test "Valid email with numbers is accepted" {
    run validate_email "user123@example456.com"
    
    [ "$status" -eq 0 ]
}

@test "Empty email is rejected" {
    run validate_email ""
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot be empty"* ]]
}

@test "Email without @ symbol is rejected" {
    run validate_email "userexample.com"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid email format"* ]]
}

@test "Email without domain is rejected" {
    run validate_email "user@"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid email format"* ]]
}

@test "Email without local part is rejected" {
    run validate_email "@example.com"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid email format"* ]]
}

@test "Malformed email with spaces is rejected" {
    run validate_email "user name@example.com"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid email format"* ]]
}

@test "Email without TLD is rejected" {
    run validate_email "user@localhost"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid email format"* ]]
}

################################################################################
# validate_configuration() Wrapper Tests
################################################################################

@test "validate_configuration() accepts valid Claude API key" {
    run validate_configuration "claude_api_key" "sk-ant-api03-1234567890abcdefghijklmnopqrstuvwxyz"
    
    [ "$status" -eq 0 ]
}

@test "validate_configuration() accepts valid domain name" {
    run validate_configuration "domain_name" "example.com"
    
    [ "$status" -eq 0 ]
}

@test "validate_configuration() accepts valid email" {
    run validate_configuration "tailscale_email" "user@example.com"
    
    [ "$status" -eq 0 ]
}

@test "validate_configuration() rejects empty Claude API key" {
    run validate_configuration "claude_api_key" ""
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot be empty"* ]]
}

@test "validate_configuration() rejects empty domain name" {
    run validate_configuration "domain_name" ""
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot be empty"* ]]
}

@test "validate_configuration() rejects empty email" {
    run validate_configuration "tailscale_email" ""
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot be empty"* ]]
}

@test "validate_configuration() rejects unknown field type" {
    run validate_configuration "unknown_field" "some_value"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown configuration field"* ]]
}
