#!/usr/bin/env bats
################################################################################
# Property-Based Test: QR Code File Persistence
#
# **Validates: Requirements 6.4**
#
# Property 4: QR Code File Persistence
# For any generated QR code (app store link or service access URL), the script
# shall save it as a PNG image file in `/etc/ai-website-builder/qr-codes/` with
# a filename corresponding to its type.
#
# Feature: quick-start-deployment, Property 4: QR Code File Persistence
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
    # Set test environment variables to override script defaults
    export CONFIG_DIR="/tmp/test-qr-config-$$-$RANDOM"
    export QR_CODE_DIR="$CONFIG_DIR/qr-codes"
    export LOG_FILE="$CONFIG_DIR/test.log"
    export STATE_FILE="$CONFIG_DIR/.install-state"
    export CONFIG_FILE="$CONFIG_DIR/config.env"
    export REPOSITORY_PATH="/tmp/test-repo"
    export SCRIPT_VERSION="1.0.0"
    
    # Create test directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Create mock config file with test values
    cat > "$CONFIG_FILE" << EOF
CLAUDE_API_KEY=sk-ant-test123456789
DOMAIN_NAME=test-$(date +%s).example.com
TAILSCALE_EMAIL=test-$(date +%s)@example.com
EOF
    
    # Source the QR code generation functions from deploy.sh
    # We need to source the logging functions first
    source <(sed -n '/^# Initialize logging/,/^# Placeholder Functions/p' "$DEPLOY_SCRIPT" | head -n -2)
    
    # Source the QR code generation function
    source <(sed -n '/^# Generate QR codes for end user access/,/^# Display QR codes in terminal/p' "$DEPLOY_SCRIPT" | head -n -2)
    
    # Mock qrencode command to avoid dependency on actual qrencode installation
    # Create a mock qrencode that creates dummy files
    export PATH="$CONFIG_DIR/mock-bin:$PATH"
    mkdir -p "$CONFIG_DIR/mock-bin"
    
    cat > "$CONFIG_DIR/mock-bin/qrencode" << 'MOCK_EOF'
#!/bin/bash
# Mock qrencode for testing
output_file=""
output_type=""
input_data=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -o)
            output_file="$2"
            shift 2
            ;;
        -t)
            output_type="$2"
            shift 2
            ;;
        *)
            input_data="$1"
            shift
            ;;
    esac
done

if [ -n "$output_file" ]; then
    if [ "$output_type" = "PNG" ]; then
        # Create a dummy PNG file
        echo "PNG_MOCK_DATA_$input_data" > "$output_file"
    elif [ "$output_type" = "ASCII" ]; then
        # Create ASCII art QR code
        cat > "$output_file" << 'EOF'
█████████████████████████████████
█████████████████████████████████
████ ▄▄▄▄▄ █▀█ █▄▄▀▄█ ▄▄▄▄▄ ████
████ █   █ █▀▀▀█ ▀▄ █ █   █ ████
████ █▄▄▄█ █▀ █▀▀█▄▀█ █▄▄▄█ ████
████▄▄▄▄▄▄▄█▄▀ ▀▄█ █▄▄▄▄▄▄▄████
█████████████████████████████████
EOF
    fi
fi
exit 0
MOCK_EOF
    
    chmod +x "$CONFIG_DIR/mock-bin/qrencode"
    
    # Mock tailscale command
    cat > "$CONFIG_DIR/mock-bin/tailscale" << 'MOCK_EOF'
#!/bin/bash
# Mock tailscale for testing
if [ "$1" = "status" ]; then
    echo "test-hostname-$(date +%s)"
fi
exit 0
MOCK_EOF
    
    chmod +x "$CONFIG_DIR/mock-bin/tailscale"
}

teardown() {
    # Clean up test artifacts
    rm -rf "$CONFIG_DIR"
}

################################################################################
# Helper Functions
################################################################################

