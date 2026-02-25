# Tailscale VPN Configuration for AI Website Builder

## Overview

This document describes the Tailscale VPN configuration for the AI Website Builder application, implementing Requirements 2.3 and 2.5 from the specification.

## Security Architecture

The AI Website Builder uses Tailscale VPN to protect the Builder Interface from unauthorized access:

1. **Public-Facing Component**: Static website served by NGINX on ports 80/443 (accessible to everyone)
2. **Protected Component**: Builder Interface on port 3000 (accessible ONLY through Tailscale VPN)

### Network Security Model

```
Internet Users
   │
   ├─── Port 80/443 ────────────► NGINX (Public Website)
   │                               ✓ Accessible to everyone
   │
   └─── Port 3000 ──────────────► ✗ BLOCKED by firewall
                                   ✗ NOT accessible from internet

Tailscale VPN Users
   │
   └─── Tailscale Network ──────► Builder Interface (Port 3000)
                                   ✓ Accessible only through VPN
                                   ✓ Encrypted tunnel
                                   ✓ Authenticated users only
```

## Requirements Implementation

### Requirement 2.3: VPN-Only Access

**Requirement**: "THE Builder_Interface SHALL be accessible only through Tailscale VPN connections"

**Implementation**:
1. Builder Interface binds only to Tailscale IP address (not 0.0.0.0 or public IP)
2. Port 3000 is NOT exposed in UFW firewall
3. Systemd service configured to use Tailscale IP via environment variable

**Validation**:
- UFW status shows port 3000 is NOT allowed
- Builder Interface only listens on Tailscale IP (100.x.x.x)
- Public IP cannot access port 3000

### Requirement 2.5: Deny Without VPN

**Requirement**: "WHEN a user attempts to access the Builder_Interface without Tailscale, THEN THE System SHALL deny access"

**Implementation**:
1. Firewall blocks all traffic to port 3000 from public internet
2. Builder Interface does not listen on public IP addresses
3. Only Tailscale network can route to the Builder Interface

**Validation**:
- Attempting to access http://public-ip:3000 fails (connection refused)
- Attempting to access http://tailscale-ip:3000 without VPN fails (no route)
- Only works when connected to Tailscale: http://tailscale-ip:3000

## Tailscale Overview

### What is Tailscale?

Tailscale is a zero-config VPN that creates a secure network between your devices:

- **Encrypted**: All traffic is encrypted using WireGuard
- **Authenticated**: Only authorized devices can join your network
- **Zero-config**: No complex VPN server setup required
- **Cross-platform**: Works on Linux, macOS, Windows, iOS, Android

### How It Works

1. Each device gets a Tailscale IP address (100.x.x.x range)
2. Devices can communicate directly using these IPs
3. Traffic is encrypted end-to-end
4. No need to expose ports to the public internet

## Installation and Configuration

### Prerequisites

Before configuring Tailscale, you need:

1. **Tailscale Account**: Sign up at https://tailscale.com/
2. **Auth Key**: Generate from https://login.tailscale.com/admin/settings/keys
   - Choose "Reusable" if you plan to deploy multiple instances
   - Set an expiration time (or make it non-expiring for production)
3. **UFW Configured**: Run `configure-ufw.sh` first to set up firewall

### Configuration Steps

#### 1. Generate Tailscale Auth Key

1. Go to https://login.tailscale.com/admin/settings/keys
2. Click "Generate auth key"
3. Options:
   - **Reusable**: Check if you want to use the key for multiple devices
   - **Ephemeral**: Uncheck (we want persistent devices)
   - **Preauthorized**: Check (auto-approve the device)
   - **Expiration**: Set based on your security policy
4. Copy the generated key (starts with `tskey-auth-`)

#### 2. Run Configuration Script

```bash
# Copy script to server
scp infrastructure/scripts/configure-tailscale.sh ubuntu@<server-ip>:~/

# SSH to server
ssh ubuntu@<server-ip>

# Run configuration script
sudo ./configure-tailscale.sh tskey-auth-XXXXXXXXXX
```

The script will:
1. Install Tailscale from official repository
2. Authenticate with your Tailscale network
3. Configure Builder Interface to bind only to Tailscale IP
4. Verify firewall configuration
5. Display access information

#### 3. Verify Configuration

```bash
# Run test script
sudo ./test-tailscale-config.sh
```

