#!/usr/bin/env bats
################################################################################
# Property-Based Test: Credential File Security
#
# **Validates: Requirements 11.3**
#
# Property 9: Credential File Security
# For any file containing sensitive credentials (API keys, authentication tokens),
# the script shall set file permissions to 600 (owner read/write only) and
# ownership to root:root.
#
# Feature: quick-start-deployment, Property 9: Credential File Security
################################################################################

# Load BATS helpers
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Test configuration
ITERATIONS=100
TEST_CONFIG_DIR="/tmp/test-ai-website-builder-security-$$"
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
    export LOG_FILE="/tmp/test-deploy-security-$$.log"
    export REPOSITORY_PATH="/tmp/test-repo"
    export QR_CODE_DIR="$TEST_CONFIG_DIR/qr-codes"
    export SCRIPT_VERSION="1.0.0"
    
    # Source necessary functions from deploy.sh
    source <(sed -n '/^# Mask sensitive value for display/,/^# Initialize logging/p' "$DEPLOY_SCRIPT" | head -n -2)
    source <(sed -n '/^# Initialize logging/,/^# Placeholder Functions/p' "$DEPLOY_SCRIPT" | head -n -2)
    source <(sed -n '/^# Save configuration to secure file/,/^# Install system dependencies/p' "$DEPLOY_SCRIPT" | head -n -2)
}

teardown() {
    # Clean up test artifacts
    rm -rf "$TEST_CONFIG_DIR"
    rm -f "/tmp/test-deploy-security-$$.log"
}

################################################################################
# Helper Functions
################################################################################

# Generate random credentials
generate_random_credentials() {
    local iteration=$1
    local random_suffix=$(printf "%04d" $iteration)
    
    CLAUDE_API_KEY="sk-ant-test-key-${random_suffix}-$(openssl rand -hex 16)"
    DOMAIN_NAME="test-${random_suffix}.example.com"
    TAILSCALE_EMAIL="test-${random_suffix}@example.com"
    INSTALL_DATE=$(date -Iseconds)
}

# Create credential file with insecure permissions
create_insecure_credential_file() {
    mkdir -p "$CONFIG_DIR"
    chmod 755 "$CONFIG_DIR"  # Insecure directory permissions
    
    cat > "$CONFIG_FILE" <<EOF
CLAUDE_API_KEY=$CLAUDE_API_KEY
DOMAIN_NAME=$DOMAIN_NAME
TAILSCALE_EMAIL=$TAILSCALE_EMAIL
EOF
    
    chmod 644 "$CONFIG_FILE"  # Insecure file permissions
}

# Check file permissions
check_file_permissions() {
    local file=$1
    local expected_perms=$2
    
    local actual_perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null)
    [ "$actual_perms" = "$expected_perms" ]
}

# Check file ownership
check_file_ownership() {
    local file=$1
    
    # Skip ownership check if not running as root
    if [ "$(id -u)" -ne 0 ]; then
        return 0
    fi
    
    local owner=$(stat -c "%U:%G" "$file" 2>/dev/null || stat -f "%Su:%Sg" "$file" 2>/dev/null)
    [ "$owner" = "root:root" ]
}

################################################################################
# Property Tests
################################################################################

@test "Property 9: Configuration file always has 600 permissions after save" {
    # Test that save_configuration always sets 600 permissions
    
    local test_iterations=100
    local secure_count=0
    
    for i in $(seq 1 $test_iterations); do
        # Generate random credentials
        generate_random_credentials "$i"
        
        # Save configuration
        save_configuration >/dev/null 2>&1
        
        # Verify file permissions are 600
        if check_file_permissions "$CONFIG_FILE" "600"; then
            secure_count=$((secure_count + 1))
        else
            local actual_perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%A" "$CONFIG_FILE" 2>/dev/null)
            echo "Iteration $i: File permissions not secure: $actual_perms (expected 600)"
            return 1
        fi
        
        # Clean up for next iteration
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
    
    # All files should have been secured
    [ "$secure_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations secure files, got $secure_count"
        return 1
    }
}

@test "Property 9: Configuration directory always has 700 permissions" {
    # Test that configuration directory is always secured
    
    local test_iterations=100
    local secure_count=0
    
    for i in $(seq 1 $test_iterations); do
        # Generate random credentials
        generate_random_credentials "$i"
        
        # Save configuration
        save_configuration >/dev/null 2>&1
        
        # Verify directory permissions are 700
        if check_file_permissions "$CONFIG_DIR" "700"; then
            secure_count=$((secure_count + 1))
        else
            local actual_perms=$(stat -c "%a" "$CONFIG_DIR" 2>/dev/null || stat -f "%A" "$CONFIG_DIR" 2>/dev/null)
            echo "Iteration $i: Directory permissions not secure: $actual_perms (expected 700)"
            return 1
        fi
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
    
    [ "$secure_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations secure directories, got $secure_count"
        return 1
    }
}

@test "Property 9: Insecure permissions are corrected on save" {
    # Test that save_configuration corrects insecure permissions
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Generate random credentials
        generate_random_credentials "$i"
        
        # Create file with insecure permissions
        create_insecure_credential_file
        
        # Verify file is insecure before save
        local before_perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%A" "$CONFIG_FILE" 2>/dev/null)
        [ "$before_perms" != "600" ] || {
            echo "Iteration $i: Test setup failed - file should be insecure"
            return 1
        }
        
        # Save configuration (should correct permissions)
        save_configuration >/dev/null 2>&1
        
        # Verify permissions are now secure
        check_file_permissions "$CONFIG_FILE" "600" || {
            local actual_perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%A" "$CONFIG_FILE" 2>/dev/null)
            echo "Iteration $i: Permissions not corrected: $actual_perms (expected 600)"
            return 1
        }
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
}

