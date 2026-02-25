#!/bin/bash
################################################################################
# Runner Script for Fresh Installation Integration Test
#
# This script runs the fresh installation integration test with proper
# environment setup and error handling.
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SCRIPT="$SCRIPT_DIR/integration-fresh-installation.sh"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}Fresh Installation Integration Test Runner${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗${NC} This test must be run as root"
    echo ""
    echo "Please run:"
    echo "  sudo $0"
    echo ""
    exit 1
fi

# Check if test script exists
if [ ! -f "$TEST_SCRIPT" ]; then
    echo -e "${RED}✗${NC} Test script not found: $TEST_SCRIPT"
    exit 1
fi

# Make test script executable if needed
if [ ! -x "$TEST_SCRIPT" ]; then
    echo -e "${YELLOW}⚠${NC} Making test script executable..."
    chmod +x "$TEST_SCRIPT"
fi

# Run the integration test
echo -e "${BLUE}▶${NC} Running integration test..."
echo ""

if bash "$TEST_SCRIPT"; then
    echo ""
    echo -e "${GREEN}✓ Integration test completed successfully${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}✗ Integration test failed${NC}"
    exit 1
fi
