#!/bin/bash

# configure-systemd.sh
# Creates systemd service files for the AI Website Builder
# Requirements: 1.5

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_info "Creating systemd service files for AI Website Builder..."
echo "========================================"

# Define paths
SERVICE_FILE="/etc/systemd/system/website-builder.service"
APP_DIR="/opt/website-builder"
APP_USER="www-data"
APP_GROUP="www-data"

# Get Tailscale IP if available
TAILSCALE_IP=""
if command -v tailscale &> /dev/null; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
fi

if [ -z "$TAILSCALE_IP" ]; then
    print_warning "Tailscale not configured or not running"
    print_warning "Service will bind to 0.0.0.0 (all interfaces)"
    print_warning "Run configure-tailscale.sh first for VPN-only access"
    BIND_ADDRESS="0.0.0.0"
else
    print_success "Tailscale IP detected: $TAILSCALE_IP"
    BIND_ADDRESS="$TAILSCALE_IP"
fi

# Create systemd service file
print_info "Creating systemd service file..."

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=AI Website Builder - Builder Interface
Documentation=https://github.com/your-repo/ai-website-builder
After=network.target
# If Tailscale is configured, wait for it
After=tailscaled.service
Wants=tailscaled.service

[Service]
Type=simple
User=$APP_USER
Group=$APP_GROUP
WorkingDirectory=$APP_DIR/app

# Environment variables
Environment="NODE_ENV=production"
Environment="PORT=3000"
Environment="BIND_ADDRESS=$BIND_ADDRESS"
Environment="CONFIG_DIR=$APP_DIR/config"
Environment="ASSETS_DIR=$APP_DIR/assets"
Environment="PUBLIC_DIR=/var/www/html"
Environment="VERSIONS_DIR=$APP_DIR/versions"
Environment="LOG_DIR=$APP_DIR/logs"

# Load additional environment variables from file
EnvironmentFile=-$APP_DIR/.env

# Start the application
ExecStart=/usr/bin/node server.js

# Restart policy
Restart=on-failure
RestartSec=10s
StartLimitInterval=5min
StartLimitBurst=3

# Resource limits (for 1GB RAM instance)
MemoryLimit=512M
CPUQuota=80%

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR $APP_DIR/config $APP_DIR/assets $APP_DIR/versions $APP_DIR/logs /var/www/html

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=website-builder

[Install]
WantedBy=multi-user.target
EOF

print_success "Systemd service file created: $SERVICE_FILE"

# Create Tailscale binding override if Tailscale is configured
if [ -n "$TAILSCALE_IP" ]; then
    print_info "Creating Tailscale binding override..."
    
    OVERRIDE_DIR="/etc/systemd/system/website-builder.service.d"
    mkdir -p "$OVERRIDE_DIR"
    
    cat > "$OVERRIDE_DIR/tailscale-binding.conf" << EOF
[Service]
# Override BIND_ADDRESS to use Tailscale IP
Environment="BIND_ADDRESS=$TAILSCALE_IP"
Environment="PORT=3000"
EOF
    
    print_success "Tailscale binding override created: $OVERRIDE_DIR/tailscale-binding.conf"
fi

# Create application directory structure if it doesn't exist
print_info "Creating application directory structure..."

mkdir -p "$APP_DIR"/{app,config,config/pages,assets/uploads,assets/processed/{320,768,1920},versions,logs}

