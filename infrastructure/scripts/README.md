# Infrastructure Scripts

This directory contains scripts for configuring the AI Website Builder infrastructure.

## NGINX Configuration

### configure-nginx.sh

Installs and configures NGINX as a static web server for serving generated HTML files.

**What it does:**
- Installs NGINX package
- Creates `/var/www/html` web root directory with proper permissions
- Configures gzip compression for text-based content
- Sets up cache headers for optimal performance
- Creates a custom 404 error page
- Configures security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)
- Blocks access to hidden files and config files
- Enables NGINX to start on boot

**Requirements:**
- Ubuntu/Debian-based system
- Root/sudo access
- Internet connection for package installation

**Usage:**
```bash
sudo ./configure-nginx.sh
```

**Configuration Details:**

1. **Server Block:**
   - Listens on port 80 (HTTP)
   - Serves files from `/var/www/html`
   - Default index file: `index.html`

2. **Gzip Compression:**
   - Enabled for text-based content (HTML, CSS, JS, JSON, XML, SVG)
   - Compression level: 6
   - Minimum file size: 1024 bytes
   - Includes `Vary: Accept-Encoding` header

3. **Cache Headers:**
   - Static assets (images, fonts, CSS, JS): 1 year with immutable flag
   - HTML files: 1 hour with must-revalidate
   - Reduces server load and improves page load times

4. **404 Error Handling:**
   - Custom styled 404 page at `/var/www/html/404.html`
   - User-friendly design with "Go Home" link
   - Automatically served for missing pages

5. **Security:**
   - Blocks access to hidden files (`.htaccess`, `.git`, etc.)
   - Blocks access to config files (`.json`, `.conf`, `.config`)
   - Security headers to prevent clickjacking and XSS

**File Locations:**
- NGINX config: `/etc/nginx/sites-available/website-builder`
- Enabled site: `/etc/nginx/sites-enabled/website-builder`
- Web root: `/var/www/html`
- 404 page: `/var/www/html/404.html`
- Access logs: `/var/log/nginx/access.log`
- Error logs: `/var/log/nginx/error.log`

**Testing:**
After running the script, test the configuration:

```bash
# Check NGINX status
sudo systemctl status nginx

# Test configuration syntax
sudo nginx -t

# View access logs
sudo tail -f /var/log/nginx/access.log

# View error logs
sudo tail -f /var/log/nginx/error.log
```

**Next Steps:**
After NGINX configuration, complete:
1. Task 1.3: Set up UFW firewall rules
2. Task 1.4: Configure Tailscale VPN integration
3. Task 1.5: Set up Let's Encrypt SSL automation

**Troubleshooting:**

If NGINX fails to start:
```bash
# Check configuration syntax
sudo nginx -t

# View detailed error logs
sudo journalctl -u nginx -n 50

# Check if port 80 is already in use
sudo netstat -tlnp | grep :80
```

If you need to modify the configuration:
```bash
# Edit the configuration
sudo nano /etc/nginx/sites-available/website-builder

# Test the changes
sudo nginx -t

# Reload NGINX (without downtime)
sudo systemctl reload nginx
```

## UFW Firewall Configuration

### configure-ufw.sh

Configures UFW (Uncomplicated Firewall) to allow only necessary ports for the AI Website Builder.

**What it does:**
- Sets default policies (deny incoming, allow outgoing)
- Allows SSH (port 22) to prevent lockout
- Allows HTTP (port 80) for public web traffic
- Allows HTTPS (port 443) for secure public web traffic
- Allows Tailscale VPN (port 41641 UDP) for VPN access
- Blocks all other inbound traffic by default
- Enables UFW and displays status

**Requirements:**
- Ubuntu/Debian-based system
- Root/sudo access
- UFW installed (script will install if missing)

**Usage:**
```bash
sudo ./configure-ufw.sh
```

**Security Details:**

1. **Allowed Ports:**
   - Port 22 (TCP): SSH access for server management
   - Port 80 (TCP): HTTP web traffic for public website
   - Port 443 (TCP): HTTPS web traffic for public website
   - Port 41641 (UDP): Tailscale VPN for secure Builder Interface access

2. **Default Policies:**
   - Incoming: DENY (all inbound traffic blocked by default)
   - Outgoing: ALLOW (server can make outbound connections)

