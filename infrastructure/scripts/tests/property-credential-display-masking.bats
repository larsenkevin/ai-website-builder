#!/usr/bin/env bats
################################################################################
# Property-Based Test: Credential Display Masking
#
# **Validates: Requirements 11.5**
#
# Property 11: Credential Display Masking
# For any sensitive configuration value displayed in update mode, the script
# shall mask all but the last 4 characters (e.g., "sk-ant-***************xyz").
#
# Feature: quick-start-deployment, Property 11: Credential Display Masking
################################################################################

# Load BATS helpers
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Test configuration
ITERATIONS=100
TEST_CONFIG_DIR="/tmp/test-config-masking-$$"
DEPLOY_SCRIPT="$(dirname "$BATS_TEST_DIRNAME")/deploy.sh"

################################################################################
# Setup and Teardown
################################################################################

setup() {
    # Set test environment variables
    export CONFIG_DIR="$TEST_CONFIG_DIR"
    export CONFIG_FILE="$CONFIG_DIR/config.env"
    export STATE_FILE="$CONFIG_DIR/.install-state"
    export LOG_FILE="/tmp/test-deploy-masking-$$.log"
    export REPOSITORY_PATH="/tmp/test-repo"
    export QR_CODE_DIR="$CONFIG_DIR/qr-codes"
    export SCRIPT_VERSION="1.0.0"
    
    # Create test directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Source necessary functions from deploy.sh
    source <(sed -n '/^# Mask sensitive value for display/,/^# Initialize logging/p' "$DEPLOY_SCRIPT" | head -n -2)
}

teardown() {
    # Clean up test artifacts
    rm -rf "$CONFIG_DIR"
    rm -f "/tmp/test-deploy-masking-$$.log"
}

################################################################################
# Helper Functions
################################################################################

# Generate random credential
generate_random_credential() {
    local iteration=$1
    local length=${2:-50}
    echo "sk-ant-api03-$(openssl rand -hex $((length / 2)))-iter-${iteration}"
}

# Generate random email
generate_random_email() {
    local iteration=$1
    echo "user-${iteration}-$(openssl rand -hex 8)@example.com"
}

