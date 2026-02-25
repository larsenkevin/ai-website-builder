#!/bin/bash
################################################################################
# Unit Tests for Task 11.4: Domain Configuration
#
# This test suite verifies the domain configuration functions:
# - configure_web_server() - nginx configuration generation
# - setup_ssl_certificates() - SSL certificate acquisition
# - verify_domain_accessibility() - domain verification checks
#
# Tests cover:
# - Nginx configuration generated correctly
# - SSL certificates acquired
# - Domain verification checks DNS and HTTP/HTTPS
# - Configuration failure shows troubleshooting guidance
#
# Requirements: 10.2, 10.3, 10.4, 10.5
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/../deploy.sh"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
echo "Task 11.4: Domain Configuration Unit Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

################################################################################
# Section 1: Nginx Configuration Tests (configure_web_server)
################################################################################

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Section 1: Nginx Configuration Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

################################################################################
# Test 1.1: configure_web_server function exists
################################################################################
test_start "Test 1.1: configure_web_server function exists"

if grep -q "^configure_web_server()" "$DEPLOY_SCRIPT"; then
    test_pass "Test 1.1: configure_web_server function exists"
else
    test_fail "Test 1.1: configure_web_server function exists" "Function not found in deploy script"
fi

################################################################################
# Test 1.2: Function generates nginx configuration with HTTP server block
################################################################################
test_start "Test 1.2: Function generates nginx configuration with HTTP server block"

# Check for HTTP server block elements
has_http_listen=false
has_acme_location=false
has_https_redirect=false

if grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -q "listen 80;"; then
    has_http_listen=true
fi

if grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -q "location /.well-known/acme-challenge/"; then
    has_acme_location=true
fi

if grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -q "return 301 https://"; then
    has_https_redirect=true
fi

if [ "$has_http_listen" = true ] && [ "$has_acme_location" = true ] && [ "$has_https_redirect" = true ]; then
    test_pass "Test 1.2: Function generates nginx configuration with HTTP server block"
else
    test_fail "Test 1.2: Function generates nginx configuration with HTTP server block" \
        "Missing elements - HTTP listen: $has_http_listen, ACME location: $has_acme_location, HTTPS redirect: $has_https_redirect"
fi

################################################################################
# Test 1.3: Function generates nginx configuration with HTTPS server block
################################################################################
test_start "Test 1.3: Function generates nginx configuration with HTTPS server block"

has_https_listen=false
has_ssl_cert=false
has_proxy_pass=false

if grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -q "listen 443 ssl http2;"; then
    has_https_listen=true
fi

if grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -q "ssl_certificate"; then
    has_ssl_cert=true
fi

if grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -q "proxy_pass http://localhost:3000;"; then
    has_proxy_pass=true
fi

if [ "$has_https_listen" = true ] && [ "$has_ssl_cert" = true ] && [ "$has_proxy_pass" = true ]; then
    test_pass "Test 1.3: Function generates nginx configuration with HTTPS server block"
else
    test_fail "Test 1.3: Function generates nginx configuration with HTTPS server block" \
        "Missing elements - HTTPS listen: $has_https_listen, SSL cert: $has_ssl_cert, Proxy pass: $has_proxy_pass"
fi

################################################################################
# Test 1.4: Function includes security headers in nginx configuration
################################################################################
test_start "Test 1.4: Function includes security headers in nginx configuration"

has_xframe=false
has_content_type=false
has_xss=false

if grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -q "X-Frame-Options"; then
    has_xframe=true
fi

if grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -q "X-Content-Type-Options"; then
    has_content_type=true
fi

if grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -q "X-XSS-Protection"; then
    has_xss=true
fi

if [ "$has_xframe" = true ] && [ "$has_content_type" = true ] && [ "$has_xss" = true ]; then
    test_pass "Test 1.4: Function includes security headers in nginx configuration"
else
    test_fail "Test 1.4: Function includes security headers in nginx configuration" \
        "Missing headers - X-Frame-Options: $has_xframe, X-Content-Type-Options: $has_content_type, X-XSS-Protection: $has_xss"
fi

################################################################################
# Test 1.5: Function creates symlink to enable site
################################################################################
test_start "Test 1.5: Function creates symlink to enable site"

if grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -q "ln -s.*sites-available.*sites-enabled"; then
    test_pass "Test 1.5: Function creates symlink to enable site"
else
    test_fail "Test 1.5: Function creates symlink to enable site" "Symlink creation not found"
fi

################################################################################
# Test 1.6: Function reloads nginx configuration
################################################################################
test_start "Test 1.6: Function reloads nginx configuration"

if grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -q "systemctl reload nginx"; then
    test_pass "Test 1.6: Function reloads nginx configuration"
else
    test_fail "Test 1.6: Function reloads nginx configuration" "Nginx reload not found"
fi

################################################################################
# Test 1.7: Function provides troubleshooting guidance on failure
################################################################################
test_start "Test 1.7: Function provides troubleshooting guidance on failure"

has_error_handling=false
has_remediation=false

if grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -q "ERROR:.*configuration failed"; then
    has_error_handling=true
fi

if grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -q "Remediation:"; then
    has_remediation=true
fi

if [ "$has_error_handling" = true ] && [ "$has_remediation" = true ]; then
    test_pass "Test 1.7: Function provides troubleshooting guidance on failure"
else
    test_fail "Test 1.7: Function provides troubleshooting guidance on failure" \
        "Missing guidance - Error handling: $has_error_handling, Remediation: $has_remediation"
fi

################################################################################
# Section 2: SSL Certificate Tests (setup_ssl_certificates)
################################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Section 2: SSL Certificate Acquisition Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

################################################################################
# Test 2.1: setup_ssl_certificates function exists
################################################################################
test_start "Test 2.1: setup_ssl_certificates function exists"

if grep -q "^setup_ssl_certificates()" "$DEPLOY_SCRIPT"; then
    test_pass "Test 2.1: setup_ssl_certificates function exists"
else
    test_fail "Test 2.1: setup_ssl_certificates function exists" "Function not found in deploy script"
fi

################################################################################
# Test 2.2: Function uses certbot with nginx plugin
################################################################################
test_start "Test 2.2: Function uses certbot with nginx plugin"

if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "certbot certonly.*--nginx"; then
    test_pass "Test 2.2: Function uses certbot with nginx plugin"
else
    test_fail "Test 2.2: Function uses certbot with nginx plugin" "certbot nginx plugin not used"
fi

################################################################################
# Test 2.3: Function uses non-interactive mode with agree-tos
################################################################################
test_start "Test 2.3: Function uses non-interactive mode with agree-tos"

has_non_interactive=false
has_agree_tos=false

if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "\--non-interactive"; then
    has_non_interactive=true
fi

if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "\--agree-tos"; then
    has_agree_tos=true
fi

if [ "$has_non_interactive" = true ] && [ "$has_agree_tos" = true ]; then
    test_pass "Test 2.3: Function uses non-interactive mode with agree-tos"
else
    test_fail "Test 2.3: Function uses non-interactive mode with agree-tos" \
        "Missing flags - non-interactive: $has_non_interactive, agree-tos: $has_agree_tos"
fi

################################################################################
# Test 2.4: Function uses provided email and domain variables
################################################################################
test_start "Test 2.4: Function uses provided email and domain variables"

has_email=false
has_domain=false

if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "\--email.*TAILSCALE_EMAIL"; then
    has_email=true
fi

if grep -A 200 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "\-d.*DOMAIN_NAME"; then
    has_domain=true
fi

if [ "$has_email" = true ] && [ "$has_domain" = true ]; then
    test_pass "Test 2.4: Function uses provided email and domain variables"
else
    test_fail "Test 2.4: Function uses provided email and domain variables" \
        "Missing parameters - email: $has_email, domain: $has_domain"
fi

################################################################################
# Test 2.5: Function checks for existing certificates (idempotency)
################################################################################
test_start "Test 2.5: Function checks for existing certificates (idempotency)"

if grep -A 100 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "/etc/letsencrypt/live/\$DOMAIN_NAME"; then
    test_pass "Test 2.5: Function checks for existing certificates (idempotency)"
else
    test_fail "Test 2.5: Function checks for existing certificates (idempotency)" "Existing certificate check not found"
fi

