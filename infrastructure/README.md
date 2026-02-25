# AI Website Builder - Infrastructure

This directory contains infrastructure-as-code for deploying the AI Website Builder on AWS Lightsail.

## Deployment Options

Choose one of the following deployment methods:

### Option 1: Terraform (Recommended)

Terraform provides better state management and more features.

**Location**: `terraform/`

**Quick Start**:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

See [terraform/README.md](terraform/README.md) for detailed instructions.

### Option 2: CloudFormation

Native AWS solution, good for AWS-centric workflows.

**Location**: `cloudformation/`

**Quick Start**:
```bash
cd cloudformation
cp parameters.json.example parameters.json
# Edit parameters.json with your values
./deploy-cloudformation.sh create
./configure-firewall.sh
```

See [cloudformation/README.md](cloudformation/README.md) for detailed instructions.

## Infrastructure Overview

### Resources Created

Both deployment methods create:

1. **AWS Lightsail Instance**
   - Bundle: nano_2_0 (1 CPU, 1GB RAM)
   - OS: Ubuntu 22.04 LTS
   - Storage: 20GB SSD
   - Cost: ~$7/month

2. **Static IP Address**
   - Persistent public IP
   - Free while attached to instance

3. **Firewall Rules**
   - Port 80 (HTTP) - Public
   - Port 443 (HTTPS) - Public
   - Port 41641 (UDP) - Tailscale VPN

4. **Automatic Security Updates**
   - Configured via user-data script
   - Daily security patch checks
   - Automatic installation of updates

### Directory Structure Created

The deployment creates the following structure on the instance:

```
/opt/website-builder/
├── app/                    # Application code (deployed separately)
├── config/                 # Configuration files
│   ├── site.json
│   └── pages/
├── assets/                 # Asset storage
│   ├── uploads/
│   └── processed/
│       ├── 320/
│       ├── 768/
│       └── 1920/
├── versions/               # Version backups
└── logs/                   # Application logs

/var/www/html/              # Public web root (NGINX)
```

## Prerequisites

### Required Tools

- **AWS CLI**: For AWS authentication and API access
- **Terraform** (for Terraform deployment): >= 1.0
- **Git**: For cloning and version control

### Required Information

Before deployment, gather:

1. **Domain Name**: Your website domain (e.g., example.com)
2. **SSL Email**: Email for Let's Encrypt certificates
3. **Anthropic API Key**: From https://console.anthropic.com/
4. **Tailscale Auth Key**: From https://login.tailscale.com/admin/settings/keys

### AWS Setup

1. Install AWS CLI:
   ```bash
   # macOS
   brew install awscli
   
   # Linux
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

2. Configure credentials:
   ```bash
   aws configure
   ```

## Deployment Process

### 1. Choose Deployment Method

Select either Terraform or CloudFormation based on your preference.

### 2. Configure Variables

Copy the example configuration file and fill in your values:

**Terraform**:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

**CloudFormation**:
```bash
cd cloudformation
cp parameters.json.example parameters.json
nano parameters.json
```

### 3. Deploy Infrastructure

**Terraform**:
```bash
cd terraform
../scripts/deploy.sh deploy
```

**CloudFormation**:
```bash
cd cloudformation
./deploy-cloudformation.sh create
./configure-firewall.sh
```

### 4. Configure DNS

Point your domain's A record to the public IP address shown in the deployment outputs.

### 5. Verify Deployment

SSH into the instance:
```bash
ssh ubuntu@<public-ip>
```

Check user-data script logs:
```bash
sudo cat /var/log/user-data.log
```

Verify automatic updates:
```bash
sudo cat /etc/apt/apt.conf.d/20auto-upgrades
```

## Post-Deployment Tasks

After infrastructure deployment, complete these tasks:

### 1. Task 1.2: Configure NGINX as static web server

Run the NGINX configuration script:

```bash
# Copy script to server
scp infrastructure/scripts/configure-nginx.sh ubuntu@<server-ip>:~/

# SSH to server and run
ssh ubuntu@<server-ip>
sudo ./configure-nginx.sh
```

This script will:
- Install NGINX
- Configure server blocks for serving from `/var/www/html`
- Enable gzip compression for text content
- Set up cache headers for optimal performance
- Create a custom 404 error page
- Configure security headers

See `infrastructure/scripts/README.md` for detailed documentation.

### 2. Task 1.3: Set up UFW firewall rules

Run the UFW configuration script:

```bash
# Copy script to server
scp infrastructure/scripts/configure-ufw.sh ubuntu@<server-ip>:~/

# SSH to server and run
ssh ubuntu@<server-ip>
sudo ./configure-ufw.sh

# Verify configuration
sudo ./test-ufw-config.sh
```

This script will:
- Set default policies (deny incoming, allow outgoing)
- Allow SSH (port 22) to prevent lockout
- Allow HTTP (port 80) for public web traffic
- Allow HTTPS (port 443) for secure public web traffic
- Allow Tailscale VPN (port 41641 UDP) for VPN access
- Block all other inbound traffic by default
- Enable UFW and display status

**Important**: The Builder Interface (port 3000) is NOT exposed to the internet. It will only be accessible through Tailscale VPN (configured in Task 1.4).

**Validation**: Run `test-ufw-config.sh` to verify all firewall rules are correctly configured and requirements 2.1 and 2.2 are met.

See `infrastructure/scripts/README.md` and `infrastructure/scripts/UFW-CONFIGURATION.md` for detailed documentation.

### 3. Task 1.4: Configure Tailscale VPN integration

Run the Tailscale configuration script:

```bash
# 1. Generate Tailscale auth key
# Go to: https://login.tailscale.com/admin/settings/keys
# Generate a reusable, preauthorized key

