#!/bin/bash
# Simple test for Task 15.1: Installation state file writer

set -e

echo "Testing save_installation_state function..."

# Create temporary test directory
TEST_DIR="/tmp/test-state-$$"
mkdir -p "$TEST_DIR/etc/ai-website-builder"
mkdir -p "$TEST_DIR/var/log"

# Override variables for testing
export CONFIG_DIR="$TEST_DIR/etc/ai-website-builder"
export STATE_FILE="$CONFIG_DIR/.install-state"
export LOG_FILE="$TEST_DIR/var/log/deploy.log"
export SCRIPT_VERSION="1.0.0"
export REPOSITORY_PATH="/opt/ai-website-builder"
export MODE="fresh"

# Source required functions from deploy.sh
cd "$(dirname "$0")/.."
source <(sed -n '/^display_progress()/,/^}/p' deploy.sh)
source <(sed -n '/^display_success()/,/^}/p' deploy.sh)
source <(sed -n '/^display_warning()/,/^}/p' deploy.sh)
source <(sed -n '/^log_operation()/,/^}/p' deploy.sh)
source <(sed -n '/^save_installation_state()/,/^}/p' deploy.sh)

# Test 1: Fresh installation
echo ""
echo "Test 1: Fresh installation mode"
save_installation_state

if [ -f "$STATE_FILE" ]; then
    echo "✓ State file created"
else
    echo "✗ State file not created"
    exit 1
fi

if grep -q "INSTALL_DATE=" "$STATE_FILE"; then
    echo "✓ INSTALL_DATE present"
else
    echo "✗ INSTALL_DATE missing"
    exit 1
fi

if grep -q "INSTALL_VERSION=" "$STATE_FILE"; then
    echo "✓ INSTALL_VERSION present"
else
    echo "✗ INSTALL_VERSION missing"
    exit 1
fi

if grep -q "REPOSITORY_PATH=" "$STATE_FILE"; then
    echo "✓ REPOSITORY_PATH present"
else
    echo "✗ REPOSITORY_PATH missing"
    exit 1
fi

if grep -q "LAST_UPDATE=" "$STATE_FILE"; then
    echo "✓ LAST_UPDATE present"
else
    echo "✗ LAST_UPDATE missing"
    exit 1
fi

# Check permissions
PERMS=$(stat -c "%a" "$STATE_FILE" 2>/dev/null || stat -f "%A" "$STATE_FILE" 2>/dev/null)
if [ "$PERMS" = "600" ]; then
    echo "✓ File permissions are 600"
else
    echo "✗ File permissions are $PERMS (expected 600)"
fi

# Save original INSTALL_DATE
ORIGINAL_DATE=$(grep "INSTALL_DATE=" "$STATE_FILE" | cut -d'=' -f2)

# Test 2: Update mode
echo ""
echo "Test 2: Update mode"
sleep 1
export MODE="update"
save_installation_state

NEW_DATE=$(grep "INSTALL_DATE=" "$STATE_FILE" | cut -d'=' -f2)
if [ "$ORIGINAL_DATE" = "$NEW_DATE" ]; then
    echo "✓ INSTALL_DATE preserved in update mode"
else
    echo "✗ INSTALL_DATE changed in update mode"
    exit 1
fi

LAST_UPDATE=$(grep "LAST_UPDATE=" "$STATE_FILE" | cut -d'=' -f2)
if [ "$ORIGINAL_DATE" != "$LAST_UPDATE" ]; then
    echo "✓ LAST_UPDATE updated in update mode"
else
    echo "✗ LAST_UPDATE not updated in update mode"
    exit 1
fi

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo "✓ All tests passed!"
