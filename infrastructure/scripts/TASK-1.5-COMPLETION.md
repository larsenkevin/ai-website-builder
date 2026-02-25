# Task 1.5 Completion: Let's Encrypt SSL Automation

## Overview

This document describes the implementation of Task 1.5: Set up Let's Encrypt SSL automation for the AI Website Builder project.

## Requirements Addressed

- **Requirement 3.1**: SSL/TLS certificates from Let's Encrypt
- **Requirement 3.2**: Automatic certificate renewal
- **Requirement 3.3**: All public content served over HTTPS
- **Requirement 3.4**: Renewal retry logic with exponential backoff
- **Requirement 3.5**: Certificate expiration monitoring (30-day threshold)

## Implementation Details

### 1. Main Configuration Script

**File**: `infrastructure/scripts/configure-ssl.sh`

This script performs the complete SSL automation setup:

1. **Installs certbot** - The official Let's Encrypt client
2. **Obtains SSL certificate** - Uses webroot plugin for domain validation
3. **Configures NGINX for HTTPS** - Updates NGINX to serve content over HTTPS with proper security headers
4. **Creates renewal script** - Implements retry logic with exponential backoff
5. **Creates monitoring script** - Checks certificate expiration and triggers renewal when needed
6. **Sets up cron jobs** - Automates renewal and monitoring tasks

**Usage**:
```bash
sudo DOMAIN=example.com SSL_EMAIL=admin@example.com ./configure-ssl.sh
```

**Environment Variables**:
- `DOMAIN`: Your website domain (required)
- `SSL_EMAIL`: Email for Let's Encrypt notifications (required)

### 2. Renewal Script with Retry Logic

**File**: `/usr/local/bin/ssl-renewal-with-retry.sh`

Implements **Requirement 3.4** - Renewal retry logic with exponential backoff:

- **Maximum retries**: 5 attempts
- **Initial delay**: 60 seconds (1 minute)
- **Backoff strategy**: Exponential (doubles each retry)
  - Attempt 1: Immediate
  - Attempt 2: Wait 60 seconds
  - Attempt 3: Wait 120 seconds (2 minutes)
  - Attempt 4: Wait 240 seconds (4 minutes)
  - Attempt 5: Wait 480 seconds (8 minutes)

**Features**:
- Logs all renewal attempts
- Automatically reloads NGINX after successful renewal
- Returns appropriate exit codes for monitoring

### 3. Certificate Expiration Monitor

**File**: `/usr/local/bin/ssl-monitor.sh`

Implements **Requirement 3.5** - Certificate expiration monitoring:

- **Threshold**: 30 days before expiration
- **Action**: Automatically triggers renewal when threshold is reached
- **Logging**: Records all checks and actions

**Features**:
- Checks certificate expiration date using OpenSSL
- Calculates days until expiration
- Triggers renewal script when within 30-day threshold
- Logs all monitoring activities

### 4. Automated Scheduling

**File**: `/etc/cron.d/ssl-automation`

Implements **Requirement 3.2** - Automatic certificate renewal:

**Cron Jobs**:
1. **Certificate Monitoring**: Daily at 3:00 AM
   ```
   0 3 * * * root /usr/local/bin/ssl-monitor.sh
   ```

2. **Renewal Attempts**: Twice daily at 2:00 AM and 2:00 PM
   ```
   0 2,14 * * * root /usr/local/bin/ssl-renewal-with-retry.sh
   ```

**Note**: Certbot only renews certificates when they are within 30 days of expiration, so running renewal checks twice daily is safe and ensures timely renewal.

### 5. NGINX SSL Configuration

Implements **Requirement 3.3** - All public content served over HTTPS:

**Security Features**:
- HTTP to HTTPS redirect (301 permanent redirect)
- TLS 1.2 and 1.3 only (no older protocols)
- Strong cipher suites
- HSTS (HTTP Strict Transport Security) header
- Security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)
- SSL session caching
- OCSP stapling

**Configuration Highlights**:
```nginx
# HTTP server - redirect to HTTPS
server {
    listen 80;
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    ssl_certificate /etc/letsencrypt/live/DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    # ... additional security settings
}
```

### 6. Logging

All SSL automation activities are logged to `/var/log/ssl-automation/`:

- `renewal.log` - Certificate renewal attempts and results
- `monitor.log` - Certificate expiration checks

**Log Format**:
```
[2024-02-23 15:30:00] Starting certificate renewal process
[2024-02-23 15:30:05] SUCCESS: Certificate renewed successfully
[2024-02-23 15:30:06] SUCCESS: NGINX reloaded with new certificate
```

## Testing

### Test Script

**File**: `infrastructure/scripts/test-ssl-config.sh`

Comprehensive test suite that validates:

1. Certbot installation
2. Renewal script existence and executability
3. Monitor script existence and executability
4. Cron job configuration
5. Log directory and files
6. NGINX SSL configuration
7. HTTPS redirect configuration
8. SSL protocols and security headers
9. Retry logic implementation
10. Exponential backoff implementation
11. 30-day threshold configuration
12. Certificate validity (if certificate exists)

**Usage**:
```bash
sudo ./test-ssl-config.sh
```

**Expected Output**:
```
=== SSL Configuration Test Suite ===

Testing: Certbot installed... PASS
Testing: Renewal script exists... PASS
Testing: Renewal script is executable... PASS
...
Testing: Certificate is valid... PASS

=== Test Summary ===
Passed: 22
Failed: 0

✓ All tests passed!
```

## Deployment Instructions

### Prerequisites

1. **Domain configured**: DNS A record pointing to server IP
2. **NGINX installed**: Task 1.2 must be completed
3. **Firewall configured**: Ports 80 and 443 must be open (Task 1.3)
4. **Root access**: Script must be run as root

