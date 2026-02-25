#!/usr/bin/env bats
################################################################################
# Property-Based Test: Configuration Input Validation
#
# **Validates: Requirements 3.4, 3.5**
#
# Property 1: Configuration Input Validation
# For any configuration input (Claude API key, domain name, Tailscale email),
# if the input is invalid according to the validation rules, the script shall
# reject it, display a descriptive error message, and re-prompt for that input.
#
# Feature: quick-start-deployment, Property 1: Configuration Input Validation
################################################################################

# Load BATS helpers
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Test configuration
ITERATIONS=100
DEPLOY_SCRIPT="$(dirname "$BATS_TEST_DIRNAME")/deploy.sh"

################################################################################
# Setup and Teardown
################################################################################

setup() {
    # Source the validation functions from deploy.sh
    source <(sed -n '/^# Validate Claude API key format/,/^# Collect configuration input from user/p' "$DEPLOY_SCRIPT" | head -n -2)
}

teardown() {
    # No cleanup needed for validation tests
    :
}

################################################################################
# Helper Functions
################################################################################

# Generate invalid Claude API keys
generate_invalid_api_key() {
    local type=$((RANDOM % 6))
    
    case $type in
        0)
            # Empty string
            echo ""
            ;;
        1)
            # Wrong prefix
            echo "api-key-$(openssl rand -hex 16)"
            ;;
        2)
            # Too short
            echo "sk-ant-abc"
            ;;
        3)
            # No prefix
            echo "$(openssl rand -hex 20)"
            ;;
        4)
            # Only prefix
            echo "sk-ant-"
            ;;
        5)
            # Invalid characters
            echo "sk-ant-@#$%^&*()"
            ;;
    esac
}

# Generate valid Claude API keys
generate_valid_api_key() {
    echo "sk-ant-test-$(openssl rand -hex 16)"
}

# Generate invalid domain names
generate_invalid_domain() {
    local type=$((RANDOM % 8))
    
    case $type in
        0)
            # Empty string
            echo ""
            ;;
        1)
            # No TLD
            echo "example"
            ;;
        2)
            # Invalid characters
            echo "example@domain.com"
            ;;
        3)
            # Starts with hyphen
            echo "-example.com"
            ;;
        4)
            # Ends with hyphen
            echo "example-.com"
            ;;
        5)
            # Double dots
            echo "example..com"
            ;;
        6)
            # Spaces
            echo "example domain.com"
            ;;
        7)
            # Only TLD
            echo ".com"
            ;;
    esac
}

# Generate valid domain names
generate_valid_domain() {
    local random_suffix=$(openssl rand -hex 4)
    echo "test-${random_suffix}.example.com"
}

# Generate invalid email addresses
generate_invalid_email() {
    local type=$((RANDOM % 7))
    
    case $type in
        0)
            # Empty string
            echo ""
            ;;
        1)
            # No @ symbol
            echo "userexample.com"
            ;;
        2)
            # No domain
            echo "user@"
            ;;
        3)
            # No username
            echo "@example.com"
            ;;
        4)
            # Multiple @ symbols
            echo "user@@example.com"
            ;;
        5)
            # No TLD
            echo "user@example"
            ;;
        6)
            # Invalid characters
            echo "user name@example.com"
            ;;
    esac
}

# Generate valid email addresses
generate_valid_email() {
    local random_suffix=$(openssl rand -hex 4)
    echo "test-${random_suffix}@example.com"
}

################################################################################
# Property Tests
################################################################################

@test "Property 1: Invalid Claude API keys are rejected with error message" {
    # Test that all invalid API key formats are rejected
    
    local test_iterations=100
    local rejection_count=0
    
    for i in $(seq 1 $test_iterations); do
        local invalid_key=$(generate_invalid_api_key)
        
        # Run validation
        local error_message
        error_message=$(validate_configuration "claude_api_key" "$invalid_key" 2>&1)
        local exit_code=$?
        
        # Validation should fail (non-zero exit code)
        if [ $exit_code -ne 0 ]; then
            rejection_count=$((rejection_count + 1))
            
            # Error message should be descriptive (not empty)
            [ -n "$error_message" ] || {
                echo "Iteration $i: Invalid API key rejected but no error message provided"
                echo "Invalid key: '$invalid_key'"
                return 1
            }
            
            # Error message should contain "ERROR"
            [[ "$error_message" =~ ERROR ]] || {
                echo "Iteration $i: Error message doesn't contain 'ERROR'"
                echo "Message: $error_message"
                return 1
            }
        else
            echo "Iteration $i: Invalid API key was accepted: '$invalid_key'"
            return 1
        fi
    done
    
    # All invalid keys should have been rejected
    [ "$rejection_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations rejections, got $rejection_count"
        return 1
    }
}

