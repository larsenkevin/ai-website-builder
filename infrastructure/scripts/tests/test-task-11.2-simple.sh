#!/bin/bash
################################################################################
# Simple Test for Task 11.2: SSL Certificate Acquisition Function
#
# This test verifies that the setup_ssl_certificates() function:
# 1. Implements setup_ssl_certificates() function
# 2. Runs certbot with nginx plugin
# 3. Uses non-interactive mode with provided email and domain
# 4. Handles certificate acquisition failures with troubleshooting guidance
# 5. Checks for existing certificates (idempotency)
# 6. Verifies nginx is running before attempting certificate acquisition
# 7. Reloads nginx after certificate acquisition
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/../deploy.sh"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_start() {
    local test_name="$1"
    echo -e "${YELLOW}▶ Running: $test_name${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    local test_name="$1"
    echo -e "${GREEN}✓ PASSED: $test_name${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    echo -e "${RED}✗ FAILED: $test_name${NC}"
    echo -e "${RED}  Reason: $reason${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Task 11.2: SSL Certificate Acquisition Function Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

################################################################################
# Test 1: Function exists in deploy script
################################################################################
test_start "Test 1: setup_ssl_certificates function exists"

if grep -q "^setup_ssl_certificates()" "$DEPLOY_SCRIPT"; then
    test_pass "Test 1: setup_ssl_certificates function exists"
else
    test_fail "Test 1: setup_ssl_certificates function exists" "Function not found in deploy script"
fi

################################################################################
# Test 2: Function checks for certbot installation
################################################################################
test_start "Test 2: Function checks for certbot installation"

if grep -A 20 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "command -v certbot"; then
    test_pass "Test 2: Function checks for certbot installation"
else
    test_fail "Test 2: Function checks for certbot installation" "certbot check not found"
fi

################################################################################
# Test 3: Function uses certbot with nginx plugin
################################################################################
test_start "Test 3: Function uses certbot with nginx plugin"

if grep -A 100 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "certbot certonly.*--nginx"; then
    test_pass "Test 3: Function uses certbot with nginx plugin"
else
    test_fail "Test 3: Function uses certbot with nginx plugin" "certbot nginx plugin not used"
fi

################################################################################
# Test 4: Function uses non-interactive mode
################################################################################
test_start "Test 4: Function uses non-interactive mode"

has_non_interactive=false
has_agree_tos=false

if grep -A 100 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "\--non-interactive"; then
    has_non_interactive=true
fi

if grep -A 100 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "\--agree-tos"; then
    has_agree_tos=true
fi

if [ "$has_non_interactive" = true ] && [ "$has_agree_tos" = true ]; then
    test_pass "Test 4: Function uses non-interactive mode"
else
    test_fail "Test 4: Function uses non-interactive mode" \
        "Missing flags - non-interactive: $has_non_interactive, agree-tos: $has_agree_tos"
fi

################################################################################
# Test 5: Function uses provided email and domain
################################################################################
test_start "Test 5: Function uses provided email and domain"

has_email=false
has_domain=false

if grep -A 100 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "\--email.*TAILSCALE_EMAIL"; then
    has_email=true
fi

if grep -A 100 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "\-d.*DOMAIN_NAME"; then
    has_domain=true
fi

if [ "$has_email" = true ] && [ "$has_domain" = true ]; then
    test_pass "Test 5: Function uses provided email and domain"
else
    test_fail "Test 5: Function uses provided email and domain" \
        "Missing parameters - email: $has_email, domain: $has_domain"
fi

################################################################################
# Test 6: Function checks for existing certificates (idempotency)
################################################################################
test_start "Test 6: Function checks for existing certificates"

if grep -A 50 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "/etc/letsencrypt/live/\$DOMAIN_NAME"; then
    test_pass "Test 6: Function checks for existing certificates"
else
    test_fail "Test 6: Function checks for existing certificates" "Existing certificate check not found"
fi

################################################################################
# Test 7: Function verifies nginx is running
################################################################################
test_start "Test 7: Function verifies nginx is running"

if grep -A 80 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "systemctl is-active.*nginx"; then
    test_pass "Test 7: Function verifies nginx is running"