3. **Builder Interface Protection:**
   - Port 3000 (Builder Interface) is NOT exposed to the internet
   - Only accessible through Tailscale VPN (configured in Task 1.4)
   - Provides security for the administrative interface

**Verification:**
After running the script, verify the configuration:

```bash
# Check UFW status
sudo ufw status verbose

# List all rules with numbers
sudo ufw status numbered

# Check if UFW is active
sudo systemctl status ufw
```

**Expected Output:**
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere                   # SSH access
80/tcp                     ALLOW IN    Anywhere                   # HTTP web traffic
443/tcp                    ALLOW IN    Anywhere                   # HTTPS web traffic
41641/udp                  ALLOW IN    Anywhere                   # Tailscale VPN
```

**Troubleshooting:**

If you get locked out (SSH connection lost):
- Use AWS Lightsail console to access the instance
- Or use the browser-based SSH terminal in Lightsail
- Check UFW rules: `sudo ufw status`
- Ensure port 22 is allowed: `sudo ufw allow 22/tcp`

To temporarily disable UFW:
```bash
sudo ufw disable
```

To re-enable UFW:
```bash
sudo ufw enable
```

To delete a rule:
```bash
# List rules with numbers
sudo ufw status numbered

# Delete by number
sudo ufw delete <number>
```

**Next Steps:**
After UFW configuration, complete:
1. Task 1.4: Configure Tailscale VPN integration
2. Task 1.5: Set up Let's Encrypt SSL automation

### test-ufw-config.sh

Validates that UFW firewall is properly configured with all required rules.

**What it tests:**
- UFW is installed and enabled
- Default policies are correctly set (deny incoming, allow outgoing)
- Required ports are allowed (80, 443, 41641)
- Builder Interface port (3000) is NOT exposed
- All requirements 2.1 and 2.2 are met

**Requirements:**
- UFW must be configured (run configure-ufw.sh first)
- Root/sudo access to check UFW status

**Usage:**
```bash
sudo ./test-ufw-config.sh
```

**Expected Output (Success):**
```
Testing UFW Firewall Configuration...
======================================

ℹ Test 1: Checking if UFW is installed...
✓ UFW is installed

ℹ Test 2: Checking if UFW is enabled...
✓ UFW is enabled and active

ℹ Test 3: Checking default policies...
✓ Default incoming policy is DENY
✓ Default outgoing policy is ALLOW

ℹ Test 4: Checking required ports are allowed...
✓ Port 80 (HTTP) is allowed
✓ Port 443 (HTTPS) is allowed
✓ Port 41641 (Tailscale UDP) is allowed

ℹ Test 5: Verifying Builder Interface (port 3000) is NOT exposed...
✓ Port 3000 is not exposed (correct - VPN only)

======================================
All tests passed!

UFW Configuration Summary:
  ✓ Port 80 (HTTP) - ALLOWED
  ✓ Port 443 (HTTPS) - ALLOWED
  ✓ Port 41641 (Tailscale UDP) - ALLOWED
  ✓ All other inbound traffic - BLOCKED
  ✓ Port 3000 (Builder Interface) - NOT EXPOSED

Requirements validated:
  ✓ Requirement 2.1: Allow ports 80, 443, and Tailscale port
  ✓ Requirement 2.2: Block all other inbound traffic by default
