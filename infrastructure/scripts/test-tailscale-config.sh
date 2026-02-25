#!/bin/bash

################################################################################
# Tailscale VPN Configuration Test Script
#
# This script validates the Tailscale VPN configuration for the AI Website Builder.
# It verifies Requirements 2.3 and 2.5 are properly implemented.
#
# Requirements Tested:
# - 2.3: Builder Interface SHALL be accessible only through Tailscale VPN
# - 2.5: System SHALL deny access to Builder Interface without Tailscale
#
# Usage:
#   sudo ./test-tailscale-config.sh
#
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BUILDER_PORT=3000
TAILSCALE_PORT=41641

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

################################################################################
# Helper Functions
################################################################################

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[ERROR]${NC} This script must be run as root (use sudo)"
        exit 1
    fi
}

################################################################################
# Test Functions
################################################################################

test_tailscale_installed() {
    log_test "Checking if Tailscale is installed..."
    
    if command -v tailscale &> /dev/null; then
        log_pass "Tailscale is installed"
        return 0
    else
        log_fail "Tailscale is not installed"
        return 1
    fi
}

test_tailscale_running() {
    log_test "Checking if Tailscale is running..."
    
    if systemctl is-active --quiet tailscaled; then
        log_pass "Tailscale service is running"
        return 0
    else
        log_fail "Tailscale service is not running"
        return 1
    fi
}

test_tailscale_authenticated() {
    log_test "Checking if Tailscale is authenticated..."
    
    if tailscale status &> /dev/null; then
        local status=$(tailscale status 2>&1)
        if echo "$status" | grep -q "Logged out"; then
            log_fail "Tailscale is not authenticated"
            return 1
        else
            log_pass "Tailscale is authenticated"
            return 0
        fi
    else
        log_fail "Cannot check Tailscale authentication status"
        return 1
    fi
}

test_tailscale_ip_assigned() {
    log_test "Checking if Tailscale IP is assigned..."
    
    local tailscale_ip=$(tailscale ip -4 2>/dev/null || echo "")
    
    if [ -n "$tailscale_ip" ]; then
        log_pass "Tailscale IP assigned: $tailscale_ip"
        return 0
    else
        log_fail "No Tailscale IP assigned"
        return 1
    fi
}

test_firewall_allows_tailscale() {
    log_test "Checking if firewall allows Tailscale port..."
    
    if ! command -v ufw &> /dev/null; then
        log_fail "UFW is not installed"
        return 1
    fi
    
    if ufw status | grep -q "$TAILSCALE_PORT"; then
        log_pass "Firewall allows Tailscale port $TAILSCALE_PORT"
        return 0
    else
        log_fail "Firewall does not allow Tailscale port $TAILSCALE_PORT"
        return 1
    fi
}

test_builder_port_not_exposed() {
    log_test "Checking if Builder Interface port is NOT exposed..."
    
    if ! command -v ufw &> /dev/null; then
        log_fail "UFW is not installed"
        return 1
    fi
    
    if ufw status | grep -q "$BUILDER_PORT"; then
        log_fail "Builder Interface port $BUILDER_PORT is exposed (SECURITY ISSUE!)"
        return 1
    else
        log_pass "Builder Interface port $BUILDER_PORT is not exposed (correct)"
        return 0
    fi
}

test_builder_not_listening_public() {
    log_test "Checking if Builder Interface is not listening on public IP..."
    
    # Check if anything is listening on port 3000 on public interfaces
    local public_listeners=$(ss -tlnp | grep ":$BUILDER_PORT" | grep -v "127.0.0.1" | grep -v "100\." || echo "")
    
    if [ -z "$public_listeners" ]; then
        log_pass "Builder Interface is not listening on public IP"
        return 0
    else
        # Check if it's only listening on Tailscale IP
        local tailscale_ip=$(tailscale ip -4 2>/dev/null || echo "")
        if [ -n "$tailscale_ip" ] && echo "$public_listeners" | grep -q "$tailscale_ip"; then
            log_pass "Builder Interface is only listening on Tailscale IP"
            return 0
        else
            log_fail "Builder Interface may be listening on public IP"
            echo "  Listeners: $public_listeners"
            return 1
        fi
    fi
}

test_config_file_exists() {
    log_test "Checking if configuration file exists..."
    
    if [ -f /opt/website-builder-tailscale.conf ]; then
        log_pass "Configuration file exists: /opt/website-builder-tailscale.conf"
        return 0
    else
        log_fail "Configuration file not found: /opt/website-builder-tailscale.conf"
        return 1
    fi
}

test_systemd_override_exists() {
    log_test "Checking if systemd override configuration exists..."
    
    local override_file="/etc/systemd/system/website-builder.service.d/tailscale-binding.conf"
    
    if [ -f "$override_file" ]; then
        log_pass "Systemd override configuration exists"
        
        # Check if it contains the Tailscale IP binding
        if grep -q "BIND_ADDRESS" "$override_file"; then
            log_pass "Override configuration includes BIND_ADDRESS"
            return 0
        else
            log_fail "Override configuration missing BIND_ADDRESS"
            return 1
        fi
    else
        log_fail "Systemd override configuration not found"
        return 1
    fi
}

################################################################################
# Main Test Runner
################################################################################

main() {
    echo "Testing Tailscale VPN Configuration..."
    echo "======================================"
    echo ""
    
    # Check if running as root
    check_root
    
    # Run all tests
    test_tailscale_installed
    test_tailscale_running
    test_tailscale_authenticated
    test_tailscale_ip_assigned
    test_firewall_allows_tailscale
    test_builder_port_not_exposed
    test_builder_not_listening_public
    test_config_file_exists
    test_systemd_override_exists
    
    echo ""
    echo "======================================"
    
    # Display results
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        echo ""
        log_info "Requirements validated:"
        echo "  ✓ Requirement 2.3: Builder Interface accessible only through Tailscale VPN"
        echo "  ✓ Requirement 2.5: System denies access to Builder Interface without Tailscale"
        echo ""
        
        # Display Tailscale status
        log_info "Tailscale Status:"
        tailscale status
        echo ""
        
        # Display access information
        local tailscale_ip=$(tailscale ip -4 2>/dev/null || echo "unknown")
        log_info "Builder Interface Access:"
        echo "  URL: http://$tailscale_ip:$BUILDER_PORT"
        echo "  Note: Only accessible when connected to Tailscale VPN"
        
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        echo ""
        echo "Tests passed: $TESTS_PASSED"
        echo "Tests failed: $TESTS_FAILED"
        echo ""
        echo "Please review the failed tests and run configure-tailscale.sh again."
        exit 1
    fi
}

# Run main function
main