@test "Property 9: File ownership is root:root when running as root" {
    # Skip if not running as root
    if [ "$(id -u)" -ne 0 ]; then
        skip "Test requires root privileges"
    fi
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Generate random credentials
        generate_random_credentials "$i"
        
        # Save configuration
        save_configuration >/dev/null 2>&1
        
        # Verify ownership
        check_file_ownership "$CONFIG_FILE" || {
            local actual_owner=$(stat -c "%U:%G" "$CONFIG_FILE" 2>/dev/null || stat -f "%Su:%Sg" "$CONFIG_FILE" 2>/dev/null)
            echo "Iteration $i: File ownership not secure: $actual_owner (expected root:root)"
            return 1
        }
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
}

@test "Property 9: Directory ownership is root:root when running as root" {
    # Skip if not running as root
    if [ "$(id -u)" -ne 0 ]; then
        skip "Test requires root privileges"
    fi
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Generate random credentials
        generate_random_credentials "$i"
        
        # Save configuration
        save_configuration >/dev/null 2>&1
        
        # Verify directory ownership
        check_file_ownership "$CONFIG_DIR" || {
            local actual_owner=$(stat -c "%U:%G" "$CONFIG_DIR" 2>/dev/null || stat -f "%Su:%Sg" "$CONFIG_DIR" 2>/dev/null)
            echo "Iteration $i: Directory ownership not secure: $actual_owner (expected root:root)"
            return 1
        }
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
}

@test "Property 9: Permissions remain secure after multiple saves" {
    # Test that permissions stay secure across multiple save operations
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        # Generate initial credentials
        generate_random_credentials "$i"
        
        # Save configuration multiple times
        for cycle in {1..5}; do
            save_configuration >/dev/null 2>&1
            
            # Verify permissions after each save
            check_file_permissions "$CONFIG_FILE" "600" || {
                local actual_perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%A" "$CONFIG_FILE" 2>/dev/null)
                echo "Iteration $i, cycle $cycle: Permissions not secure: $actual_perms"
                return 1
            }
            
            check_file_permissions "$CONFIG_DIR" "700" || {
                local actual_perms=$(stat -c "%a" "$CONFIG_DIR" 2>/dev/null || stat -f "%A" "$CONFIG_DIR" 2>/dev/null)
                echo "Iteration $i, cycle $cycle: Directory permissions not secure: $actual_perms"
                return 1
            }
        done
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
}

@test "Property 9: Permissions are secure regardless of umask" {
    # Test that permissions are secure even with permissive umask
    
    local test_iterations=30
    local original_umask=$(umask)
    
    for i in $(seq 1 $test_iterations); do
        # Set a permissive umask
        umask 0000
        
        # Generate random credentials
        generate_random_credentials "$i"
        
        # Save configuration
        save_configuration >/dev/null 2>&1
        
        # Verify permissions are still secure despite permissive umask
        check_file_permissions "$CONFIG_FILE" "600" || {
            local actual_perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%A" "$CONFIG_FILE" 2>/dev/null)
            umask "$original_umask"
            echo "Iteration $i: Permissions not secure with permissive umask: $actual_perms"
            return 1
        }
        
        check_file_permissions "$CONFIG_DIR" "700" || {
            local actual_perms=$(stat -c "%a" "$CONFIG_DIR" 2>/dev/null || stat -f "%A" "$CONFIG_DIR" 2>/dev/null)
            umask "$original_umask"
            echo "Iteration $i: Directory permissions not secure with permissive umask: $actual_perms"
            return 1
        }
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
    
    # Restore original umask
    umask "$original_umask"
}

@test "Property 9: Configuration file is not world-readable" {
    # Test that configuration file cannot be read by other users
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Generate random credentials
        generate_random_credentials "$i"
        
        # Save configuration
        save_configuration >/dev/null 2>&1
        
        # Check that file is not world-readable (no read bit for others)
        local perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%A" "$CONFIG_FILE" 2>/dev/null)
        local others_perms=${perms: -1}
        
        [ "$others_perms" = "0" ] || {
            echo "Iteration $i: File is world-readable: permissions=$perms"
            return 1
        }
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
}

@test "Property 9: Configuration file is not group-readable" {
    # Test that configuration file cannot be read by group members
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Generate random credentials
        generate_random_credentials "$i"
        
        # Save configuration
        save_configuration >/dev/null 2>&1
        
        # Check that file is not group-readable (no read bit for group)
        local perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%A" "$CONFIG_FILE" 2>/dev/null)
        local group_perms=${perms:1:1}
        
        [ "$group_perms" = "0" ] || {
            echo "Iteration $i: File is group-readable: permissions=$perms"
            return 1
        }
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
}

@test "Property 9: Configuration directory is not accessible to others" {
    # Test that configuration directory cannot be accessed by other users
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Generate random credentials
        generate_random_credentials "$i"
        
        # Save configuration
        save_configuration >/dev/null 2>&1
        
        # Check that directory is not accessible to others
        local perms=$(stat -c "%a" "$CONFIG_DIR" 2>/dev/null || stat -f "%A" "$CONFIG_DIR" 2>/dev/null)
        local others_perms=${perms: -1}
        
        [ "$others_perms" = "0" ] || {
            echo "Iteration $i: Directory is accessible to others: permissions=$perms"
            return 1
        }
        
        # Clean up
        rm -rf "$TEST_CONFIG_DIR"
        mkdir -p "$TEST_CONFIG_DIR"
    done
}