```

**Exit Codes:**
- 0: All tests passed
- 1: One or more tests failed

## Let's Encrypt SSL Automation

### configure-ssl.sh

Installs and configures Let's Encrypt SSL certificates with automatic renewal and monitoring.

**What it does:**
- Installs certbot (Let's Encrypt client)
- Obtains SSL/TLS certificate from Let's Encrypt
- Configures NGINX for HTTPS with security headers
- Creates renewal script with exponential backoff retry logic
- Creates certificate expiration monitoring script
- Sets up automated cron jobs for renewal and monitoring
- Implements 30-day expiration threshold monitoring

**Requirements:**
- Ubuntu/Debian-based system
- Root/sudo access
- Domain name with DNS configured
- NGINX must be installed and running (Task 1.2)
- Ports 80 and 443 must be open (Task 1.3)

**Usage:**
```bash
sudo DOMAIN=example.com SSL_EMAIL=admin@example.com ./configure-ssl.sh
```

**Environment Variables:**
- `DOMAIN`: Your website domain (required)
- `SSL_EMAIL`: Email for Let's Encrypt notifications (required)

**Security Features:**

1. **HTTPS Enforcement:**
   - All HTTP traffic redirected to HTTPS (301 permanent redirect)
   - Implements Requirement 3.3

2. **Modern TLS Configuration:**
   - TLS 1.2 and 1.3 only (no older protocols)
   - Strong cipher suites
   - Perfect Forward Secrecy

3. **Security Headers:**
   - HSTS (HTTP Strict Transport Security) - 1 year
   - X-Frame-Options: SAMEORIGIN
   - X-Content-Type-Options: nosniff
   - X-XSS-Protection: 1; mode=block

4. **SSL Optimization:**
   - Session caching (10 minutes)
   - OCSP stapling enabled
   - HTTP/2 support

**Automatic Renewal:**

Implements **Requirement 3.2** - Automatic certificate renewal:

1. **Cron Jobs:**
   - Certificate monitoring: Daily at 3:00 AM
   - Renewal attempts: Twice daily at 2:00 AM and 2:00 PM

2. **Renewal Script** (`/usr/local/bin/ssl-renewal-with-retry.sh`):
   - Implements **Requirement 3.4** - Exponential backoff retry logic
   - Maximum 5 retry attempts
   - Initial delay: 60 seconds
   - Backoff strategy: Doubles each retry (60s, 120s, 240s, 480s)
   - Automatically reloads NGINX after successful renewal
   - Comprehensive logging

3. **Monitor Script** (`/usr/local/bin/ssl-monitor.sh`):
   - Implements **Requirement 3.5** - 30-day expiration threshold
   - Checks certificate expiration daily
   - Triggers renewal when within 30 days of expiration
   - Logs all monitoring activities

**File Locations:**
- Certificates: `/etc/letsencrypt/live/<domain>/`
- Renewal script: `/usr/local/bin/ssl-renewal-with-retry.sh`
- Monitor script: `/usr/local/bin/ssl-monitor.sh`
- Cron jobs: `/etc/cron.d/ssl-automation`
- Logs: `/var/log/ssl-automation/`
  - `renewal.log` - Renewal attempts and results
  - `monitor.log` - Expiration checks

**Certificate Lifecycle:**
- **Issued**: Valid for 90 days
- **Renewal window**: 30 days before expiration
- **Automatic renewal**: Attempted twice daily
- **Retry logic**: Up to 5 attempts with exponential backoff
- **Monitoring**: Daily expiration checks

**Verification:**
After running the script, verify the configuration:

```bash
# Check certificate
sudo certbot certificates

# View certificate expiration
sudo openssl x509 -enddate -noout -in /etc/letsencrypt/live/example.com/cert.pem

# Test HTTPS access
curl -I https://example.com

# Check SSL configuration
openssl s_client -connect example.com:443 -servername example.com < /dev/null

# View renewal logs
sudo tail -f /var/log/ssl-automation/renewal.log

# View monitor logs
sudo tail -f /var/log/ssl-automation/monitor.log
```

**Manual Operations:**

Force certificate renewal:
```bash
sudo certbot renew --force-renewal
```

Test renewal (dry run):
```bash
sudo certbot renew --dry-run
```

Check certificate expiration:
```bash
sudo openssl x509 -enddate -noout -in /etc/letsencrypt/live/example.com/cert.pem
```

Manually trigger renewal script:
```bash
sudo /usr/local/bin/ssl-renewal-with-retry.sh
```

Manually trigger monitor script:
```bash
sudo DOMAIN=example.com /usr/local/bin/ssl-monitor.sh
```

**Troubleshooting:**

Certificate acquisition fails:
```bash
# Verify DNS is configured
dig example.com

# Ensure port 80 is accessible
curl http://example.com/.well-known/acme-challenge/test

# Check NGINX is running
sudo systemctl status nginx

# Review certbot logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

