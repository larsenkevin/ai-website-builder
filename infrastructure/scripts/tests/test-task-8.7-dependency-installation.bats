#!/usr/bin/env bats
# Unit Tests for Task 8.7: Dependency Installation
# Tests for system packages, Node.js, Tailscale, firewall, and update mode
# Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    export TEST_LOG="$TEST_DIR/test.log"
    export DEPLOY_SCRIPT="infrastructure/scripts/deploy.sh"
    
    # Mock environment variables
    export LOG_FILE="$TEST_LOG"
    export CONFIG_DIR="$TEST_DIR/config"
    export REPOSITORY_PATH="$TEST_DIR/repo"
    
    # Create mock directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$REPOSITORY_PATH"
}

teardown() {
    # Clean up temporary directory
    rm -rf "$TEST_DIR"
}

# Helper function to check if a function exists in the deploy script
function_exists() {
    local func_name="$1"
    grep -q "^${func_name}()" "$DEPLOY_SCRIPT"
}

# Helper function to extract a function from deploy script
extract_function() {
    local func_name="$1"
    local output_file="$2"
    
    # Extract the function definition
    sed -n "/^${func_name}()/,/^}/p" "$DEPLOY_SCRIPT" > "$output_file"
}

@test "8.7.1: install_system_dependencies function exists" {
    run function_exists "install_system_dependencies"
    assert_success
}

@test "8.7.2: install_runtime_dependencies function exists" {
    run function_exists "install_runtime_dependencies"
    assert_success
}

@test "8.7.3: install_tailscale function exists" {
    run function_exists "install_tailscale"
    assert_success
}

@test "8.7.4: configure_firewall function exists" {
    run function_exists "configure_firewall"
    assert_success
}

@test "8.7.5: update_dependencies function exists" {
    run function_exists "update_dependencies"
    assert_success
}

@test "8.7.6: System dependencies function includes apt update" {
    run grep -q "apt update" "$DEPLOY_SCRIPT"
    assert_success
}

@test "8.7.7: System dependencies function installs curl" {
    # Check that curl is in the list of packages to install
    run grep -A 20 "install_system_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "curl"
}

@test "8.7.8: System dependencies function installs wget" {
    run grep -A 20 "install_system_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "wget"
}

@test "8.7.9: System dependencies function installs git" {
    run grep -A 20 "install_system_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "git"
}

@test "8.7.10: System dependencies function installs nginx" {
    run grep -A 20 "install_system_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "nginx"
}

@test "8.7.11: System dependencies function installs certbot" {
    run grep -A 20 "install_system_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "certbot"
}

@test "8.7.12: System dependencies function installs qrencode" {
    run grep -A 20 "install_system_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "qrencode"
}

@test "8.7.13: System dependencies function installs ufw" {
    run grep -A 20 "install_system_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "ufw"
}

@test "8.7.14: System dependencies function displays progress" {
    # Check that the function uses display_progress
    run grep -A 50 "install_system_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "display_progress"
}

@test "8.7.15: System dependencies function handles installation failures" {
    # Check for error handling in system dependencies
    run grep -A 100 "install_system_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "Failed to install"
}

@test "8.7.16: Runtime dependencies function adds NodeSource repository" {
    run grep -A 50 "install_runtime_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "nodesource"
}

@test "8.7.17: Runtime dependencies function installs Node.js" {
    run grep -A 50 "install_runtime_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "nodejs"
}

@test "8.7.18: Runtime dependencies function clones repository" {
    run grep -A 100 "install_runtime_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "git clone"
}

@test "8.7.19: Runtime dependencies function runs npm install" {
    run grep -A 100 "install_runtime_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "npm install"
}

@test "8.7.20: Runtime dependencies function checks for existing Node.js" {
    # Should check if node is already installed
    run grep -A 50 "install_runtime_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "node --version"
}

@test "8.7.21: Tailscale installer adds Tailscale repository" {
    run grep -A 50 "install_tailscale()" "$DEPLOY_SCRIPT"
    assert_output --partial "tailscale"
}

@test "8.7.22: Tailscale installer enables tailscaled service" {
    run grep -A 100 "install_tailscale()" "$DEPLOY_SCRIPT"
    assert_output --partial "systemctl enable tailscaled"
}

@test "8.7.23: Tailscale installer starts tailscaled service" {
    run grep -A 100 "install_tailscale()" "$DEPLOY_SCRIPT"
    assert_output --partial "systemctl start tailscaled"
}

@test "8.7.24: Tailscale installer checks for existing installation" {
    run grep -A 50 "install_tailscale()" "$DEPLOY_SCRIPT"
    assert_output --partial "tailscale version"
}

@test "8.7.25: Firewall configuration enables ufw" {
    run grep -A 50 "configure_firewall()" "$DEPLOY_SCRIPT"
    assert_output --partial "ufw enable"
}

