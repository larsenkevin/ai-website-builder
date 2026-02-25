#!/bin/bash
################################################################################
# Simple Property Test for Task 2.4: Operation Logging
#
# This script validates Property 5: Operation Logging
# For any operation performed by the deployment script, an entry shall be
# written to the log file.
#
# This is a simplified version of the full BATS property test that can run
# without BATS installation.
################################################################################

set -e

# Setup test environment
export LOG_FILE="/tmp/test-deploy-logging-$$.log"
export CONFIG_DIR="/tmp/test-config-$$"
export STATE_FILE="$CONFIG_DIR/.install-state"
export CONFIG_FILE="$CONFIG_DIR/config.env"
export REPOSITORY_PATH="/tmp/test-repo"
export QR_CODE_DIR="$CONFIG_DIR/qr-codes"
export SCRIPT_VERSION="1.0.0"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_ITERATIONS=0

# Create test directories
mkdir -p "$CONFIG_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Source the logging functions from deploy.sh
source <(sed -n '/^# Initialize logging/,/^# Placeholder Functions/p' ../deploy.sh | head -n -2)

echo "Property Test for Task 2.4: Operation Logging"
echo "=============================================="
echo ""
echo "Testing Property 5: Operation Logging"
echo "For any operation performed by the deployment script, an entry"
echo "shall be written to the log file."
echo ""

################################################################################
# Helper Functions
################################################################################

