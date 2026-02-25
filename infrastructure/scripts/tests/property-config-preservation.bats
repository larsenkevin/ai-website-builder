#!/usr/bin/env bats
################################################################################
# Property-Based Test: Configuration Preservation in Update Mode
#
# **Validates: Requirements 5.3, 5.4, 5.5**
#
# Property 3: Configuration Preservation in Update Mode
# For any configuration value in update mode, if the user does not provide a
# new value (presses Enter), the existing value shall remain unchanged in the
# configuration file.
#
# Feature: quick-start-deployment, Property 3: Configuration Preservation in Update Mode
################################################################################

# Load BATS helpers
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Test configuration
ITERATIONS=100
TEST_CONFIG_DIR="/tmp/test-ai-website-builder-preserve-$$"
TEST_CONFIG_FILE="$TEST_CONFIG_DIR/config.env"
TEST_STATE_FILE="$TEST_CONFIG_DIR/.install-state"
DEPLOY_SCRIPT="$(dirname "$BATS_TEST_DIRNAME")/deploy.sh"

################################################################################
# Setup and Teardown
################################################################################

setup() {
    # Create test configuration directory
    mkdir -p "$TEST_CONFIG_DIR"
    
    # Set test environment variables to override script defaults
    export CONFIG_DIR="$TEST_CONFIG_DIR"
    export CONFIG_FILE="$TEST_CONFIG_FILE"
    export STATE_FILE="$TEST_STATE_FILE"
    export LOG_FILE="/tmp/test-deploy-preserve-$$.log"
    
    # Source necessary functions from deploy.sh
    # We need: mask_value, validation functions, save_configuration
    source <(sed -n '/^# Mask sensitive value for display/,/^# Initialize logging/p' "$DEPLOY_SCRIPT" | head -n -2)
    source <(sed -n '/^# Validate Claude API key format/,/^# Collect configuration input from user/p' "$DEPLOY_SCRIPT" | head -n -2)
    source <(sed -n '/^# Save configuration to secure file/,/^# Install system dependencies/p' "$DEPLOY_SCRIPT" | head -n -2)
    
    # Source logging functions
    source <(sed -n '/^# Log operation to file/,/^# Display progress message/p' "$DEPLOY_SCRIPT" | head -n -2)
    source <(sed -n '/^# Display progress message/,/^# Display success message/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^# Display success message/,/^# Display warning message/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^# Display warning message/,/^# Display info message/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^# Display info message/,/^# Display error message/p' "$DEPLOY_SCRIPT")
}

teardown() {
    # Clean up test artifacts
    rm -rf "$TEST_CONFIG_DIR"
    rm -f "/tmp/test-deploy-preserve-$$.log"
}

################################################################################
# Helper Functions
################################################################################

# Generate random valid configuration
generate_random_config() {
    local iteration=$1
    local random_suffix=$(printf "%04d" $iteration)
    
    CLAUDE_API_KEY="sk-ant-test-key-${random_suffix}-$(openssl rand -hex 16)"
    DOMAIN_NAME="test-${random_suffix}.example.com"
    TAILSCALE_EMAIL="test-${random_suffix}@example.com"
}

# Create initial configuration file
create_initial_config() {
    local iteration=$1
    
    generate_random_config "$iteration"
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"
    
    # Write configuration file
    cat > "$CONFIG_FILE" <<EOF
# AI Website Builder Configuration
# Generated: $(date -Iseconds)
# DO NOT SHARE THIS FILE - Contains sensitive credentials

CLAUDE_API_KEY=$CLAUDE_API_KEY
DOMAIN_NAME=$DOMAIN_NAME
TAILSCALE_EMAIL=$TAILSCALE_EMAIL
INSTALL_DATE=$(date -Iseconds)
REPOSITORY_PATH=/opt/ai-website-builder
EOF
    
    chmod 600 "$CONFIG_FILE"
    chown root:root "$CONFIG_FILE" 2>/dev/null || true
}

# Read configuration value from file
read_config_value() {
    local field=$1
    grep "^${field}=" "$CONFIG_FILE" | cut -d'=' -f2-
}

# Simulate user pressing Enter (keeping existing value)
simulate_keep_value() {
    local field=$1
    
    # Load existing configuration
    source "$CONFIG_FILE"
    
    # The value should remain unchanged
    # In the actual script, this happens when user presses Enter
    # We simulate this by not changing the variable
}