@test "Property 1: Valid Claude API keys are accepted" {
    # Test that valid API key formats are accepted
    
    local test_iterations=50
    local acceptance_count=0
    
    for i in $(seq 1 $test_iterations); do
        local valid_key=$(generate_valid_api_key)
        
        # Run validation
        local error_message
        error_message=$(validate_configuration "claude_api_key" "$valid_key" 2>&1)
        local exit_code=$?
        
        # Validation should succeed (zero exit code)
        if [ $exit_code -eq 0 ]; then
            acceptance_count=$((acceptance_count + 1))
        else
            echo "Iteration $i: Valid API key was rejected: '$valid_key'"
            echo "Error message: $error_message"
            return 1
        fi
    done
    
    # All valid keys should have been accepted
    [ "$acceptance_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations acceptances, got $acceptance_count"
        return 1
    }
}

@test "Property 1: Invalid domain names are rejected with error message" {
    # Test that all invalid domain name formats are rejected
    
    local test_iterations=100
    local rejection_count=0
    
    for i in $(seq 1 $test_iterations); do
        local invalid_domain=$(generate_invalid_domain)
        
        # Run validation
        local error_message
        error_message=$(validate_configuration "domain_name" "$invalid_domain" 2>&1)
        local exit_code=$?
        
        # Validation should fail (non-zero exit code)
        if [ $exit_code -ne 0 ]; then
            rejection_count=$((rejection_count + 1))
            
            # Error message should be descriptive (not empty)
            [ -n "$error_message" ] || {
                echo "Iteration $i: Invalid domain rejected but no error message provided"
                echo "Invalid domain: '$invalid_domain'"
                return 1
            }
            
            # Error message should contain "ERROR"
            [[ "$error_message" =~ ERROR ]] || {
                echo "Iteration $i: Error message doesn't contain 'ERROR'"
                echo "Message: $error_message"
                return 1
            }
        else
            echo "Iteration $i: Invalid domain was accepted: '$invalid_domain'"
            return 1
        fi
    done
    
    # All invalid domains should have been rejected
    [ "$rejection_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations rejections, got $rejection_count"
        return 1
    }
}

@test "Property 1: Valid domain names are accepted" {
    # Test that valid domain name formats are accepted
    
    local test_iterations=50
    local acceptance_count=0
    
    for i in $(seq 1 $test_iterations); do
        local valid_domain=$(generate_valid_domain)
        
        # Run validation
        local error_message
        error_message=$(validate_configuration "domain_name" "$valid_domain" 2>&1)
        local exit_code=$?
        
        # Validation should succeed (zero exit code)
        if [ $exit_code -eq 0 ]; then
            acceptance_count=$((acceptance_count + 1))
        else
            echo "Iteration $i: Valid domain was rejected: '$valid_domain'"
            echo "Error message: $error_message"
            return 1
        fi
    done
    
    # All valid domains should have been accepted
    [ "$acceptance_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations acceptances, got $acceptance_count"
        return 1
    }
}

@test "Property 1: Invalid email addresses are rejected with error message" {
    # Test that all invalid email formats are rejected
    
    local test_iterations=100
    local rejection_count=0
    
    for i in $(seq 1 $test_iterations); do
        local invalid_email=$(generate_invalid_email)
        
        # Run validation
        local error_message
        error_message=$(validate_configuration "tailscale_email" "$invalid_email" 2>&1)
        local exit_code=$?
        
        # Validation should fail (non-zero exit code)
        if [ $exit_code -ne 0 ]; then
            rejection_count=$((rejection_count + 1))
            
            # Error message should be descriptive (not empty)
            [ -n "$error_message" ] || {
                echo "Iteration $i: Invalid email rejected but no error message provided"
                echo "Invalid email: '$invalid_email'"
                return 1
            }
            
            # Error message should contain "ERROR"
            [[ "$error_message" =~ ERROR ]] || {
                echo "Iteration $i: Error message doesn't contain 'ERROR'"
                echo "Message: $error_message"
                return 1
            }
        else
            echo "Iteration $i: Invalid email was accepted: '$invalid_email'"
            return 1
        fi
    done
    
    # All invalid emails should have been rejected
    [ "$rejection_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations rejections, got $rejection_count"
        return 1
    }
}

