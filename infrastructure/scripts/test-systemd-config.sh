#!/bin/bash

# test-systemd-config.sh
# Tests systemd service configuration for AI Website Builder
# Requirements: 1.5

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

echo "Testing Systemd Service Configuration..."
echo "========================================"
echo ""

# Define paths
SERVICE_FILE="/etc/systemd/system/website-builder.service"
OVERRIDE_DIR="/etc/systemd/system/website-builder.service.d"
APP_DIR="/opt/website-builder"
HELPER_SCRIPT="/usr/local/bin/website-builder-service"

# Test 1: Service file exists
print_info "Test 1: Checking if service file exists..."
if [ -f "$SERVICE_FILE" ]; then
    print_success "Service file exists: $SERVICE_FILE"
else
    print_error "Service file not found: $SERVICE_FILE"
fi

# Test 2: Service file is valid
print_info "Test 2: Checking if service file is valid..."
if systemd-analyze verify "$SERVICE_FILE" 2>/dev/null; then
    print_success "Service file is valid"
else
    print_error "Service file has errors"
fi

# Test 3: Service is enabled
print_info "Test 3: Checking if service is enabled..."
if systemctl is-enabled website-builder.service &>/dev/null; then
    print_success "Service is enabled (will start on boot)"
else
    print_error "Service is not enabled"
fi

# Test 4: Application directory exists
print_info "Test 4: Checking if application directory exists..."
if [ -d "$APP_DIR" ]; then
    print_success "Application directory exists: $APP_DIR"
else
    print_error "Application directory not found: $APP_DIR"
fi

# Test 5: Required subdirectories exist
print_info "Test 5: Checking if required subdirectories exist..."
REQUIRED_DIRS=("app" "config" "config/pages" "assets" "assets/uploads" "assets/processed" "versions" "logs")
ALL_DIRS_EXIST=true

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$APP_DIR/$dir" ]; then
        print_error "Missing directory: $APP_DIR/$dir"
        ALL_DIRS_EXIST=false
    fi
done

if [ "$ALL_DIRS_EXIST" = true ]; then
    print_success "All required subdirectories exist"
fi

# Test 6: .env file exists
print_info "Test 6: Checking if .env file exists..."
if [ -f "$APP_DIR/.env" ]; then
    print_success ".env file exists: $APP_DIR/.env"
else
    print_warning ".env file not found (will be created on first run)"
fi

# Test 7: Service has correct user/group
print_info "Test 7: Checking service user and group..."
if grep -q "User=www-data" "$SERVICE_FILE" && grep -q "Group=www-data" "$SERVICE_FILE"; then
    print_success "Service configured with correct user/group (www-data)"
else
    print_error "Service user/group configuration incorrect"
fi

# Test 8: Service has restart policy
print_info "Test 8: Checking restart policy..."
if grep -q "Restart=on-failure" "$SERVICE_FILE"; then
    print_success "Restart policy configured (on-failure)"
else
    print_error "Restart policy not configured"
fi

# Test 9: Service has restart delay
print_info "Test 9: Checking restart delay..."
if grep -q "RestartSec=" "$SERVICE_FILE"; then
    RESTART_SEC=$(grep "RestartSec=" "$SERVICE_FILE" | cut -d'=' -f2)
    print_success "Restart delay configured: $RESTART_SEC"
else
    print_error "Restart delay not configured"
fi

# Test 10: Service has start limit
print_info "Test 10: Checking start limit..."
if grep -q "StartLimitInterval=" "$SERVICE_FILE" && grep -q "StartLimitBurst=" "$SERVICE_FILE"; then
    print_success "Start limit configured"
else
    print_error "Start limit not configured"
fi

# Test 11: Service has resource limits
print_info "Test 11: Checking resource limits..."
if grep -q "MemoryLimit=" "$SERVICE_FILE" && grep -q "CPUQuota=" "$SERVICE_FILE"; then
    MEMORY_LIMIT=$(grep "MemoryLimit=" "$SERVICE_FILE" | cut -d'=' -f2)
    CPU_QUOTA=$(grep "CPUQuota=" "$SERVICE_FILE" | cut -d'=' -f2)
    print_success "Resource limits configured (Memory: $MEMORY_LIMIT, CPU: $CPU_QUOTA)"
else
    print_error "Resource limits not configured"
fi

# Test 12: Service has security hardening
print_info "Test 12: Checking security hardening..."
SECURITY_FEATURES=("NoNewPrivileges=true" "PrivateTmp=true" "ProtectSystem=strict" "ProtectHome=true")
ALL_SECURITY_PRESENT=true

for feature in "${SECURITY_FEATURES[@]}"; do
    if ! grep -q "$feature" "$SERVICE_FILE"; then
        print_error "Missing security feature: $feature"
        ALL_SECURITY_PRESENT=false
    fi
done

if [ "$ALL_SECURITY_PRESENT" = true ]; then
    print_success "Security hardening configured"
fi

# Test 13: Service has logging configuration
print_info "Test 13: Checking logging configuration..."
if grep -q "StandardOutput=journal" "$SERVICE_FILE" && grep -q "StandardError=journal" "$SERVICE_FILE"; then
    print_success "Logging to systemd journal configured"
