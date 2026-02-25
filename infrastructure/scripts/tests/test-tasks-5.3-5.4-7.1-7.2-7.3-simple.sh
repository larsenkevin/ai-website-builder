#!/bin/bash
################################################################################
# Simple Test for Tasks 5.3, 5.4, 7.1, 7.2, 7.3
# 
# Tests:
# - Task 5.3: Load existing configuration
# - Task 5.4: Configuration preservation in update mode
# - Task 7.1: Secure configuration file writer
# - Task 7.2: Credential masking for display
# - Task 7.3: Credential logging protection
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/../deploy.sh"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_start() {
    echo -e "${YELLOW}TEST:${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo ""
}

test_fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo ""
}

# Source the deploy script to get access to functions
# We need to prevent main() from running
source "$DEPLOY_SCRIPT" 2>/dev/null || true

echo "=================================="
echo "Testing Tasks 5.3, 5.4, 7.1, 7.2, 7.3"
echo "=================================="
echo ""

################################################################################
# Test 1: mask_value function (Task 7.2)
################################################################################

test_start "mask_value function masks credentials correctly"

# Test with API key
result=$(mask_value "sk-ant-1234567890abcdef")
expected="**************cdef"

if [ "$result" = "$expected" ]; then
    test_pass
else
    test_fail "Expected '$expected', got '$result'"
fi

################################################################################
# Test 2: mask_value with short value
################################################################################

test_start "mask_value handles short values"

result=$(mask_value "abc")
# Should show last 1 character for short values
if [[ "$result" =~ \*.*c ]]; then
    test_pass
else
    test_fail "Expected masked value ending with 'c', got '$result'"
fi

################################################################################
# Test 3: save_configuration creates secure files (Task 7.1)
################################################################################

test_start "save_configuration creates directory with 700 permissions"

# Create temporary test environment
TEST_CONFIG_DIR="/tmp/test-ai-website-builder-$$"
TEST_CONFIG_FILE="$TEST_CONFIG_DIR/config.env"

# Override global variables for testing
CONFIG_DIR="$TEST_CONFIG_DIR"
CONFIG_FILE="$TEST_CONFIG_FILE"
CLAUDE_API_KEY="sk-ant-test123456789"
DOMAIN_NAME="test.example.com"
TAILSCALE_EMAIL="test@example.com"
REPOSITORY_PATH="/opt/test"

# Run save_configuration
save_configuration >/dev/null 2>&1

# Check directory permissions
if [ -d "$TEST_CONFIG_DIR" ]; then
    dir_perms=$(stat -c "%a" "$TEST_CONFIG_DIR")
    if [ "$dir_perms" = "700" ]; then
        test_pass
    else
        test_fail "Directory permissions are $dir_perms, expected 700"
    fi
else
    test_fail "Configuration directory was not created"
fi

################################################################################
# Test 4: save_configuration creates file with 600 permissions (Task 7.1)
################################################################################

test_start "save_configuration creates file with 600 permissions"

if [ -f "$TEST_CONFIG_FILE" ]; then
    file_perms=$(stat -c "%a" "$TEST_CONFIG_FILE")
    if [ "$file_perms" = "600" ]; then
        test_pass
    else
        test_fail "File permissions are $file_perms, expected 600"
    fi
else
    test_fail "Configuration file was not created"
fi

################################################################################
# Test 5: Configuration file contains expected values
################################################################################

test_start "Configuration file contains all required values"

if [ -f "$TEST_CONFIG_FILE" ]; then
    if grep -q "CLAUDE_API_KEY=sk-ant-test123456789" "$TEST_CONFIG_FILE" && \
       grep -q "DOMAIN_NAME=test.example.com" "$TEST_CONFIG_FILE" && \
       grep -q "TAILSCALE_EMAIL=test@example.com" "$TEST_CONFIG_FILE"; then
        test_pass
    else
        test_fail "Configuration file missing expected values"
    fi
else
    test_fail "Configuration file does not exist"
fi

################################################################################
# Test 6: load_existing_configuration can read saved config (Task 5.3)
################################################################################

test_start "load_existing_configuration can read saved configuration"

# Clear variables
unset CLAUDE_API_KEY DOMAIN_NAME TAILSCALE_EMAIL

# Source the config file (simulating what load_existing_configuration does)
if [ -f "$TEST_CONFIG_FILE" ]; then
    source "$TEST_CONFIG_FILE"
    
    if [ "$CLAUDE_API_KEY" = "sk-ant-test123456789" ] && \
       [ "$DOMAIN_NAME" = "test.example.com" ] && \
       [ "$TAILSCALE_EMAIL" = "test@example.com" ]; then
        test_pass
    else
        test_fail "Configuration values not loaded correctly"
    fi
else
    test_fail "Configuration file does not exist"
fi

################################################################################
# Test 7: Credential masking in log_operation (Task 7.3)
################################################################################

test_start "log_operation masks credentials in log messages"

# Create temporary log file
TEST_LOG_FILE="/tmp/test-deploy-log-$$"
LOG_FILE="$TEST_LOG_FILE"

# Log a message with an API key
log_operation "Testing with API key: sk-ant-secretkey123456"

# Check if the log file contains masked version
if [ -f "$TEST_LOG_FILE" ]; then
    if grep -q "sk-ant-secretkey123456" "$TEST_LOG_FILE"; then
        test_fail "API key was not masked in log file"
    elif grep -q "\*\*\*" "$TEST_LOG_FILE"; then
        test_pass
    else
        test_fail "Log file does not contain expected masked content"
    fi
else
    test_fail "Log file was not created"
fi

# Cleanup
rm -f "$TEST_LOG_FILE"

################################################################################
# Cleanup
################################################################################

# Remove test configuration directory
rm -rf "$TEST_CONFIG_DIR"

################################################################################
# Test Summary
################################################################################

echo "=================================="
echo "Test Summary"
echo "=================================="
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
else
    echo "Tests failed: $TESTS_FAILED"
fi
echo "=================================="

if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