# Simulate user providing new value
simulate_update_value() {
    local field=$1
    local new_value=$2
    
    # Update the variable
    case "$field" in
        "CLAUDE_API_KEY")
            CLAUDE_API_KEY="$new_value"
            ;;
        "DOMAIN_NAME")
            DOMAIN_NAME="$new_value"
            ;;
        "TAILSCALE_EMAIL")
            TAILSCALE_EMAIL="$new_value"
            ;;
    esac
}

# Save configuration and verify preservation
save_and_verify() {
    local field=$1
    local original_value=$2
    
    # Save configuration
    save_configuration >/dev/null 2>&1
    
    # Read back the value
    local saved_value=$(read_config_value "$field")
    
    # Compare
    [ "$saved_value" = "$original_value" ]
}

################################################################################
# Property Tests
################################################################################

@test "Property 3: Keeping existing API key preserves original value" {
    # Test that pressing Enter for API key keeps the original value
    
    local test_iterations=100
    local preservation_count=0
    
    for i in $(seq 1 $test_iterations); do
        # Create initial configuration
        create_initial_config "$i"
        
        # Store original value
        local original_api_key=$(read_config_value "CLAUDE_API_KEY")
        
        # Load configuration (simulating update mode)
        source "$CONFIG_FILE"
        
        # Simulate user pressing Enter (keeping value)
        simulate_keep_value "CLAUDE_API_KEY"
        
        # Save configuration
        if save_and_verify "CLAUDE_API_KEY" "$original_api_key"; then
            preservation_count=$((preservation_count + 1))
        else
            echo "Iteration $i: API key was not preserved"
            echo "Original: $original_api_key"
            echo "Saved: $(read_config_value 'CLAUDE_API_KEY')"
            return 1
        fi
        
        # Clean up for next iteration
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
    
    # All values should have been preserved
    [ "$preservation_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations preservations, got $preservation_count"
        return 1
    }
}

@test "Property 3: Keeping existing domain name preserves original value" {
    # Test that pressing Enter for domain name keeps the original value
    
    local test_iterations=100
    local preservation_count=0
    
    for i in $(seq 1 $test_iterations); do
        # Create initial configuration
        create_initial_config "$i"
        
        # Store original value
        local original_domain=$(read_config_value "DOMAIN_NAME")
        
        # Load configuration
        source "$CONFIG_FILE"
        
        # Simulate user pressing Enter
        simulate_keep_value "DOMAIN_NAME"
        
        # Save configuration
        if save_and_verify "DOMAIN_NAME" "$original_domain"; then
            preservation_count=$((preservation_count + 1))
        else
            echo "Iteration $i: Domain name was not preserved"
            echo "Original: $original_domain"
            echo "Saved: $(read_config_value 'DOMAIN_NAME')"
            return 1
        fi
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
    
    [ "$preservation_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations preservations, got $preservation_count"
        return 1
    }
}

@test "Property 3: Keeping existing email preserves original value" {
    # Test that pressing Enter for email keeps the original value
    
    local test_iterations=100
    local preservation_count=0
    
    for i in $(seq 1 $test_iterations); do
        # Create initial configuration
        create_initial_config "$i"
        
        # Store original value
        local original_email=$(read_config_value "TAILSCALE_EMAIL")
        
        # Load configuration
        source "$CONFIG_FILE"
        
        # Simulate user pressing Enter
        simulate_keep_value "TAILSCALE_EMAIL"
        
        # Save configuration
        if save_and_verify "TAILSCALE_EMAIL" "$original_email"; then
            preservation_count=$((preservation_count + 1))
        else
            echo "Iteration $i: Email was not preserved"
            echo "Original: $original_email"
            echo "Saved: $(read_config_value 'TAILSCALE_EMAIL')"
            return 1
        fi
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
    
    [ "$preservation_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations preservations, got $preservation_count"
        return 1
    }
}