# Generate random operation types
generate_random_operation() {
    local operations=(
        "install_system_dependencies"
        "install_runtime_dependencies"
        "install_tailscale"
        "configure_firewall"
        "configure_web_server"
        "setup_ssl_certificates"
        "handle_browser_authentication"
        "generate_qr_codes"
        "configure_systemd_service"
        "start_services"
        "restart_services"
        "verify_service_status"
        "verify_domain_accessibility"
        "save_installation_state"
        "collect_configuration_input"
        "load_existing_configuration"
        "detect_existing_installation"
    )
    
    local index=$((RANDOM % ${#operations[@]}))
    echo "${operations[$index]}"
}

# Generate random operation message
generate_random_message() {
    local operation=$1
    local messages=(
        "Starting $operation"
        "Executing $operation"
        "Running $operation"
        "Processing $operation"
        "Performing $operation"
    )
    
    local index=$((RANDOM % ${#messages[@]}))
    echo "${messages[$index]}"
}

# Test assertion helper
assert_test() {
    local test_name="$1"
    local condition=$2
    
    if [ $condition -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

################################################################################
# Property Tests
################################################################################

echo "Test 1: All operations are logged to the log file (100 iterations)"
echo "-------------------------------------------------------------------"
rm -f "$LOG_FILE"
test_iterations=100
for i in $(seq 1 $test_iterations); do
    operation=$(generate_random_operation)
    message=$(generate_random_message "$operation")
    
    # Log the operation
    log_operation "OPERATION: $operation - $message"
    
    # Verify it was logged
    if ! grep -q "OPERATION: $operation - $message" "$LOG_FILE"; then
        echo -e "${RED}✗${NC} Iteration $i: Operation '$operation' was not logged"
        ((TESTS_FAILED++))
        exit 1
    fi
    ((TOTAL_ITERATIONS++))
done

# Verify we have exactly the expected number of log entries
log_count=$(grep -c "OPERATION:" "$LOG_FILE")
if [ "$log_count" -eq "$test_iterations" ]; then
    assert_test "All $test_iterations operations logged correctly" 0
else
    echo -e "${RED}✗${NC} Expected $test_iterations log entries, found $log_count"
    ((TESTS_FAILED++))
fi
echo ""

echo "Test 2: Log entries include ISO 8601 timestamps (50 iterations)"
echo "----------------------------------------------------------------"
rm -f "$LOG_FILE"
test_iterations=50
for i in $(seq 1 $test_iterations); do
    operation=$(generate_random_operation)
    message=$(generate_random_message "$operation")
    log_operation "OPERATION: $operation - $message"
    ((TOTAL_ITERATIONS++))
done

entries_with_timestamps=$(grep -cE '\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' "$LOG_FILE")
if [ "$entries_with_timestamps" -eq "$test_iterations" ]; then
    assert_test "All $test_iterations entries have ISO 8601 timestamps" 0
else
    echo -e "${RED}✗${NC} Expected $test_iterations entries with timestamps, found $entries_with_timestamps"
    ((TESTS_FAILED++))
fi
echo ""

echo "Test 3: display_progress() logs with PROGRESS prefix (30 iterations)"
echo "---------------------------------------------------------------------"
rm -f "$LOG_FILE"
test_iterations=30
for i in $(seq 1 $test_iterations); do
    operation=$(generate_random_operation)
    message="Progress: $operation iteration $i"
    display_progress "$message" > /dev/null 2>&1
    ((TOTAL_ITERATIONS++))
done

progress_count=$(grep -c "PROGRESS:" "$LOG_FILE")
if [ "$progress_count" -eq "$test_iterations" ]; then
    assert_test "All $test_iterations progress messages logged with PROGRESS prefix" 0
else
    echo -e "${RED}✗${NC} Expected $test_iterations PROGRESS entries, found $progress_count"
    ((TESTS_FAILED++))
fi
echo ""

echo "Test 4: display_success() logs with SUCCESS prefix (30 iterations)"
echo "-------------------------------------------------------------------"
rm -f "$LOG_FILE"
test_iterations=30
for i in $(seq 1 $test_iterations); do
    operation=$(generate_random_operation)
    message="Success: $operation completed iteration $i"
    display_success "$message" > /dev/null 2>&1
    ((TOTAL_ITERATIONS++))
done

success_count=$(grep -c "SUCCESS:" "$LOG_FILE")
if [ "$success_count" -eq "$test_iterations" ]; then
    assert_test "All $test_iterations success messages logged with SUCCESS prefix" 0
else
    echo -e "${RED}✗${NC} Expected $test_iterations SUCCESS entries, found $success_count"
    ((TESTS_FAILED++))
fi
echo ""

echo "Test 5: display_warning() logs with WARNING prefix (30 iterations)"
echo "-------------------------------------------------------------------"
rm -f "$LOG_FILE"
test_iterations=30
for i in $(seq 1 $test_iterations); do
    operation=$(generate_random_operation)
    message="Warning: $operation issue iteration $i"
    display_warning "$message" > /dev/null 2>&1
    ((TOTAL_ITERATIONS++))
done

warning_count=$(grep -c "WARNING:" "$LOG_FILE")
if [ "$warning_count" -eq "$test_iterations" ]; then
    assert_test "All $test_iterations warning messages logged with WARNING prefix" 0
else
    echo -e "${RED}✗${NC} Expected $test_iterations WARNING entries, found $warning_count"
    ((TESTS_FAILED++))
fi
echo ""

echo "Test 6: display_info() logs with INFO prefix (30 iterations)"
echo "-------------------------------------------------------------"
rm -f "$LOG_FILE"
test_iterations=30
for i in $(seq 1 $test_iterations); do
    operation=$(generate_random_operation)
    message="Info: $operation status iteration $i"
    display_info "$message" > /dev/null 2>&1
    ((TOTAL_ITERATIONS++))
done

info_count=$(grep -c "INFO:" "$LOG_FILE")
if [ "$info_count" -eq "$test_iterations" ]; then
    assert_test "All $test_iterations info messages logged with INFO prefix" 0
else
    echo -e "${RED}✗${NC} Expected $test_iterations INFO entries, found $info_count"
    ((TESTS_FAILED++))
fi
echo ""

echo "Test 7: Log file is created if it doesn't exist (20 iterations)"
echo "----------------------------------------------------------------"
test_iterations=20
for i in $(seq 1 $test_iterations); do
    rm -f "$LOG_FILE"
    
    if [ -f "$LOG_FILE" ]; then
        echo -e "${RED}✗${NC} Iteration $i: Log file should not exist before operation"
        ((TESTS_FAILED++))
        exit 1
    fi
    
    operation=$(generate_random_operation)
    log_operation "Test operation: $operation"
    
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}✗${NC} Iteration $i: Log file was not created after operation"
        ((TESTS_FAILED++))
        exit 1
    fi
    ((TOTAL_ITERATIONS++))
done
assert_test "Log file created on first operation in all $test_iterations iterations" 0
echo ""

echo "Test 8: Multiple operations append to the same log file (50 iterations)"
echo "------------------------------------------------------------------------"
rm -f "$LOG_FILE"
test_iterations=50
for i in $(seq 1 $test_iterations); do
    operation=$(generate_random_operation)
    message="Operation $i: $operation"
    log_operation "OPERATION: $operation - $message"
    
    # Verify all previous entries still exist
    current_count=$(grep -c "OPERATION:" "$LOG_FILE")
    if [ "$current_count" -ne "$i" ]; then
        echo -e "${RED}✗${NC} Iteration $i: Expected $i log entries, found $current_count"
        ((TESTS_FAILED++))
        exit 1
    fi
    ((TOTAL_ITERATIONS++))
done
assert_test "All $test_iterations operations appended correctly without overwriting" 0
echo ""

echo "Test 9: init_logging() creates log file with session header (20 iterations)"
echo "----------------------------------------------------------------------------"
test_iterations=20
for i in $(seq 1 $test_iterations); do
    rm -f "$LOG_FILE"
    
    init_logging > /dev/null 2>&1
    
    if ! grep -q "Deployment started at" "$LOG_FILE"; then
        echo -e "${RED}✗${NC} Iteration $i: Missing 'Deployment started at' in log header"
        ((TESTS_FAILED++))
        exit 1
    fi
    
    if ! grep -q "Script version:" "$LOG_FILE"; then
        echo -e "${RED}✗${NC} Iteration $i: Missing 'Script version' in log header"
        ((TESTS_FAILED++))
        exit 1
    fi
    
    separator_count=$(grep -c "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$LOG_FILE")
    if [ "$separator_count" -lt 2 ]; then
        echo -e "${RED}✗${NC} Iteration $i: Expected at least 2 separator lines, found $separator_count"
        ((TESTS_FAILED++))
        exit 1
    fi
    ((TOTAL_ITERATIONS++))
done
assert_test "Session header created correctly in all $test_iterations iterations" 0
echo ""

echo "Test 10: All deployment functions log their execution"
echo "------------------------------------------------------"
rm -f "$LOG_FILE"

# List of functions that should log their execution
functions=(
    "detect_existing_installation"
    "prompt_vm_snapshot"
    "collect_configuration_input"
    "load_existing_configuration"
    "install_system_dependencies"
    "install_runtime_dependencies"
    "install_tailscale"
    "configure_firewall"
    "configure_web_server"
    "setup_ssl_certificates"
    "handle_browser_authentication"
    "generate_qr_codes"
    "configure_systemd_service"
    "start_services"
    "restart_services"
    "verify_service_status"
    "verify_domain_accessibility"
    "save_installation_state"
)

# Call each function
for func in "${functions[@]}"; do
    $func > /dev/null 2>&1 || true
    
    if ! grep -q "FUNCTION: $func called" "$LOG_FILE"; then
        echo -e "${RED}✗${NC} Function $func did not log its execution"
        ((TESTS_FAILED++))
        exit 1
    fi
    ((TOTAL_ITERATIONS++))
done

function_log_count=$(grep -c "FUNCTION:" "$LOG_FILE")
if [ "$function_log_count" -eq "${#functions[@]}" ]; then
    assert_test "All ${#functions[@]} deployment functions logged their execution" 0
else
    echo -e "${RED}✗${NC} Expected ${#functions[@]} function log entries, found $function_log_count"
    ((TESTS_FAILED++))
fi
echo ""

# Cleanup
rm -f "$LOG_FILE"
rm -rf "$CONFIG_DIR"

# Summary
echo "=============================================="
echo "Property Test Summary"
echo "=============================================="
echo "Property: Operation Logging (Property 5)"
echo "Validates: Requirements 7.4"
echo ""
echo "Total iterations executed: $TOTAL_ITERATIONS"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All property tests passed!${NC}"
    echo ""
    echo "Property 5 validated: All operations are logged to the log file."
    exit 0
else
    echo -e "${RED}✗ Some property tests failed${NC}"
    exit 1
fi
