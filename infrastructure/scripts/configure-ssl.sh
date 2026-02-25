#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="${DOMAIN:-}"
SSL_EMAIL="${SSL_EMAIL:-}"
WEBROOT="/var/www/html"
CERT_DIR="/etc/letsencrypt/live"
RENEWAL_SCRIPT="/usr/local/bin/ssl-renewal-with-retry.sh"
MONITOR_SCRIPT="/usr/local/bin/ssl-monitor.sh"
LOG_DIR="/var/log/ssl-automation"

echo -e "${GREEN}=== Let's Encrypt SSL Automation Setup ===${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    exit 1
fi

# Validate required parameters
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Error: DOMAIN environment variable is required${NC}"
    echo "Usage: DOMAIN=example.com SSL_EMAIL=admin@example.com $0"
    exit 1
fi

if [ -z "$SSL_EMAIL" ]; then
    echo -e "${RED}Error: SSL_EMAIL environment variable is required${NC}"
    echo "Usage: DOMAIN=example.com SSL_EMAIL=admin@example.com $0"
    exit 1
fi

echo "Domain: $DOMAIN"
echo "Email: $SSL_EMAIL"
echo ""

# Create log directory
echo -e "${YELLOW}Creating log directory...${NC}"
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"

# Install certbot
echo -e "${YELLOW}Installing certbot...${NC}"
if ! command -v certbot &> /dev/null; then
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
    echo -e "${GREEN}✓ Certbot installed${NC}"
else
    echo -e "${GREEN}✓ Certbot already installed${NC}"
fi

# Ensure NGINX is configured and running
echo -e "${YELLOW}Checking NGINX status...${NC}"
if ! systemctl is-active --quiet nginx; then
    echo -e "${RED}Error: NGINX is not running. Please configure NGINX first (Task 1.2)${NC}"
    exit 1
fi
echo -e "${GREEN}✓ NGINX is running${NC}"

# Create webroot directory if it doesn't exist
mkdir -p "$WEBROOT"
chown -R www-data:www-data "$WEBROOT"

# Obtain SSL certificate
echo -e "${YELLOW}Obtaining SSL certificate from Let's Encrypt...${NC}"
if [ -d "$CERT_DIR/$DOMAIN" ]; then
    echo -e "${YELLOW}Certificate already exists for $DOMAIN${NC}"
    echo "To force renewal, run: certbot renew --force-renewal"
else
    # Use webroot plugin for certificate acquisition
    certbot certonly \
        --webroot \
        --webroot-path="$WEBROOT" \
        --email "$SSL_EMAIL" \
        --agree-tos \
        --no-eff-email \
        --domain "$DOMAIN" \
        --non-interactive
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ SSL certificate obtained successfully${NC}"
    else
        echo -e "${RED}Error: Failed to obtain SSL certificate${NC}"
        exit 1
    fi
fi

# Update NGINX configuration to use SSL
echo -e "${YELLOW}Updating NGINX configuration for SSL...${NC}"
NGINX_CONF="/etc/nginx/sites-available/default"

# Backup existing configuration
cp "$NGINX_CONF" "${NGINX_CONF}.backup-$(date +%Y%m%d-%H%M%S)"

# Create SSL-enabled NGINX configuration
cat > "$NGINX_CONF" << 'EOF'
# HTTP server - redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name _;

    # Allow Let's Encrypt challenges
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name _;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/chain.pem;

    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Document root
    root /var/www/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|webp|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Main location
    location / {
        try_files $uri $uri/ =404;
    }

    # Custom 404 page
    error_page 404 /404.html;
    location = /404.html {
        internal;
    }
}
EOF

# Replace domain placeholder
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" "$NGINX_CONF"

# Test NGINX configuration
echo -e "${YELLOW}Testing NGINX configuration...${NC}"
if nginx -t; then
    echo -e "${GREEN}✓ NGINX configuration is valid${NC}"
    systemctl reload nginx
    echo -e "${GREEN}✓ NGINX reloaded${NC}"
else
    echo -e "${RED}Error: NGINX configuration test failed${NC}"
    echo "Restoring backup configuration..."
    mv "${NGINX_CONF}.backup-"* "$NGINX_CONF"
    systemctl reload nginx
    exit 1
fi

# Create renewal script with exponential backoff retry logic
echo -e "${YELLOW}Creating renewal script with retry logic...${NC}"
cat > "$RENEWAL_SCRIPT" << 'RENEWAL_EOF'
#!/bin/bash
# SSL Certificate Renewal Script with Exponential Backoff
# Requirements: 3.2, 3.4

LOG_FILE="/var/log/ssl-automation/renewal.log"
MAX_RETRIES=5
INITIAL_DELAY=60  # 1 minute

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Exponential backoff retry function
retry_with_backoff() {
    local attempt=1
    local delay=$INITIAL_DELAY
    
    while [ $attempt -le $MAX_RETRIES ]; do
        log "Renewal attempt $attempt of $MAX_RETRIES"
        
        if certbot renew --quiet --no-self-upgrade; then
            log "SUCCESS: Certificate renewed successfully"
            
            # Reload NGINX to use new certificate
            if systemctl reload nginx; then
                log "SUCCESS: NGINX reloaded with new certificate"
            else
                log "WARNING: Failed to reload NGINX"
            fi
            
            return 0
        else
            log "FAILED: Renewal attempt $attempt failed"
            
            if [ $attempt -lt $MAX_RETRIES ]; then
                log "Waiting ${delay} seconds before retry..."
                sleep $delay
                
                # Exponential backoff: double the delay
                delay=$((delay * 2))
                attempt=$((attempt + 1))
            else
                log "ERROR: All renewal attempts failed after $MAX_RETRIES tries"
                return 1
            fi
        fi
    done
}

