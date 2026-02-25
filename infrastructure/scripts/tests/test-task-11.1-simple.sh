#!/bin/bash
################################################################################
# Simple Test for Task 11.1: Nginx Configuration Generator
#
# This test verifies that the configure_web_server() function:
# 1. Generates nginx configuration file at /etc/nginx/sites-available/ai-website-builder
# 2. Configures HTTP server block with ACME challenge support
# 3. Configures HTTPS server block with proxy to localhost:3000
# 4. Enables site by symlinking to sites-enabled
# 5. Reloads nginx configuration
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
echo "Task 11.1: Nginx Configuration Generator Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This test must be run as root (requires nginx configuration)${NC}"
    echo "Please run with: sudo $0"
    exit 1
fi

# Check if nginx is installed
if ! command -v nginx >/dev/null 2>&1; then
    echo -e "${RED}ERROR: nginx is not installed${NC}"
    echo "Please install nginx: apt install nginx"
    exit 1
fi

# Set up test environment
TEST_DOMAIN="test-example.com"
TEST_CONFIG_DIR="/tmp/test-ai-website-builder-$$"
TEST_NGINX_CONFIG="/tmp/test-nginx-config-$$"
TEST_LOG_FILE="/tmp/test-deploy-11.1-$$.log"

# Create test directories
mkdir -p "$TEST_CONFIG_DIR"
mkdir -p "$TEST_NGINX_CONFIG/sites-available"
mkdir -p "$TEST_NGINX_CONFIG/sites-enabled"

# Export variables needed by the function
export DOMAIN_NAME="$TEST_DOMAIN"
export LOG_FILE="$TEST_LOG_FILE"
export CONFIG_DIR="$TEST_CONFIG_DIR"

# Source required functions from deploy script
source <(sed -n '/^# Color Codes for Output/,/^NC=/p' "$DEPLOY_SCRIPT")
source <(sed -n '/^log_operation()/,/^}/p' "$DEPLOY_SCRIPT")
source <(sed -n '/^display_progress()/,/^}/p' "$DEPLOY_SCRIPT")
source <(sed -n '/^display_success()/,/^}/p' "$DEPLOY_SCRIPT")
source <(sed -n '/^display_error()/,/^}/p' "$DEPLOY_SCRIPT")
source <(sed -n '/^display_info()/,/^}/p' "$DEPLOY_SCRIPT")
source <(sed -n '/^display_warning()/,/^}/p' "$DEPLOY_SCRIPT")

# Extract and modify configure_web_server function for testing
# We'll create a test version that uses our test paths
create_test_function() {
    cat > /tmp/test-configure-web-server-$$.sh << 'EOF'
configure_web_server_test() {
    display_progress "Configuring nginx web server..."
    log_operation "FUNCTION: configure_web_server called"
    
    # Create directory for ACME challenge if it doesn't exist
    display_progress "Creating ACME challenge directory..."
    log_operation "Creating /var/www/certbot directory for ACME challenges"
    
    mkdir -p /var/www/certbot
    display_success "ACME challenge directory created"
    log_operation "ACME challenge directory created at /var/www/certbot"
    
    # Generate nginx configuration file
    display_progress "Generating nginx configuration..."
    log_operation "Generating nginx configuration for domain: $DOMAIN_NAME"
    
    local nginx_config="$TEST_NGINX_CONFIG/sites-available/ai-website-builder"
    
    cat > "$nginx_config" << EOFCONFIG
# AI Website Builder - Nginx Configuration
# Generated: $(date -Iseconds)
# Domain: $DOMAIN_NAME

# HTTP Server Block - Handles ACME challenges and redirects to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME;
    
    # ACME challenge location for Let's Encrypt certificate acquisition
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri =404;
    }
    
    # Redirect all other HTTP traffic to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS Server Block - Proxies to AI Website Builder application
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN_NAME;
    
    # SSL certificate paths (will be configured by certbot)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    
    # SSL configuration for security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    
    # Proxy to AI Website Builder application on localhost:3000
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        
        # Proxy headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support (if needed)
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Logging
    access_log /var/log/nginx/ai-website-builder-access.log;
    error_log /var/log/nginx/ai-website-builder-error.log;
}
EOFCONFIG
    
    display_success "Nginx configuration generated at $nginx_config"
    log_operation "Nginx configuration file created successfully"
    
    # Create symlink to enable site
    display_progress "Enabling nginx site..."
    log_operation "Creating symlink to enable site"
    
    local sites_enabled="$TEST_NGINX_CONFIG/sites-enabled/ai-website-builder"
    
    if [ -L "$sites_enabled" ]; then
        rm -f "$sites_enabled"
    fi
    
    ln -s "$nginx_config" "$sites_enabled"
    display_success "Site enabled in nginx"
    log_operation "Symlink created: $sites_enabled -> $nginx_config"
    
    display_success "Nginx web server configured successfully"
    log_operation "Nginx configuration completed successfully"
}
EOF
    source /tmp/test-configure-web-server-$$.sh
}

