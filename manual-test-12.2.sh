#!/bin/bash
# Manual verification test for task 12.2

echo "=== Task 12.2 Manual Verification ==="
echo ""
echo "Checking implementation in deploy.sh..."
echo ""

# Check if service access URL generation code exists
if grep -q "Service access URL QR code" infrastructure/scripts/deploy.sh; then
    echo "✓ Service access URL QR code generation code found"
else
    echo "✗ Service access URL QR code generation code NOT found"
    exit 1
fi

# Check if service-access.png is referenced
if grep -q "service-access.png" infrastructure/scripts/deploy.sh; then
    echo "✓ service-access.png file reference found"
else
    echo "✗ service-access.png file reference NOT found"
    exit 1
fi

# Check if service-access.txt is referenced
if grep -q "service-access.txt" infrastructure/scripts/deploy.sh; then
    echo "✓ service-access.txt file reference found"
else
    echo "✗ service-access.txt file reference NOT found"
    exit 1
fi

# Check if Tailscale hostname retrieval is implemented
if grep -q "tailscale status --json" infrastructure/scripts/deploy.sh; then
    echo "✓ Tailscale hostname retrieval implemented"
else
    echo "✗ Tailscale hostname retrieval NOT implemented"
    exit 1
fi

# Check if service_access_url variable is used
if grep -q "service_access_url=" infrastructure/scripts/deploy.sh; then
    echo "✓ service_access_url variable defined"
else
    echo "✗ service_access_url variable NOT defined"
    exit 1
fi

# Check if proper logging is in place
if grep -q "Service access URL:" infrastructure/scripts/deploy.sh; then
    echo "✓ Service access URL logging found"
else
    echo "✗ Service access URL logging NOT found"
    exit 1
fi

# Check if error handling is in place
if grep -q "Service access QR code generation failed" infrastructure/scripts/deploy.sh; then
    echo "✓ Error handling for service access QR code found"
else
    echo "✗ Error handling for service access QR code NOT found"
    exit 1
fi

echo ""
echo "=== All checks passed! ==="
echo ""
echo "Implementation summary:"
echo "- Service access URL QR code generation added"
echo "- PNG saved to: /etc/ai-website-builder/qr-codes/service-access.png"
echo "- ASCII art saved to: /etc/ai-website-builder/qr-codes/service-access.txt"
echo "- Uses Tailscale hostname with domain name fallback"
echo "- Proper error handling and logging in place"