Renewal fails:
```bash
# Check renewal logs
sudo tail -f /var/log/ssl-automation/renewal.log

# Test renewal manually
sudo certbot renew --dry-run

# Verify NGINX configuration
sudo nginx -t

# Ensure webroot is accessible
ls -la /var/www/html/.well-known/acme-challenge/
```

Certificate not renewing automatically:
```bash
# Verify cron jobs
cat /etc/cron.d/ssl-automation

# Check cron service
sudo systemctl status cron

# Review monitor logs
sudo tail -f /var/log/ssl-automation/monitor.log

# Test monitor script manually
sudo DOMAIN=example.com /usr/local/bin/ssl-monitor.sh
```

**Next Steps:**
After SSL configuration, complete:
1. Task 1.6: Create systemd service files for the Builder Interface

### test-ssl-config.sh

Validates that SSL automation is properly configured and all requirements are met.

**What it tests:**
- Certbot is installed
- Renewal script exists and is executable
- Monitor script exists and is executable
- Cron jobs are configured
- Log directory and files exist
- NGINX SSL configuration is correct
- HTTPS redirect is configured
- SSL protocols are secure (TLS 1.2/1.3)
- Security headers are present (HSTS)
- Retry logic is implemented
- Exponential backoff is configured
- 30-day threshold is set
- Certificate validity (if certificate exists)
- Requirements 3.1-3.5 are met

**Requirements:**
- SSL must be configured (run configure-ssl.sh first)
- Root/sudo access

**Usage:**
```bash
sudo ./test-ssl-config.sh
```

**Expected Output (Success):**
```
=== SSL Configuration Test Suite ===

Testing: Certbot installed... PASS
Testing: Renewal script exists... PASS
Testing: Renewal script is executable... PASS
Testing: Monitor script exists... PASS
Testing: Monitor script is executable... PASS
Testing: Cron job file exists... PASS
Testing: Log directory exists... PASS
Testing: Renewal log file exists... PASS
Testing: Monitor log file exists... PASS
Testing: NGINX SSL configuration... PASS
Testing: NGINX HTTPS redirect... PASS
Testing: NGINX SSL protocols... PASS
Testing: NGINX HSTS header... PASS
Testing: Cron job for monitoring... PASS
Testing: Cron job for renewal... PASS
Testing: Renewal script has retry logic... PASS
Testing: Renewal script has exponential backoff... PASS
Testing: Monitor script checks 30-day threshold... PASS
Testing: Monitor script triggers renewal... PASS
Testing: NGINX configuration is valid... PASS

Certificate Information:
Testing: Certificate file exists... PASS
  Domain: example.com
  Expires: Mar 24 12:00:00 2024 GMT
  Days until expiry: 28
  Status: Valid

Testing: Certificate is valid... PASS

=== Test Summary ===
Passed: 22
Failed: 0

✓ All tests passed!

SSL automation is properly configured:
  ✓ Certbot installed
  ✓ Automatic renewal configured (twice daily)
  ✓ Exponential backoff retry logic implemented
  ✓ Certificate expiration monitoring (30-day threshold)
  ✓ NGINX configured for HTTPS
  ✓ Security headers enabled

Requirements validated:
  ✓ 3.1: SSL/TLS certificates from Let's Encrypt
  ✓ 3.2: Automatic certificate renewal
  ✓ 3.3: All public content served over HTTPS
  ✓ 3.4: Renewal retry logic with exponential backoff
  ✓ 3.5: Certificate expiration monitoring (30-day threshold)
```

**Exit Codes:**
- 0: All tests passed
- 1: One or more tests failed

## Systemd Service Configuration

### configure-systemd.sh

Creates systemd service files for the AI Website Builder to manage the Builder Interface application.

**What it does:**
- Creates systemd service file for Builder Interface
- Configures automatic restart on failure
- Sets up service logging to systemd journal
- Creates application directory structure
- Generates placeholder .env file with secure defaults
- Integrates with Tailscale VPN binding configuration
- Creates service management helper script
- Enables service to start on boot
- Implements resource limits (512MB RAM, 80% CPU)
- Applies security hardening (NoNewPrivileges, PrivateTmp, ProtectSystem)

**Requirements:**
- Ubuntu/Debian-based system
- Root/sudo access
- Systemd init system
- Tailscale configured (optional, for VPN-only access)

**Usage:**
```bash
sudo ./configure-systemd.sh
```