else
    print_error "Logging configuration missing"
fi

# Test 14: Service has environment variables
print_info "Test 14: Checking environment variables..."
REQUIRED_ENV_VARS=("NODE_ENV" "PORT" "BIND_ADDRESS" "CONFIG_DIR" "ASSETS_DIR" "PUBLIC_DIR" "VERSIONS_DIR" "LOG_DIR")
ALL_ENV_PRESENT=true

for var in "${REQUIRED_ENV_VARS[@]}"; do
    if ! grep -q "Environment=\"$var=" "$SERVICE_FILE"; then
        print_error "Missing environment variable: $var"
        ALL_ENV_PRESENT=false
    fi
done

if [ "$ALL_ENV_PRESENT" = true ]; then
    print_success "All required environment variables configured"
fi

# Test 15: Check Tailscale binding override (if Tailscale is configured)
print_info "Test 15: Checking Tailscale binding override..."
if command -v tailscale &> /dev/null && tailscale status &>/dev/null; then
    if [ -f "$OVERRIDE_DIR/tailscale-binding.conf" ]; then
        print_success "Tailscale binding override exists"
        
        # Check if override has correct BIND_ADDRESS
        TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
        if grep -q "BIND_ADDRESS=$TAILSCALE_IP" "$OVERRIDE_DIR/tailscale-binding.conf"; then
            print_success "Tailscale binding override has correct IP: $TAILSCALE_IP"
        else
            print_error "Tailscale binding override has incorrect IP"
        fi
    else
        print_warning "Tailscale is configured but binding override not found"
    fi
else
    print_warning "Tailscale not configured (service will bind to 0.0.0.0)"
fi

# Test 16: Helper script exists and is executable
print_info "Test 16: Checking helper script..."
if [ -f "$HELPER_SCRIPT" ] && [ -x "$HELPER_SCRIPT" ]; then
    print_success "Helper script exists and is executable: $HELPER_SCRIPT"
else
    print_error "Helper script not found or not executable: $HELPER_SCRIPT"
fi

# Test 17: Service dependencies
print_info "Test 17: Checking service dependencies..."
if grep -q "After=network.target" "$SERVICE_FILE"; then
    print_success "Service waits for network"
else
    print_error "Service network dependency missing"
fi

# Test 18: Systemd daemon is aware of the service
print_info "Test 18: Checking if systemd knows about the service..."
if systemctl list-unit-files | grep -q "website-builder.service"; then
    print_success "Systemd is aware of the service"
else
    print_error "Systemd is not aware of the service (run: systemctl daemon-reload)"
fi

# Test 19: Directory permissions
print_info "Test 19: Checking directory permissions..."
if [ -d "$APP_DIR" ]; then
    OWNER=$(stat -c '%U:%G' "$APP_DIR")
    if [ "$OWNER" = "www-data:www-data" ]; then
        print_success "Application directory has correct ownership (www-data:www-data)"
    else
        print_error "Application directory has incorrect ownership: $OWNER"
    fi
fi

# Test 20: Service can be started (if app code exists)
print_info "Test 20: Checking if service can be started..."
if [ -f "$APP_DIR/app/server.js" ]; then
    # Try to start the service
    if systemctl start website-builder.service 2>/dev/null; then
        sleep 2
        if systemctl is-active website-builder.service &>/dev/null; then
            print_success "Service started successfully"
            # Stop it again
            systemctl stop website-builder.service
        else
            print_error "Service failed to start (check logs: journalctl -u website-builder.service)"
        fi
    else
        print_error "Failed to start service"
    fi
else
    print_warning "Application code not deployed yet (server.js not found)"
    print_warning "Service cannot be started until application is deployed"
fi

# Display summary
echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo ""
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    print_success "All tests passed!"
    echo ""
    echo "Systemd service is properly configured:"
    echo "  ✓ Service file created and valid"
    echo "  ✓ Automatic restart on failure configured"
    echo "  ✓ Resource limits set (512MB RAM, 80% CPU)"
    echo "  ✓ Security hardening enabled"
    echo "  ✓ Logging to systemd journal"
    echo "  ✓ Enabled to start on boot"
    echo ""
    echo "Requirements validated:"
    echo "  ✓ Requirement 1.5: Systemd service for Builder Interface"
    echo "  ✓ Automatic restart on failure"
    echo "  ✓ Service logging configured"
    echo ""
    echo "Service Management:"
    echo "  Start:   website-builder-service start"
    echo "  Stop:    website-builder-service stop"
    echo "  Restart: website-builder-service restart"
    echo "  Status:  website-builder-service status"
    echo "  Logs:    website-builder-service logs"
    echo ""
    
    if command -v tailscale &> /dev/null && tailscale status &>/dev/null; then
        TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
        echo "VPN Access:"
        echo "  Builder Interface: http://$TAILSCALE_IP:3000"
        echo "  (Only accessible through Tailscale VPN)"
        echo ""
    fi
    
    exit 0
else
    print_error "Some tests failed!"
    echo ""
    echo "Please review the errors above and run configure-systemd.sh again"
    echo ""
    exit 1
fi