Expected output:
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
```

## Accessing the Builder Interface

### From Your Computer

1. **Install Tailscale** on your computer:
   - macOS: `brew install tailscale` or download from https://tailscale.com/download
   - Windows: Download from https://tailscale.com/download
   - Linux: Follow instructions at https://tailscale.com/download/linux

2. **Connect to Tailscale**:
   ```bash
   # Start Tailscale
   sudo tailscale up
   
   # Check status
   tailscale status
   ```

3. **Find the server's Tailscale IP**:
   ```bash
   # On the server
   tailscale ip -4
   
   # Or from your computer
   tailscale status | grep ai-website-builder
   ```

4. **Access the Builder Interface**:
   - Open browser: `http://100.x.x.x:3000`
   - Replace `100.x.x.x` with the actual Tailscale IP

### From Mobile Devices

1. Install Tailscale app from App Store (iOS) or Play Store (Android)
2. Sign in with your Tailscale account
3. Connect to your Tailscale network
4. Access `http://100.x.x.x:3000` in mobile browser

## Configuration Files

### Tailscale Configuration

**Location**: `/opt/website-builder-tailscale.conf`

This file contains:
- Tailscale IP address
- Builder Interface port
- Builder Interface URL
- Access instructions

Example:
```bash
# Tailscale VPN Configuration for AI Website Builder
TAILSCALE_IP=100.x.x.x
BUILDER_PORT=3000
BUILDER_URL=http://100.x.x.x:3000

# Access Instructions:
# 1. Ensure you are connected to the Tailscale network
# 2. Access the Builder Interface at: http://100.x.x.x:3000
# 3. The Builder Interface is NOT accessible from the public internet
```

### Systemd Service Override

**Location**: `/etc/systemd/system/website-builder.service.d/tailscale-binding.conf`

This file configures the Builder Interface service to bind only to the Tailscale IP:

```ini
[Service]
# Bind Builder Interface only to Tailscale IP
# This ensures the service is only accessible through VPN
Environment="BIND_ADDRESS=100.x.x.x"
Environment="PORT=3000"
```

The application code should read these environment variables:
```javascript
const bindAddress = process.env.BIND_ADDRESS || '0.0.0.0';
const port = process.env.PORT || 3000;

app.listen(port, bindAddress, () => {
  console.log(`Builder Interface listening on ${bindAddress}:${port}`);
});
```

## Security Considerations

### Defense in Depth

The Tailscale configuration is part of a multi-layered security approach:

1. **Network Layer**: UFW firewall blocks port 3000 from public internet
2. **VPN Layer**: Tailscale provides encrypted tunnel and authentication
3. **Application Layer**: Builder Interface binds only to Tailscale IP
4. **Access Control**: Tailscale ACLs can further restrict access

### Tailscale Access Control Lists (ACLs)

You can configure ACLs in Tailscale to further restrict access:

1. Go to https://login.tailscale.com/admin/acls
2. Define which users/devices can access the Builder Interface
3. Example ACL:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["group:admins"],
      "dst": ["tag:website-builder:3000"]
    }
  ],
  "groups": {
    "group:admins": ["user@example.com"]
  },
  "tagOwners": {
    "tag:website-builder": ["user@example.com"]
  }
}
```

### Best Practices

1. **Use Reusable Keys Carefully**: Reusable auth keys can be used multiple times. Store them securely.
2. **Set Key Expiration**: Auth keys should expire after a reasonable time.
3. **Enable MFA**: Enable multi-factor authentication on your Tailscale account.
4. **Regular Audits**: Review connected devices regularly in Tailscale admin panel.
5. **Revoke Unused Devices**: Remove devices that are no longer needed.

## Operational Procedures

### Checking Tailscale Status

```bash
# Check if Tailscale is running
sudo systemctl status tailscaled

# Check Tailscale network status
tailscale status

# Get Tailscale IP
tailscale ip -4

# Check connectivity to other devices
tailscale ping <device-name>
```

### Restarting Tailscale

```bash
# Restart Tailscale service
sudo systemctl restart tailscaled

# Reconnect to Tailscale network
sudo tailscale up
```

### Viewing Tailscale Logs

```bash
# View Tailscale service logs
sudo journalctl -u tailscaled -f

# View recent logs
sudo journalctl -u tailscaled --since "1 hour ago"
```

### Updating Tailscale

```bash
# Update package list
sudo apt-get update

# Upgrade Tailscale
sudo apt-get upgrade tailscale

# Restart service
sudo systemctl restart tailscaled
```

## Troubleshooting

### Cannot Connect to Tailscale

**Symptom**: `tailscale up` fails or `tailscale status` shows "Logged out"

**Solutions**:
1. Check if Tailscale service is running:
   ```bash
   sudo systemctl status tailscaled
   ```

2. Check firewall allows Tailscale port:
   ```bash
   sudo ufw status | grep 41641
   ```

3. Re-authenticate with a new auth key:
   ```bash
   sudo tailscale up --authkey=tskey-auth-XXXXXXXXXX
   ```

4. Check Tailscale logs:
   ```bash
   sudo journalctl -u tailscaled -n 50
   ```

### Cannot Access Builder Interface

**Symptom**: Cannot access `http://100.x.x.x:3000` even when connected to Tailscale

