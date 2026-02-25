#!/usr/bin/env bats
################################################################################
# Property-Based Test: Installation Mode Detection
#
# **Validates: Requirements 5.1**
#
# Property 2: Installation Mode Detection
# For any system state, if an installation state file exists at
# `/etc/ai-website-builder/.install-state`, the script shall detect it and
# enter update mode; otherwise, it shall enter fresh installation mode.
#
# Feature: quick-start-deployment, Property 2: Installation Mode Detection
################################################################################

# Load BATS helpers
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Test configuration
ITERATIONS=100
TEST_CONFIG_DIR="/tmp/test-ai-website-builder-mode-$$"
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
    export STATE_FILE="$TEST_STATE_FILE"
    export LOG_FILE="/tmp/test-deploy-mode-$$.log"
    
    # Source the detection function from deploy.sh
    source <(sed -n '/^# Detect if this is a fresh installation or update mode/,/^# Validate Claude API key format/p' "$DEPLOY_SCRIPT" | head -n -2)
    
    # Source the logging functions needed by detect_existing_installation
    source <(sed -n '/^# Display progress message/,/^# Display info message/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^# Display info message/,/^# Display error message/p' "$DEPLOY_SCRIPT")
    source <(sed -n '/^# Log operation to file/,/^# Display progress message/p' "$DEPLOY_SCRIPT" | head -n -2)
}

teardown() {
    # Clean up test artifacts
    rm -rf "$TEST_CONFIG_DIR"
    rm -f "/tmp/test-deploy-mode-$$.log"
}

################################################################################
# Helper Functions
################################################################################

# Generate random state file content
generate_state_file_content() {
    local iteration=$1
    cat <<EOF
INSTALL_DATE=$(date -Iseconds)
INSTALL_VERSION=1.0.$iteration
LAST_UPDATE=$(date -Iseconds)
REPOSITORY_PATH=/opt/ai-website-builder
EOF
}

# Create state file with random content
create_state_file() {
    local iteration=$1
    mkdir -p "$(dirname "$STATE_FILE")"
    generate_state_file_content "$iteration" > "$STATE_FILE"
}

# Remove state file
remove_state_file() {
    rm -f "$STATE_FILE"
}

# Check if mode was set correctly
verify_mode() {
    local expected_mode=$1
    [ "$MODE" = "$expected_mode" ]
}

################################################################################
# Property Tests
################################################################################

@test "Property 2: State file exists -> update mode detected" {
    # Test that presence of state file always triggers update mode
    
    local test_iterations=100
    local update_mode_count=0
    
    for i in $(seq 1 $test_iterations); do
        # Clean up from previous iteration
        unset MODE
        remove_state_file
        
        # Create state file
        create_state_file "$i"
        
        # Verify state file exists
        [ -f "$STATE_FILE" ] || {
            echo "Iteration $i: State file was not created"
            return 1
        }
        
        # Run detection
        detect_existing_installation >/dev/null 2>&1
        
        # Verify update mode was detected
        if verify_mode "update"; then
            update_mode_count=$((update_mode_count + 1))
        else
            echo "Iteration $i: Update mode not detected despite state file existing"
            echo "MODE=$MODE"
            echo "STATE_FILE=$STATE_FILE"
            ls -la "$STATE_FILE" || echo "State file not found"
            return 1
        fi
    done
    
    # All iterations should have detected update mode
    [ "$update_mode_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations update mode detections, got $update_mode_count"
        return 1
    }
}