# Generate random URL for testing
generate_random_url() {
    local url_types=("https://example.com" "https://test.com" "https://app.example.com")
    local index=$((RANDOM % ${#url_types[@]}))
    echo "${url_types[$index]}/path-$RANDOM"
}

# Generate random QR code type
generate_random_qr_type() {
    local types=("tailscale-app" "service-access")
    local index=$((RANDOM % ${#types[@]}))
    echo "${types[$index]}"
}

# Verify QR code files exist
verify_qr_files_exist() {
    local qr_type=$1
    local png_file="$QR_CODE_DIR/${qr_type}.png"
    local txt_file="$QR_CODE_DIR/${qr_type}.txt"
    
    # Check PNG file exists
    [ -f "$png_file" ] || return 1
    
    # Check ASCII file exists
    [ -f "$txt_file" ] || return 1
    
    return 0
}

# Verify QR code directory has correct permissions
verify_qr_directory_permissions() {
    [ -d "$QR_CODE_DIR" ] || return 1
    
    # Check directory permissions (should be 700)
    local perms=$(stat -c "%a" "$QR_CODE_DIR" 2>/dev/null || stat -f "%Lp" "$QR_CODE_DIR" 2>/dev/null)
    [ "$perms" = "700" ] || return 1
    
    return 0
}

################################################################################
# Property Tests
################################################################################

@test "Property 4: Generated QR codes are saved as PNG files" {
    # Test that QR code generation creates PNG files
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        # Clean QR code directory for each iteration
        rm -rf "$QR_CODE_DIR"
        mkdir -p "$CONFIG_DIR"
        
        # Generate QR codes
        run generate_qr_codes
        
        # Verify both PNG files exist
        [ -f "$QR_CODE_DIR/tailscale-app.png" ] || {
            echo "Iteration $i: tailscale-app.png not created"
            return 1
        }
        
        [ -f "$QR_CODE_DIR/service-access.png" ] || {
            echo "Iteration $i: service-access.png not created"
            return 1
        }
    done
}

@test "Property 4: Generated QR codes are saved as ASCII text files" {
    # Test that QR code generation creates ASCII text files
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        # Clean QR code directory for each iteration
        rm -rf "$QR_CODE_DIR"
        mkdir -p "$CONFIG_DIR"
        
        # Generate QR codes
        run generate_qr_codes
        
        # Verify both ASCII files exist
        [ -f "$QR_CODE_DIR/tailscale-app.txt" ] || {
            echo "Iteration $i: tailscale-app.txt not created"
            return 1
        }
        
        [ -f "$QR_CODE_DIR/service-access.txt" ] || {
            echo "Iteration $i: service-access.txt not created"
            return 1
        }
    done
}

@test "Property 4: QR code files have correct filenames corresponding to their type" {
    # Test that QR code files are named according to their type
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        # Clean QR code directory
        rm -rf "$QR_CODE_DIR"
        mkdir -p "$CONFIG_DIR"
        
        # Generate QR codes
        generate_qr_codes >/dev/null 2>&1
        
        # Verify Tailscale app QR code has correct filename
        run verify_qr_files_exist "tailscale-app"
        assert_success "Iteration $i: Tailscale app QR code files not found with correct names"
        
        # Verify service access QR code has correct filename
        run verify_qr_files_exist "service-access"
        assert_success "Iteration $i: Service access QR code files not found with correct names"
    done
}

@test "Property 4: QR code directory is created if it doesn't exist" {
    # Test that QR code generation creates the directory
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        # Remove QR code directory
        rm -rf "$QR_CODE_DIR"
        
        # Verify it doesn't exist
        [ ! -d "$QR_CODE_DIR" ] || {
            echo "Iteration $i: QR code directory should not exist before generation"
            return 1
        }
        
        # Generate QR codes
        generate_qr_codes >/dev/null 2>&1
        
        # Verify directory was created
        [ -d "$QR_CODE_DIR" ] || {
            echo "Iteration $i: QR code directory was not created"
            return 1
        }
    done
}

@test "Property 4: QR code directory has secure permissions (700)" {
    # Test that QR code directory has correct permissions
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        # Clean QR code directory
        rm -rf "$QR_CODE_DIR"
        mkdir -p "$CONFIG_DIR"
        
        # Generate QR codes
        generate_qr_codes >/dev/null 2>&1
        
        # Verify directory permissions
        run verify_qr_directory_permissions
        assert_success "Iteration $i: QR code directory does not have 700 permissions"
    done
}

@test "Property 4: QR code files persist after generation" {
    # Test that QR code files remain accessible after generation
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        # Clean QR code directory
        rm -rf "$QR_CODE_DIR"
        mkdir -p "$CONFIG_DIR"
        
        # Generate QR codes
        generate_qr_codes >/dev/null 2>&1
        
        # Verify files exist immediately after generation
        [ -f "$QR_CODE_DIR/tailscale-app.png" ] || {
            echo "Iteration $i: tailscale-app.png not found after generation"
            return 1
        }
        
        [ -f "$QR_CODE_DIR/service-access.png" ] || {
            echo "Iteration $i: service-access.png not found after generation"
            return 1
        }
        
        # Simulate some time passing (file system operations)
        sleep 0.01
        
        # Verify files still exist
        [ -f "$QR_CODE_DIR/tailscale-app.png" ] || {
            echo "Iteration $i: tailscale-app.png not persisted"
            return 1
        }
        
        [ -f "$QR_CODE_DIR/service-access.png" ] || {
            echo "Iteration $i: service-access.png not persisted"
            return 1
        }
    done
}

@test "Property 4: QR code PNG files contain data" {
    # Test that generated PNG files are not empty
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        # Clean QR code directory
        rm -rf "$QR_CODE_DIR"
        mkdir -p "$CONFIG_DIR"
        
        # Generate QR codes
        generate_qr_codes >/dev/null 2>&1
        
        # Verify PNG files are not empty
        [ -s "$QR_CODE_DIR/tailscale-app.png" ] || {
            echo "Iteration $i: tailscale-app.png is empty"
            return 1
        }
        
        [ -s "$QR_CODE_DIR/service-access.png" ] || {
            echo "Iteration $i: service-access.png is empty"
            return 1
        }
    done
}

@test "Property 4: QR code ASCII files contain data" {
    # Test that generated ASCII files are not empty
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        # Clean QR code directory
        rm -rf "$QR_CODE_DIR"
        mkdir -p "$CONFIG_DIR"
        
        # Generate QR codes
        generate_qr_codes >/dev/null 2>&1
        
        # Verify ASCII files are not empty
        [ -s "$QR_CODE_DIR/tailscale-app.txt" ] || {
            echo "Iteration $i: tailscale-app.txt is empty"
            return 1
        }
        
        [ -s "$QR_CODE_DIR/service-access.txt" ] || {
            echo "Iteration $i: service-access.txt is empty"
            return 1
        }
    done
}

@test "Property 4: Multiple QR code generation calls don't corrupt existing files" {
    # Test that regenerating QR codes doesn't corrupt the files
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        # Clean QR code directory
        rm -rf "$QR_CODE_DIR"
        mkdir -p "$CONFIG_DIR"
        
        # Generate QR codes first time
        generate_qr_codes >/dev/null 2>&1
        
        # Get file sizes after first generation
        local size1_png=$(stat -c "%s" "$QR_CODE_DIR/tailscale-app.png" 2>/dev/null || stat -f "%z" "$QR_CODE_DIR/tailscale-app.png" 2>/dev/null)
        local size1_txt=$(stat -c "%s" "$QR_CODE_DIR/tailscale-app.txt" 2>/dev/null || stat -f "%z" "$QR_CODE_DIR/tailscale-app.txt" 2>/dev/null)
        
        # Generate QR codes second time
        generate_qr_codes >/dev/null 2>&1
        
        # Get file sizes after second generation
        local size2_png=$(stat -c "%s" "$QR_CODE_DIR/tailscale-app.png" 2>/dev/null || stat -f "%z" "$QR_CODE_DIR/tailscale-app.png" 2>/dev/null)
        local size2_txt=$(stat -c "%s" "$QR_CODE_DIR/tailscale-app.txt" 2>/dev/null || stat -f "%z" "$QR_CODE_DIR/tailscale-app.txt" 2>/dev/null)
        
        # Verify files still exist and have reasonable sizes
        [ -n "$size2_png" ] && [ "$size2_png" -gt 0 ] || {
            echo "Iteration $i: PNG file corrupted after regeneration"
            return 1
        }
        
        [ -n "$size2_txt" ] && [ "$size2_txt" -gt 0 ] || {
            echo "Iteration $i: ASCII file corrupted after regeneration"
            return 1
        }
    done
}

@test "Property 4: QR code files are accessible for reading" {
    # Test that generated QR code files can be read
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        # Clean QR code directory
        rm -rf "$QR_CODE_DIR"
        mkdir -p "$CONFIG_DIR"
        
        # Generate QR codes
        generate_qr_codes >/dev/null 2>&1
        
        # Try to read PNG files
        run cat "$QR_CODE_DIR/tailscale-app.png"
        assert_success "Iteration $i: Cannot read tailscale-app.png"
        
        run cat "$QR_CODE_DIR/service-access.png"
        assert_success "Iteration $i: Cannot read service-access.png"
        
        # Try to read ASCII files
        run cat "$QR_CODE_DIR/tailscale-app.txt"
        assert_success "Iteration $i: Cannot read tailscale-app.txt"
        
        run cat "$QR_CODE_DIR/service-access.txt"
        assert_success "Iteration $i: Cannot read service-access.txt"
    done
}

@test "Property 4: QR code generation logs file creation" {
    # Test that QR code file creation is logged
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        # Clean QR code directory and log
        rm -rf "$QR_CODE_DIR"
        rm -f "$LOG_FILE"
        mkdir -p "$CONFIG_DIR"
        
        # Initialize logging
        init_logging
        
        # Generate QR codes
        generate_qr_codes >/dev/null 2>&1
        
        # Verify logging occurred
        [ -f "$LOG_FILE" ] || {
            echo "Iteration $i: Log file not created"
            return 1
        }
        
        # Verify QR code generation was logged
        grep -q "generate_qr_codes" "$LOG_FILE" || {
            echo "Iteration $i: QR code generation not logged"
            return 1
        }
    done
}

@test "Property 4: Both QR code types are always generated together" {
    # Test that both Tailscale app and service access QR codes are created
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        # Clean QR code directory
        rm -rf "$QR_CODE_DIR"
        mkdir -p "$CONFIG_DIR"
        
        # Generate QR codes
        generate_qr_codes >/dev/null 2>&1
        
        # Count PNG files
        local png_count=$(find "$QR_CODE_DIR" -name "*.png" -type f | wc -l)
        [ "$png_count" -eq 2 ] || {
            echo "Iteration $i: Expected 2 PNG files, found $png_count"
            return 1
        }
        
        # Count ASCII files
        local txt_count=$(find "$QR_CODE_DIR" -name "*.txt" -type f | wc -l)
        [ "$txt_count" -eq 2 ] || {
            echo "Iteration $i: Expected 2 ASCII files, found $txt_count"
            return 1
        }
    done
}