**Service Features:**

1. **Automatic Restart:**
   - Restart policy: on-failure
   - Restart delay: 10 seconds
   - Start limit: 3 attempts in 5 minutes
   - Prevents rapid restart loops

2. **Resource Management:**
   - Memory limit: 512MB (appropriate for 1GB instance)
   - CPU quota: 80% (prevents CPU starvation)
   - Protects system from resource exhaustion

3. **Security Hardening:**
   - Runs as www-data user (not root)
   - NoNewPrivileges=true (prevents privilege escalation)
   - PrivateTmp=true (isolated /tmp directory)
   - ProtectSystem=strict (read-only system directories)
   - ProtectHome=true (no access to user home directories)
   - Explicit write permissions only where needed

4. **Logging:**
   - All output to systemd journal
   - Structured logging with metadata
   - Persistent logs across reboots
   - Easy filtering and searching

5. **VPN Integration:**
   - Binds to Tailscale IP if configured
   - Reads BIND_ADDRESS from environment
   - Systemd override for Tailscale binding
   - Graceful degradation if VPN not available

**Application Directory Structure:**
```
/opt/website-builder/
├── app/                          # Application code
├── config/                       # Configuration files
│   └── pages/                    # Page configurations
├── assets/                       # Asset storage
│   ├── uploads/                  # Original uploads
│   └── processed/                # Optimized images
│       ├── 320/                  # Mobile variants
│       ├── 768/                  # Tablet variants
│       └── 1920/                 # Desktop variants
├── versions/                     # Version backups
├── logs/                         # Application logs
└── .env                          # Environment variables
```

**Environment Variables:**

Service sets the following environment variables:
- `NODE_ENV=production` - Production mode
- `PORT=3000` - Application port
- `BIND_ADDRESS` - IP address to bind to (Tailscale IP or 0.0.0.0)
- `CONFIG_DIR=/opt/website-builder/config` - Configuration directory
- `ASSETS_DIR=/opt/website-builder/assets` - Assets directory
- `PUBLIC_DIR=/var/www/html` - Public web root
- `VERSIONS_DIR=/opt/website-builder/versions` - Version backups
- `LOG_DIR=/opt/website-builder/logs` - Application logs

Additional variables loaded from `/opt/website-builder/.env`:
- `ANTHROPIC_API_KEY` - Claude API key
- `DOMAIN` - Website domain
- `SSL_EMAIL` - SSL certificate email
- `SESSION_SECRET` - Session encryption key (auto-generated)
- `ALLOWED_ORIGINS` - CORS allowed origins
- `MAX_REQUESTS_PER_MINUTE` - Rate limiting (default: 10)
- `MONTHLY_TOKEN_THRESHOLD` - Token usage threshold (default: 1000000)
- `LOG_LEVEL` - Logging level (default: info)
- `LOG_ROTATION_SIZE` - Log rotation size (default: 100MB)
- `LOG_RETENTION_DAYS` - Log retention period (default: 30)

**Service Management:**

A helper script is created at `/usr/local/bin/website-builder-service`:

```bash
# Start the service
website-builder-service start

# Stop the service
website-builder-service stop

# Restart the service
website-builder-service restart

# Check service status
website-builder-service status

# View logs in real-time
website-builder-service logs

# Enable service (start on boot)
website-builder-service enable

# Disable service (don't start on boot)
website-builder-service disable
```

Or use systemctl directly:
```bash
sudo systemctl start website-builder.service
sudo systemctl status website-builder.service
sudo journalctl -u website-builder.service -f
```

**Verification:**
After running the script, verify the configuration:

```bash
# Check service status
sudo systemctl status website-builder.service

# Check if service is enabled
sudo systemctl is-enabled website-builder.service

# View service configuration
sudo systemctl cat website-builder.service

# Check directory structure
ls -la /opt/website-builder/

# View environment file
sudo cat /opt/website-builder/.env
```