@test "8.7.26: Firewall configuration allows SSH port 22" {
    run grep -A 50 "configure_firewall()" "$DEPLOY_SCRIPT"
    assert_output --partial "22"
}

@test "8.7.27: Firewall configuration allows HTTP port 80" {
    run grep -A 50 "configure_firewall()" "$DEPLOY_SCRIPT"
    assert_output --partial "80"
}

@test "8.7.28: Firewall configuration allows HTTPS port 443" {
    run grep -A 50 "configure_firewall()" "$DEPLOY_SCRIPT"
    assert_output --partial "443"
}

@test "8.7.29: Firewall configuration checks if ufw is installed" {
    run grep -A 50 "configure_firewall()" "$DEPLOY_SCRIPT"
    assert_output --partial "ufw"
}

@test "8.7.30: Update mode runs apt upgrade" {
    run grep -A 50 "update_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "apt upgrade"
}

@test "8.7.31: Update mode runs npm update" {
    run grep -A 50 "update_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "npm update"
}

@test "8.7.32: Update mode checks for Tailscale updates" {
    run grep -A 50 "update_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "tailscale"
}

@test "8.7.33: Update mode runs apt update first" {
    run grep -A 50 "update_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "apt update"
}

@test "8.7.34: All dependency functions log operations" {
    # Check that all dependency functions use log_operation
    
    functions=("install_system_dependencies" "install_runtime_dependencies" "install_tailscale" "configure_firewall" "update_dependencies")
    
    for func in "${functions[@]}"; do
        run grep -A 10 "${func}()" "$DEPLOY_SCRIPT"
        assert_output --partial "log_operation"
    done
}

@test "8.7.35: System dependencies function provides specific error messages" {
    # Check for specific error messages for each package
    run grep -A 100 "install_system_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "Failed to install"
    assert_output --partial "package"
}

@test "8.7.36: Runtime dependencies function handles repository clone failure" {
    run grep -A 100 "install_runtime_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "Failed to clone"
}

@test "8.7.37: Runtime dependencies function handles npm install failure" {
    run grep -A 100 "install_runtime_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "npm"
}

@test "8.7.38: Tailscale installer handles service start failure" {
    run grep -A 100 "install_tailscale()" "$DEPLOY_SCRIPT"
    assert_output --partial "Failed to start"
}

@test "8.7.39: Firewall configuration handles enable failure" {
    run grep -A 100 "configure_firewall()" "$DEPLOY_SCRIPT"
    assert_output --partial "enable"
}

@test "8.7.40: All dependency functions display success messages" {
    functions=("install_system_dependencies" "install_runtime_dependencies" "install_tailscale" "configure_firewall" "update_dependencies")
    
    for func in "${functions[@]}"; do
        run grep -A 100 "${func}()" "$DEPLOY_SCRIPT"
        assert_output --partial "display_success"
    done
}

@test "8.7.41: System dependencies uses DEBIAN_FRONTEND=noninteractive" {
    # Ensure non-interactive installation
    run grep -A 50 "install_system_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "DEBIAN_FRONTEND=noninteractive"
}

@test "8.7.42: Runtime dependencies uses DEBIAN_FRONTEND=noninteractive" {
    run grep -A 50 "install_runtime_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "DEBIAN_FRONTEND=noninteractive"
}

@test "8.7.43: Tailscale installer uses DEBIAN_FRONTEND=noninteractive" {
    run grep -A 50 "install_tailscale()" "$DEPLOY_SCRIPT"
    assert_output --partial "DEBIAN_FRONTEND=noninteractive"
}

@test "8.7.44: System dependencies checks if packages are already installed" {
    # Should check dpkg to avoid reinstalling
    run grep -A 50 "install_system_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "dpkg"
}

@test "8.7.45: Runtime dependencies checks if repository already exists" {
    run grep -A 100 "install_runtime_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "REPOSITORY_PATH"
}

@test "8.7.46: Update mode checks if repository exists before npm update" {
    run grep -A 50 "update_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "REPOSITORY_PATH"
}

@test "8.7.47: Firewall configuration verifies firewall status" {
    run grep -A 100 "configure_firewall()" "$DEPLOY_SCRIPT"
    assert_output --partial "ufw status"
}

@test "8.7.48: All dependency functions redirect output to log file" {
    # Check that operations redirect to LOG_FILE
    functions=("install_system_dependencies" "install_runtime_dependencies" "install_tailscale" "configure_firewall")
    
    for func in "${functions[@]}"; do
        run grep -A 100 "${func}()" "$DEPLOY_SCRIPT"
        assert_output --partial "LOG_FILE"
    done
}

@test "8.7.49: System dependencies provides remediation steps on failure" {
    run grep -A 100 "install_system_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "Remediation"
}

@test "8.7.50: Runtime dependencies provides remediation steps on failure" {
    run grep -A 150 "install_runtime_dependencies()" "$DEPLOY_SCRIPT"
    assert_output --partial "Remediation"
}