@test "Property 1: Valid email addresses are accepted" {
    # Test that valid email formats are accepted
    
    local test_iterations=50
    local acceptance_count=0
    
    for i in $(seq 1 $test_iterations); do
        local valid_email=$(generate_valid_email)
        
        # Run validation
        local error_message
        error_message=$(validate_configuration "tailscale_email" "$valid_email" 2>&1)
        local exit_code=$?
        
        # Validation should succeed (zero exit code)
        if [ $exit_code -eq 0 ]; then
            acceptance_count=$((acceptance_count + 1))
        else
            echo "Iteration $i: Valid email was rejected: '$valid_email'"
            echo "Error message: $error_message"
            return 1
        fi
    done
    
    # All valid emails should have been accepted
    [ "$acceptance_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations acceptances, got $acceptance_count"
        return 1
    }
}

@test "Property 1: Error messages are descriptive and specific to field type" {
    # Test that error messages are specific to the type of validation failure
    
    # Test API key error messages
    local empty_key_error=$(validate_configuration "claude_api_key" "" 2>&1)
    [[ "$empty_key_error" =~ "empty" ]] || {
        echo "Empty API key error should mention 'empty'"
        echo "Got: $empty_key_error"
        return 1
    }
    
    local wrong_prefix_error=$(validate_configuration "claude_api_key" "api-key-test" 2>&1)
    [[ "$wrong_prefix_error" =~ "sk-ant-" ]] || {
        echo "Wrong prefix error should mention 'sk-ant-'"
        echo "Got: $wrong_prefix_error"
        return 1
    }
    
    local short_key_error=$(validate_configuration "claude_api_key" "sk-ant-abc" 2>&1)
    [[ "$short_key_error" =~ "short" ]] || {
        echo "Short API key error should mention 'short'"
        echo "Got: $short_key_error"
        return 1
    }
    
    # Test domain error messages
    local empty_domain_error=$(validate_configuration "domain_name" "" 2>&1)
    [[ "$empty_domain_error" =~ "empty" ]] || {
        echo "Empty domain error should mention 'empty'"
        echo "Got: $empty_domain_error"
        return 1
    }
    
    local no_tld_error=$(validate_configuration "domain_name" "example" 2>&1)
    [[ "$no_tld_error" =~ "top-level domain" || "$no_tld_error" =~ "FQDN" ]] || {
        echo "No TLD error should mention 'top-level domain' or 'FQDN'"
        echo "Got: $no_tld_error"
        return 1
    }
    
    # Test email error messages
    local empty_email_error=$(validate_configuration "tailscale_email" "" 2>&1)
    [[ "$empty_email_error" =~ "empty" ]] || {
        echo "Empty email error should mention 'empty'"
        echo "Got: $empty_email_error"
        return 1
    }
    
    local invalid_format_error=$(validate_configuration "tailscale_email" "notanemail" 2>&1)
    [[ "$invalid_format_error" =~ "format" || "$invalid_format_error" =~ "email" ]] || {
        echo "Invalid format error should mention 'format' or 'email'"
        echo "Got: $invalid_format_error"
        return 1
    }
}

@test "Property 1: Validation is consistent across multiple calls with same input" {
    # Test that validation produces consistent results for the same input
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        local invalid_key=$(generate_invalid_api_key)
        
        # Run validation multiple times
        local result1=$(validate_configuration "claude_api_key" "$invalid_key" 2>&1; echo $?)
        local result2=$(validate_configuration "claude_api_key" "$invalid_key" 2>&1; echo $?)
        local result3=$(validate_configuration "claude_api_key" "$invalid_key" 2>&1; echo $?)
        
        # Extract exit codes (last line)
        local exit1=$(echo "$result1" | tail -1)
        local exit2=$(echo "$result2" | tail -1)
        local exit3=$(echo "$result3" | tail -1)
        
        # All should have same exit code
        [ "$exit1" = "$exit2" ] && [ "$exit2" = "$exit3" ] || {
            echo "Iteration $i: Inconsistent validation results for: '$invalid_key'"
            echo "Exit codes: $exit1, $exit2, $exit3"
            return 1
        }
    done
}
