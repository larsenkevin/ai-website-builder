# Quick Start Guide

Get your AI Website Builder infrastructure deployed in 5 minutes.

## Prerequisites Checklist

- [ ] AWS account with credentials configured
- [ ] Domain name ready
- [ ] Anthropic API key (get from https://console.anthropic.com/)
- [ ] Tailscale auth key (get from https://login.tailscale.com/admin/settings/keys)

## Terraform Deployment (Recommended)

### 1. Install Terraform

```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### 2. Configure AWS

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region (e.g., us-east-1)
```

### 3. Set Up Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region         = "us-east-1"
instance_name      = "ai-website-builder"
environment        = "production"
domain             = "yourdomain.com"              # YOUR DOMAIN
ssl_email          = "admin@yourdomain.com"        # YOUR EMAIL
anthropic_api_key  = "sk-ant-xxxxx"                # YOUR API KEY
tailscale_auth_key = "tskey-auth-xxxxx"            # YOUR AUTH KEY
```

### 4. Deploy

```bash
../scripts/deploy.sh deploy
```

This will:
- Initialize Terraform
- Validate configuration
- Show deployment plan
- Create all resources
- Display outputs with IP address

### 5. Configure DNS

Point your domain's A record to the IP address shown in the output.

### 6. Verify

```bash
# Get outputs
terraform output

# SSH to instance
ssh ubuntu@<public-ip>

# Check deployment log
sudo cat /var/log/user-data.log
```

## CloudFormation Deployment

### 1. Configure AWS

```bash
aws configure
```

### 2. Set Up Parameters

```bash
cd cloudformation
cp parameters.json.example parameters.json
```

Edit `parameters.json` with your values.

### 3. Deploy

```bash
./deploy-cloudformation.sh create
```

Wait for stack creation to complete.

### 4. Configure Firewall

```bash
./configure-firewall.sh
```

### 5. Get Outputs

```bash
./deploy-cloudformation.sh outputs
```

## What Gets Created

- **Lightsail Instance**: Ubuntu 22.04 LTS, 1 CPU, 1GB RAM
- **Static IP**: Persistent public IP address
- **Firewall Rules**: Ports 80, 443, 41641 (Tailscale)
- **Auto Updates**: Security patches applied automatically
- **Directory Structure**: Application directories created

## Cost

- **Instance**: $7/month
- **Static IP**: Free (while attached)
- **Total**: $7/month + API usage

## Next Steps

After infrastructure deployment:

1. **Configure NGINX** (Task 1.2)
   ```bash
   scp infrastructure/scripts/configure-nginx.sh ubuntu@<server-ip>:~/
   ssh ubuntu@<server-ip>
   sudo ./configure-nginx.sh
   ```
   This will:
   - Install and configure NGINX web server
   - Set up gzip compression for text content
   - Configure cache headers for optimal performance
   - Create custom 404 error page
   - Configure security headers
   
   See `infrastructure/scripts/README.md` for details.

2. **Set Up Firewall** (Task 1.3)
   - Configure UFW rules
   - Block unnecessary ports

3. **Install Tailscale** (Task 1.4)
   - Set up VPN access
   - Restrict builder interface

4. **Configure SSL** (Task 1.5)
   - Install certbot
   - Set up automatic renewal

5. **Create Services** (Task 1.6)
   - Write systemd service files
   - Enable auto-start

## Troubleshooting

### Terraform Errors

**"No valid credential sources found"**:
```bash
aws configure
```

**"terraform: command not found"**:
```bash
# Install Terraform (see step 1 above)
```

**"Error creating Lightsail Instance"**:
- Check AWS region supports Lightsail
- Verify you have permissions
- Check instance name is unique

### CloudFormation Errors

**"Stack creation failed"**:
```bash
aws cloudformation describe-stack-events \
  --stack-name ai-website-builder \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'
```

### SSH Connection Issues

**"Connection refused"**:
- Wait a few minutes for instance to fully boot
- Check security group allows SSH (port 22)
- Verify you're using correct IP address

**"Permission denied (publickey)"**:
- Lightsail uses default SSH key
- Download key from Lightsail console
- Use: `ssh -i LightsailDefaultKey.pem ubuntu@<ip>`

### User Data Script Issues

```bash
# SSH to instance
ssh ubuntu@<public-ip>

# Check logs
sudo cat /var/log/user-data.log

# Check for errors
sudo journalctl -xe
```

## Getting Help

- **Main README**: `infrastructure/README.md`
- **Terraform Guide**: `terraform/README.md`
- **CloudFormation Guide**: `cloudformation/README.md`
- **Design Doc**: `.kiro/specs/ai-website-builder/design.md`

## Clean Up

To remove all resources:

**Terraform**:
```bash
cd terraform
terraform destroy
```

**CloudFormation**:
```bash
cd cloudformation
./deploy-cloudformation.sh delete
```

**Warning**: This deletes everything. Backup data first!
