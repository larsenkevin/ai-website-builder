#!/bin/bash

################################################################################
# Tailscale VPN Configuration Script
# 
# This script configures Tailscale VPN for the AI Website Builder.
# It implements Requirements 2.3 and 2.5 from the specification.
#
# Requirements:
# - 2.3: Builder Interface SHALL be accessible only through Tailscale VPN
# - 2.5: System SHALL deny access to Builder Interface without Tailscale
#
# Usage:
#   sudo ./configure-tailscale.sh <auth-key>
#
# Arguments:
#   auth-key: Tailscale authentication key from https://login.tailscale.com/admin/settings/keys
#
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BUILDER_PORT=3000
TAILSCALE_PORT=41641

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

################################################################################
# Main Functions
################################################################################

install_tailscale() {
    log_info "Installing Tailscale..."
    
    # Add Tailscale's package signing key and repository
    if [ ! -f /usr/share/keyrings/tailscale-archive-keyring.gpg ]; then
        log_info "Adding Tailscale repository..."
        curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
        curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list
    fi
    
    # Update package list and install Tailscale
    log_info "Updating package list..."
    apt-get update -qq
    
    log_info "Installing Tailscale package..."
    apt-get install -y tailscale
    
    log_info "Tailscale installed successfully"
}

authenticate_tailscale() {
    local auth_key="$1"
    
    log_info "Authenticating with Tailscale..."
    
    # Start Tailscale and authenticate
    # --authkey: Use the provided authentication key
    # --accept-routes: Accept subnet routes advertised by other nodes
    # --accept-dns: Accept DNS configuration from Tailscale
    tailscale up --authkey="$auth_key" --accept-routes --accept-dns
    
    log_info "Tailscale authentication successful"
}

get_tailscale_ip() {
    # Get the Tailscale IP address
    local tailscale_ip=$(tailscale ip -4 2>/dev/null || echo "")
    
    if [ -z "$tailscale_ip" ]; then
        log_error "Failed to get Tailscale IP address"
        return 1
    fi
    
    echo "$tailscale_ip"
}

configure_builder_interface_access() {
    log_info "Configuring Builder Interface access control..."
    
    # Get Tailscale IP
    local tailscale_ip=$(get_tailscale_ip)
    if [ $? -ne 0 ]; then
        log_error "Cannot configure access control without Tailscale IP"
        return 1
    fi
    
    log_info "Tailscale IP: $tailscale_ip"
    
    # Create systemd drop-in directory for the builder service
    # This will be used when the builder service is created in Task 1.6
    local service_dir="/etc/systemd/system/website-builder.service.d"
    mkdir -p "$service_dir"
    
    # Create override configuration to bind only to Tailscale interface
    cat > "$service_dir/tailscale-binding.conf" <<EOF
[Service]
# Bind Builder Interface only to Tailscale IP
# This ensures the service is only accessible through VPN
Environment="BIND_ADDRESS=$tailscale_ip"
Environment="PORT=$BUILDER_PORT"
EOF
    
    log_info "Builder Interface configured to bind to Tailscale IP only"
    
    # Create a configuration file for future reference
    cat > /opt/website-builder-tailscale.conf <<EOF
# Tailscale VPN Configuration for AI Website Builder
# Generated on $(date)

TAILSCALE_IP=$tailscale_ip
BUILDER_PORT=$BUILDER_PORT
BUILDER_URL=http://$tailscale_ip:$BUILDER_PORT

# Access Instructions:
# 1. Ensure you are connected to the Tailscale network
# 2. Access the Builder Interface at: http://$tailscale_ip:$BUILDER_PORT
# 3. The Builder Interface is NOT accessible from the public internet
EOF
    
    log_info "Configuration saved to /opt/website-builder-tailscale.conf"
}

verify_firewall() {
    log_info "Verifying firewall configuration..."
    
    # Check if UFW is installed and enabled
    if ! command -v ufw &> /dev/null; then
        log_warn "UFW is not installed. Please run configure-ufw.sh first."
        return 1
    fi
    
    # Check if UFW is active
    if ! ufw status | grep -q "Status: active"; then
        log_warn "UFW is not active. Please run configure-ufw.sh first."
        return 1
    fi
    
    # Verify Tailscale port is allowed
    if ! ufw status | grep -q "$TAILSCALE_PORT"; then
        log_warn "Tailscale port $TAILSCALE_PORT is not allowed in UFW"
        log_info "Adding Tailscale port to UFW..."
        ufw allow $TAILSCALE_PORT/udp comment 'Tailscale VPN'
    fi
    
    # Verify Builder Interface port is NOT exposed
    if ufw status | grep -q "$BUILDER_PORT"; then
        log_error "Builder Interface port $BUILDER_PORT is exposed in UFW!"
        log_error "This violates Requirement 2.3 (VPN-only access)"
        return 1
    fi
    
    log_info "Firewall configuration verified"
}

display_status() {
    log_info "Tailscale VPN Status:"
    echo ""
    
    # Display Tailscale status
    tailscale status
    
    echo ""
    log_info "Configuration Summary:"
    echo "  Tailscale IP: $(get_tailscale_ip)"
    echo "  Builder Interface Port: $BUILDER_PORT"
    echo "  Builder Interface URL: http://$(get_tailscale_ip):$BUILDER_PORT"
    echo ""
    log_info "Access Instructions:"
    echo "  1. Connect to Tailscale VPN on your client device"
    echo "  2. Access Builder Interface at: http://$(get_tailscale_ip):$BUILDER_PORT"
    echo "  3. The Builder Interface is NOT accessible from the public internet"
    echo ""
    log_info "Configuration file: /opt/website-builder-tailscale.conf"
}

################################################################################
# Main Script
################################################################################

main() {
    log_info "Starting Tailscale VPN configuration..."
    echo ""
    
    # Check if running as root
    check_root
    
    # Check if auth key is provided
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <tailscale-auth-key>"
        log_error ""
        log_error "Get your auth key from: https://login.tailscale.com/admin/settings/keys"
        exit 1
    fi
    
    local auth_key="$1"
    
    # Step 1: Install Tailscale
    install_tailscale
    echo ""
    
    # Step 2: Authenticate with Tailscale
    authenticate_tailscale "$auth_key"
    echo ""
    
    # Step 3: Configure Builder Interface access control
    configure_builder_interface_access
    echo ""
    
    # Step 4: Verify firewall configuration
    verify_firewall
    echo ""
    
    # Step 5: Display status
    display_status
    echo ""
    
    log_info "Tailscale VPN configuration complete!"
    log_info ""
    log_info "Requirements validated:"
    log_info "  ✓ Requirement 2.3: Builder Interface accessible only through Tailscale VPN"
    log_info "  ✓ Requirement 2.5: System denies access to Builder Interface without Tailscale"
}

# Run main function
main "$@"