################################################################################
# Test 2.6: Function verifies nginx is running before certificate acquisition
################################################################################
test_start "Test 2.6: Function verifies nginx is running before certificate acquisition"

if grep -A 150 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "systemctl is-active.*nginx"; then
    test_pass "Test 2.6: Function verifies nginx is running before certificate acquisition"
else
    test_fail "Test 2.6: Function verifies nginx is running before certificate acquisition" "Nginx status check not found"
fi

################################################################################
# Test 2.7: Function verifies certificate files after acquisition
################################################################################
test_start "Test 2.7: Function verifies certificate files after acquisition"

has_fullchain=false
has_privkey=false

if grep -A 250 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "fullchain.pem"; then
    has_fullchain=true
fi

if grep -A 250 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "privkey.pem"; then
    has_privkey=true
fi

if [ "$has_fullchain" = true ] && [ "$has_privkey" = true ]; then
    test_pass "Test 2.7: Function verifies certificate files after acquisition"
else
    test_fail "Test 2.7: Function verifies certificate files after acquisition" \
        "Missing file checks - fullchain: $has_fullchain, privkey: $has_privkey"
fi

################################################################################
# Test 2.8: Function reloads nginx after certificate acquisition
################################################################################
test_start "Test 2.8: Function reloads nginx after certificate acquisition"

# Count how many times nginx reload/restart appears after certbot
reload_count=$(grep -A 300 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -c "systemctl reload nginx\|systemctl restart nginx" || true)

if [ "$reload_count" -ge 1 ]; then
    test_pass "Test 2.8: Function reloads nginx after certificate acquisition"
else
    test_fail "Test 2.8: Function reloads nginx after certificate acquisition" "Nginx reload not found after certificate acquisition"
fi

################################################################################
# Test 2.9: Function provides comprehensive troubleshooting guidance on failure
################################################################################
test_start "Test 2.9: Function provides comprehensive troubleshooting guidance on failure"

has_dns_guidance=false
has_port_guidance=false
has_rate_limit_guidance=false
has_manual_command=false

if grep -A 300 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "Verify DNS configuration"; then
    has_dns_guidance=true
fi

if grep -A 300 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "port 80"; then
    has_port_guidance=true
fi

if grep -A 300 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "rate limit"; then
    has_rate_limit_guidance=true
fi

if grep -A 300 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "certbot certonly"; then
    has_manual_command=true
fi

if [ "$has_dns_guidance" = true ] && [ "$has_port_guidance" = true ] && \
   [ "$has_rate_limit_guidance" = true ] && [ "$has_manual_command" = true ]; then
    test_pass "Test 2.9: Function provides comprehensive troubleshooting guidance on failure"
else
    test_fail "Test 2.9: Function provides comprehensive troubleshooting guidance on failure" \
        "Missing guidance - DNS: $has_dns_guidance, Port: $has_port_guidance, Rate limit: $has_rate_limit_guidance, Manual command: $has_manual_command"
fi

################################################################################
# Test 2.10: Function mentions alternative approaches (standalone mode)
################################################################################
test_start "Test 2.10: Function mentions alternative approaches (standalone mode)"

if grep -A 300 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -q "standalone"; then
    test_pass "Test 2.10: Function mentions alternative approaches (standalone mode)"
else
    test_fail "Test 2.10: Function mentions alternative approaches (standalone mode)" "Standalone mode alternative not mentioned"
fi

################################################################################
# Section 3: Domain Verification Tests (verify_domain_accessibility)
################################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Section 3: Domain Verification Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

################################################################################
# Test 3.1: verify_domain_accessibility function exists
################################################################################
test_start "Test 3.1: verify_domain_accessibility function exists"

if grep -q "^verify_domain_accessibility()" "$DEPLOY_SCRIPT"; then
    test_pass "Test 3.1: verify_domain_accessibility function exists"
else
    test_fail "Test 3.1: verify_domain_accessibility function exists" "Function not found in deploy script"
fi

################################################################################
# Test 3.2: Function checks DNS resolution with dig command
################################################################################
test_start "Test 3.2: Function checks DNS resolution with dig command"

if grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "dig.*\$DOMAIN_NAME"; then
    test_pass "Test 3.2: Function checks DNS resolution with dig command"
else
    test_fail "Test 3.2: Function checks DNS resolution with dig command" "dig command not found"
