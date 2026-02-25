#!/bin/bash
# Configure UFW (Uncomplicated Firewall) for AI Website Builder
# This script sets up firewall rules to allow only necessary ports:
# - Port 80 (HTTP)
# - Port 443 (HTTPS)
# - Port 41641 (Tailscale VPN)
# All other inbound traffic is blocked by default

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_info "Starting UFW firewall configuration..."

# Check if UFW is installed
if ! command -v ufw &> /dev/null; then
    print_error "UFW is not installed. Installing..."
    apt-get update
    apt-get install -y ufw
fi

# Reset UFW to default state (optional, commented out for safety)
# print_warning "Resetting UFW to default state..."
# ufw --force reset

# Set default policies
print_info "Setting default policies..."
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (port 22) - IMPORTANT: Don't lock yourself out!
print_info "Allowing SSH (port 22)..."
ufw allow 22/tcp comment 'SSH access'

# Allow HTTP (port 80)
print_info "Allowing HTTP (port 80)..."
ufw allow 80/tcp comment 'HTTP web traffic'

# Allow HTTPS (port 443)
print_info "Allowing HTTPS (port 443)..."
ufw allow 443/tcp comment 'HTTPS web traffic'

# Allow Tailscale VPN (port 41641 UDP)
print_info "Allowing Tailscale VPN (port 41641 UDP)..."
ufw allow 41641/udp comment 'Tailscale VPN'

# Enable UFW
print_info "Enabling UFW..."
ufw --force enable

# Display status
print_info "UFW configuration complete!"
echo ""
print_info "Current UFW status:"
ufw status verbose

echo ""
print_info "Firewall rules summary:"
echo "  ✓ Port 22 (SSH) - ALLOWED"
echo "  ✓ Port 80 (HTTP) - ALLOWED"
echo "  ✓ Port 443 (HTTPS) - ALLOWED"
echo "  ✓ Port 41641 (Tailscale UDP) - ALLOWED"
echo "  ✓ All other inbound traffic - BLOCKED"
echo ""
print_warning "Note: The Builder Interface (port 3000) is NOT exposed to the internet."
print_warning "It will only be accessible through Tailscale VPN (Task 1.4)."