# Check if value is properly masked
is_properly_masked() {
    local original=$1
    local masked=$2
    
    # Masked value should contain asterisks
    [[ "$masked" == *"*"* ]] || return 1
    
    # Masked value should show last 4 characters
    local last_four="${original: -4}"
    [[ "$masked" == *"$last_four" ]] || return 1
    
    # Masked value should NOT contain the full original
    [[ "$masked" != "$original" ]] || return 1
    
    # Masked value should have same length as original
    [ ${#masked} -eq ${#original} ] || return 1
    
    return 0
}

# Count asterisks in masked value
count_asterisks() {
    local value=$1
    echo "$value" | tr -cd '*' | wc -c
}

################################################################################
# Property Tests
################################################################################

@test "Property 11: mask_value() masks all but last 4 characters" {
    # Test that mask_value consistently masks credentials correctly
    
    local test_iterations=100
    local correct_count=0
    
    for i in $(seq 1 $test_iterations); do
        # Generate random credential
        local credential=$(generate_random_credential "$i")
        
        # Mask the credential
        local masked=$(mask_value "$credential")
        
        # Verify masking is correct
        if is_properly_masked "$credential" "$masked"; then
            correct_count=$((correct_count + 1))
        else
            echo "Iteration $i: Masking incorrect"
            echo "Original: $credential"
            echo "Masked: $masked"
            return 1
        fi
    done
    
    [ "$correct_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations correct maskings, got $correct_count"
        return 1
    }
}

@test "Property 11: Masked value shows last 4 characters for identification" {
    # Test that last 4 characters are always visible
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        local credential=$(generate_random_credential "$i")
        local last_four="${credential: -4}"
        
        # Mask the credential
        local masked=$(mask_value "$credential")
        
        # Verify last 4 characters are visible
        [[ "$masked" == *"$last_four" ]] || {
            echo "Iteration $i: Last 4 characters not visible"
            echo "Original: $credential"
            echo "Masked: $masked"
            echo "Expected last 4: $last_four"
            return 1
        }
    done
}

@test "Property 11: Masked value contains asterisks" {
    # Test that masked values contain masking characters
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        local credential=$(generate_random_credential "$i")
        
        # Mask the credential
        local masked=$(mask_value "$credential")
        
        # Verify asterisks are present
        [[ "$masked" == *"*"* ]] || {
            echo "Iteration $i: No asterisks in masked value"
            echo "Original: $credential"
            echo "Masked: $masked"
            return 1
        }
        
        # Verify there are multiple asterisks (at least length - 4)
        local asterisk_count=$(count_asterisks "$masked")
        local expected_min=$((${#credential} - 4))
        
        [ "$asterisk_count" -ge "$expected_min" ] || {
            echo "Iteration $i: Not enough asterisks"
            echo "Expected at least: $expected_min"
            echo "Got: $asterisk_count"
            return 1
        }
    done
}

@test "Property 11: Masked value has same length as original" {
    # Test that masking preserves string length
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        local credential=$(generate_random_credential "$i")
        
        # Mask the credential
        local masked=$(mask_value "$credential")
        
        # Verify lengths match
        [ ${#masked} -eq ${#credential} ] || {
            echo "Iteration $i: Length mismatch"
            echo "Original length: ${#credential}"
            echo "Masked length: ${#masked}"
            return 1
        }
    done
}

@test "Property 11: Masked value does not contain full original" {
    # Test that full credential is never visible in masked output
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        local credential=$(generate_random_credential "$i")
        
        # Mask the credential
        local masked=$(mask_value "$credential")
        
        # Verify full credential is not in masked value
        [[ "$masked" != "$credential" ]] || {
            echo "Iteration $i: Full credential visible in masked value"
            echo "Original: $credential"
            echo "Masked: $masked"
            return 1
        }
    done
}

@test "Property 11: Short credentials are masked appropriately" {
    # Test that short credentials (< 4 chars) are handled correctly
    
    local test_values=("abc" "ab" "a" "test" "key" "sk")
    
    for value in "${test_values[@]}"; do
        local masked=$(mask_value "$value")
        
        # Should contain asterisks
        [[ "$masked" == *"*"* ]] || {
            echo "Short value '$value' not masked: $masked"
            return 1
        }
        
        # Should show at least last character
        local last_char="${value: -1}"
        [[ "$masked" == *"$last_char" ]] || {
            echo "Short value '$value' doesn't show last char: $masked"
            return 1
        }
        
        # Should not show full value
        [[ "$masked" != "$value" ]] || {
            echo "Short value '$value' not masked: $masked"
            return 1
        }
    done
}

@test "Property 11: Long credentials are masked correctly" {
    # Test that very long credentials are masked properly
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        # Generate very long credential (100+ characters)
        local credential=$(generate_random_credential "$i" 100)
        
        # Mask the credential
        local masked=$(mask_value "$credential")
        
        # Verify masking is correct
        is_properly_masked "$credential" "$masked" || {
            echo "Iteration $i: Long credential not masked correctly"
            echo "Original length: ${#credential}"
            echo "Masked length: ${#masked}"
            return 1
        }
    done
}

@test "Property 11: Credentials with special characters are masked" {
    # Test that credentials containing special characters are masked
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Generate credential with special characters
        local credential="sk-ant_api03-test-key_$i-with-special-chars_$(openssl rand -hex 16)"
        
        # Mask the credential
        local masked=$(mask_value "$credential")
        
        # Verify masking is correct
        is_properly_masked "$credential" "$masked" || {
            echo "Iteration $i: Credential with special chars not masked correctly"
            echo "Original: $credential"
            echo "Masked: $masked"
            return 1
        }
    done
}

@test "Property 11: mask_value() is consistent for same input" {
    # Test that masking produces consistent output
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        local credential=$(generate_random_credential "$i")
        
        # Mask multiple times
        local masked1=$(mask_value "$credential")
        local masked2=$(mask_value "$credential")
        local masked3=$(mask_value "$credential")
        
        # All should be identical
        [ "$masked1" = "$masked2" ] || {
            echo "Iteration $i: Inconsistent masking (1 vs 2)"
            return 1
        }
        
        [ "$masked2" = "$masked3" ] || {
            echo "Iteration $i: Inconsistent masking (2 vs 3)"
            return 1
        }
    done
}

@test "Property 11: Different credentials produce different masked values" {
    # Test that different credentials have different masked outputs
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        local credential1=$(generate_random_credential "${i}a")
        local credential2=$(generate_random_credential "${i}b")
        
        # Mask both
        local masked1=$(mask_value "$credential1")
        local masked2=$(mask_value "$credential2")
        
        # They should be different (unless by extreme coincidence they have same last 4)
        local last_four1="${credential1: -4}"
        local last_four2="${credential2: -4}"
        
        if [ "$last_four1" != "$last_four2" ]; then
            [ "$masked1" != "$masked2" ] || {
                echo "Iteration $i: Different credentials produced same masked value"
                return 1
            }
        fi
    done
}

@test "Property 11: Masked API keys are identifiable by last 4 chars" {
    # Test that users can identify which key by last 4 characters
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        # Generate multiple credentials with different endings
        local cred1="sk-ant-api03-$(openssl rand -hex 20)-AAA${i}"
        local cred2="sk-ant-api03-$(openssl rand -hex 20)-BBB${i}"
        local cred3="sk-ant-api03-$(openssl rand -hex 20)-CCC${i}"
        
        # Mask all
        local masked1=$(mask_value "$cred1")
        local masked2=$(mask_value "$cred2")
        local masked3=$(mask_value "$cred3")
        
        # Verify each shows its unique last 4
        [[ "$masked1" == *"A${i}" ]] || {
            echo "Iteration $i: Credential 1 last chars not visible"
            return 1
        }
        
        [[ "$masked2" == *"B${i}" ]] || {
            echo "Iteration $i: Credential 2 last chars not visible"
            return 1
        }
        
        [[ "$masked3" == *"C${i}" ]] || {
            echo "Iteration $i: Credential 3 last chars not visible"
            return 1
        }
    done
}

@test "Property 11: Masking works for various credential types" {
    # Test that masking works for different types of sensitive values
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        # Test various credential formats
        local api_key="sk-ant-api03-$(openssl rand -hex 24)"
        local auth_token="tskey-auth-$(openssl rand -hex 20)"
        local secret="secret-$(openssl rand -hex 16)"
        local password="pass-$(openssl rand -hex 12)"
        
        # Mask all
        local masked_api=$(mask_value "$api_key")
        local masked_token=$(mask_value "$auth_token")
        local masked_secret=$(mask_value "$secret")
        local masked_pass=$(mask_value "$password")
        
        # Verify all are properly masked
        is_properly_masked "$api_key" "$masked_api" || {
            echo "Iteration $i: API key not masked correctly"
            return 1
        }
        
        is_properly_masked "$auth_token" "$masked_token" || {
            echo "Iteration $i: Auth token not masked correctly"
            return 1
        }
        
        is_properly_masked "$secret" "$masked_secret" || {
            echo "Iteration $i: Secret not masked correctly"
            return 1
        }
        
        is_properly_masked "$password" "$masked_pass" || {
            echo "Iteration $i: Password not masked correctly"
            return 1
        }
    done
}

@test "Property 11: Empty string is handled gracefully" {
    # Test that empty string doesn't cause errors
    
    run mask_value ""
    
    assert_success
    
    # Output should be empty or minimal
    [ ${#output} -le 1 ]
}

@test "Property 11: Whitespace in credentials is preserved in length" {
    # Test that credentials with whitespace are masked correctly
    
    local test_iterations=20
    
    for i in $(seq 1 $test_iterations); do
        local credential="sk-ant api03 $(openssl rand -hex 16) test"
        
        # Mask the credential
        local masked=$(mask_value "$credential")
        
        # Length should be preserved
        [ ${#masked} -eq ${#credential} ] || {
            echo "Iteration $i: Length not preserved with whitespace"
            echo "Original length: ${#credential}"
            echo "Masked length: ${#masked}"
            return 1
        }
    done
}

@test "Property 11: Numeric credentials are masked" {
    # Test that numeric-only credentials are masked
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        local credential="1234567890123456789${i}"
        
        # Mask the credential
        local masked=$(mask_value "$credential")
        
        # Verify masking
        is_properly_masked "$credential" "$masked" || {
            echo "Iteration $i: Numeric credential not masked correctly"
            echo "Original: $credential"
            echo "Masked: $masked"
            return 1
        }
    done
}

@test "Property 11: Masking preserves credential type identification" {
    # Test that masked values still allow identifying credential type by prefix
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        # Different credential types with distinct prefixes
        local api_key="sk-ant-$(openssl rand -hex 20)"
        local token="tskey-$(openssl rand -hex 20)"
        
        # Mask both
        local masked_api=$(mask_value "$api_key")
        local masked_token=$(mask_value "$token")
        
        # First few characters should be visible (before masking starts)
        # This helps identify credential type
        [[ "$masked_api" == "sk-ant"* ]] || {
            echo "Iteration $i: API key prefix not preserved"
            return 1
        }
        
        [[ "$masked_token" == "tskey"* ]] || {
            echo "Iteration $i: Token prefix not preserved"
            return 1
        }
    done
}

@test "Property 11: Masked values are safe to display in terminal" {
    # Test that masked values don't contain control characters
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        local credential=$(generate_random_credential "$i")
        
        # Mask the credential
        local masked=$(mask_value "$credential")
        
        # Verify no control characters (only printable ASCII and asterisks)
        [[ "$masked" =~ ^[[:print:]]+$ ]] || {
            echo "Iteration $i: Masked value contains non-printable characters"
            return 1
        }
    done
}