fi

################################################################################
# Test 3.3: Function checks HTTP accessibility with curl
################################################################################
test_start "Test 3.3: Function checks HTTP accessibility with curl"

if grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "curl.*http://.*\$DOMAIN_NAME"; then
    test_pass "Test 3.3: Function checks HTTP accessibility with curl"
else
    test_fail "Test 3.3: Function checks HTTP accessibility with curl" "HTTP curl check not found"
fi

################################################################################
# Test 3.4: Function checks HTTPS accessibility with curl
################################################################################
test_start "Test 3.4: Function checks HTTPS accessibility with curl"

if grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "curl.*https://.*\$DOMAIN_NAME"; then
    test_pass "Test 3.4: Function checks HTTPS accessibility with curl"
else
    test_fail "Test 3.4: Function checks HTTPS accessibility with curl" "HTTPS curl check not found"
fi

################################################################################
# Test 3.5: Function displays verification results
################################################################################
test_start "Test 3.5: Function displays verification results"

has_dns_result=false
has_http_result=false
has_https_result=false

if grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "DNS resolution.*PASSED\|DNS resolution.*FAILED"; then
    has_dns_result=true
fi

if grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "HTTP accessibility.*PASSED\|HTTP accessibility.*FAILED"; then
    has_http_result=true
fi

if grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "HTTPS accessibility.*PASSED\|HTTPS accessibility.*FAILED"; then
    has_https_result=true
fi

if [ "$has_dns_result" = true ] && [ "$has_http_result" = true ] && [ "$has_https_result" = true ]; then
    test_pass "Test 3.5: Function displays verification results"
else
    test_fail "Test 3.5: Function displays verification results" \
        "Missing results - DNS: $has_dns_result, HTTP: $has_http_result, HTTPS: $has_https_result"
fi

################################################################################
# Test 3.6: Function handles missing commands gracefully
################################################################################
test_start "Test 3.6: Function handles missing commands gracefully"

# Check if function checks for command availability
command_checks=$(grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -c "command -v" || true)

if [ "$command_checks" -ge 2 ]; then
    test_pass "Test 3.6: Function handles missing commands gracefully"
else
    test_fail "Test 3.6: Function handles missing commands gracefully" "Insufficient command availability checks (found $command_checks, expected at least 2)"
fi

################################################################################
# Test 3.7: Function provides troubleshooting guidance when checks fail
################################################################################
test_start "Test 3.7: Function provides troubleshooting guidance when checks fail"

has_dns_guidance=false
has_firewall_guidance=false
has_nginx_guidance=false

if grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "DNS.*propagat"; then
    has_dns_guidance=true
fi

if grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "firewall\|Firewall"; then
    has_firewall_guidance=true
fi

if grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -q "nginx.*status\|systemctl status nginx"; then
    has_nginx_guidance=true
fi

if [ "$has_dns_guidance" = true ] && [ "$has_firewall_guidance" = true ] && [ "$has_nginx_guidance" = true ]; then
    test_pass "Test 3.7: Function provides troubleshooting guidance when checks fail"
else
    test_fail "Test 3.7: Function provides troubleshooting guidance when checks fail" \
        "Missing guidance - DNS: $has_dns_guidance, Firewall: $has_firewall_guidance, Nginx: $has_nginx_guidance"
fi

################################################################################
# Test 3.8: Function logs all verification operations
################################################################################
test_start "Test 3.8: Function logs all verification operations"

log_count=$(grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -c "log_operation" || true)

if [ "$log_count" -ge 5 ]; then
    test_pass "Test 3.8: Function logs all verification operations"
else
    test_fail "Test 3.8: Function logs all verification operations" "Insufficient logging (found $log_count log_operation calls, expected at least 5)"
fi

################################################################################
# Section 4: Integration Tests
################################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Section 4: Integration Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

################################################################################
# Test 4.1: All three functions exist and are properly defined
################################################################################
test_start "Test 4.1: All three functions exist and are properly defined"

has_configure=false
has_setup_ssl=false
has_verify=false

if grep -q "^configure_web_server()" "$DEPLOY_SCRIPT"; then
    has_configure=true
fi