else
    test_fail "Test 7: Function verifies nginx is running" "Nginx status check not found"
fi

################################################################################
# Test 8: Function reloads nginx after certificate acquisition
################################################################################
test_start "Test 8: Function reloads nginx after certificate acquisition"

if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "systemctl reload nginx"; then
    test_pass "Test 8: Function reloads nginx after certificate acquisition"
else
    test_fail "Test 8: Function reloads nginx after certificate acquisition" "Nginx reload not found"
fi

################################################################################
# Test 9: Function provides troubleshooting guidance on failure
################################################################################
test_start "Test 9: Function provides troubleshooting guidance on failure"

has_dns_guidance=false
has_port_guidance=false
has_rate_limit_guidance=false
has_manual_command=false

# Check for DNS troubleshooting
if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "Verify DNS configuration"; then
    has_dns_guidance=true
fi

# Check for port/firewall troubleshooting
if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "port 80"; then
    has_port_guidance=true
fi

# Check for rate limit guidance
if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "rate limit"; then
    has_rate_limit_guidance=true
fi

# Check for manual command suggestion
if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "certbot certonly --nginx"; then
    has_manual_command=true
fi

if [ "$has_dns_guidance" = true ] && [ "$has_port_guidance" = true ] && \
   [ "$has_rate_limit_guidance" = true ] && [ "$has_manual_command" = true ]; then
    test_pass "Test 9: Function provides troubleshooting guidance on failure"
else
    test_fail "Test 9: Function provides troubleshooting guidance on failure" \
        "Missing guidance - DNS: $has_dns_guidance, Port: $has_port_guidance, Rate limit: $has_rate_limit_guidance, Manual command: $has_manual_command"
fi

################################################################################
# Test 10: Function logs operations
################################################################################
test_start "Test 10: Function logs operations"

log_count=$(grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -c "log_operation" || true)

if [ "$log_count" -ge 5 ]; then
    test_pass "Test 10: Function logs operations"
else
    test_fail "Test 10: Function logs operations" "Insufficient logging (found $log_count log_operation calls, expected at least 5)"
fi

################################################################################
# Test 11: Function displays progress messages
################################################################################
test_start "Test 11: Function displays progress messages"

progress_count=$(grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -c "display_progress\|display_success\|display_error\|display_info" || true)

if [ "$progress_count" -ge 5 ]; then
    test_pass "Test 11: Function displays progress messages"
else
    test_fail "Test 11: Function displays progress messages" "Insufficient progress messages (found $progress_count, expected at least 5)"
fi

################################################################################
# Test 12: Function verifies certificate files after acquisition
################################################################################
test_start "Test 12: Function verifies certificate files after acquisition"

has_fullchain_check=false
has_privkey_check=false

if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "fullchain.pem"; then
    has_fullchain_check=true
fi

if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "privkey.pem"; then
    has_privkey_check=true
fi

if [ "$has_fullchain_check" = true ] && [ "$has_privkey_check" = true ]; then
    test_pass "Test 12: Function verifies certificate files after acquisition"
else
    test_fail "Test 12: Function verifies certificate files after acquisition" \
        "Missing file checks - fullchain: $has_fullchain_check, privkey: $has_privkey_check"
fi

################################################################################
# Test 13: Function handles nginx reload failure gracefully
################################################################################
test_start "Test 13: Function handles nginx reload failure gracefully"

if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "systemctl restart nginx"; then
    test_pass "Test 13: Function handles nginx reload failure gracefully"
else
    test_fail "Test 13: Function handles nginx reload failure gracefully" "Nginx restart fallback not found"
fi

################################################################################
# Test 14: Function provides alternative approaches in troubleshooting
################################################################################
test_start "Test 14: Function provides alternative approaches in troubleshooting"

if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "standalone"; then
    test_pass "Test 14: Function provides alternative approaches in troubleshooting"
else
    test_fail "Test 14: Function provides alternative approaches in troubleshooting" "Alternative approach (standalone mode) not mentioned"
fi

################################################################################
# Test Summary
################################################################################
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
else
    echo "Tests failed: $TESTS_FAILED"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Exit with appropriate code
if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