# Set proper ownership
chown -R $APP_USER:$APP_GROUP "$APP_DIR"
chmod 750 "$APP_DIR"
chmod 640 "$APP_DIR/config"/*.json 2>/dev/null || true

print_success "Application directory structure created"

# Create placeholder .env file if it doesn't exist
if [ ! -f "$APP_DIR/.env" ]; then
    print_info "Creating placeholder .env file..."
    
    cat > "$APP_DIR/.env" << EOF
# AI Website Builder Environment Variables
# Copy this file and fill in your actual values

# Claude API Configuration
ANTHROPIC_API_KEY=your-api-key-here

# Domain Configuration
DOMAIN=example.com
SSL_EMAIL=admin@example.com

# Security
SESSION_SECRET=$(openssl rand -hex 32)
ALLOWED_ORIGINS=https://example.com

# Rate Limiting
MAX_REQUESTS_PER_MINUTE=10
MONTHLY_TOKEN_THRESHOLD=1000000

# Monitoring
LOG_LEVEL=info
LOG_ROTATION_SIZE=100MB
LOG_RETENTION_DAYS=30
EOF
    
    chown $APP_USER:$APP_GROUP "$APP_DIR/.env"
    chmod 600 "$APP_DIR/.env"
    
    print_success "Placeholder .env file created: $APP_DIR/.env"
    print_warning "Remember to update $APP_DIR/.env with your actual values"
fi

# Reload systemd daemon
print_info "Reloading systemd daemon..."
systemctl daemon-reload
print_success "Systemd daemon reloaded"

# Enable service to start on boot
print_info "Enabling service to start on boot..."
systemctl enable website-builder.service
print_success "Service enabled"

# Create service management helper script
print_info "Creating service management helper script..."

cat > /usr/local/bin/website-builder-service << 'EOF'
#!/bin/bash

# website-builder-service
# Helper script for managing the AI Website Builder service

case "$1" in
    start)
        echo "Starting AI Website Builder..."
        systemctl start website-builder.service
        ;;
    stop)
        echo "Stopping AI Website Builder..."
        systemctl stop website-builder.service
        ;;
    restart)
        echo "Restarting AI Website Builder..."
        systemctl restart website-builder.service
        ;;
    status)
        systemctl status website-builder.service
        ;;
    logs)
        journalctl -u website-builder.service -f
        ;;
    enable)
        echo "Enabling AI Website Builder to start on boot..."
        systemctl enable website-builder.service
        ;;
    disable)
        echo "Disabling AI Website Builder from starting on boot..."
        systemctl disable website-builder.service
        ;;
    *)
        echo "Usage: website-builder-service {start|stop|restart|status|logs|enable|disable}"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/website-builder-service
print_success "Service management helper created: /usr/local/bin/website-builder-service"

# Display configuration summary
echo ""
echo "========================================"
print_success "Systemd service configuration complete!"
echo "========================================"
echo ""
echo "Service Details:"
echo "  Service Name: website-builder.service"
echo "  Service File: $SERVICE_FILE"
echo "  Application Directory: $APP_DIR"
echo "  User: $APP_USER"
echo "  Group: $APP_GROUP"
echo "  Bind Address: $BIND_ADDRESS"
echo "  Port: 3000"
echo ""
echo "Service Features:"
echo "  ✓ Automatic restart on failure"
echo "  ✓ Restart delay: 10 seconds"
echo "  ✓ Start limit: 3 attempts in 5 minutes"
echo "  ✓ Memory limit: 512MB"
echo "  ✓ CPU quota: 80%"
echo "  ✓ Security hardening enabled"
echo "  ✓ Logging to systemd journal"
echo "  ✓ Enabled to start on boot"
echo ""

if [ -n "$TAILSCALE_IP" ]; then
    echo "VPN Configuration:"
    echo "  ✓ Tailscale binding configured"
    echo "  ✓ Builder Interface accessible at: http://$TAILSCALE_IP:3000"
    echo "  ✓ VPN-only access enforced"
    echo ""
fi

echo "Service Management Commands:"
echo "  Start:   website-builder-service start"
echo "  Stop:    website-builder-service stop"
echo "  Restart: website-builder-service restart"
echo "  Status:  website-builder-service status"
echo "  Logs:    website-builder-service logs"
echo ""
echo "Or use systemctl directly:"
echo "  systemctl start website-builder.service"
echo "  systemctl status website-builder.service"
echo "  journalctl -u website-builder.service -f"
echo ""
echo "Next Steps:"
echo "  1. Update $APP_DIR/.env with your actual values"
echo "  2. Deploy your application code to $APP_DIR/app/"
echo "  3. Start the service: website-builder-service start"
echo "  4. Check status: website-builder-service status"
echo "  5. View logs: website-builder-service logs"
echo ""
print_warning "Note: The service will not start until you deploy the application code"
echo ""