@test "Property 3: Updating one field preserves other fields" {
    # Test that updating one field doesn't affect other fields
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Create initial configuration
        create_initial_config "$i"
        
        # Store all original values
        local original_api_key=$(read_config_value "CLAUDE_API_KEY")
        local original_domain=$(read_config_value "DOMAIN_NAME")
        local original_email=$(read_config_value "TAILSCALE_EMAIL")
        
        # Load configuration
        source "$CONFIG_FILE"
        
        # Update only one field (rotate which field we update)
        case $((i % 3)) in
            0)
                # Update API key, keep others
                simulate_update_value "CLAUDE_API_KEY" "sk-ant-new-$(openssl rand -hex 16)"
                ;;
            1)
                # Update domain, keep others
                simulate_update_value "DOMAIN_NAME" "new-$i.example.com"
                ;;
            2)
                # Update email, keep others
                simulate_update_value "TAILSCALE_EMAIL" "new-$i@example.com"
                ;;
        esac
        
        # Save configuration
        save_configuration >/dev/null 2>&1
        
        # Verify unchanged fields are preserved
        case $((i % 3)) in
            0)
                # API key was updated, others should be preserved
                local saved_domain=$(read_config_value "DOMAIN_NAME")
                local saved_email=$(read_config_value "TAILSCALE_EMAIL")
                
                [ "$saved_domain" = "$original_domain" ] || {
                    echo "Iteration $i: Domain was changed when updating API key"
                    echo "Original: $original_domain"
                    echo "Saved: $saved_domain"
                    return 1
                }
                
                [ "$saved_email" = "$original_email" ] || {
                    echo "Iteration $i: Email was changed when updating API key"
                    echo "Original: $original_email"
                    echo "Saved: $saved_email"
                    return 1
                }
                ;;
            1)
                # Domain was updated, others should be preserved
                local saved_api_key=$(read_config_value "CLAUDE_API_KEY")
                local saved_email=$(read_config_value "TAILSCALE_EMAIL")
                
                [ "$saved_api_key" = "$original_api_key" ] || {
                    echo "Iteration $i: API key was changed when updating domain"
                    return 1
                }
                
                [ "$saved_email" = "$original_email" ] || {
                    echo "Iteration $i: Email was changed when updating domain"
                    return 1
                }
                ;;
            2)
                # Email was updated, others should be preserved
                local saved_api_key=$(read_config_value "CLAUDE_API_KEY")
                local saved_domain=$(read_config_value "DOMAIN_NAME")
                
                [ "$saved_api_key" = "$original_api_key" ] || {
                    echo "Iteration $i: API key was changed when updating email"
                    return 1
                }
                
                [ "$saved_domain" = "$original_domain" ] || {
                    echo "Iteration $i: Domain was changed when updating email"
                    return 1
                }
                ;;
        esac
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
}

@test "Property 3: Multiple update cycles preserve values correctly" {
    # Test that values are preserved across multiple update cycles
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        # Create initial configuration
        create_initial_config "$i"
        
        # Store original values
        local original_api_key=$(read_config_value "CLAUDE_API_KEY")
        local original_domain=$(read_config_value "DOMAIN_NAME")
        local original_email=$(read_config_value "TAILSCALE_EMAIL")
        
        # Perform multiple update cycles without changing values
        for cycle in {1..5}; do
            # Load configuration
            source "$CONFIG_FILE"
            
            # Keep all values (simulate pressing Enter for all)
            simulate_keep_value "CLAUDE_API_KEY"
            simulate_keep_value "DOMAIN_NAME"
            simulate_keep_value "TAILSCALE_EMAIL"
            
            # Save configuration
            save_configuration >/dev/null 2>&1
        done
        
        # Verify all values are still original
        local final_api_key=$(read_config_value "CLAUDE_API_KEY")
        local final_domain=$(read_config_value "DOMAIN_NAME")
        local final_email=$(read_config_value "TAILSCALE_EMAIL")
        
        [ "$final_api_key" = "$original_api_key" ] || {
            echo "Iteration $i: API key changed after multiple cycles"
            echo "Original: $original_api_key"
            echo "Final: $final_api_key"
            return 1
        }
        
        [ "$final_domain" = "$original_domain" ] || {
            echo "Iteration $i: Domain changed after multiple cycles"
            return 1
        }
        
        [ "$final_email" = "$original_email" ] || {
            echo "Iteration $i: Email changed after multiple cycles"
            return 1
        }
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
}