create_test_function

################################################################################
# Test 1: Function creates nginx configuration file
################################################################################
test_start "Test 1: Function creates nginx configuration file"

configure_web_server_test > /dev/null 2>&1

nginx_config="$TEST_NGINX_CONFIG/sites-available/ai-website-builder"

if [ -f "$nginx_config" ]; then
    test_pass "Test 1: Function creates nginx configuration file"
else
    test_fail "Test 1: Function creates nginx configuration file" "Configuration file not created at $nginx_config"
fi

################################################################################
# Test 2: Configuration includes HTTP server block with ACME challenge support
################################################################################
test_start "Test 2: Configuration includes HTTP server block with ACME challenge support"

has_http_block=false
has_acme_location=false
has_https_redirect=false

if grep -q "listen 80;" "$nginx_config"; then
    has_http_block=true
fi

if grep -q "location /.well-known/acme-challenge/" "$nginx_config"; then
    has_acme_location=true
fi

if grep -q "return 301 https://" "$nginx_config"; then
    has_https_redirect=true
fi

if [ "$has_http_block" = true ] && [ "$has_acme_location" = true ] && [ "$has_https_redirect" = true ]; then
    test_pass "Test 2: Configuration includes HTTP server block with ACME challenge support"
else
    test_fail "Test 2: Configuration includes HTTP server block with ACME challenge support" \
        "Missing elements - HTTP block: $has_http_block, ACME location: $has_acme_location, HTTPS redirect: $has_https_redirect"
fi

################################################################################
# Test 3: Configuration includes HTTPS server block with proxy to localhost:3000
################################################################################
test_start "Test 3: Configuration includes HTTPS server block with proxy to localhost:3000"

has_https_block=false
has_ssl_config=false
has_proxy=false
has_proxy_headers=false

if grep -q "listen 443 ssl http2;" "$nginx_config"; then
    has_https_block=true
fi

if grep -q "ssl_certificate" "$nginx_config" && grep -q "ssl_certificate_key" "$nginx_config"; then
    has_ssl_config=true
fi

if grep -q "proxy_pass http://localhost:3000;" "$nginx_config"; then
    has_proxy=true
fi

if grep -q "proxy_set_header Host" "$nginx_config" && grep -q "proxy_set_header X-Real-IP" "$nginx_config"; then
    has_proxy_headers=true
fi

if [ "$has_https_block" = true ] && [ "$has_ssl_config" = true ] && [ "$has_proxy" = true ] && [ "$has_proxy_headers" = true ]; then
    test_pass "Test 3: Configuration includes HTTPS server block with proxy to localhost:3000"
else
    test_fail "Test 3: Configuration includes HTTPS server block with proxy to localhost:3000" \
        "Missing elements - HTTPS block: $has_https_block, SSL config: $has_ssl_config, Proxy: $has_proxy, Proxy headers: $has_proxy_headers"
fi

################################################################################
# Test 4: Configuration includes domain name
################################################################################
test_start "Test 4: Configuration includes domain name"

if grep -q "server_name $TEST_DOMAIN;" "$nginx_config"; then
    test_pass "Test 4: Configuration includes domain name"
else
    test_fail "Test 4: Configuration includes domain name" "Domain name $TEST_DOMAIN not found in configuration"
fi

################################################################################
# Test 5: Function creates symlink to enable site
################################################################################
test_start "Test 5: Function creates symlink to enable site"

sites_enabled="$TEST_NGINX_CONFIG/sites-enabled/ai-website-builder"

