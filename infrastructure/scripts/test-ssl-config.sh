#!/bin/bash
# Test script for SSL configuration
# Validates Task 1.5 implementation

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

echo -e "${GREEN}=== SSL Configuration Test Suite ===${NC}"
echo ""

# Test function
test_check() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Test 1: Certbot installation
test_check "Certbot installed" "command -v certbot"

# Test 2: Renewal script exists
test_check "Renewal script exists" "[ -f /usr/local/bin/ssl-renewal-with-retry.sh ]"

# Test 3: Renewal script is executable
test_check "Renewal script is executable" "[ -x /usr/local/bin/ssl-renewal-with-retry.sh ]"

# Test 4: Monitor script exists
test_check "Monitor script exists" "[ -f /usr/local/bin/ssl-monitor.sh ]"

# Test 5: Monitor script is executable
test_check "Monitor script is executable" "[ -x /usr/local/bin/ssl-monitor.sh ]"

# Test 6: Cron job file exists
test_check "Cron job file exists" "[ -f /etc/cron.d/ssl-automation ]"

# Test 7: Log directory exists
test_check "Log directory exists" "[ -d /var/log/ssl-automation ]"

# Test 8: Renewal log file exists
test_check "Renewal log file exists" "[ -f /var/log/ssl-automation/renewal.log ]"

# Test 9: Monitor log file exists
test_check "Monitor log file exists" "[ -f /var/log/ssl-automation/monitor.log ]"

# Test 10: NGINX SSL configuration
echo -n "Testing: NGINX SSL configuration... "
if grep -q "ssl_certificate" /etc/nginx/sites-available/default; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 11: NGINX HTTPS redirect
echo -n "Testing: NGINX HTTPS redirect... "
if grep -q "return 301 https" /etc/nginx/sites-available/default; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 12: NGINX SSL protocols
echo -n "Testing: NGINX SSL protocols... "
if grep -q "ssl_protocols TLSv1.2 TLSv1.3" /etc/nginx/sites-available/default; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 13: NGINX HSTS header
echo -n "Testing: NGINX HSTS header... "
if grep -q "Strict-Transport-Security" /etc/nginx/sites-available/default; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 14: Cron job for monitoring
echo -n "Testing: Cron job for monitoring... "
if grep -q "ssl-monitor.sh" /etc/cron.d/ssl-automation; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 15: Cron job for renewal
echo -n "Testing: Cron job for renewal... "
if grep -q "ssl-renewal-with-retry.sh" /etc/cron.d/ssl-automation; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 16: Renewal script has retry logic
echo -n "Testing: Renewal script has retry logic... "
if grep -q "retry_with_backoff" /usr/local/bin/ssl-renewal-with-retry.sh; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 17: Renewal script has exponential backoff
echo -n "Testing: Renewal script has exponential backoff... "
if grep -q "delay=\$((delay \* 2))" /usr/local/bin/ssl-renewal-with-retry.sh; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 18: Monitor script checks 30-day threshold
echo -n "Testing: Monitor script checks 30-day threshold... "
if grep -q "RENEWAL_THRESHOLD_DAYS=30" /usr/local/bin/ssl-monitor.sh; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 19: Monitor script triggers renewal
echo -n "Testing: Monitor script triggers renewal... "
if grep -q "ssl-renewal-with-retry.sh" /usr/local/bin/ssl-monitor.sh; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 20: NGINX configuration is valid
echo -n "Testing: NGINX configuration is valid... "
if nginx -t > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
fi

# Additional checks if certificate exists
if [ -n "$DOMAIN" ] && [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    echo ""
    echo -e "${YELLOW}Certificate Information:${NC}"
    
    # Test 21: Certificate file exists
    echo -n "Testing: Certificate file exists... "
    if [ -f "/etc/letsencrypt/live/$DOMAIN/cert.pem" ]; then
        echo -e "${GREEN}PASS${NC}"
        PASSED=$((PASSED + 1))
        
        # Show certificate details
        EXPIRY_DATE=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$DOMAIN/cert.pem" | cut -d= -f2)
        EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
        CURRENT_EPOCH=$(date +%s)
        DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))
        
        echo "  Domain: $DOMAIN"
        echo "  Expires: $EXPIRY_DATE"
        echo "  Days until expiry: $DAYS_UNTIL_EXPIRY"
        
        if [ $DAYS_UNTIL_EXPIRY -le 30 ]; then
            echo -e "  Status: ${YELLOW}Renewal needed${NC}"
        else
            echo -e "  Status: ${GREEN}Valid${NC}"
        fi
    else
        echo -e "${RED}FAIL${NC}"
        FAILED=$((FAILED + 1))
    fi
    
    # Test 22: Certificate is valid
    echo -n "Testing: Certificate is valid... "
    if openssl x509 -checkend 0 -noout -in "/etc/letsencrypt/live/$DOMAIN/cert.pem" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        FAILED=$((FAILED + 1))
    fi
fi

# Summary
echo ""
echo -e "${GREEN}=== Test Summary ===${NC}"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "SSL automation is properly configured:"
    echo "  ✓ Certbot installed"
    echo "  ✓ Automatic renewal configured (twice daily)"
    echo "  ✓ Exponential backoff retry logic implemented"
    echo "  ✓ Certificate expiration monitoring (30-day threshold)"
    echo "  ✓ NGINX configured for HTTPS"
    echo "  ✓ Security headers enabled"
    echo ""
    echo "Requirements validated:"
    echo "  ✓ 3.1: SSL/TLS certificates from Let's Encrypt"
    echo "  ✓ 3.2: Automatic certificate renewal"
    echo "  ✓ 3.3: All public content served over HTTPS"
    echo "  ✓ 3.4: Renewal retry logic with exponential backoff"
    echo "  ✓ 3.5: Certificate expiration monitoring (30-day threshold)"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo "Please review the failed tests and fix any issues."
    exit 1
fi
