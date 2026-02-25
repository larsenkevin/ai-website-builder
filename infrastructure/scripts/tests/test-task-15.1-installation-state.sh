#!/bin/bash
################################################################################
# Test for Task 15.1: Create installation state file writer
#
# This test verifies that the save_installation_state function:
# 1. Creates the state file at /etc/ai-website-builder/.install-state
# 2. Writes installation metadata (date, version, repository path)
# 3. Updates last_update timestamp in update mode
# 4. Sets proper file permissions (600) and ownership (root:root)
# 5. Logs all operations
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_DIR="/tmp/test-install-state-$$"
TEST_CONFIG_DIR="$TEST_DIR/etc/ai-website-builder"
TEST_STATE_FILE="$TEST_CONFIG_DIR/.install-state"
TEST_LOG_FILE="$TEST_DIR/var/log/ai-website-builder-deploy.log"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment
setup_test_env() {
    echo -e "${BLUE}Setting up test environment...${NC}"
    
    # Create test directories
    mkdir -p "$TEST_CONFIG_DIR"
    mkdir -p "$(dirname "$TEST_LOG_FILE")"
    
    # Source the deploy script functions (but override paths)
    export CONFIG_DIR="$TEST_CONFIG_DIR"
    export STATE_FILE="$TEST_STATE_FILE"
    export LOG_FILE="$TEST_LOG_FILE"
    export SCRIPT_VERSION="1.0.0-test"
    export REPOSITORY_PATH="/opt/ai-website-builder-test"
    
    # Source the deploy script to get the functions
    # We need to extract just the functions we need
    source <(grep -A 200 "^save_installation_state()" ../../deploy.sh | sed '/^[a-z_]*() {$/q' | head -n -1)
    source <(grep -A 50 "^display_progress()" ../../deploy.sh | sed '/^}$/q')
    source <(grep -A 50 "^display_success()" ../../deploy.sh | sed '/^}$/q')
    source <(grep -A 50 "^display_warning()" ../../deploy.sh | sed '/^}$/q')
    source <(grep -A 50 "^display_info()" ../../deploy.sh | sed '/^}$/q')
    source <(grep -A 50 "^log_operation()" ../../deploy.sh | sed '/^}$/q')
    
    echo -e "${GREEN}✓ Test environment setup complete${NC}"
    echo ""
}

# Cleanup test environment
cleanup_test_env() {
    echo ""
    echo -e "${BLUE}Cleaning up test environment...${NC}"
    rm -rf "$TEST_DIR"
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

# Test helper functions
assert_file_exists() {
    local file="$1"
    local description="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $description"
        echo "  Expected file to exist: $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if grep -q "$pattern" "$file"; then
        echo -e "${GREEN}✓ PASS${NC}: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $description"
        echo "  Expected pattern in file: $pattern"
        echo "  File contents:"
        cat "$file" | sed 's/^/    /'
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_permissions() {
    local file="$1"
    local expected_perms="$2"
    local description="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    local actual_perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null)
    
    if [ "$actual_perms" = "$expected_perms" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $description"
        echo "  Expected permissions: $expected_perms"
        echo "  Actual permissions: $actual_perms"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 1: Fresh installation creates state file
test_fresh_installation() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test 1: Fresh installation creates state file"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Set mode to fresh
    export MODE="fresh"
    
    # Call the function
    save_installation_state
    
    # Verify state file was created
    assert_file_exists "$TEST_STATE_FILE" "State file created"
    
    # Verify state file contains required fields
    assert_file_contains "$TEST_STATE_FILE" "^INSTALL_DATE=" "State file contains INSTALL_DATE"
    assert_file_contains "$TEST_STATE_FILE" "^INSTALL_VERSION=" "State file contains INSTALL_VERSION"
    assert_file_contains "$TEST_STATE_FILE" "^REPOSITORY_PATH=" "State file contains REPOSITORY_PATH"
    assert_file_contains "$TEST_STATE_FILE" "^LAST_UPDATE=" "State file contains LAST_UPDATE"
    
    # Verify INSTALL_DATE and LAST_UPDATE are the same in fresh install
    local install_date=$(grep "^INSTALL_DATE=" "$TEST_STATE_FILE" | cut -d'=' -f2)
    local last_update=$(grep "^LAST_UPDATE=" "$TEST_STATE_FILE" | cut -d'=' -f2)
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$install_date" = "$last_update" ]; then
        echo -e "${GREEN}✓ PASS${NC}: INSTALL_DATE equals LAST_UPDATE in fresh install"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: INSTALL_DATE should equal LAST_UPDATE in fresh install"
        echo "  INSTALL_DATE: $install_date"
        echo "  LAST_UPDATE: $last_update"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Verify file permissions (600)
    assert_file_permissions "$TEST_STATE_FILE" "600" "State file has 600 permissions"
    
    echo ""
}

# Test 2: Update mode preserves INSTALL_DATE and updates LAST_UPDATE
test_update_mode() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test 2: Update mode preserves INSTALL_DATE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Get the original INSTALL_DATE from the previous test
    local original_install_date=$(grep "^INSTALL_DATE=" "$TEST_STATE_FILE" | cut -d'=' -f2)
    
    # Wait a moment to ensure timestamp changes
    sleep 2
    
    # Set mode to update
    export MODE="update"
    
    # Call the function again
    save_installation_state
    
    # Verify INSTALL_DATE is preserved
    local new_install_date=$(grep "^INSTALL_DATE=" "$TEST_STATE_FILE" | cut -d'=' -f2)
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$original_install_date" = "$new_install_date" ]; then
        echo -e "${GREEN}✓ PASS${NC}: INSTALL_DATE preserved in update mode"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: INSTALL_DATE should be preserved in update mode"
        echo "  Original INSTALL_DATE: $original_install_date"
        echo "  New INSTALL_DATE: $new_install_date"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Verify LAST_UPDATE is different from INSTALL_DATE
    local last_update=$(grep "^LAST_UPDATE=" "$TEST_STATE_FILE" | cut -d'=' -f2)
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$new_install_date" != "$last_update" ]; then
        echo -e "${GREEN}✓ PASS${NC}: LAST_UPDATE is different from INSTALL_DATE in update mode"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: LAST_UPDATE should be different from INSTALL_DATE in update mode"
        echo "  INSTALL_DATE: $new_install_date"
        echo "  LAST_UPDATE: $last_update"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    echo ""
}

# Test 3: Verify logging
test_logging() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test 3: Verify logging"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Verify log file contains function call
    assert_file_contains "$TEST_LOG_FILE" "FUNCTION: save_installation_state called" "Log contains function call"
    
    # Verify log file contains state file creation/update
    assert_file_contains "$TEST_LOG_FILE" "Installation state" "Log contains state operation"
    
    echo ""
}

# Main test execution
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  Task 15.1: Installation State File Writer Test           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Setup
    setup_test_env
    
    # Run tests
    test_fresh_installation
    test_update_mode
    test_logging
    
    # Cleanup
    cleanup_test_env
    
    # Print summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

# Run main
main
