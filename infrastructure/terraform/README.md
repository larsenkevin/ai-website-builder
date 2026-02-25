# AWS Lightsail Infrastructure Deployment

This directory contains Terraform configuration for deploying the AI Website Builder on AWS Lightsail.

## Prerequisites

1. **Terraform**: Install Terraform >= 1.0
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **AWS CLI**: Configure AWS credentials
   ```bash
   aws configure
   ```

3. **Required Information**:
   - Domain name for your website
   - Email address for SSL certificates
   - Anthropic API key (from https://console.anthropic.com/)
   - Tailscale auth key (from https://login.tailscale.com/admin/settings/keys)

## Deployment Steps

### 1. Configure Variables

Copy the example variables file and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your actual values:

```hcl
aws_region         = "us-east-1"
instance_name      = "ai-website-builder"
environment        = "production"
domain             = "yourdomain.com"
ssl_email          = "admin@yourdomain.com"
anthropic_api_key  = "sk-ant-your-actual-key"
tailscale_auth_key = "tskey-auth-your-actual-key"
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

This will show you what resources will be created:
- AWS Lightsail instance (nano_2_0: 1 CPU, 1GB RAM)
- Static IP address
- Firewall rules (ports 80, 443, 41641)

### 4. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm deployment.

### 5. Post-Deployment Configuration

After deployment completes, Terraform will output:
- Public IP address
- SSH command
- Next steps

**Configure DNS**:
Point your domain's A record to the public IP address shown in the output.

**Verify Deployment**:
```bash
# SSH into the instance
ssh ubuntu@<public-ip>

# Check user-data script logs
sudo cat /var/log/user-data.log

# Verify automatic updates are configured
sudo cat /etc/apt/apt.conf.d/20auto-upgrades
```

## Infrastructure Details

### Instance Specifications

- **Bundle**: nano_2_0
- **CPU**: 1 vCPU
- **RAM**: 1 GB
- **Storage**: 20 GB SSD
- **Transfer**: 1 TB/month
- **Cost**: ~$7/month (within $12-30 budget)

### Operating System

- **OS**: Ubuntu 22.04 LTS
- **Automatic Security Updates**: Enabled
- **Update Schedule**: Daily check, automatic installation
- **Reboot**: Manual (automatic reboot disabled for stability)

### Network Configuration

**Open Ports**:
- Port 80 (HTTP) - Public access
- Port 443 (HTTPS) - Public access
- Port 41641 (UDP) - Tailscale VPN

**Firewall**: UFW configured via user-data script

### Directory Structure

The user-data script creates the following structure:

```
/opt/website-builder/
├── app/                    # Application code
├── config/                 # Configuration files
│   └── pages/             # Page configurations
├── assets/                # Asset storage
│   ├── uploads/           # Original uploads
│   └── processed/         # Optimized images
│       ├── 320/
│       ├── 768/
│       └── 1920/
├── versions/              # Version backups
└── logs/                  # Application logs

/var/www/html/             # Public web root (NGINX)
```

## Updating Infrastructure

To update the infrastructure:

1. Modify the Terraform files
2. Run `terraform plan` to review changes
3. Run `terraform apply` to apply changes

## Destroying Infrastructure

To completely remove all resources:

```bash
terraform destroy
```

**Warning**: This will delete the instance and all data. Make sure to backup any important data first.

## Cost Optimization

The deployment is optimized for the $12-30/month budget:

- **Lightsail Instance**: $7/month (nano_2_0)
- **Static IP**: Free (while attached)
- **Data Transfer**: 1TB included
- **Estimated Total**: $7-12/month (excluding API costs)

Claude API costs are controlled through:
- Rate limiting (10 requests/minute)
- Monthly token tracking
- Request queuing

## Troubleshooting

### Instance Not Accessible

Check security group rules:
```bash
terraform show | grep port_info
```

### User Data Script Failed

SSH into instance and check logs:
```bash
ssh ubuntu@<public-ip>
sudo cat /var/log/user-data.log
```

### Automatic Updates Not Working

Verify configuration:
```bash
sudo systemctl status unattended-upgrades
sudo cat /etc/apt/apt.conf.d/50unattended-upgrades
```

## Security Notes

1. **Sensitive Variables**: The `terraform.tfvars` file contains sensitive data and is excluded from version control via `.gitignore`
2. **SSH Access**: Use SSH keys for authentication (password authentication disabled)
3. **VPN Protection**: Builder interface only accessible via Tailscale VPN
4. **Automatic Updates**: Security patches applied automatically
5. **Fail2ban**: Installed to prevent brute-force attacks

## Next Steps

After infrastructure deployment:

1. Complete NGINX configuration (Task 1.2)
   ```bash
   scp infrastructure/scripts/configure-nginx.sh ubuntu@<server-ip>:~/
   ssh ubuntu@<server-ip>
   sudo ./configure-nginx.sh
   ```
   See `infrastructure/scripts/README.md` for details.
2. Set up UFW firewall rules (Task 1.3)
3. Configure Tailscale VPN (Task 1.4)
4. Set up Let's Encrypt SSL (Task 1.5)
5. Create systemd services (Task 1.6)

## Support

For issues or questions:
- Check the main project README
- Review the design document in `.kiro/specs/ai-website-builder/design.md`
- Check AWS Lightsail documentation: https://docs.aws.amazon.com/lightsail/
