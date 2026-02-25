# UFW Firewall Configuration for AI Website Builder

## Overview

This document describes the UFW (Uncomplicated Firewall) configuration for the AI Website Builder application, implementing Requirements 2.1 and 2.2 from the specification.

## Security Architecture

The AI Website Builder uses a two-component security model:

1. **Public-Facing Component**: Static website served by NGINX on ports 80/443
2. **Protected Component**: Builder Interface accessible only via Tailscale VPN

### Network Security Layers

```
Internet
   │
   ├─── Port 80 (HTTP) ────────────► NGINX (Public Website)
   ├─── Port 443 (HTTPS) ──────────► NGINX (Public Website)
   │
   └─── Port 41641 (Tailscale) ───► VPN Tunnel
                                       │
                                       └─► Builder Interface (Port 3000)
```

## Firewall Rules

### Allowed Inbound Traffic

| Port | Protocol | Service | Purpose | Requirement |
|------|----------|---------|---------|-------------|
| 22 | TCP | SSH | Server management | Infrastructure |
| 80 | TCP | HTTP | Public website | 2.1 |
| 443 | TCP | HTTPS | Public website (secure) | 2.1 |
| 41641 | UDP | Tailscale | VPN access to Builder | 2.1 |

### Default Policies

- **Incoming**: DENY (all inbound traffic blocked by default) - Requirement 2.2
- **Outgoing**: ALLOW (server can make outbound connections)
- **Routed**: DISABLED (no routing between interfaces)

### Blocked Traffic

All other inbound traffic is blocked by default, including:
- Port 3000 (Builder Interface) - Only accessible via VPN
- All other ports and protocols

## Implementation

### Configuration Script

The `configure-ufw.sh` script implements the firewall rules:

```bash
# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow required ports
ufw allow 22/tcp comment 'SSH access'
ufw allow 80/tcp comment 'HTTP web traffic'
ufw allow 443/tcp comment 'HTTPS web traffic'
ufw allow 41641/udp comment 'Tailscale VPN'

# Enable firewall
ufw --force enable
```

### Validation

The `test-ufw-config.sh` script validates the configuration:

1. Verifies UFW is installed and enabled
2. Checks default policies are correct
3. Confirms required ports are allowed
4. Ensures Builder Interface port is NOT exposed
5. Validates requirements 2.1 and 2.2 are met

## Security Considerations

### Builder Interface Protection

The Builder Interface (port 3000) is **intentionally NOT exposed** to the internet:

- ✅ Only accessible through Tailscale VPN
- ✅ Provides authentication and encryption via VPN
- ✅ Prevents unauthorized access to administrative functions
- ✅ Meets Requirement 2.3: "Builder Interface SHALL be accessible only through Tailscale VPN"

### Defense in Depth

The firewall is one layer in a multi-layered security approach:

1. **Network Layer**: UFW blocks unwanted traffic
2. **VPN Layer**: Tailscale provides encrypted tunnel and authentication
3. **Application Layer**: Builder Interface requires authentication
4. **File System Layer**: Configuration files protected with proper permissions

### SSH Access

Port 22 (SSH) is allowed to prevent lockout during configuration:

- Required for initial server setup
- Used for deployment and maintenance
- Should be further restricted using:
  - Key-based authentication only (disable password auth)
  - fail2ban for brute-force protection
  - IP whitelisting if possible

## Operational Procedures

### Initial Setup

1. Run the configuration script:
   ```bash
   sudo ./configure-ufw.sh
   ```

2. Verify the configuration:
   ```bash
   sudo ./test-ufw-config.sh
   ```

3. Check UFW status:
   ```bash
   sudo ufw status verbose
   ```

### Monitoring

Regular monitoring tasks:

```bash
# Check firewall status
sudo ufw status verbose

# View firewall logs
sudo tail -f /var/log/ufw.log

# Check for blocked connections
sudo grep -i "UFW BLOCK" /var/log/ufw.log
```

### Troubleshooting

#### Locked Out of SSH

If you lose SSH access:

1. Use AWS Lightsail browser-based SSH terminal
2. Check UFW status: `sudo ufw status`
3. Ensure port 22 is allowed: `sudo ufw allow 22/tcp`
4. If needed, temporarily disable: `sudo ufw disable`

#### Website Not Accessible

If the public website is not accessible:

1. Check if ports 80/443 are allowed:
   ```bash
   sudo ufw status | grep -E "80|443"
   ```

2. Verify NGINX is running:
   ```bash
   sudo systemctl status nginx
   ```

3. Check firewall logs for blocked connections:
   ```bash
   sudo grep -i "DPT=80\|DPT=443" /var/log/ufw.log
   ```

#### Builder Interface Not Accessible via VPN

If the Builder Interface is not accessible through Tailscale:

1. Verify Tailscale is running:
   ```bash
   sudo tailscale status
   ```

2. Check if port 41641 is allowed:
   ```bash
   sudo ufw status | grep 41641
   ```

3. Ensure port 3000 is NOT exposed:
   ```bash
   sudo ufw status | grep 3000
   # Should return nothing
   ```

### Modifying Rules

To add a new rule:
```bash
sudo ufw allow <port>/<protocol> comment 'Description'
```

To delete a rule:
```bash
# List rules with numbers
sudo ufw status numbered

# Delete by number
sudo ufw delete <number>
```

To reload UFW:
```bash
sudo ufw reload
```

## Compliance

### Requirements Validation

| Requirement | Description | Implementation | Status |
|-------------|-------------|----------------|--------|
| 2.1 | Allow ports 80, 443, Tailscale | `ufw allow 80/tcp`, `ufw allow 443/tcp`, `ufw allow 41641/udp` | ✅ Complete |
| 2.2 | Block all other inbound traffic | `ufw default deny incoming` | ✅ Complete |
| 2.3 | Builder Interface VPN-only | Port 3000 not exposed, Tailscale port allowed | ✅ Complete |
| 2.4 | Static Server publicly accessible | Ports 80/443 allowed | ✅ Complete |

### Testing

The configuration can be validated using:

```bash
# Run automated tests
sudo ./test-ufw-config.sh

# Manual verification
sudo ufw status verbose

# Check specific ports
sudo ufw status | grep -E "22|80|443|41641|3000"
```

Expected output:
```
22/tcp                     ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
41641/udp                  ALLOW IN    Anywhere
```

Port 3000 should NOT appear in the output.

## References

- [UFW Documentation](https://help.ubuntu.com/community/UFW)
- [Tailscale Firewall Documentation](https://tailscale.com/kb/1082/firewall-ports/)
- AI Website Builder Requirements Document (Section 2: Network Security and Access Control)
- AI Website Builder Design Document (Section: File System Organization and Security)

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2024-02-23 | 1.0 | Initial UFW configuration implementation | System |