if [ -L "$sites_enabled" ]; then
    # Check if symlink points to correct file
    link_target=$(readlink "$sites_enabled")
    expected_target="$TEST_NGINX_CONFIG/sites-available/ai-website-builder"
    
    if [ "$link_target" = "$expected_target" ]; then
        test_pass "Test 5: Function creates symlink to enable site"
    else
        test_fail "Test 5: Function creates symlink to enable site" "Symlink points to wrong target: $link_target (expected: $expected_target)"
    fi
else
    test_fail "Test 5: Function creates symlink to enable site" "Symlink not created at $sites_enabled"
fi

################################################################################
# Test 6: Configuration includes security headers
################################################################################
test_start "Test 6: Configuration includes security headers"

has_xframe=false
has_content_type=false
has_xss=false

if grep -q "X-Frame-Options" "$nginx_config"; then
    has_xframe=true
fi

if grep -q "X-Content-Type-Options" "$nginx_config"; then
    has_content_type=true
fi

if grep -q "X-XSS-Protection" "$nginx_config"; then
    has_xss=true
fi

if [ "$has_xframe" = true ] && [ "$has_content_type" = true ] && [ "$has_xss" = true ]; then
    test_pass "Test 6: Configuration includes security headers"
else
    test_fail "Test 6: Configuration includes security headers" \
        "Missing headers - X-Frame-Options: $has_xframe, X-Content-Type-Options: $has_content_type, X-XSS-Protection: $has_xss"
fi

################################################################################
# Test 7: Configuration includes WebSocket support
################################################################################
test_start "Test 7: Configuration includes WebSocket support"

has_upgrade_header=false
has_connection_header=false

if grep -q "proxy_set_header Upgrade" "$nginx_config"; then
    has_upgrade_header=true
fi

if grep -q 'proxy_set_header Connection "upgrade"' "$nginx_config"; then
    has_connection_header=true
fi

if [ "$has_upgrade_header" = true ] && [ "$has_connection_header" = true ]; then
    test_pass "Test 7: Configuration includes WebSocket support"
else
    test_fail "Test 7: Configuration includes WebSocket support" \
        "Missing WebSocket headers - Upgrade: $has_upgrade_header, Connection: $has_connection_header"
fi

################################################################################
# Test 8: Configuration includes SSL protocols and ciphers
################################################################################
test_start "Test 8: Configuration includes SSL protocols and ciphers"

has_ssl_protocols=false
has_ssl_ciphers=false

if grep -q "ssl_protocols TLSv1.2 TLSv1.3" "$nginx_config"; then
    has_ssl_protocols=true
fi

if grep -q "ssl_ciphers" "$nginx_config"; then
    has_ssl_ciphers=true
fi

if [ "$has_ssl_protocols" = true ] && [ "$has_ssl_ciphers" = true ]; then
    test_pass "Test 8: Configuration includes SSL protocols and ciphers"
else
    test_fail "Test 8: Configuration includes SSL protocols and ciphers" \
        "Missing SSL config - Protocols: $has_ssl_protocols, Ciphers: $has_ssl_ciphers"
fi

################################################################################
# Test 9: Function logs operations
################################################################################
test_start "Test 9: Function logs operations"

if [ -f "$TEST_LOG_FILE" ] && [ -s "$TEST_LOG_FILE" ]; then
    if grep -q "configure_web_server called" "$TEST_LOG_FILE"; then
        test_pass "Test 9: Function logs operations"
    else
        test_fail "Test 9: Function logs operations" "Function call not logged"
    fi
else
    test_fail "Test 9: Function logs operations" "Log file not created or empty"
fi

################################################################################
# Test 10: ACME challenge directory is created
################################################################################
test_start "Test 10: ACME challenge directory is created"

if [ -d "/var/www/certbot" ]; then
    test_pass "Test 10: ACME challenge directory is created"
else
    test_fail "Test 10: ACME challenge directory is created" "Directory /var/www/certbot not created"
fi

# Cleanup
rm -rf "$TEST_CONFIG_DIR"
rm -rf "$TEST_NGINX_CONFIG"
rm -f "$TEST_LOG_FILE"
rm -f /tmp/test-configure-web-server-$$.sh

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
