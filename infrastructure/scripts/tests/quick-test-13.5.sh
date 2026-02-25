#!/bin/bash
# Quick test to verify service management functions exist

DEPLOY_SCRIPT="../deploy.sh"

echo "Testing service management functions..."
echo ""

# Test 1
if grep -q "^configure_systemd_service()" "$DEPLOY_SCRIPT"; then
    echo "✓ configure_systemd_service exists"
else
    echo "✗ configure_systemd_service NOT found"
fi

# Test 2
if grep -q "^start_services()" "$DEPLOY_SCRIPT"; then
    echo "✓ start_services exists"
else
    echo "✗ start_services NOT found"
fi

# Test 3
if grep -q "^verify_service_status()" "$DEPLOY_SCRIPT"; then
    echo "✓ verify_service_status exists"
else
    echo "✗ verify_service_status NOT found"
fi

# Test 4
if grep -q "^restart_services()" "$DEPLOY_SCRIPT"; then
    echo "✓ restart_services exists"
else
    echo "✗ restart_services NOT found"
fi

echo ""
echo "Quick test complete!"