**Solutions**:
1. Verify you're connected to Tailscale:
   ```bash
   tailscale status
   ```

2. Check if Builder Interface is running:
   ```bash
   sudo systemctl status website-builder
   ```

3. Verify Builder Interface is listening on Tailscale IP:
   ```bash
   sudo ss -tlnp | grep 3000
   ```

4. Check if firewall is blocking (it shouldn't be):
   ```bash
   sudo ufw status | grep 3000
   ```

5. Test connectivity:
   ```bash
   # From your computer (connected to Tailscale)
   curl http://100.x.x.x:3000
   ```

### Builder Interface Accessible from Public Internet

**Symptom**: Can access Builder Interface from public IP (SECURITY ISSUE!)

**Solutions**:
1. **IMMEDIATELY** check firewall:
   ```bash
   sudo ufw status | grep 3000
   ```
   Port 3000 should NOT appear in the output.

2. Check what IPs the Builder Interface is listening on:
   ```bash
   sudo ss -tlnp | grep 3000
   ```
   Should only show Tailscale IP (100.x.x.x), not 0.0.0.0 or public IP.

3. Verify systemd override is in place:
   ```bash
   cat /etc/systemd/system/website-builder.service.d/tailscale-binding.conf
   ```

4. Restart the Builder Interface service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart website-builder
   ```

5. Run the test script:
   ```bash
   sudo ./test-tailscale-config.sh
   ```

### Tailscale IP Changed

**Symptom**: Tailscale IP address changed after restart

**Solutions**:
1. Tailscale IPs are generally stable, but can change in some cases.

2. Update the configuration:
   ```bash
   # Re-run the configuration script
   sudo ./configure-tailscale.sh tskey-auth-XXXXXXXXXX
   ```

3. Restart the Builder Interface:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart website-builder
   ```

4. To prevent IP changes, use Tailscale's "Disable key expiry" feature for the device.

## Monitoring and Maintenance

### Regular Checks

Perform these checks regularly:

```bash
# 1. Verify Tailscale is running
sudo systemctl status tailscaled

# 2. Check Tailscale network status
tailscale status

# 3. Verify firewall configuration
sudo ufw status | grep -E "3000|41641"

# 4. Check Builder Interface is only on Tailscale IP
sudo ss -tlnp | grep 3000

# 5. Run automated tests
sudo ./test-tailscale-config.sh
```

### Backup and Recovery

**Configuration Backup**:
```bash
# Backup Tailscale configuration
sudo cp /opt/website-builder-tailscale.conf /opt/website-builder-tailscale.conf.backup

# Backup systemd override
sudo cp -r /etc/systemd/system/website-builder.service.d /etc/systemd/system/website-builder.service.d.backup
```

**Recovery**:
If Tailscale configuration is lost:
1. Re-run `configure-tailscale.sh` with a new auth key
2. Restart the Builder Interface service
3. Verify with `test-tailscale-config.sh`

## Integration with Other Components

### With UFW Firewall (Task 1.3)

- UFW must allow Tailscale port 41641/udp
- UFW must NOT allow Builder Interface port 3000
- Run `configure-ufw.sh` before `configure-tailscale.sh`

### With Builder Interface (Task 1.6)

- Builder Interface service must read BIND_ADDRESS environment variable
- Service should bind to Tailscale IP, not 0.0.0.0
- Systemd override provides the correct IP

### With NGINX (Task 1.2)

- NGINX serves public content on ports 80/443
- NGINX does NOT proxy to Builder Interface
- Complete separation between public and protected components

## Compliance Summary

| Requirement | Description | Implementation | Status |
|-------------|-------------|----------------|--------|
| 2.3 | Builder Interface VPN-only | Binds to Tailscale IP only | ✅ Complete |
| 2.5 | Deny without VPN | Firewall blocks port 3000, no public binding | ✅ Complete |

## References

- [Tailscale Documentation](https://tailscale.com/kb/)
- [Tailscale Installation Guide](https://tailscale.com/kb/1031/install-linux/)
- [Tailscale ACLs](https://tailscale.com/kb/1018/acls/)
- [WireGuard Protocol](https://www.wireguard.com/)
- AI Website Builder Requirements Document (Section 2: Network Security and Access Control)
- AI Website Builder Design Document (Section: File System Organization and Security)

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2024-02-23 | 1.0 | Initial Tailscale VPN configuration implementation | System |