# 2. Copy script to server
scp infrastructure/scripts/configure-tailscale.sh ubuntu@<server-ip>:~/

# 3. SSH to server and run
ssh ubuntu@<server-ip>
sudo ./configure-tailscale.sh tskey-auth-XXXXXXXXXX

# 4. Verify configuration
sudo ./test-tailscale-config.sh
```

This script will:
- Install Tailscale client from official repository
- Authenticate with your Tailscale network
- Configure Builder Interface to bind only to Tailscale IP
- Create systemd service override for VPN-only binding
- Verify firewall configuration
- Display access information

**Important**: The Builder Interface (port 3000) will ONLY be accessible through Tailscale VPN. You must install Tailscale on your computer/device to access it.

**Accessing the Builder Interface**:
1. Install Tailscale on your computer (https://tailscale.com/download)
2. Connect to Tailscale: `sudo tailscale up`
3. Access Builder Interface: `http://100.x.x.x:3000` (use server's Tailscale IP)

**Validation**: Run `test-tailscale-config.sh` to verify all VPN configuration is correct and requirements 2.3 and 2.5 are met.

See `infrastructure/scripts/README.md` and `infrastructure/scripts/TAILSCALE-CONFIGURATION.md` for detailed documentation.

### 4. Task 1.5: Set up Let's Encrypt SSL automation

### 5. Task 1.6: Create systemd service files

See the main project tasks.md for details.

## Cost Breakdown

### Monthly Costs

- **Lightsail Instance (nano_2_0)**: $7.00
- **Static IP**: $0.00 (free while attached)
- **Data Transfer**: $0.00 (1TB included)
- **Subtotal**: $7.00/month

### Additional Costs

- **Claude API**: Variable based on usage
  - Rate limited to 10 requests/minute
  - Monthly token tracking
  - Estimated: $5-23/month depending on usage

**Total Estimated Cost**: $12-30/month (within budget)

## Security Features

### Network Security

- **VPN Protection**: Builder interface only accessible via Tailscale
- **Public Access**: Only static website content exposed
- **Firewall**: UFW configured to block all non-essential ports
- **Fail2ban**: Prevents brute-force attacks

### System Security

- **Automatic Updates**: Security patches applied daily
- **Minimal Attack Surface**: Only required services installed
- **File Permissions**: Strict permissions on application files
- **SSH Keys**: Password authentication disabled

### Application Security

- **Configuration Protection**: Config files outside web root
- **Environment Variables**: Sensitive data in .env file
- **Input Validation**: All user input validated
- **Rate Limiting**: API requests throttled

## Monitoring and Maintenance

### Health Checks

Check system status:
```bash
# Instance status
aws lightsail get-instance-state --instance-name ai-website-builder

# Disk usage
ssh ubuntu@<ip> "df -h"

# Memory usage
ssh ubuntu@<ip> "free -h"

# Service status
ssh ubuntu@<ip> "sudo systemctl status website-builder"
```

### Log Access

View logs:
```bash
# User data script
ssh ubuntu@<ip> "sudo cat /var/log/user-data.log"

# Application logs
ssh ubuntu@<ip> "sudo journalctl -u website-builder -f"

# NGINX logs
ssh ubuntu@<ip> "sudo tail -f /var/log/nginx/access.log"
```

### Backup Strategy

The application includes automatic version control:
- Last 10 versions of each page retained
- Configuration files backed up before changes
- Manual backups recommended for disaster recovery

## Troubleshooting

### Common Issues

**Cannot SSH to instance**:
- Verify security group allows SSH (port 22)
- Check you're using the correct key pair
- Ensure instance is running

**User data script failed**:
- SSH to instance and check `/var/log/user-data.log`
- Look for error messages in the log
- Re-run failed commands manually

**Automatic updates not working**:
- Check configuration: `cat /etc/apt/apt.conf.d/20auto-upgrades`
- Verify service: `systemctl status unattended-upgrades`
- Check logs: `cat /var/log/unattended-upgrades/unattended-upgrades.log`

**High costs**:
- Check API usage in status dashboard
- Review rate limiting configuration
- Monitor monthly token usage

### Getting Help

1. Check the main project README
2. Review design document: `.kiro/specs/ai-website-builder/design.md`
3. Check AWS Lightsail documentation
4. Review Terraform/CloudFormation logs

## Updating Infrastructure

### Terraform

```bash
cd terraform
# Edit configuration files
terraform plan
terraform apply
```

### CloudFormation

```bash
cd cloudformation
# Edit template or parameters
./deploy-cloudformation.sh update
```

## Destroying Infrastructure

**Warning**: This will delete all resources and data.

### Terraform

```bash
cd terraform
terraform destroy
```

### CloudFormation

```bash
cd cloudformation
./deploy-cloudformation.sh delete
```

## Next Steps

1. Complete remaining infrastructure tasks (1.2-1.6)
2. Deploy application code (Tasks 2.x)
3. Configure services and integrations
4. Test the complete system
5. Set up monitoring and alerts

## Support

For issues or questions:
- Review the spec documents in `.kiro/specs/ai-website-builder/`
- Check AWS Lightsail documentation
- Review Terraform/CloudFormation documentation