**Expected Output:**
```
Creating systemd service files for AI Website Builder...
========================================

✓ Tailscale IP detected: 100.x.x.x
✓ Systemd service file created
✓ Tailscale binding override created
✓ Application directory structure created
✓ Placeholder .env file created
✓ Systemd daemon reloaded
✓ Service enabled
✓ Service management helper created

========================================
Systemd service configuration complete!
========================================

Service Details:
  Service Name: website-builder.service
  Bind Address: 100.x.x.x
  Port: 3000

Service Features:
  ✓ Automatic restart on failure
  ✓ Restart delay: 10 seconds
  ✓ Memory limit: 512MB
  ✓ CPU quota: 80%
  ✓ Security hardening enabled
  ✓ Logging to systemd journal
  ✓ Enabled to start on boot
```

**Deployment Workflow:**

After configuring the service:

1. **Update .env file:**
   ```bash
   sudo nano /opt/website-builder/.env
   # Set ANTHROPIC_API_KEY, DOMAIN, etc.
   ```

2. **Deploy application code:**
   ```bash
   # Copy application files
   sudo cp -r app/* /opt/website-builder/app/
   
   # Or use git
   cd /opt/website-builder
   sudo git clone <repo-url> app
   ```

3. **Install dependencies:**
   ```bash
   cd /opt/website-builder/app
   sudo -u www-data npm install --production
   ```

4. **Start the service:**
   ```bash
   sudo website-builder-service start
   sudo website-builder-service status
   ```

**Troubleshooting:**

Service won't start:
```bash
# Check service status
sudo systemctl status website-builder.service

# View detailed logs
sudo journalctl -u website-builder.service -n 50

# Check if application code exists
ls -la /opt/website-builder/app/

# Check permissions
ls -la /opt/website-builder/
```

Service keeps restarting:
```bash
# View restart count
systemctl show website-builder.service --property=NRestarts

# Check logs for errors
sudo journalctl -u website-builder.service -p err

# Check if hitting memory limit
sudo journalctl -u website-builder.service | grep -i "memory"
```

Cannot access Builder Interface:
```bash
# Check if service is running
sudo systemctl status website-builder.service

# Check if listening on correct address
sudo ss -tlnp | grep 3000

# Check Tailscale connection
tailscale status
```

**Next Steps:**
After systemd configuration, complete:
1. Task 2.1: Initialize Node.js/TypeScript project
2. Task 2.2: Set up Express.js server (implement binding to BIND_ADDRESS)

### test-systemd-config.sh

Validates that systemd service is properly configured and all requirements are met.

**What it tests:**
- Service file exists and is valid
- Service is enabled (start on boot)
- Application directory structure exists
- .env file exists
- Service has correct user/group (www-data)
- Restart policy configured (on-failure)
- Restart delay configured (10s)
- Start limit configured (3 attempts in 5 minutes)
- Resource limits set (512MB RAM, 80% CPU)
- Security hardening enabled
- Logging to systemd journal configured
- Environment variables configured
- Tailscale binding override (if Tailscale configured)
- Helper script exists and is executable
- Service dependencies configured
- Directory permissions correct
- Requirements 1.5 met

**Requirements:**
- Systemd service must be configured (run configure-systemd.sh first)
- Root/sudo access

**Usage:**
```bash
sudo ./test-systemd-config.sh
```

**Expected Output (Success):**
```
Testing Systemd Service Configuration...
========================================

✓ Service file exists: /etc/systemd/system/website-builder.service
✓ Service file is valid
✓ Service is enabled (will start on boot)
✓ Application directory exists: /opt/website-builder
✓ All required subdirectories exist
✓ .env file exists
✓ Service configured with correct user/group (www-data)
✓ Restart policy configured (on-failure)
✓ Restart delay configured: 10s
✓ Start limit configured
✓ Resource limits configured (Memory: 512M, CPU: 80%)
✓ Security hardening configured
✓ Logging to systemd journal configured
✓ All required environment variables configured
✓ Tailscale binding override has correct IP: 100.x.x.x
✓ Helper script exists and is executable
✓ Service waits for network
✓ Systemd is aware of the service
✓ Application directory has correct ownership (www-data:www-data)

========================================
Test Summary
========================================

Passed: 20
Failed: 0

✓ All tests passed!

Requirements validated:
  ✓ Requirement 1.5: Systemd service for Builder Interface
  ✓ Automatic restart on failure
  ✓ Service logging configured

Service Management:
  Start:   website-builder-service start
  Stop:    website-builder-service stop
  Restart: website-builder-service restart
  Status:  website-builder-service status
  Logs:    website-builder-service logs
```