@test "Property 2: State file absent -> fresh mode detected" {
    # Test that absence of state file always triggers fresh installation mode
    
    local test_iterations=100
    local fresh_mode_count=0
    
    for i in $(seq 1 $test_iterations); do
        # Clean up from previous iteration
        unset MODE
        remove_state_file
        
        # Verify state file does not exist
        [ ! -f "$STATE_FILE" ] || {
            echo "Iteration $i: State file should not exist"
            return 1
        }
        
        # Run detection
        detect_existing_installation >/dev/null 2>&1
        
        # Verify fresh mode was detected
        if verify_mode "fresh"; then
            fresh_mode_count=$((fresh_mode_count + 1))
        else
            echo "Iteration $i: Fresh mode not detected despite state file being absent"
            echo "MODE=$MODE"
            echo "STATE_FILE=$STATE_FILE"
            return 1
        fi
    done
    
    # All iterations should have detected fresh mode
    [ "$fresh_mode_count" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations fresh mode detections, got $fresh_mode_count"
        return 1
    }
}

@test "Property 2: Mode detection is consistent across multiple calls" {
    # Test that detection produces same result when called multiple times
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Randomly decide whether to create state file
        if [ $((i % 2)) -eq 0 ]; then
            create_state_file "$i"
            local expected_mode="update"
        else
            remove_state_file
            local expected_mode="fresh"
        fi
        
        # Run detection multiple times
        unset MODE
        detect_existing_installation >/dev/null 2>&1
        local mode1="$MODE"
        
        unset MODE
        detect_existing_installation >/dev/null 2>&1
        local mode2="$MODE"
        
        unset MODE
        detect_existing_installation >/dev/null 2>&1
        local mode3="$MODE"
        
        # All should be the same
        [ "$mode1" = "$mode2" ] && [ "$mode2" = "$mode3" ] || {
            echo "Iteration $i: Inconsistent mode detection"
            echo "Expected: $expected_mode"
            echo "Got: $mode1, $mode2, $mode3"
            return 1
        }
        
        # All should match expected mode
        [ "$mode1" = "$expected_mode" ] || {
            echo "Iteration $i: Mode doesn't match expected"
            echo "Expected: $expected_mode"
            echo "Got: $mode1"
            return 1
        }
    done
}

@test "Property 2: State file content doesn't affect mode detection" {
    # Test that mode detection only checks file existence, not content
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        unset MODE
        remove_state_file
        
        # Create state file with various content (including invalid/empty)
        mkdir -p "$(dirname "$STATE_FILE")"
        
        case $((i % 5)) in
            0)
                # Valid content
                generate_state_file_content "$i" > "$STATE_FILE"
                ;;
            1)
                # Empty file
                touch "$STATE_FILE"
                ;;
            2)
                # Invalid content
                echo "INVALID CONTENT" > "$STATE_FILE"
                ;;
            3)
                # Partial content
                echo "INSTALL_DATE=$(date -Iseconds)" > "$STATE_FILE"
                ;;
            4)
                # Random content
                openssl rand -base64 32 > "$STATE_FILE"
                ;;
        esac
        
        # Run detection
        detect_existing_installation >/dev/null 2>&1
        
        # Should always detect update mode when file exists
        verify_mode "update" || {
            echo "Iteration $i: Update mode not detected despite state file existing"
            echo "MODE=$MODE"
            echo "State file content:"
            cat "$STATE_FILE"
            return 1
        }
    done
}

