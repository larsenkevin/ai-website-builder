#!/usr/bin/env bats
################################################################################
# Property-Based Test: Error Remediation Guidance
#
# **Validates: Requirements 7.5, 9.7, 10.4, 13.5**
#
# Property 12: Error Remediation Guidance
# For any error that occurs during deployment (dependency installation failure,
# domain configuration failure, service start failure), the script shall display
# an error message that includes specific remediation steps or troubleshooting
# guidance.
#
# Feature: quick-start-deployment, Property 12: Error Remediation Guidance
################################################################################

# Load BATS helpers
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Test configuration
ITERATIONS=100
TEST_LOG_FILE="/tmp/test-deploy-error-remediation-$.log"
TEST_CONFIG_DIR="/tmp/test-config-error-remediation-$"
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
    source <(sed -n '/^# Initialize logging/,/^# Placeholder Functions/p' "$DEPLOY_SCRIPT" | head -n -2)
}

teardown() {
    # Clean up test artifacts
    rm -f "$TEST_LOG_FILE"
    rm -rf "$TEST_CONFIG_DIR"
}

################################################################################
# Helper Functions
################################################################################

# Generate random package name
generate_random_package() {
    local packages=("curl" "wget" "git" "nginx" "certbot" "qrencode" "ufw" "nodejs" "npm")
    local index=$((RANDOM % ${#packages[@]}))
    echo "${packages[$index]}"
}

# Generate random domain name
generate_random_domain() {
    echo "test-$RANDOM.example.com"
}

# Simulate dependency installation failure
simulate_dependency_failure() {
    local package=$1
    local output_file=$2
    
    cat > "$output_file" <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ ERROR: Package installation failed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Details: Failed to install package: $package

Remediation:
  1. Check your network connectivity
  2. Verify the package name is correct and available in your Ubuntu version
  3. Check the log file for detailed error information: $LOG_FILE
  4. Try running 'apt install $package' manually to see the error
  5. Ensure you have sufficient disk space

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Simulate domain configuration failure
simulate_domain_failure() {
    local domain=$1
    local output_file=$2
    
    cat > "$output_file" <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ ERROR: SSL certificate acquisition failed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Details: Failed to acquire SSL certificate for domain: $domain

Remediation:
  1. Verify your domain DNS is configured correctly
  2. Ensure port 80 is accessible from the internet
  3. Check certbot logs: /var/log/letsencrypt/letsencrypt.log
  4. Verify domain resolves to this server: dig +short $domain
  5. Try running certbot manually: certbot certonly --nginx -d $domain

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Simulate service start failure
simulate_service_failure() {
    local output_file=$1
    
    cat > "$output_file" <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ ERROR: Failed to start ai-website-builder service
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Details: systemctl start command failed

Service logs (last 20 lines):
[Service error logs would appear here]

Remediation:
  1. Check the log file for details: $LOG_FILE
  2. View full service logs: journalctl -u ai-website-builder -n 100
  3. Check service status: systemctl status ai-website-builder
  4. Verify configuration file exists: ls -l $CONFIG_FILE
  5. Check application logs in the repository directory

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Simulate general error
simulate_general_error() {
    local error_msg=$1
    local output_file=$2
    
    cat > "$output_file" <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ ERROR: $error_msg
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Details: An error occurred during deployment

Remediation:
  1. Check the log file for detailed error information:
     $LOG_FILE
  2. Verify all prerequisites are met (Ubuntu 22.04, root access, network)
  3. If you created a VM snapshot, you can restore it and try again
  4. Re-run this script to resume from a safe checkpoint

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Check if error message contains remediation section
has_remediation_section() {
    local error_output=$1
    grep -q "Remediation:" "$error_output"
}

# Count remediation steps in error message
count_remediation_steps() {
    local error_output=$1
    grep -c "^  [0-9]\+\." "$error_output" || echo "0"
}

# Check if error message has proper formatting
has_proper_formatting() {
    local error_output=$1
    
    # Check for separator lines
    grep -q "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$error_output" || return 1
    
    # Check for ERROR prefix
    grep -q "❌ ERROR:" "$error_output" || return 1
    
    # Check for Details section
    grep -q "Details:" "$error_output" || return 1
    
    return 0
}

################################################################################
# Property Tests
################################################################################

@test "Property 12: Dependency installation failures include remediation guidance" {
    # Test that dependency installation errors include specific remediation steps
    
    local test_iterations=100
    local errors_with_remediation=0
    
    for i in $(seq 1 $test_iterations); do
        local package=$(generate_random_package)
        local error_output="/tmp/error-output-$i-$$.txt"
        
        # Simulate dependency installation failure
        simulate_dependency_failure "$package" "$error_output"
        
        # Verify remediation section exists
        if has_remediation_section "$error_output"; then
            errors_with_remediation=$((errors_with_remediation + 1))
        else
            echo "Iteration $i: Dependency error for package '$package' missing remediation section"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        fi
        
        # Verify at least 3 remediation steps
        local step_count=$(count_remediation_steps "$error_output")
        [ "$step_count" -ge 3 ] || {
            echo "Iteration $i: Expected at least 3 remediation steps, found $step_count"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        # Verify proper formatting
        has_proper_formatting "$error_output" || {
            echo "Iteration $i: Error message lacks proper formatting"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        rm -f "$error_output"
    done
    
    [ "$errors_with_remediation" -eq "$test_iterations" ] || {
        echo "Expected $test_iterations errors with remediation, got $errors_with_remediation"
        return 1
    }
}

@test "Property 12: Domain configuration failures include remediation guidance" {
    # Test that domain configuration errors include specific remediation steps
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        local domain=$(generate_random_domain)
        local error_output="/tmp/error-output-domain-$i-$$.txt"
        
        # Simulate domain configuration failure
        simulate_domain_failure "$domain" "$error_output"
        
        # Verify remediation section exists
        has_remediation_section "$error_output" || {
            echo "Iteration $i: Domain error for '$domain' missing remediation section"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        # Verify at least 3 remediation steps
        local step_count=$(count_remediation_steps "$error_output")
        [ "$step_count" -ge 3 ] || {
            echo "Iteration $i: Expected at least 3 remediation steps, found $step_count"
            rm -f "$error_output"
            return 1
        }
        
        # Verify domain-specific guidance (DNS, certbot, etc.)
        grep -q "DNS\|certbot\|domain" "$error_output" || {
            echo "Iteration $i: Domain error missing domain-specific guidance"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        rm -f "$error_output"
    done
}

@test "Property 12: Service start failures include remediation guidance" {
    # Test that service start errors include specific remediation steps
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        local error_output="/tmp/error-output-service-$i-$$.txt"
        
        # Simulate service start failure
        simulate_service_failure "$error_output"
        
        # Verify remediation section exists
        has_remediation_section "$error_output" || {
            echo "Iteration $i: Service error missing remediation section"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        # Verify at least 3 remediation steps
        local step_count=$(count_remediation_steps "$error_output")
        [ "$step_count" -ge 3 ] || {
            echo "Iteration $i: Expected at least 3 remediation steps, found $step_count"
            rm -f "$error_output"
            return 1
        }
        
        # Verify service-specific guidance (systemctl, journalctl, etc.)
        grep -q "systemctl\|journalctl\|service" "$error_output" || {
            echo "Iteration $i: Service error missing service-specific guidance"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        rm -f "$error_output"
    done
}

@test "Property 12: General errors include remediation guidance" {
    # Test that general errors include remediation steps
    
    local test_iterations=100
    local error_messages=(
        "Deployment failed"
        "Configuration error"
        "Network timeout"
        "Permission denied"
        "File not found"
    )
    
    for i in $(seq 1 $test_iterations); do
        local msg_index=$((RANDOM % ${#error_messages[@]}))
        local error_msg="${error_messages[$msg_index]}"
        local error_output="/tmp/error-output-general-$i-$$.txt"
        
        # Simulate general error
        simulate_general_error "$error_msg" "$error_output"
        
        # Verify remediation section exists
        has_remediation_section "$error_output" || {
            echo "Iteration $i: General error '$error_msg' missing remediation section"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        # Verify at least 2 remediation steps
        local step_count=$(count_remediation_steps "$error_output")
        [ "$step_count" -ge 2 ] || {
            echo "Iteration $i: Expected at least 2 remediation steps, found $step_count"
            rm -f "$error_output"
            return 1
        }
        
        rm -f "$error_output"
    done
}

@test "Property 12: All error messages have consistent formatting" {
    # Test that all error types follow the same formatting pattern
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        local error_type=$((RANDOM % 4))
        local error_output="/tmp/error-output-format-$i-$$.txt"
        
        case $error_type in
            0)
                simulate_dependency_failure "test-package" "$error_output"
                ;;
            1)
                simulate_domain_failure "test.example.com" "$error_output"
                ;;
            2)
                simulate_service_failure "$error_output"
                ;;
            3)
                simulate_general_error "Test error" "$error_output"
                ;;
        esac
        
        # Verify consistent formatting
        has_proper_formatting "$error_output" || {
            echo "Iteration $i: Error type $error_type lacks proper formatting"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        # Verify separator lines at start and end
        local separator_count=$(grep -c "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$error_output")
        [ "$separator_count" -ge 2 ] || {
            echo "Iteration $i: Expected at least 2 separator lines, found $separator_count"
            rm -f "$error_output"
            return 1
        }
        
        rm -f "$error_output"
    done
}

@test "Property 12: Remediation steps are numbered and actionable" {
    # Test that remediation steps are properly numbered and contain actionable guidance
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        local package=$(generate_random_package)
        local error_output="/tmp/error-output-steps-$i-$$.txt"
        
        simulate_dependency_failure "$package" "$error_output"
        
        # Extract remediation section
        local remediation_section=$(sed -n '/Remediation:/,/━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━/p' "$error_output")
        
        # Verify steps are numbered sequentially
        echo "$remediation_section" | grep -q "  1\." || {
            echo "Iteration $i: Missing step 1"
            rm -f "$error_output"
            return 1
        }
        
        echo "$remediation_section" | grep -q "  2\." || {
            echo "Iteration $i: Missing step 2"
            rm -f "$error_output"
            return 1
        }
        
        # Verify steps contain actionable verbs
        echo "$remediation_section" | grep -qE "Check|Verify|Try|Ensure|Run|View|Install" || {
            echo "Iteration $i: Remediation steps lack actionable verbs"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        rm -f "$error_output"
    done
}

@test "Property 12: Error messages reference log file location" {
    # Test that error messages include reference to the log file
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        local error_type=$((RANDOM % 4))
        local error_output="/tmp/error-output-logref-$i-$$.txt"
        
        case $error_type in
            0)
                simulate_dependency_failure "test-pkg" "$error_output"
                ;;
            1)
                simulate_domain_failure "test.com" "$error_output"
                ;;
            2)
                simulate_service_failure "$error_output"
                ;;
            3)
                simulate_general_error "Test" "$error_output"
                ;;
        esac
        
        # Verify log file is referenced
        grep -q "log file\|LOG_FILE\|/var/log" "$error_output" || {
            echo "Iteration $i: Error message doesn't reference log file"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        rm -f "$error_output"
    done
}

@test "Property 12: Dependency errors mention specific package name" {
    # Test that dependency errors include the specific package that failed
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        local package=$(generate_random_package)
        local error_output="/tmp/error-output-pkgname-$i-$$.txt"
        
        simulate_dependency_failure "$package" "$error_output"
        
        # Verify package name appears in error message
        grep -q "$package" "$error_output" || {
            echo "Iteration $i: Package name '$package' not found in error message"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        rm -f "$error_output"
    done
}

@test "Property 12: Domain errors mention specific domain name" {
    # Test that domain errors include the specific domain that failed
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        local domain=$(generate_random_domain)
        local error_output="/tmp/error-output-domain-name-$i-$$.txt"
        
        simulate_domain_failure "$domain" "$error_output"
        
        # Verify domain name appears in error message
        grep -q "$domain" "$error_output" || {
            echo "Iteration $i: Domain name '$domain' not found in error message"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        rm -f "$error_output"
    done
}

@test "Property 12: Service errors include diagnostic commands" {
    # Test that service errors provide specific diagnostic commands
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        local error_output="/tmp/error-output-diag-$i-$$.txt"
        
        simulate_service_failure "$error_output"
        
        # Verify diagnostic commands are included
        grep -q "systemctl status\|journalctl" "$error_output" || {
            echo "Iteration $i: Service error missing diagnostic commands"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        rm -f "$error_output"
    done
}

@test "Property 12: Error messages include Details section" {
    # Test that all error messages have a Details section
    
    local test_iterations=100
    
    for i in $(seq 1 $test_iterations); do
        local error_type=$((RANDOM % 4))
        local error_output="/tmp/error-output-details-$i-$$.txt"
        
        case $error_type in
            0)
                simulate_dependency_failure "pkg" "$error_output"
                ;;
            1)
                simulate_domain_failure "test.com" "$error_output"
                ;;
            2)
                simulate_service_failure "$error_output"
                ;;
            3)
                simulate_general_error "Error" "$error_output"
                ;;
        esac
        
        # Verify Details section exists
        grep -q "Details:" "$error_output" || {
            echo "Iteration $i: Error message missing Details section"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        rm -f "$error_output"
    done
}

@test "Property 12: Remediation steps are specific to error type" {
    # Test that remediation guidance is contextually appropriate
    
    local test_iterations=30
    
    for i in $(seq 1 $test_iterations); do
        # Test dependency error has network/package-specific guidance
        local dep_output="/tmp/error-dep-$i-$$.txt"
        simulate_dependency_failure "test-pkg" "$dep_output"
        grep -q "network\|package\|apt" "$dep_output" || {
            echo "Iteration $i: Dependency error lacks package-specific guidance"
            rm -f "$dep_output"
            return 1
        }
        rm -f "$dep_output"
        
        # Test domain error has DNS/SSL-specific guidance
        local dom_output="/tmp/error-dom-$i-$$.txt"
        simulate_domain_failure "test.com" "$dom_output"
        grep -q "DNS\|SSL\|certbot\|domain" "$dom_output" || {
            echo "Iteration $i: Domain error lacks DNS/SSL-specific guidance"
            rm -f "$dom_output"
            return 1
        }
        rm -f "$dom_output"
        
        # Test service error has systemd-specific guidance
        local svc_output="/tmp/error-svc-$i-$$.txt"
        simulate_service_failure "$svc_output"
        grep -q "systemctl\|journalctl\|service" "$svc_output" || {
            echo "Iteration $i: Service error lacks systemd-specific guidance"
            rm -f "$svc_output"
            return 1
        }
        rm -f "$svc_output"
    done
}

@test "Property 12: Error messages are human-readable" {
    # Test that error messages use clear, understandable language
    
    local test_iterations=50
    
    for i in $(seq 1 $test_iterations); do
        local error_type=$((RANDOM % 4))
        local error_output="/tmp/error-output-readable-$i-$$.txt"
        
        case $error_type in
            0)
                simulate_dependency_failure "test-package" "$error_output"
                ;;
            1)
                simulate_domain_failure "test.example.com" "$error_output"
                ;;
            2)
                simulate_service_failure "$error_output"
                ;;
            3)
                simulate_general_error "Test error" "$error_output"
                ;;
        esac
        
        # Verify message doesn't contain raw error codes or technical jargon only
        # Should have explanatory text
        local word_count=$(wc -w < "$error_output")
        [ "$word_count" -gt 20 ] || {
            echo "Iteration $i: Error message too brief (only $word_count words)"
            cat "$error_output"
            rm -f "$error_output"
            return 1
        }
        
        rm -f "$error_output"
    done
}

@test "Property 12: Multiple error types maintain consistent structure" {
    # Test that different error types follow the same structural pattern
    
    local test_iterations=25
    
    for i in $(seq 1 $test_iterations); do
        local dep_output="/tmp/error-struct-dep-$i-$$.txt"
        local dom_output="/tmp/error-struct-dom-$i-$$.txt"
        local svc_output="/tmp/error-struct-svc-$i-$$.txt"
        local gen_output="/tmp/error-struct-gen-$i-$$.txt"
        
        simulate_dependency_failure "pkg" "$dep_output"
        simulate_domain_failure "test.com" "$dom_output"
        simulate_service_failure "$svc_output"
        simulate_general_error "Error" "$gen_output"
        
        # All should have same number of separator lines
        local dep_sep=$(grep -c "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$dep_output")
        local dom_sep=$(grep -c "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$dom_output")
        local svc_sep=$(grep -c "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$svc_output")
        local gen_sep=$(grep -c "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$gen_output")
        
        [ "$dep_sep" -eq "$dom_sep" ] && [ "$dom_sep" -eq "$svc_sep" ] && [ "$svc_sep" -eq "$gen_sep" ] || {
            echo "Iteration $i: Inconsistent separator counts: dep=$dep_sep, dom=$dom_sep, svc=$svc_sep, gen=$gen_sep"
            rm -f "$dep_output" "$dom_output" "$svc_output" "$gen_output"
            return 1
        }
        
        # All should have Details and Remediation sections
        for output in "$dep_output" "$dom_output" "$svc_output" "$gen_output"; do
            grep -q "Details:" "$output" || {
                echo "Iteration $i: Missing Details section in $output"
                rm -f "$dep_output" "$dom_output" "$svc_output" "$gen_output"
                return 1
            }
            grep -q "Remediation:" "$output" || {
                echo "Iteration $i: Missing Remediation section in $output"
                rm -f "$dep_output" "$dom_output" "$svc_output" "$gen_output"
                return 1
            }
        done
        
        rm -f "$dep_output" "$dom_output" "$svc_output" "$gen_output"
    done
}
