#!/bin/bash
################################################################################
# Simple Test Script for Tasks 8.1-8.7: Dependency Installation
#
# This script performs basic validation of the dependency installation functions
# without requiring a full Ubuntu environment or actual package installation.
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/../deploy.sh"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
test_result() {
    local test_name="$1"
    local result="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "=================================="
echo "Tasks 8.1-8.7: Dependency Installation Tests"
echo "=================================="
echo ""

# Test 1: Check if deploy.sh exists
if [ -f "$DEPLOY_SCRIPT" ]; then
    test_result "Deploy script exists" "PASS"
else
    test_result "Deploy script exists" "FAIL"
    echo "ERROR: Deploy script not found at $DEPLOY_SCRIPT"
    exit 1
fi

# Test 2: Check if install_system_dependencies function exists
if grep -q "^install_system_dependencies()" "$DEPLOY_SCRIPT"; then
    test_result "install_system_dependencies function exists" "PASS"
else
    test_result "install_system_dependencies function exists" "FAIL"
fi

# Test 3: Check if install_runtime_dependencies function exists
if grep -q "^install_runtime_dependencies()" "$DEPLOY_SCRIPT"; then
    test_result "install_runtime_dependencies function exists" "PASS"
else
    test_result "install_runtime_dependencies function exists" "FAIL"
fi

# Test 4: Check if install_tailscale function exists
if grep -q "^install_tailscale()" "$DEPLOY_SCRIPT"; then
    test_result "install_tailscale function exists" "PASS"
else
    test_result "install_tailscale function exists" "FAIL"
fi

# Test 5: Check if configure_firewall function exists
if grep -q "^configure_firewall()" "$DEPLOY_SCRIPT"; then
    test_result "configure_firewall function exists" "PASS"
else
    test_result "configure_firewall function exists" "FAIL"
fi

# Test 6: Check if update_dependencies function exists
if grep -q "^update_dependencies()" "$DEPLOY_SCRIPT"; then
    test_result "update_dependencies function exists" "PASS"
else
    test_result "update_dependencies function exists" "FAIL"
fi

# Test 7: Verify system packages are listed
packages=("curl" "wget" "git" "nginx" "certbot" "qrencode" "ufw")
all_packages_found=true

for package in "${packages[@]}"; do
    if ! grep -A 30 "install_system_dependencies()" "$DEPLOY_SCRIPT" | grep -q "\"$package\""; then
        all_packages_found=false
        echo "  Missing package: $package"
    fi
done

if [ "$all_packages_found" = true ]; then
    test_result "All required system packages listed" "PASS"
else
    test_result "All required system packages listed" "FAIL"
fi

# Test 8: Verify apt update is called
if grep -A 20 "install_system_dependencies()" "$DEPLOY_SCRIPT" | grep -q "apt update"; then
    test_result "System dependencies runs apt update" "PASS"
else
    test_result "System dependencies runs apt update" "FAIL"
fi

# Test 9: Verify NodeSource repository is added
if grep -A 50 "install_runtime_dependencies()" "$DEPLOY_SCRIPT" | grep -q "nodesource"; then
    test_result "Runtime dependencies adds NodeSource repository" "PASS"
else
    test_result "Runtime dependencies adds NodeSource repository" "FAIL"
fi

# Test 10: Verify Node.js installation
if grep -A 50 "install_runtime_dependencies()" "$DEPLOY_SCRIPT" | grep -q "nodejs"; then
    test_result "Runtime dependencies installs Node.js" "PASS"
else
    test_result "Runtime dependencies installs Node.js" "FAIL"
fi

# Test 11: Verify repository cloning
if grep -A 100 "install_runtime_dependencies()" "$DEPLOY_SCRIPT" | grep -q "git clone"; then
    test_result "Runtime dependencies clones repository" "PASS"
else
    test_result "Runtime dependencies clones repository" "FAIL"
fi

# Test 12: Verify npm install
if grep -A 100 "install_runtime_dependencies()" "$DEPLOY_SCRIPT" | grep -q "npm install"; then
    test_result "Runtime dependencies runs npm install" "PASS"
else
    test_result "Runtime dependencies runs npm install" "FAIL"
fi

# Test 13: Verify Tailscale repository addition
if grep -A 50 "install_tailscale()" "$DEPLOY_SCRIPT" | grep -q "tailscale"; then
    test_result "Tailscale installer adds repository" "PASS"
else
    test_result "Tailscale installer adds repository" "FAIL"
fi

# Test 14: Verify tailscaled service is enabled
if grep -A 100 "install_tailscale()" "$DEPLOY_SCRIPT" | grep -q "systemctl enable tailscaled"; then
    test_result "Tailscale installer enables service" "PASS"
else
    test_result "Tailscale installer enables service" "FAIL"
fi

# Test 15: Verify tailscaled service is started
if grep -A 100 "install_tailscale()" "$DEPLOY_SCRIPT" | grep -q "systemctl start tailscaled"; then
    test_result "Tailscale installer starts service" "PASS"
else
    test_result "Tailscale installer starts service" "FAIL"
fi

# Test 16: Verify firewall allows SSH (port 22)
if grep -A 50 "configure_firewall()" "$DEPLOY_SCRIPT" | grep -q "22"; then
    test_result "Firewall allows SSH (port 22)" "PASS"
else
    test_result "Firewall allows SSH (port 22)" "FAIL"
fi

# Test 17: Verify firewall allows HTTP (port 80)
if grep -A 50 "configure_firewall()" "$DEPLOY_SCRIPT" | grep -q "80"; then
    test_result "Firewall allows HTTP (port 80)" "PASS"
else
    test_result "Firewall allows HTTP (port 80)" "FAIL"
fi

# Test 18: Verify firewall allows HTTPS (port 443)
if grep -A 50 "configure_firewall()" "$DEPLOY_SCRIPT" | grep -q "443"; then
    test_result "Firewall allows HTTPS (port 443)" "PASS"
else
    test_result "Firewall allows HTTPS (port 443)" "FAIL"
fi

# Test 19: Verify firewall is enabled
if grep -A 50 "configure_firewall()" "$DEPLOY_SCRIPT" | grep -q "ufw enable"; then
    test_result "Firewall is enabled" "PASS"
else
    test_result "Firewall is enabled" "FAIL"
fi

# Test 20: Verify update mode runs apt upgrade
if grep -A 50 "update_dependencies()" "$DEPLOY_SCRIPT" | grep -q "apt upgrade"; then
    test_result "Update mode runs apt upgrade" "PASS"
else
    test_result "Update mode runs apt upgrade" "FAIL"
fi

# Test 21: Verify update mode runs npm update
if grep -A 50 "update_dependencies()" "$DEPLOY_SCRIPT" | grep -q "npm update"; then
    test_result "Update mode runs npm update" "PASS"
else
    test_result "Update mode runs npm update" "FAIL"
fi

# Test 22: Verify update mode checks Tailscale updates
if grep -A 50 "update_dependencies()" "$DEPLOY_SCRIPT" | grep -q "tailscale"; then
    test_result "Update mode checks Tailscale updates" "PASS"
else
    test_result "Update mode checks Tailscale updates" "FAIL"
fi

# Test 23: Verify progress indication in system dependencies
if grep -A 50 "install_system_dependencies()" "$DEPLOY_SCRIPT" | grep -q "display_progress"; then
    test_result "System dependencies displays progress" "PASS"
else
    test_result "System dependencies displays progress" "FAIL"
fi

# Test 24: Verify error handling in system dependencies
if grep -A 100 "install_system_dependencies()" "$DEPLOY_SCRIPT" | grep -q "Failed to install"; then
    test_result "System dependencies handles errors" "PASS"
else
    test_result "System dependencies handles errors" "FAIL"
fi

# Test 25: Verify non-interactive installation
if grep -A 50 "install_system_dependencies()" "$DEPLOY_SCRIPT" | grep -q "DEBIAN_FRONTEND=noninteractive"; then
    test_result "System dependencies uses non-interactive mode" "PASS"
else
    test_result "System dependencies uses non-interactive mode" "FAIL"
fi

# Test 26: Verify logging in all functions
functions=("install_system_dependencies" "install_runtime_dependencies" "install_tailscale" "configure_firewall" "update_dependencies")
all_functions_log=true

for func in "${functions[@]}"; do
    if ! grep -A 10 "${func}()" "$DEPLOY_SCRIPT" | grep -q "log_operation"; then
        all_functions_log=false
        echo "  Function $func does not log operations"
    fi
done

if [ "$all_functions_log" = true ]; then
    test_result "All dependency functions log operations" "PASS"
else
    test_result "All dependency functions log operations" "FAIL"
fi

# Test 27: Verify main function calls dependency installation in fresh mode
if grep -A 200 "main()" "$DEPLOY_SCRIPT" | grep -A 10 "MODE.*fresh" | grep -q "install_system_dependencies"; then
    test_result "Main function calls install_system_dependencies in fresh mode" "PASS"
else
    test_result "Main function calls install_system_dependencies in fresh mode" "FAIL"
fi

# Test 28: Verify main function calls update_dependencies in update mode
if grep -A 200 "main()" "$DEPLOY_SCRIPT" | grep -A 10 "MODE.*update" | grep -q "update_dependencies"; then
    test_result "Main function calls update_dependencies in update mode" "PASS"
else
    test_result "Main function calls update_dependencies in update mode" "FAIL"
fi

echo ""
echo "=================================="
echo "Test Summary"
echo "=================================="
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
else
    echo -e "${GREEN}Tests failed: $TESTS_FAILED${NC}"
fi
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