### Step-by-Step Deployment

1. **Set environment variables**:
   ```bash
   export DOMAIN=yourdomain.com
   export SSL_EMAIL=admin@yourdomain.com
   ```

2. **Run configuration script**:
   ```bash
   sudo -E ./configure-ssl.sh
   ```

3. **Verify installation**:
   ```bash
   sudo ./test-ssl-config.sh
   ```

4. **Test HTTPS access**:
   ```bash
   curl -I https://yourdomain.com
   ```

5. **Verify certificate**:
   ```bash
   openssl s_client -connect yourdomain.com:443 -servername yourdomain.com < /dev/null
   ```

### Troubleshooting

**Issue**: Certificate acquisition fails

**Solution**:
- Verify DNS is correctly configured: `dig yourdomain.com`
- Ensure port 80 is accessible: `curl http://yourdomain.com/.well-known/acme-challenge/test`
- Check NGINX is running: `systemctl status nginx`
- Review certbot logs: `tail -f /var/log/letsencrypt/letsencrypt.log`

**Issue**: Renewal fails

**Solution**:
- Check renewal logs: `tail -f /var/log/ssl-automation/renewal.log`
- Test renewal manually: `certbot renew --dry-run`
- Verify NGINX configuration: `nginx -t`
- Ensure webroot is accessible: `ls -la /var/www/html/.well-known/acme-challenge/`

**Issue**: Certificate not renewing automatically

**Solution**:
- Verify cron jobs: `cat /etc/cron.d/ssl-automation`
- Check cron service: `systemctl status cron`
- Review monitor logs: `tail -f /var/log/ssl-automation/monitor.log`
- Test monitor script manually: `sudo DOMAIN=yourdomain.com /usr/local/bin/ssl-monitor.sh`

## Manual Operations

### Force Certificate Renewal

```bash
sudo certbot renew --force-renewal
```

### Test Renewal (Dry Run)

```bash
sudo certbot renew --dry-run
```

### Check Certificate Expiration

```bash
sudo openssl x509 -enddate -noout -in /etc/letsencrypt/live/yourdomain.com/cert.pem
```

### View Certificate Details

```bash
sudo certbot certificates
```

### Manually Trigger Renewal Script

```bash
sudo /usr/local/bin/ssl-renewal-with-retry.sh
```

### Manually Trigger Monitor Script

```bash
sudo DOMAIN=yourdomain.com /usr/local/bin/ssl-monitor.sh
```

## Security Considerations

1. **Certificate Storage**: Certificates are stored in `/etc/letsencrypt/` with restricted permissions
2. **Private Key Protection**: Private keys are only readable by root
3. **HTTPS Enforcement**: All HTTP traffic is redirected to HTTPS
4. **Modern TLS**: Only TLS 1.2 and 1.3 are enabled
5. **HSTS**: Browsers will remember to use HTTPS for 1 year
6. **Security Headers**: Additional headers protect against common attacks

## Maintenance

### Regular Tasks

1. **Monitor logs**: Check `/var/log/ssl-automation/` weekly
2. **Verify renewals**: Ensure certificates are being renewed automatically
3. **Test HTTPS**: Periodically test HTTPS access and certificate validity
4. **Update certbot**: Keep certbot updated with system updates

### Certificate Lifecycle

- **Issued**: Valid for 90 days
- **Renewal window**: 30 days before expiration
- **Automatic renewal**: Attempted twice daily
- **Retry logic**: Up to 5 attempts with exponential backoff
- **Monitoring**: Daily expiration checks

## Integration with Other Tasks

### Dependencies

- **Task 1.2**: NGINX must be installed and configured
- **Task 1.3**: Firewall must allow ports 80 and 443

### Next Steps

After completing Task 1.5, proceed to:

1. **Task 1.6**: Create systemd service files for the Builder Interface
2. **Task 2.x**: Backend project setup and core infrastructure

## Files Created

1. `infrastructure/scripts/configure-ssl.sh` - Main configuration script
2. `infrastructure/scripts/test-ssl-config.sh` - Test suite
3. `/usr/local/bin/ssl-renewal-with-retry.sh` - Renewal script with retry logic
4. `/usr/local/bin/ssl-monitor.sh` - Certificate expiration monitor
5. `/etc/cron.d/ssl-automation` - Cron job configuration
6. `/var/log/ssl-automation/renewal.log` - Renewal log file
7. `/var/log/ssl-automation/monitor.log` - Monitor log file

## Requirements Validation

| Requirement | Implementation | Status |
|-------------|----------------|--------|
| 3.1 - Obtain SSL/TLS certificates from Let's Encrypt | Certbot with webroot plugin | ✓ Complete |
| 3.2 - Automatically renew certificates before expiration | Cron jobs run twice daily | ✓ Complete |
| 3.3 - Serve all public content over HTTPS | NGINX configured with HTTPS and HTTP redirect | ✓ Complete |
| 3.4 - Retry with exponential backoff on renewal failure | Renewal script with 5 retries, exponential backoff | ✓ Complete |
| 3.5 - Monitor certificate expiration (30-day threshold) | Monitor script checks daily, triggers renewal at 30 days | ✓ Complete |

## Conclusion

Task 1.5 is complete. The SSL automation system is fully implemented with:

- ✓ Automatic certificate acquisition from Let's Encrypt
- ✓ Automatic renewal with retry logic and exponential backoff
- ✓ Certificate expiration monitoring with 30-day threshold
- ✓ HTTPS enforcement for all public content
- ✓ Comprehensive logging and monitoring
- ✓ Robust error handling and recovery

The system requires no manual intervention for certificate management and will automatically renew certificates before expiration.