@test "Property 3: INSTALL_DATE is preserved in update mode" {
    # Test that INSTALL_DATE field is not changed during updates
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Create initial configuration with specific install date
        create_initial_config "$i"
        local original_install_date=$(read_config_value "INSTALL_DATE")
        
        # Wait a moment to ensure timestamp would differ
        sleep 0.1
        
        # Load and save configuration (simulating update)
        source "$CONFIG_FILE"
        save_configuration >/dev/null 2>&1
        
        # Verify INSTALL_DATE is preserved
        local saved_install_date=$(read_config_value "INSTALL_DATE")
        
        [ "$saved_install_date" = "$original_install_date" ] || {
            echo "Iteration $i: INSTALL_DATE was changed during update"
            echo "Original: $original_install_date"
            echo "Saved: $saved_install_date"
            return 1
        }
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
}

@test "Property 3: Configuration file permissions preserved after update" {
    # Test that file permissions remain secure after updates
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        # Create initial configuration
        create_initial_config "$i"
        
        # Verify initial permissions
        local initial_perms=$(stat -c "%a" "$CONFIG_FILE")
        [ "$initial_perms" = "600" ] || {
            echo "Iteration $i: Initial permissions not 600: $initial_perms"
            return 1
        }
        
        # Load and save configuration
        source "$CONFIG_FILE"
        save_configuration >/dev/null 2>&1
        
        # Verify permissions are still 600
        local final_perms=$(stat -c "%a" "$CONFIG_FILE")
        [ "$final_perms" = "600" ] || {
            echo "Iteration $i: Permissions changed after update: $final_perms"
            return 1
        }
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
}

@test "Property 3: Empty input preserves value (simulated)" {
    # Test that empty string input is treated as "keep existing value"
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Create initial configuration
        create_initial_config "$i"
        
        # Store original values
        local original_api_key=$(read_config_value "CLAUDE_API_KEY")
        local original_domain=$(read_config_value "DOMAIN_NAME")
        local original_email=$(read_config_value "TAILSCALE_EMAIL")
        
        # Load configuration
        source "$CONFIG_FILE"
        
        # Simulate empty input (which means keep existing)
        # In the actual script, this is: if [ -z "$new_value" ]; then keep existing
        # We simulate by not changing the variables
        
        # Save configuration
        save_configuration >/dev/null 2>&1
        
        # Verify all values preserved
        [ "$(read_config_value 'CLAUDE_API_KEY')" = "$original_api_key" ] || {
            echo "Iteration $i: API key not preserved with empty input"
            return 1
        }
        
        [ "$(read_config_value 'DOMAIN_NAME')" = "$original_domain" ] || {
            echo "Iteration $i: Domain not preserved with empty input"
            return 1
        }
        
        [ "$(read_config_value 'TAILSCALE_EMAIL')" = "$original_email" ] || {
            echo "Iteration $i: Email not preserved with empty input"
            return 1
        }
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
}

@test "Property 3: Preservation works with special characters in values" {
    # Test that values with special characters are preserved correctly
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        # Create configuration with special characters
        mkdir -p "$CONFIG_DIR"
        chmod 700 "$CONFIG_DIR"
        
        # Generate values with special characters
        CLAUDE_API_KEY="sk-ant-test_key-$i-with-special-chars_$(openssl rand -hex 8)"
        DOMAIN_NAME="test-$i.sub-domain.example.com"
        TAILSCALE_EMAIL="test+tag$i@sub-domain.example.com"
        
        # Save initial configuration
        save_configuration >/dev/null 2>&1
        
        # Store original values
        local original_api_key=$(read_config_value "CLAUDE_API_KEY")
        local original_domain=$(read_config_value "DOMAIN_NAME")
        local original_email=$(read_config_value "TAILSCALE_EMAIL")
        
        # Load and save again (simulating update with no changes)
        source "$CONFIG_FILE"
        save_configuration >/dev/null 2>&1
        
        # Verify preservation
        [ "$(read_config_value 'CLAUDE_API_KEY')" = "$original_api_key" ] || {
            echo "Iteration $i: API key with special chars not preserved"
            return 1
        }
        
        [ "$(read_config_value 'DOMAIN_NAME')" = "$original_domain" ] || {
            echo "Iteration $i: Domain with special chars not preserved"
            return 1
        }
        
        [ "$(read_config_value 'TAILSCALE_EMAIL')" = "$original_email" ] || {
            echo "Iteration $i: Email with special chars not preserved"
            return 1
        }
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
}