**Exit Codes:**
- 0: All tests passed
- 1: One or more tests failed

## Integration with Deployment Scripts

The configuration scripts can be integrated into the automated deployment process:

### CloudFormation
Add to the UserData section in `lightsail-stack.yaml`:
```yaml
# Configure NGINX
curl -o /tmp/configure-nginx.sh https://raw.githubusercontent.com/your-repo/main/infrastructure/scripts/configure-nginx.sh
chmod +x /tmp/configure-nginx.sh
/tmp/configure-nginx.sh

# Configure UFW Firewall
curl -o /tmp/configure-ufw.sh https://raw.githubusercontent.com/your-repo/main/infrastructure/scripts/configure-ufw.sh
chmod +x /tmp/configure-ufw.sh
/tmp/configure-ufw.sh
```

### Terraform
Add to the `user-data.sh` script:
```bash
# Configure NGINX
curl -o /tmp/configure-nginx.sh https://raw.githubusercontent.com/your-repo/main/infrastructure/scripts/configure-nginx.sh
chmod +x /tmp/configure-nginx.sh
/tmp/configure-nginx.sh

# Configure UFW Firewall
curl -o /tmp/configure-ufw.sh https://raw.githubusercontent.com/your-repo/main/infrastructure/scripts/configure-ufw.sh
chmod +x /tmp/configure-ufw.sh
/tmp/configure-ufw.sh
```

### Manual Deployment
Copy the scripts to the server and run:
```bash
# Copy scripts to server
scp infrastructure/scripts/configure-nginx.sh ubuntu@<server-ip>:~/
scp infrastructure/scripts/configure-ufw.sh ubuntu@<server-ip>:~/
scp infrastructure/scripts/configure-tailscale.sh ubuntu@<server-ip>:~/

# SSH to server
ssh ubuntu@<server-ip>

# Run scripts
sudo ./configure-nginx.sh
sudo ./configure-ufw.sh
sudo ./configure-tailscale.sh tskey-auth-XXXXXXXXXX
```

## Tailscale VPN Configuration

### configure-tailscale.sh

Installs and configures Tailscale VPN to provide secure access to the Builder Interface.

**What it does:**
- Installs Tailscale client from official repository
- Authenticates with Tailscale network using provided auth key
- Configures Builder Interface to bind only to Tailscale IP
- Creates systemd service override for VPN-only binding
- Verifies firewall configuration
- Displays access information and status

**Requirements:**
- Ubuntu/Debian-based system
- Root/sudo access
- Internet connection for package installation
- Tailscale auth key from https://login.tailscale.com/admin/settings/keys
- UFW must be configured first (run configure-ufw.sh)

**Usage:**
```bash
sudo ./configure-tailscale.sh <tailscale-auth-key>
```

**Example:**
```bash
sudo ./configure-tailscale.sh tskey-auth-k1234567890abcdef
```

**Security Details:**

1. **VPN-Only Access:**
   - Builder Interface (port 3000) only accessible through Tailscale VPN
   - Port 3000 NOT exposed to public internet
   - Implements Requirements 2.3 and 2.5

2. **Encrypted Tunnel:**
   - All traffic encrypted using WireGuard protocol
   - End-to-end encryption between devices
   - No public exposure of administrative interface

3. **Authentication:**
   - Tailscale authentication required to join network
   - Only authorized devices can access Builder Interface
   - Multi-factor authentication supported on Tailscale account

4. **Network Isolation:**
   - Complete separation between public (NGINX) and protected (Builder) components
   - Public website on ports 80/443
   - Builder Interface only on Tailscale network

**Configuration Files Created:**

1. `/opt/website-builder-tailscale.conf`
   - Contains Tailscale IP address
   - Builder Interface URL
   - Access instructions

2. `/etc/systemd/system/website-builder.service.d/tailscale-binding.conf`
   - Systemd service override
   - Sets BIND_ADDRESS environment variable
   - Ensures Builder Interface binds only to Tailscale IP

**Getting a Tailscale Auth Key:**