if grep -q "^setup_ssl_certificates()" "$DEPLOY_SCRIPT"; then
    has_setup_ssl=true
fi

if grep -q "^verify_domain_accessibility()" "$DEPLOY_SCRIPT"; then
    has_verify=true
fi

if [ "$has_configure" = true ] && [ "$has_setup_ssl" = true ] && [ "$has_verify" = true ]; then
    test_pass "Test 4.1: All three functions exist and are properly defined"
else
    test_fail "Test 4.1: All three functions exist and are properly defined" \
        "Missing functions - configure_web_server: $has_configure, setup_ssl_certificates: $has_setup_ssl, verify_domain_accessibility: $has_verify"
fi

################################################################################
# Test 4.2: Functions use consistent logging patterns
################################################################################
test_start "Test 4.2: Functions use consistent logging patterns"

configure_logs=$(grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -c "log_operation" || true)
ssl_logs=$(grep -A 300 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -c "log_operation" || true)
verify_logs=$(grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -c "log_operation" || true)

if [ "$configure_logs" -ge 5 ] && [ "$ssl_logs" -ge 5 ] && [ "$verify_logs" -ge 5 ]; then
    test_pass "Test 4.2: Functions use consistent logging patterns"
else
    test_fail "Test 4.2: Functions use consistent logging patterns" \
        "Insufficient logging - configure: $configure_logs, ssl: $ssl_logs, verify: $verify_logs (expected at least 5 each)"
fi

################################################################################
# Test 4.3: Functions use consistent progress display patterns
################################################################################
test_start "Test 4.3: Functions use consistent progress display patterns"

configure_progress=$(grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -c "display_progress\|display_success\|display_error\|display_info\|display_warning" || true)
ssl_progress=$(grep -A 300 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -c "display_progress\|display_success\|display_error\|display_info\|display_warning" || true)
verify_progress=$(grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -c "display_progress\|display_success\|display_error\|display_info\|display_warning" || true)

if [ "$configure_progress" -ge 5 ] && [ "$ssl_progress" -ge 5 ] && [ "$verify_progress" -ge 5 ]; then
    test_pass "Test 4.3: Functions use consistent progress display patterns"
else
    test_fail "Test 4.3: Functions use consistent progress display patterns" \
        "Insufficient progress messages - configure: $configure_progress, ssl: $ssl_progress, verify: $verify_progress (expected at least 5 each)"
fi

################################################################################
# Test 4.4: Functions use DOMAIN_NAME variable consistently
################################################################################
test_start "Test 4.4: Functions use DOMAIN_NAME variable consistently"

configure_domain=$(grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -c "\$DOMAIN_NAME" || true)
ssl_domain=$(grep -A 300 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -c "\$DOMAIN_NAME" || true)
verify_domain=$(grep -A 150 "^verify_domain_accessibility()" "$DEPLOY_SCRIPT" | grep -c "\$DOMAIN_NAME" || true)

if [ "$configure_domain" -ge 3 ] && [ "$ssl_domain" -ge 3 ] && [ "$verify_domain" -ge 3 ]; then
    test_pass "Test 4.4: Functions use DOMAIN_NAME variable consistently"
else
    test_fail "Test 4.4: Functions use DOMAIN_NAME variable consistently" \
        "Insufficient DOMAIN_NAME usage - configure: $configure_domain, ssl: $ssl_domain, verify: $verify_domain (expected at least 3 each)"
fi

################################################################################
# Test 4.5: All functions provide error handling with exit codes
################################################################################
test_start "Test 4.5: All functions provide error handling with exit codes"

configure_exits=$(grep -A 200 "^configure_web_server()" "$DEPLOY_SCRIPT" | grep -c "exit 1" || true)
ssl_exits=$(grep -A 300 "^setup_ssl_certificates()" "$DEPLOY_SCRIPT" | grep -c "exit 1" || true)

if [ "$configure_exits" -ge 2 ] && [ "$ssl_exits" -ge 2 ]; then
    test_pass "Test 4.5: All functions provide error handling with exit codes"
else
    test_fail "Test 4.5: All functions provide error handling with exit codes" \
        "Insufficient error handling - configure: $configure_exits, ssl: $ssl_exits (expected at least 2 each)"
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
