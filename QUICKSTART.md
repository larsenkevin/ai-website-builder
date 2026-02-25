# Quick Start Deployment Guide

Deploy the AI Website Builder on a fresh Ubuntu VM in minutes with a single command.

## Prerequisites

Before you begin, ensure you have:

- ✅ **Ubuntu VM**: A fresh Ubuntu 22.04 LTS virtual machine on any cloud provider (AWS, GCP, Azure, DigitalOcean, etc.)
- ✅ **Root SSH Access**: You must be logged into the VM as root via SSH
- ✅ **Domain Name**: A registered domain name pointing to your VM's IP address
- ✅ **Claude API Key**: An API key from Anthropic for Claude AI ([Get one here](https://console.anthropic.com/))
- ✅ **Tailscale Account**: A free Tailscale account for secure networking ([Sign up here](https://tailscale.com/))

## Deployment

### Step 1: Create a VM Snapshot (Recommended)

Before deploying, create a snapshot of your VM through your cloud provider's dashboard. This allows easy recovery if anything goes wrong.

### Step 2: Run the Deployment Script

SSH into your Ubuntu VM as root and run:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/YOUR_REPO/main/deploy.sh | bash
```

### Step 3: Provide Configuration

The script will prompt you for:

1. **Claude API Key**: Your Anthropic API key (starts with `sk-ant-`)
2. **Domain Name**: Your registered domain (e.g., `mysite.example.com`)
3. **Tailscale Email**: The email address for your Tailscale account

### Step 4: Complete Browser Authentication

When prompted, the script will display a URL for Tailscale authentication:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Browser authentication required
Please open this URL: https://login.tailscale.com/...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Open the URL in your browser, complete the authentication, and the script will continue automatically.

### Step 5: Deployment Complete!

Once finished, you'll see a success message with:
- Access URL for the AI Website Builder
- QR codes for end-user access
- Log file location for troubleshooting

## End User Access

### For End Users (Mobile Devices)

Share the generated QR codes with your end users:

1. **First QR Code**: Scan to install the Tailscale app from the app store
2. **Second QR Code**: After installing Tailscale and logging in, scan to access the AI Website Builder

### For End Users (Desktop)

1. Install Tailscale from [tailscale.com/download](https://tailscale.com/download)
2. Log in with the same Tailscale account
3. Access the AI Website Builder at the provided URL

## Updating Configuration

To update your Claude API key, domain, or Tailscale settings:

```bash
cd /opt/ai-website-builder
./deploy.sh
```

The script will detect the existing installation and allow you to update individual values. Press Enter to keep existing values unchanged.

## Troubleshooting

### Deployment Script Fails

**Check the log file for detailed error information:**
```bash
cat /var/log/ai-website-builder-deploy.log
```

### Domain Not Accessible

**Verify DNS is configured correctly:**
```bash
dig +short your-domain.com
```

The output should show your VM's IP address. If not, update your DNS records and wait for propagation (can take up to 48 hours).

### SSL Certificate Fails

**Ensure your domain points to the VM before running the script:**
- DNS must be configured and propagated
- Ports 80 and 443 must be accessible from the internet
- No other web server should be running on these ports

**To retry SSL certificate acquisition:**
```bash
certbot certonly --nginx -d your-domain.com
systemctl restart nginx
```

### Service Won't Start

**Check service status and logs:**
```bash
systemctl status ai-website-builder
journalctl -u ai-website-builder -n 50
```

**Common issues:**
- Invalid Claude API key: Update in `/etc/ai-website-builder/config.env` and restart
- Port 3000 already in use: Stop conflicting service or change port in configuration
- Missing dependencies: Re-run deployment script to install missing packages

### Tailscale Authentication Timeout

**If authentication times out:**
1. Check that you opened the correct URL in your browser
2. Verify you completed the authentication flow
3. Run `tailscale status` to check connection
4. If needed, run `tailscale up` to re-authenticate

### QR Codes Not Displaying

**QR codes are saved as PNG files even if terminal display fails:**
```bash
ls -la /etc/ai-website-builder/qr-codes/
```

Transfer these files to your local machine to share with end users:
```bash
scp root@your-vm:/etc/ai-website-builder/qr-codes/*.png .
```

### Permission Denied Errors

**Ensure you're running as root:**
```bash
sudo su -
```

The deployment script requires root access to install packages and configure system services.

### Out of Disk Space

**Check available disk space:**
```bash
df -h
```

The deployment requires at least 10GB of free space. If needed, resize your VM's disk through your cloud provider.

## System Requirements

- **OS**: Ubuntu 22.04 LTS (other versions may work but are not tested)
- **RAM**: Minimum 2GB, recommended 4GB or more
- **Disk**: Minimum 10GB free space
- **Network**: Public IP address with ports 80, 443, and 22 accessible

## Security Notes

- All credentials are stored securely in `/etc/ai-website-builder/config.env` with 600 permissions
- The AI Website Builder is accessible only through Tailscale (private network)
- SSL/TLS certificates are automatically configured for your domain
- Firewall rules are configured to allow only necessary ports

## Getting Help

- **Log File**: `/var/log/ai-website-builder-deploy.log`
- **Configuration**: `/etc/ai-website-builder/config.env`
- **Service Logs**: `journalctl -u ai-website-builder`
- **Tailscale Status**: `tailscale status`

For additional support, check the main repository documentation or open an issue.