1. Go to https://login.tailscale.com/admin/settings/keys
2. Click "Generate auth key"
3. Options:
   - **Reusable**: Check if deploying multiple instances
   - **Ephemeral**: Uncheck (we want persistent devices)
   - **Preauthorized**: Check (auto-approve the device)
   - **Expiration**: Set based on your security policy
4. Copy the generated key (starts with `tskey-auth-`)

**Verification:**
After running the script, verify the configuration:

```bash
# Check Tailscale status
tailscale status

# Get Tailscale IP
tailscale ip -4

# Verify firewall allows Tailscale port
sudo ufw status | grep 41641

# Verify Builder Interface port is NOT exposed
sudo ufw status | grep 3000  # Should return nothing

# Check configuration file
cat /opt/website-builder-tailscale.conf
```

**Expected Output:**
```
Tailscale VPN Status:
  Tailscale IP: 100.x.x.x
  Builder Interface Port: 3000
  Builder Interface URL: http://100.x.x.x:3000

Access Instructions:
  1. Connect to Tailscale VPN on your client device
  2. Access Builder Interface at: http://100.x.x.x:3000
  3. The Builder Interface is NOT accessible from the public internet

Requirements validated:
  ✓ Requirement 2.3: Builder Interface accessible only through Tailscale VPN
  ✓ Requirement 2.5: System denies access to Builder Interface without Tailscale
```

**Accessing the Builder Interface:**

1. **Install Tailscale on your computer:**
   - macOS: `brew install tailscale`
   - Windows: Download from https://tailscale.com/download
   - Linux: Follow instructions at https://tailscale.com/download/linux

2. **Connect to Tailscale:**
   ```bash
   sudo tailscale up
   tailscale status
   ```

3. **Access Builder Interface:**
   - Open browser: `http://100.x.x.x:3000`
   - Replace `100.x.x.x` with the server's Tailscale IP

**Troubleshooting:**

Cannot connect to Tailscale:
```bash
# Check Tailscale service
sudo systemctl status tailscaled

# Check firewall
sudo ufw status | grep 41641

# Re-authenticate
sudo tailscale up --authkey=tskey-auth-XXXXXXXXXX

# View logs
sudo journalctl -u tailscaled -n 50
```

Cannot access Builder Interface:
```bash
# Verify connected to Tailscale
tailscale status

# Check Builder Interface is running
sudo systemctl status website-builder

# Verify binding
sudo ss -tlnp | grep 3000

# Should only show Tailscale IP (100.x.x.x), not 0.0.0.0
```

**Next Steps:**
After Tailscale configuration, complete:
1. Task 1.5: Set up Let's Encrypt SSL automation
2. Task 1.6: Create systemd service files (will use the Tailscale binding configuration)

### test-tailscale-config.sh

Validates that Tailscale VPN is properly configured and the Builder Interface is secure.

**What it tests:**
- Tailscale is installed and running
- Tailscale is authenticated
- Tailscale IP is assigned
- Firewall allows Tailscale port (41641)
- Builder Interface port (3000) is NOT exposed
- Builder Interface is not listening on public IP
- Configuration files exist
- Systemd override configuration exists
- Requirements 2.3 and 2.5 are met

**Requirements:**
- Tailscale must be configured (run configure-tailscale.sh first)
- Root/sudo access

**Usage:**
```bash
sudo ./test-tailscale-config.sh
```

**Expected Output (Success):**
```
Testing Tailscale VPN Configuration...
======================================

✓ Tailscale is installed
✓ Tailscale service is running
✓ Tailscale is authenticated
✓ Tailscale IP assigned: 100.x.x.x
✓ Firewall allows Tailscale port 41641
✓ Builder Interface port 3000 is not exposed (correct)
✓ Builder Interface is not listening on public IP
✓ Configuration file exists
✓ Systemd override configuration exists

======================================
All tests passed!

Requirements validated:
  ✓ Requirement 2.3: Builder Interface accessible only through Tailscale VPN
  ✓ Requirement 2.5: System denies access to Builder Interface without Tailscale

Tailscale Status:
[Tailscale network status displayed here]

Builder Interface Access:
  URL: http://100.x.x.x:3000
  Note: Only accessible when connected to Tailscale VPN
```

**Exit Codes:**
- 0: All tests passed
- 1: One or more tests failed