@test "Property 2: State file permissions don't affect mode detection" {
    # Test that mode detection works regardless of file permissions
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        unset MODE
        remove_state_file
        
        # Create state file
        create_state_file "$i"
        
        # Set random permissions
        local perms=("000" "400" "600" "644" "755" "777")
        local perm_index=$((RANDOM % ${#perms[@]}))
        chmod "${perms[$perm_index]}" "$STATE_FILE" 2>/dev/null || true
        
        # Run detection
        detect_existing_installation >/dev/null 2>&1
        
        # Should detect update mode
        verify_mode "update" || {
            echo "Iteration $i: Update mode not detected with permissions ${perms[$perm_index]}"
            echo "MODE=$MODE"
            return 1
        }
    done
}

@test "Property 2: Directory structure doesn't affect mode detection" {
    # Test that only the state file matters, not other files in directory
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        unset MODE
        remove_state_file
        
        # Create various files in config directory
        mkdir -p "$CONFIG_DIR"
        touch "$CONFIG_DIR/config.env"
        touch "$CONFIG_DIR/other-file.txt"
        mkdir -p "$CONFIG_DIR/qr-codes"
        
        # Don't create state file
        [ ! -f "$STATE_FILE" ] || {
            echo "Iteration $i: State file should not exist"
            return 1
        }
        
        # Run detection
        detect_existing_installation >/dev/null 2>&1
        
        # Should detect fresh mode (state file doesn't exist)
        verify_mode "fresh" || {
            echo "Iteration $i: Fresh mode not detected despite state file being absent"
            echo "MODE=$MODE"
            echo "Config dir contents:"
            ls -la "$CONFIG_DIR"
            return 1
        }
        
        # Now create state file
        create_state_file "$i"
        
        # Run detection again
        unset MODE
        detect_existing_installation >/dev/null 2>&1
        
        # Should detect update mode
        verify_mode "update" || {
            echo "Iteration $i: Update mode not detected after creating state file"
            echo "MODE=$MODE"
            return 1
        }
    done
}

@test "Property 2: Symlinked state file is detected correctly" {
    # Test that mode detection works with symlinked state files
    
    local test_iterations=20
    
    for i in $(seq 1 $test_iterations); do
        unset MODE
        remove_state_file
        
        # Create actual state file in different location
        local actual_file="/tmp/actual-state-$i-$$.txt"
        generate_state_file_content "$i" > "$actual_file"
        
        # Create symlink
        mkdir -p "$(dirname "$STATE_FILE")"
        ln -s "$actual_file" "$STATE_FILE"
        
        # Run detection
        detect_existing_installation >/dev/null 2>&1
        
        # Should detect update mode
        verify_mode "update" || {
            echo "Iteration $i: Update mode not detected with symlinked state file"
            echo "MODE=$MODE"
            return 1
        }
        
        # Clean up
        rm -f "$actual_file"
    done
}

@test "Property 2: Rapid state file changes are detected correctly" {
    # Test that mode detection handles rapid file creation/deletion
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        unset MODE
        
        # Rapidly toggle state file existence
        if [ $((i % 2)) -eq 0 ]; then
            create_state_file "$i"
            local expected="update"
        else
            remove_state_file
            local expected="fresh"
        fi
        
        # Run detection immediately
        detect_existing_installation >/dev/null 2>&1
        
        # Verify correct mode
        verify_mode "$expected" || {
            echo "Iteration $i: Expected $expected mode, got $MODE"
            return 1
        }
    done
}

@test "Property 2: State file in non-existent directory is handled correctly" {
    # Test that mode detection handles missing parent directory
    
    local test_iterations=20
    
    for i in $(seq 1 $test_iterations); do
        unset MODE
        
        # Remove entire config directory
        rm -rf "$CONFIG_DIR"
        
        # Verify state file doesn't exist
        [ ! -f "$STATE_FILE" ] || {
            echo "Iteration $i: State file should not exist"
            return 1
        }
        
        # Run detection
        detect_existing_installation >/dev/null 2>&1
        
        # Should detect fresh mode
        verify_mode "fresh" || {
            echo "Iteration $i: Fresh mode not detected when directory doesn't exist"
            echo "MODE=$MODE"
            return 1
        }
    done
}

@test "Property 2: MODE variable is always set after detection" {
    # Test that MODE variable is always set to either "fresh" or "update"
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        unset MODE
        
        # Randomly create or remove state file
        if [ $((RANDOM % 2)) -eq 0 ]; then
            create_state_file "$i"
        else
            remove_state_file
        fi
        
        # Run detection
        detect_existing_installation >/dev/null 2>&1
        
        # MODE must be set
        [ -n "$MODE" ] || {
            echo "Iteration $i: MODE variable not set after detection"
            return 1
        }
        
        # MODE must be either "fresh" or "update"
        [[ "$MODE" == "fresh" || "$MODE" == "update" ]] || {
            echo "Iteration $i: MODE has invalid value: $MODE"
            return 1
        }
    done
}
