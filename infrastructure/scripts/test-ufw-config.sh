#!/bin/bash
# Test script to verify UFW firewall configuration
# This script checks that UFW is properly configured with the required rules

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

ERRORS=0

echo "Testing UFW Firewall Configuration..."
echo "======================================"
echo ""

# Test 1: Check if UFW is installed
print_info "Test 1: Checking if UFW is installed..."
if command -v ufw &> /dev/null; then
    print_success "UFW is installed"
else
    print_error "UFW is not installed"
    ((ERRORS++))
fi
echo ""

# Test 2: Check if UFW is enabled
print_info "Test 2: Checking if UFW is enabled..."
if sudo ufw status | grep -q "Status: active"; then
    print_success "UFW is enabled and active"
else
    print_error "UFW is not enabled"
    ((ERRORS++))
fi
echo ""

# Test 3: Check default policies
print_info "Test 3: Checking default policies..."
UFW_STATUS=$(sudo ufw status verbose)

if echo "$UFW_STATUS" | grep -q "Default: deny (incoming)"; then
    print_success "Default incoming policy is DENY"
else
    print_error "Default incoming policy is not DENY"
    ((ERRORS++))
fi

if echo "$UFW_STATUS" | grep -q "Default: allow (outgoing)"; then
    print_success "Default outgoing policy is ALLOW"
else
    print_error "Default outgoing policy is not ALLOW"
    ((ERRORS++))
fi
echo ""

# Test 4: Check required ports are allowed
print_info "Test 4: Checking required ports are allowed..."

# Check port 80 (HTTP)
if sudo ufw status | grep -q "80/tcp.*ALLOW"; then
    print_success "Port 80 (HTTP) is allowed"
else
    print_error "Port 80 (HTTP) is not allowed"
    ((ERRORS++))
fi

# Check port 443 (HTTPS)
if sudo ufw status | grep -q "443/tcp.*ALLOW"; then
    print_success "Port 443 (HTTPS) is allowed"
else
    print_error "Port 443 (HTTPS) is not allowed"
    ((ERRORS++))
fi

# Check port 41641 (Tailscale)
if sudo ufw status | grep -q "41641/udp.*ALLOW"; then
    print_success "Port 41641 (Tailscale UDP) is allowed"
else
    print_error "Port 41641 (Tailscale UDP) is not allowed"
    ((ERRORS++))
fi
echo ""

# Test 5: Verify port 3000 is NOT exposed
print_info "Test 5: Verifying Builder Interface (port 3000) is NOT exposed..."
if sudo ufw status | grep -q "3000.*ALLOW"; then
    print_error "Port 3000 is exposed (should not be!)"
    ((ERRORS++))
else
    print_success "Port 3000 is not exposed (correct - VPN only)"
fi
echo ""

# Summary
echo "======================================"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    echo ""
    echo "UFW Configuration Summary:"
    echo "  ✓ Port 80 (HTTP) - ALLOWED"
    echo "  ✓ Port 443 (HTTPS) - ALLOWED"
    echo "  ✓ Port 41641 (Tailscale UDP) - ALLOWED"
    echo "  ✓ All other inbound traffic - BLOCKED"
    echo "  ✓ Port 3000 (Builder Interface) - NOT EXPOSED"
    echo ""
    echo "Requirements validated:"
    echo "  ✓ Requirement 2.1: Allow ports 80, 443, and Tailscale port"
    echo "  ✓ Requirement 2.2: Block all other inbound traffic by default"
    exit 0
else
    echo -e "${RED}$ERRORS test(s) failed!${NC}"
    echo ""
    echo "Current UFW status:"
    sudo ufw status verbose
    exit 1
fi