log "Starting certificate renewal process"
retry_with_backoff
exit_code=$?
log "Renewal process completed with exit code: $exit_code"
exit $exit_code
RENEWAL_EOF

chmod +x "$RENEWAL_SCRIPT"
echo -e "${GREEN}✓ Renewal script created${NC}"

# Create certificate expiration monitoring script
echo -e "${YELLOW}Creating certificate monitoring script...${NC}"
cat > "$MONITOR_SCRIPT" << 'MONITOR_EOF'
#!/bin/bash
# SSL Certificate Expiration Monitor
# Requirements: 3.5

LOG_FILE="/var/log/ssl-automation/monitor.log"
CERT_DIR="/etc/letsencrypt/live"
RENEWAL_THRESHOLD_DAYS=30
DOMAIN="${DOMAIN:-}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if domain is set
if [ -z "$DOMAIN" ]; then
    log "ERROR: DOMAIN environment variable not set"
    exit 1
fi

# Check if certificate exists
CERT_FILE="$CERT_DIR/$DOMAIN/cert.pem"
if [ ! -f "$CERT_FILE" ]; then
    log "ERROR: Certificate not found at $CERT_FILE"
    exit 1
fi

# Get certificate expiration date
EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERT_FILE" | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
CURRENT_EPOCH=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))

log "Certificate expires in $DAYS_UNTIL_EXPIRY days (on $EXPIRY_DATE)"

# Check if renewal is needed
if [ $DAYS_UNTIL_EXPIRY -le $RENEWAL_THRESHOLD_DAYS ]; then
    log "WARNING: Certificate expires in $DAYS_UNTIL_EXPIRY days - triggering renewal"
    
    # Trigger renewal script
    if /usr/local/bin/ssl-renewal-with-retry.sh; then
        log "SUCCESS: Renewal triggered and completed successfully"
    else
        log "ERROR: Renewal failed - manual intervention required"
        exit 1
    fi
else
    log "OK: Certificate is valid for $DAYS_UNTIL_EXPIRY more days"
fi

exit 0
MONITOR_EOF

chmod +x "$MONITOR_SCRIPT"
echo -e "${GREEN}✓ Monitoring script created${NC}"

# Set up cron jobs for automatic renewal and monitoring
echo -e "${YELLOW}Setting up cron jobs...${NC}"

# Create cron job file
CRON_FILE="/etc/cron.d/ssl-automation"
cat > "$CRON_FILE" << CRON_EOF
# SSL Certificate Automation Cron Jobs
# Requirements: 3.2, 3.5

# Set environment variables
DOMAIN=$DOMAIN
SSL_EMAIL=$SSL_EMAIL
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Check certificate expiration daily at 3 AM
0 3 * * * root $MONITOR_SCRIPT >> $LOG_DIR/monitor.log 2>&1

# Attempt renewal twice daily (certbot will only renew if needed)
0 2,14 * * * root $RENEWAL_SCRIPT >> $LOG_DIR/renewal.log 2>&1
CRON_EOF

chmod 644 "$CRON_FILE"
echo -e "${GREEN}✓ Cron jobs configured${NC}"

# Create initial log files
touch "$LOG_DIR/renewal.log"
touch "$LOG_DIR/monitor.log"
chmod 644 "$LOG_DIR"/*.log

# Run initial monitoring check
echo -e "${YELLOW}Running initial certificate check...${NC}"
DOMAIN="$DOMAIN" "$MONITOR_SCRIPT"

echo ""
echo -e "${GREEN}=== SSL Automation Setup Complete ===${NC}"
echo ""
echo "Configuration Summary:"
echo "  Domain: $DOMAIN"
echo "  Email: $SSL_EMAIL"
echo "  Certificate: $CERT_DIR/$DOMAIN/"
echo "  Renewal Script: $RENEWAL_SCRIPT"
echo "  Monitor Script: $MONITOR_SCRIPT"
echo "  Logs: $LOG_DIR/"
echo ""
echo "Automatic Tasks:"
echo "  - Certificate expiration check: Daily at 3 AM"
echo "  - Renewal attempts: Twice daily at 2 AM and 2 PM"
echo "  - Renewal threshold: 30 days before expiration"
echo "  - Retry logic: Up to 5 attempts with exponential backoff"
echo ""
echo "Manual Commands:"
echo "  - Check certificate: openssl x509 -enddate -noout -in $CERT_DIR/$DOMAIN/cert.pem"
echo "  - Force renewal: certbot renew --force-renewal"
echo "  - Test renewal: certbot renew --dry-run"
echo "  - View logs: tail -f $LOG_DIR/renewal.log"
echo ""
echo -e "${GREEN}✓ Task 1.5 Complete${NC}"
