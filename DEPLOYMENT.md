# AI Website Builder - Deployment Guide

**Version:** 1.0  
**Last Updated:** 2024  
**Target Audience:** DevOps Engineers, System Administrators, Developers  
**Estimated Time:** 60-90 minutes  
**Difficulty:** Intermediate

---

## Table of Contents

1. [Introduction](#introduction)
   - [Purpose and Scope](#purpose-and-scope)
   - [Target Audience](#target-audience)
   - [Deployment Workflow Overview](#deployment-workflow-overview)
2. [Pre-Deployment Prerequisites](#pre-deployment-prerequisites)
3. [Infrastructure Deployment Phase](#infrastructure-deployment-phase)
4. [DNS Configuration Phase](#dns-configuration-phase)
5. [Server Configuration Phase](#server-configuration-phase)
6. [Application Deployment Phase](#application-deployment-phase)
7. [Post-Deployment Verification Phase](#post-deployment-verification-phase)
8. [User Access Instructions](#user-access-instructions)
9. [Troubleshooting Guide](#troubleshooting-guide)
10. [Maintenance Procedures](#maintenance-procedures)
11. [Cost Management](#cost-management)

---

## Introduction

### Purpose and Scope

This deployment guide provides comprehensive, step-by-step instructions for deploying the AI Website Builder from source code to a fully operational AWS Lightsail instance. The guide covers the complete deployment lifecycle, from initial prerequisites through post-deployment verification and ongoing maintenance.

The AI Website Builder is a dual-component system:
- **Builder Interface**: A VPN-protected web application (port 3000) for content management and AI-powered website generation
- **Static Server**: A public-facing NGINX server (ports 80/443) that serves the generated HTML pages

This guide serves multiple purposes:
- **Reference Manual**: Detailed documentation of all deployment steps and configurations
- **Step-by-Step Tutorial**: Sequential instructions that can be followed by operators with varying experience levels
- **Verification Checklist**: Commands and procedures to confirm successful deployment at each stage
- **Troubleshooting Resource**: Solutions to common deployment issues and diagnostic procedures

**What This Guide Covers:**
- Setting up AWS Lightsail infrastructure using Terraform or CloudFormation
- Configuring domain names and DNS records
- Installing and configuring NGINX, UFW firewall, Tailscale VPN, and SSL certificates
- Deploying and starting the Node.js application
- Verifying all components are working correctly
- Providing access instructions for end users
- Maintaining and updating the deployed system
- Monitoring and managing deployment costs

**What This Guide Does Not Cover:**
- Application development or code modifications
- Custom infrastructure configurations beyond the standard deployment
- Alternative cloud providers (AWS Lightsail only)
- Scaling beyond a single-instance deployment

### Target Audience

This guide is designed for:

**Primary Audience:**
- DevOps engineers deploying the system for the first time
- System administrators responsible for infrastructure management
- Technical operators with basic cloud infrastructure experience

**Secondary Audience:**
- Developers who need to understand the deployment architecture
- Technical leads planning deployment strategies

**Prerequisites Knowledge:**
- Basic command-line interface (CLI) usage
- Familiarity with SSH and remote server access
- Understanding of DNS and domain name configuration
- Basic knowledge of web servers and networking concepts
- Experience with cloud infrastructure (AWS preferred but not required)

### Deployment Workflow Overview

The deployment process follows a sequential workflow with six major phases. Each phase must be completed successfully before proceeding to the next, as later phases depend on the successful completion of earlier ones.

```text
┌─────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT WORKFLOW                          │
└─────────────────────────────────────────────────────────────────┘

Phase 1: Pre-Deployment Prerequisites (15-20 minutes)
├─ Install required tools (AWS CLI, Terraform/CloudFormation, Node.js)
├─ Obtain credentials (Anthropic API key, Tailscale auth key)
├─ Configure AWS account and credentials
├─ Register or prepare domain name
└─ Verify all prerequisites are met
   │
   ▼
Phase 2: Infrastructure Deployment (10-15 minutes)
├─ Choose deployment method (Terraform or CloudFormation)
├─ Configure deployment variables
├─ Execute infrastructure deployment
├─ Retrieve deployment outputs (instance IP address)
└─ Verify AWS Lightsail instance is running
   │
   ▼
Phase 3: DNS Configuration (5-30 minutes, includes propagation)
├─ Configure DNS A records for root and www subdomains
├─ Point DNS records to Lightsail instance IP
├─ Wait for DNS propagation
└─ Verify DNS resolution before proceeding
   │
   ▼
Phase 4: Server Configuration (15-20 minutes)
├─ SSH into Lightsail instance
├─ Run configure-nginx.sh (web server setup)
├─ Run configure-ufw.sh (firewall rules)
├─ Run configure-tailscale.sh (VPN integration)
├─ Run configure-ssl.sh (SSL certificates) ← Requires DNS
└─ Run configure-systemd.sh (service management)
   │
   ▼
Phase 5: Application Deployment (10-15 minutes)
├─ Transfer application code to server
├─ Install Node.js dependencies
├─ Configure environment variables (.env file)
├─ Build TypeScript application
└─ Start and enable website-builder service
   │
   ▼
Phase 6: Post-Deployment Verification (5-10 minutes)
├─ Verify NGINX is serving static content
├─ Verify firewall rules are active
├─ Verify Tailscale VPN is connected
├─ Verify SSL certificates are installed
├─ Verify Builder Interface is accessible via VPN
├─ Verify Static Server is publicly accessible
└─ Verify Builder Interface is NOT publicly accessible (security check)
```

**Phase Dependencies:**
- **Phase 3** (DNS) must complete before **Phase 4** (SSL configuration) because SSL certificates require valid DNS records
- **Phase 4** (Server Configuration) must complete before **Phase 5** (Application Deployment) because the application depends on configured services
- **Phase 5** (Application Deployment) must complete before **Phase 6** (Verification) to test the running system

**Automation Potential:**
- **Phases 2-4** can be partially automated using infrastructure-as-code and configuration management tools
- **Phase 3** requires manual DNS configuration at your domain registrar (cannot be fully automated unless using Route53)
- **Phase 5** can be automated with deployment scripts
- **Phase 6** verification steps can be scripted for automated testing

**Manual Intervention Required:**
- DNS record configuration at domain registrar (Phase 3)
- Environment variable configuration (Phase 5)
- Verification and troubleshooting at each phase

**Time Estimates by Phase:**
- **Phase 1**: 15-20 minutes (first-time setup; faster on subsequent deployments)
- **Phase 2**: 10-15 minutes (infrastructure provisioning)
- **Phase 3**: 5-30 minutes (5 minutes for configuration + up to 30 minutes for DNS propagation)
- **Phase 4**: 15-20 minutes (server configuration scripts)
- **Phase 5**: 10-15 minutes (application deployment)
- **Phase 6**: 5-10 minutes (verification)

**Total Estimated Time:** 60-90 minutes for a complete first-time deployment

**Important Notes:**
- DNS propagation time (Phase 3) is variable and can range from 5 minutes to several hours, though typically completes within 30 minutes
- If you encounter issues, refer to the [Troubleshooting Guide](#troubleshooting-guide) section
- Each phase includes verification steps to confirm success before proceeding
- Rollback procedures are provided in case of deployment failures

---

## Pre-Deployment Prerequisites

Before beginning the deployment process, ensure you have all required tools installed and configured. This section provides installation instructions for each tool across multiple operating systems, along with verification commands to confirm proper installation.

### Required Tools and Versions

The following tools are required for deploying the AI Website Builder. Minimum versions are specified where applicable.

#### 1. AWS CLI (>= 2.0)

The AWS Command Line Interface is required for managing AWS resources and deploying infrastructure.

**Installation Instructions:**

**macOS:**
```bash
# Using Homebrew
brew install awscli

# Or download the installer
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

**Linux:**
```bash
# Download and install
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Windows:**
```powershell
# Download the MSI installer from:
# https://awscli.amazonaws.com/AWSCLIV2.msi
# Run the downloaded installer and follow the prompts
```

**Verification:**
```bash
aws --version
```

**Expected Output:**
```text
aws-cli/2.x.x Python/3.x.x ...
```

**If verification fails:** Ensure the AWS CLI binary is in your system PATH. You may need to restart your terminal or add the installation directory to your PATH environment variable.

---

#### 2. Terraform (>= 1.0) OR AWS CLI for CloudFormation

You need either Terraform or AWS CLI (for CloudFormation) to deploy infrastructure. Choose one based on your preference and experience.

**Option A: Terraform (Recommended for infrastructure-as-code workflows)**

**macOS:**
```bash
# Using Homebrew
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Linux:**
```bash
# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# RHEL/CentOS/Fedora
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform
```

**Windows:**
```powershell
# Using Chocolatey
choco install terraform

# Or download from: https://www.terraform.io/downloads
# Extract the executable and add to your PATH
```

**Verification:**
```bash
terraform version
```

**Expected Output:**
```text
Terraform v1.x.x
```

**Option B: AWS CLI for CloudFormation**

If you installed AWS CLI (above), you already have CloudFormation support. No additional installation needed.

**Verification:**
```bash
aws cloudformation help
```

**Expected Output:**
```text
CLOUDFORMATION()                                              CLOUDFORMATION()

NAME
       cloudformation -
...
```

---

#### 3. Node.js (>= 18)

Node.js is required for building and running the AI Website Builder application.

**macOS:**
```bash
# Using Homebrew
brew install node@18

# Or using nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18
```

**Linux:**
```bash
# Using NodeSource repository (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Using NodeSource repository (RHEL/CentOS/Fedora)
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Or using nvm (recommended for version management)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18
```

**Windows:**
```powershell
# Download the installer from: https://nodejs.org/
# Run the LTS installer (version 18.x or higher)

# Or using Chocolatey
choco install nodejs-lts

# Or using nvm-windows
# Download from: https://github.com/coreybutler/nvm-windows/releases
# Then run: nvm install 18 && nvm use 18
```

**Verification:**
```bash
node --version
npm --version
```

**Expected Output:**
```text
v18.x.x
9.x.x
```

**If verification fails:** Ensure Node.js is in your PATH. You may need to restart your terminal after installation.

---

#### 4. Git

Git is required for cloning the repository and managing code versions.

**macOS:**
```bash
# Using Homebrew
brew install git

# Or install Xcode Command Line Tools
xcode-select --install
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install git

# RHEL/CentOS/Fedora
sudo yum install git
```

**Windows:**
```powershell
# Download Git for Windows from: https://git-scm.com/download/win
# Run the installer and follow the prompts

# Or using Chocolatey
choco install git
```

**Verification:**
```bash
git --version
```

**Expected Output:**
```text
git version 2.x.x
```

---

#### 5. SSH Client

An SSH client is required for connecting to the AWS Lightsail instance to run configuration scripts.

**macOS and Linux:**

SSH is pre-installed on macOS and most Linux distributions.

**Verification:**
```bash
ssh -V
```

**Expected Output:**
```text
OpenSSH_8.x or higher
```

**Windows:**

Windows 10 and later include OpenSSH by default.

**Verification:**
```powershell
ssh -V
```

**Expected Output:**
```text
OpenSSH_for_Windows_8.x or higher
```

**If SSH is not available on Windows:**
```powershell
# Install OpenSSH using Windows Settings:
# Settings > Apps > Optional Features > Add a feature > OpenSSH Client

# Or using PowerShell (as Administrator)
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

**Alternative SSH Clients for Windows:**
- PuTTY: https://www.putty.org/
- Git Bash (included with Git for Windows)
- Windows Subsystem for Linux (WSL)

---

### Tool Installation Summary

Once all tools are installed, verify your complete setup:

```bash
# Verify all required tools
aws --version          # Should show 2.x.x or higher
terraform version      # Should show 1.x.x or higher (if using Terraform)
node --version         # Should show v18.x.x or higher
npm --version          # Should show 9.x.x or higher
git --version          # Should show 2.x.x or higher
ssh -V                 # Should show OpenSSH 8.x or higher
```

**Checklist:**
- [ ] AWS CLI installed and verified (>= 2.0)
- [ ] Terraform (>= 1.0) OR AWS CLI for CloudFormation installed and verified
- [ ] Node.js installed and verified (>= 18)
- [ ] npm installed and verified (comes with Node.js)
- [ ] Git installed and verified
- [ ] SSH client installed and verified

**Estimated Time:** 15-20 minutes for first-time installation of all tools

**Next Steps:** Once all tools are installed and verified, proceed to obtain the required credentials (Anthropic API key, Tailscale auth key, AWS credentials) and configure your AWS account.

---

### Credential Acquisition Procedures

Before deploying the infrastructure, you must obtain several credentials and configure access to required services. This section provides step-by-step instructions for acquiring each credential, along with security best practices for handling sensitive information.

#### 1. Anthropic API Key

The Anthropic API key is required for the AI Website Builder to access Claude, the AI model that powers content generation.

**How to Obtain:**

1. **Create an Anthropic Account** (if you don't have one):
   - Visit: https://console.anthropic.com/
   - Click "Sign Up" and complete the registration process
   - Verify your email address

2. **Access the API Keys Section**:
   - Log in to the Anthropic Console: https://console.anthropic.com/
   - Navigate to "API Keys" in the left sidebar
   - Or go directly to: https://console.anthropic.com/settings/keys

3. **Create a New API Key**:
   - Click "Create Key" or "New API Key"
   - Give your key a descriptive name (e.g., "AI Website Builder Production")
   - Click "Create Key"
   - **IMPORTANT:** Copy the API key immediately and store it securely
   - The key will only be displayed once and cannot be retrieved later

4. **Set Up Billing** (if not already configured):
   - Navigate to "Billing" in the Anthropic Console
   - Add a payment method
   - Consider setting up usage limits to control costs
   - The AI Website Builder includes a monthly token threshold configuration to help manage API costs

**API Key Format:**
```text
sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Security Best Practices:**
- **Never commit API keys to version control** (Git repositories)
- Store the API key in a secure password manager
- Use environment variables or secure configuration files on the server
- Rotate API keys periodically (every 90 days recommended)
- Monitor API usage in the Anthropic Console to detect unauthorized use
- If a key is compromised, delete it immediately in the console and create a new one

**Cost Considerations:**
- Anthropic charges per token (input and output)
- Monitor your usage at: https://console.anthropic.com/settings/usage
- The AI Website Builder includes configurable monthly token limits
- See the [Cost Management](#cost-management) section for detailed cost monitoring

**Verification:**

You can verify your API key works using curl:

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: YOUR_API_KEY_HERE" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "max_tokens": 10,
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

**Expected Response:** A JSON response with a message from Claude (indicates the key is valid).

**If verification fails:**
- Ensure you copied the complete API key (they are very long)
- Check that your Anthropic account has billing configured
- Verify the API key hasn't been deleted or revoked in the console

---

#### 2. Tailscale Auth Key

Tailscale provides the VPN that secures access to the Builder Interface. An auth key is required to automatically connect the server to your Tailscale network.

**How to Obtain:**

1. **Create a Tailscale Account** (if you don't have one):
   - Visit: https://login.tailscale.com/start
   - Sign up using your preferred authentication method (Google, Microsoft, GitHub, etc.)
   - Complete the account setup

2. **Access the Admin Console**:
   - Log in to: https://login.tailscale.com/admin
   - This is your Tailscale admin dashboard

3. **Generate an Auth Key**:
   - In the admin console, navigate to "Settings" → "Keys"
   - Or go directly to: https://login.tailscale.com/admin/settings/keys
   - Click "Generate auth key..."
   - Configure the auth key settings:
     - **Description:** "AI Website Builder Server" (or similar)
     - **Reusable:** ✓ Check this box (allows the key to be used multiple times)
     - **Ephemeral:** ☐ Leave unchecked (we want the device to persist)
     - **Preauthorized:** ✓ Check this box (automatically approves the device)
     - **Tags:** Optional, but recommended to add a tag like `tag:webserver`
     - **Expiration:** Set to 90 days or longer (default is 90 days)
   - Click "Generate key"
   - **IMPORTANT:** Copy the auth key immediately and store it securely
   - The key will only be displayed once

4. **Configure Tailscale Network Settings** (Optional but Recommended):
   - In the admin console, go to "DNS" settings
   - Enable "MagicDNS" for easier device access by hostname
   - Configure "HTTPS Certificates" if you want Tailscale to manage SSL for the VPN interface

**Auth Key Format:**
```text
tskey-auth-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Security Best Practices:**
- **Never commit auth keys to version control**
- Store the auth key securely (password manager or secrets management system)
- Use reusable keys for production deployments (allows re-deployment without generating new keys)
- Set appropriate expiration times (90 days is reasonable for production)
- Use tags to organize and manage devices in your Tailscale network
- Revoke auth keys that are no longer needed in the admin console
- Monitor connected devices regularly at: https://login.tailscale.com/admin/machines

**Understanding Tailscale Auth Key Options:**

- **Reusable:** Allows the same key to connect multiple devices or reconnect the same device. Recommended for production.
- **Ephemeral:** Device is automatically removed when it goes offline. Not recommended for servers.
- **Preauthorized:** Device is automatically approved without manual intervention. Recommended for automated deployments.
- **Tags:** Used for access control and organization. Useful for managing multiple servers.

**Verification:**

After deployment, you can verify the server is connected to your Tailscale network:

1. Visit: https://login.tailscale.com/admin/machines
2. Look for your server in the list of connected devices
3. The device should show as "Connected" with a green indicator

**If verification fails:**
- Ensure the auth key hasn't expired
- Check that the key was copied completely (no truncation)
- Verify the key hasn't been revoked in the admin console
- Check server logs for Tailscale connection errors (covered in Server Configuration phase)

**Cost Considerations:**
- Tailscale is free for personal use (up to 100 devices)
- For commercial use, check pricing at: https://tailscale.com/pricing
- The AI Website Builder uses Tailscale's free tier features

---

#### 3. AWS Account Setup and Credential Configuration

An AWS account is required to provision the Lightsail instance that hosts the AI Website Builder.

**How to Set Up:**

1. **Create an AWS Account** (if you don't have one):
   - Visit: https://aws.amazon.com/
   - Click "Create an AWS Account"
   - Follow the registration process:
     - Provide email address and account name
     - Enter payment information (required even for free tier)
     - Verify your identity (phone verification)
     - Choose a support plan (Basic/Free is sufficient)
   - Complete the account setup

2. **Create an IAM User for Deployment** (Recommended):

   **Why:** Using an IAM user instead of root credentials is a security best practice.

   - Log in to the AWS Console: https://console.aws.amazon.com/
   - Navigate to IAM (Identity and Access Management): https://console.aws.amazon.com/iam/
   - Click "Users" → "Add users"
   - Configure the user:
     - **User name:** `lightsail-deployer` (or similar)
     - **Access type:** ✓ Programmatic access (enables AWS CLI access)
     - Click "Next: Permissions"
   - Attach permissions:
     - Click "Attach existing policies directly"
     - Search for and select: `AmazonLightsailFullAccess`
     - Also attach: `AmazonRoute53ReadOnlyAccess` (if using Route53 for DNS)
     - Click "Next: Tags" → "Next: Review" → "Create user"
   - **IMPORTANT:** On the success page, copy the credentials:
     - **Access Key ID:** `AKIAIOSFODNN7EXAMPLE`
     - **Secret Access Key:** `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
     - Download the CSV file or copy both values immediately
     - **These credentials will only be displayed once**

3. **Configure AWS CLI with Credentials**:

   Run the AWS CLI configuration command:

   ```bash
   aws configure
   ```

   You will be prompted for the following information:

   ```
   AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
   AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   Default region name [None]: us-east-1
   Default output format [None]: json
   ```

   **Region Selection:**
   - Choose a region close to your target audience for better performance
   - Common regions:
     - `us-east-1` (US East - N. Virginia)
     - `us-west-2` (US West - Oregon)
     - `eu-west-1` (Europe - Ireland)
     - `ap-southeast-1` (Asia Pacific - Singapore)
   - Full list: https://docs.aws.amazon.com/general/latest/gr/rande.html

   **Output Format:**
   - `json` is recommended for programmatic use
   - Other options: `yaml`, `text`, `table`

4. **Verify AWS Configuration**:

   ```bash
   aws sts get-caller-identity
   ```

   **Expected Output:**
   ```json
   {
       "UserId": "AIDAIOSFODNN7EXAMPLE",
       "Account": "123456789012",
       "Arn": "arn:aws:iam::123456789012:user/lightsail-deployer"
   }
   ```

   This confirms your AWS credentials are configured correctly.

5. **Verify Lightsail Access**:

   ```bash
   aws lightsail get-regions
   ```

   **Expected Output:** A JSON list of available Lightsail regions.

   **If verification fails:**
   - Ensure credentials were copied correctly (no extra spaces or truncation)
   - Verify the IAM user has `AmazonLightsailFullAccess` policy attached
   - Check that the credentials haven't been deactivated in the IAM console
   - Ensure you're using the correct AWS region

**Security Best Practices:**

- **Never use root account credentials for deployment**
  - Root credentials have unrestricted access to your entire AWS account
  - Always create IAM users with limited permissions
  
- **Use IAM users with minimal required permissions**
  - The `AmazonLightsailFullAccess` policy provides only Lightsail access
  - This limits the damage if credentials are compromised
  
- **Never commit AWS credentials to version control**
  - Add `.aws/` to your `.gitignore` file
  - Use environment variables or AWS credential files
  
- **Store credentials securely**
  - AWS credentials are stored in `~/.aws/credentials` by default
  - Ensure this file has restricted permissions: `chmod 600 ~/.aws/credentials`
  - Consider using a password manager for backup storage
  
- **Rotate credentials regularly**
  - Rotate IAM user access keys every 90 days
  - Delete old access keys after rotation
  - Monitor key age in the IAM console
  
- **Enable MFA (Multi-Factor Authentication)**
  - Enable MFA for your AWS root account
  - Consider enabling MFA for IAM users with console access
  - Configure at: https://console.aws.amazon.com/iam/home#/security_credentials
  
- **Monitor AWS account activity**
  - Enable AWS CloudTrail for audit logging
  - Set up billing alerts to detect unexpected usage
  - Review IAM access regularly

**Alternative Authentication Methods:**

- **AWS SSO (Single Sign-On):** For organizations with multiple AWS accounts
- **IAM Roles:** For EC2 instances or other AWS services (not applicable for local deployment)
- **AWS Vault:** Third-party tool for secure credential management
- **Environment Variables:** Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` directly

**Cost Considerations:**
- AWS account creation is free
- IAM users and policies are free
- You only pay for resources you create (Lightsail instance, data transfer, etc.)
- See the [Cost Management](#cost-management) section for detailed cost breakdown

---

#### 4. Domain Name Registration or Preparation

A domain name is required for the AI Website Builder to serve content over HTTPS and provide a professional web presence.

**Option A: Register a New Domain Name**

If you don't have a domain name, you'll need to register one through a domain registrar.

**Recommended Registrars:**

1. **AWS Route 53** (Integrated with AWS)
   - Visit: https://console.aws.amazon.com/route53/
   - Navigate to "Registered domains" → "Register domain"
   - Search for available domain names
   - Complete the registration process
   - **Advantages:** Seamless integration with AWS services, automatic DNS configuration
   - **Cost:** Varies by TLD (.com ~$12/year, .net ~$11/year, .io ~$39/year)

2. **Namecheap** (Popular and affordable)
   - Visit: https://www.namecheap.com/
   - Search for available domains
   - Add to cart and complete purchase
   - **Advantages:** Competitive pricing, free WHOIS privacy, user-friendly interface
   - **Cost:** .com domains typically $8-15/year

3. **Google Domains** (Simple and reliable)
   - Visit: https://domains.google/
   - Search and register your domain
   - **Advantages:** Clean interface, transparent pricing, free privacy protection
   - **Cost:** .com domains typically $12/year

4. **Cloudflare Registrar** (At-cost pricing)
   - Visit: https://www.cloudflare.com/products/registrar/
   - Transfer or register domains at wholesale prices
   - **Advantages:** No markup pricing, free WHOIS privacy, integrated with Cloudflare DNS
   - **Cost:** At-cost pricing (typically $8-10/year for .com)

**Domain Selection Tips:**
- Choose a domain name that reflects your website's purpose
- Prefer `.com` for general use (most recognized TLD)
- Keep it short, memorable, and easy to spell
- Avoid hyphens and numbers if possible
- Check trademark availability to avoid legal issues

**Option B: Use an Existing Domain Name**

If you already own a domain name, you can use it with the AI Website Builder.

**Requirements:**
- You must have access to the domain's DNS settings
- The domain must not be currently in use for another website (or you must be willing to point it to the new server)
- You should have the ability to create A records in your DNS configuration

**Supported DNS Providers:**
- Any DNS provider that allows you to create A records
- Common providers: Route 53, Cloudflare, Namecheap, GoDaddy, Google Domains, etc.

**What You'll Need:**
- Access to your domain registrar or DNS provider's control panel
- Ability to create/modify DNS A records
- The domain should be active (not expired or suspended)

**Domain Configuration Overview:**

During the DNS Configuration Phase (Phase 3), you will:
1. Create an A record for your root domain (e.g., `example.com`)
2. Create an A record for the www subdomain (e.g., `www.example.com`)
3. Point both records to your AWS Lightsail instance IP address
4. Wait for DNS propagation (typically 5-30 minutes)

**Subdomains and Hostnames:**

The AI Website Builder uses your domain for two purposes:

1. **Static Server (Public Website):**
   - Accessible at: `https://yourdomain.com` and `https://www.yourdomain.com`
   - Serves the generated HTML pages to the public
   - Requires DNS A records pointing to the Lightsail instance

2. **Builder Interface (VPN-Protected):**
   - Accessible at: `http://[tailscale-ip]:3000` (via Tailscale VPN)
   - Not directly accessible via your domain name
   - Protected by Tailscale VPN (not publicly accessible)

**Domain Verification:**

Before proceeding with deployment, verify you have:
- [ ] A registered domain name (or access to an existing one)
- [ ] Access to the domain's DNS settings
- [ ] Ability to create A records
- [ ] Domain is active and not expired

**Cost Considerations:**
- Domain registration: $8-40/year depending on TLD
- DNS hosting: Usually free with domain registration
- Route 53 hosted zones: $0.50/month if using AWS Route 53 (optional)

**Security Considerations:**
- **Enable WHOIS privacy protection** to hide your personal information from public WHOIS databases
- **Enable domain lock** (registrar lock) to prevent unauthorized transfers
- **Use strong passwords** for your domain registrar account
- **Enable two-factor authentication** on your registrar account if available
- **Keep your domain registration contact information up to date** to receive renewal notices

**Next Steps:**

Once you have a domain name and access to its DNS settings, you'll configure DNS records during the DNS Configuration Phase (Phase 3) of the deployment process.

---

### Credential Storage and Security Summary

**Credentials You Should Now Have:**

1. ✓ **Anthropic API Key** (format: `sk-ant-api03-...`)
2. ✓ **Tailscale Auth Key** (format: `tskey-auth-...`)
3. ✓ **AWS Access Key ID** (format: `AKIA...`)
4. ✓ **AWS Secret Access Key** (format: `wJalrXUt...`)
5. ✓ **Domain Name** (registered or prepared for use)

**Security Checklist:**

- [ ] All credentials stored in a secure password manager
- [ ] AWS credentials configured with `aws configure` (stored in `~/.aws/credentials`)
- [ ] No credentials committed to version control (check `.gitignore` includes `.env`, `.aws/`)
- [ ] IAM user created with minimal required permissions (not using root credentials)
- [ ] MFA enabled on AWS root account
- [ ] Domain registrar account secured with strong password and 2FA
- [ ] WHOIS privacy protection enabled on domain
- [ ] Credential rotation schedule planned (90 days recommended)

**Where Credentials Will Be Used:**

- **Anthropic API Key:** Will be added to the `.env` file on the server during Application Deployment (Phase 5)
- **Tailscale Auth Key:** Will be used as a parameter when running `configure-tailscale.sh` during Server Configuration (Phase 4)
- **AWS Credentials:** Already configured with AWS CLI, will be used during Infrastructure Deployment (Phase 2)
- **Domain Name:** Will be used in infrastructure configuration and DNS setup (Phases 2-3)

**Important Security Reminders:**

⚠️ **Never share credentials in:**
- Public GitHub repositories or gists
- Slack, Discord, or other chat platforms
- Email or unencrypted communication
- Screenshots or screen recordings
- Documentation or wiki pages

⚠️ **If credentials are compromised:**
- **Anthropic API Key:** Delete the key in the Anthropic Console and create a new one
- **Tailscale Auth Key:** Revoke the key in the Tailscale admin console and generate a new one
- **AWS Credentials:** Deactivate the access key in IAM and create a new one
- Update the compromised credential everywhere it's used
- Monitor for unauthorized usage

⚠️ **Regular security maintenance:**
- Review and rotate credentials every 90 days
- Monitor API usage and AWS billing for unexpected activity
- Keep your password manager and 2FA devices secure
- Regularly review IAM permissions and Tailscale connected devices

---

### Prerequisites Checklist and Readiness Verification

Before proceeding with infrastructure deployment, use this comprehensive checklist to verify that all prerequisites are met. Complete each item and confirm readiness before moving to Phase 2.

#### Pre-Deployment Checklist

**Estimated Time to Complete All Prerequisites:** 15-20 minutes (first-time setup)

**Tools Installation** (10-15 minutes)

- [ ] **AWS CLI installed and verified** (>= 2.0)
  - Verification: `aws --version` shows version 2.x.x or higher
  - Installation instructions: [See AWS CLI section above](#1-aws-cli--20)

- [ ] **Terraform OR AWS CLI for CloudFormation installed and verified**
  - [ ] Option A: Terraform (>= 1.0) - Verification: `terraform version` shows 1.x.x or higher
  - [ ] Option B: AWS CLI for CloudFormation - Verification: `aws cloudformation help` displays help text
  - Installation instructions: [See Terraform/CloudFormation section above](#2-terraform--10-or-aws-cli-for-cloudformation)

- [ ] **Node.js installed and verified** (>= 18)
  - Verification: `node --version` shows v18.x.x or higher
  - Verification: `npm --version` shows 9.x.x or higher
  - Installation instructions: [See Node.js section above](#3-nodejs--18)

- [ ] **Git installed and verified**
  - Verification: `git --version` shows version 2.x.x or higher
  - Installation instructions: [See Git section above](#4-git)

- [ ] **SSH client installed and verified**
  - Verification: `ssh -V` shows OpenSSH 8.x or higher
  - Installation instructions: [See SSH Client section above](#5-ssh-client)

**Credentials Acquisition** (5-10 minutes)

- [ ] **Anthropic API key obtained and stored securely**
  - Format: `sk-ant-api03-...` (very long string)
  - Stored in: Password manager or secure notes
  - Acquisition instructions: [See Anthropic API Key section above](#1-anthropic-api-key)
  - Verification: Test with curl command provided in the section

- [ ] **Tailscale auth key obtained and stored securely**
  - Format: `tskey-auth-...`
  - Configuration: Reusable, Preauthorized, Non-ephemeral
  - Stored in: Password manager or secure notes
  - Acquisition instructions: [See Tailscale Auth Key section above](#2-tailscale-auth-key)

- [ ] **AWS account created and credentials configured**
  - IAM user created with `AmazonLightsailFullAccess` policy
  - AWS CLI configured with `aws configure`
  - Credentials stored in: `~/.aws/credentials`
  - Verification: `aws sts get-caller-identity` returns your account information
  - Verification: `aws lightsail get-regions` returns list of regions
  - Setup instructions: [See AWS Account Setup section above](#3-aws-account-setup-and-credential-configuration)

- [ ] **Domain name registered or prepared**
  - Domain name: _________________ (write your domain here)
  - DNS access confirmed: Can create A records
  - Domain status: Active and not expired
  - Preparation instructions: [See Domain Name section above](#4-domain-name-registration-or-preparation)

**Security Configuration** (2-3 minutes)

- [ ] **All credentials stored in secure password manager**
  - Anthropic API key saved
  - Tailscale auth key saved
  - AWS Access Key ID and Secret Access Key saved (or in `~/.aws/credentials`)
  - Domain registrar login credentials saved

- [ ] **Version control security verified**
  - `.gitignore` includes `.env` files
  - `.gitignore` includes `.aws/` directory
  - No credentials committed to Git repository

- [ ] **AWS security best practices applied**
  - Using IAM user (not root credentials) for deployment
  - MFA enabled on AWS root account
  - IAM user has minimal required permissions

- [ ] **Domain security configured**
  - WHOIS privacy protection enabled
  - Domain lock (registrar lock) enabled
  - Two-factor authentication enabled on registrar account

**Knowledge and Preparation** (2-3 minutes)

- [ ] **Deployment workflow reviewed**
  - Read the [Deployment Workflow Overview](#deployment-workflow-overview)
  - Understand the six deployment phases
  - Aware of phase dependencies (DNS before SSL, etc.)

- [ ] **Time allocation confirmed**
  - 60-90 minutes allocated for complete deployment
  - Additional time available for DNS propagation (up to 30 minutes)
  - Troubleshooting time buffer considered

- [ ] **Troubleshooting resources identified**
  - [Troubleshooting Guide](#troubleshooting-guide) section bookmarked
  - AWS Lightsail documentation accessible: https://docs.aws.amazon.com/lightsail/
  - Tailscale documentation accessible: https://tailscale.com/kb/

---

#### Readiness Verification

Before proceeding to Phase 2 (Infrastructure Deployment), verify your complete setup by running all verification commands in sequence:

**1. Verify All Tools Are Installed:**

```bash
# Run all verification commands
echo "=== Tool Verification ==="
echo "AWS CLI: $(aws --version)"
echo "Terraform: $(terraform version | head -n 1)"  # Or skip if using CloudFormation
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "Git: $(git --version)"
echo "SSH: $(ssh -V 2>&1 | head -n 1)"
```

**Expected Output:** All commands should display version numbers meeting or exceeding the minimum requirements.

**2. Verify AWS Configuration:**

```bash
# Verify AWS credentials and Lightsail access
echo "=== AWS Configuration Verification ==="
aws sts get-caller-identity
aws lightsail get-regions --query 'regions[0:3].[name]' --output table
```

**Expected Output:**
- First command shows your AWS account ID and IAM user ARN
- Second command displays a table of Lightsail regions

**3. Verify Credentials Are Accessible:**

```bash
# Check that credential files exist (do not display contents)
echo "=== Credential Files Check ==="
[ -f ~/.aws/credentials ] && echo "✓ AWS credentials file exists" || echo "✗ AWS credentials file missing"
echo "Anthropic API key: [Verify you have this in your password manager]"
echo "Tailscale auth key: [Verify you have this in your password manager]"
```

**Expected Output:**
- AWS credentials file exists
- You can confirm you have the Anthropic API key and Tailscale auth key accessible

**4. Verify Domain Access:**

```bash
# Verify domain is registered and accessible
echo "=== Domain Verification ==="
echo "Domain name: [YOUR_DOMAIN_HERE]"
echo "Can access DNS settings: [YES/NO]"
echo "Domain status: [ACTIVE/EXPIRED]"
```

**Manual Verification:**
- Log in to your domain registrar
- Confirm you can access DNS settings
- Verify domain is active and not expired

---

#### Pre-Flight Checklist Summary

**All Prerequisites Met:**

- [ ] ✓ All required tools installed and verified
- [ ] ✓ All credentials obtained and stored securely
- [ ] ✓ AWS account configured and tested
- [ ] ✓ Domain name registered and accessible
- [ ] ✓ Security best practices applied
- [ ] ✓ Deployment workflow understood
- [ ] ✓ Time allocated for deployment
- [ ] ✓ Readiness verification commands executed successfully

**If all items are checked:** You are ready to proceed to Phase 2 (Infrastructure Deployment).

**If any items are not checked:** Review the relevant section above, complete the missing prerequisites, and return to this checklist.

---

#### Common Pre-Deployment Issues

**Issue: AWS CLI commands fail with "Unable to locate credentials"**

**Solution:**
```bash
# Reconfigure AWS credentials
aws configure

# Verify credentials file
cat ~/.aws/credentials  # Should show [default] profile with credentials
```

**Issue: Terraform or Node.js not found after installation**

**Solution:**
```bash
# Restart your terminal to reload PATH
# Or manually add to PATH (example for macOS/Linux)
export PATH="/usr/local/bin:$PATH"

# Verify again
terraform version
node --version
```

**Issue: Cannot access domain DNS settings**

**Solution:**
- Log in to your domain registrar's website
- Look for "DNS Management", "DNS Settings", or "Nameservers" section
- If using a third-party DNS provider (like Cloudflare), ensure nameservers are pointed correctly
- Contact registrar support if you cannot locate DNS settings

**Issue: Anthropic API key test fails**

**Solution:**
- Verify you copied the complete API key (they are very long)
- Check that billing is configured in the Anthropic Console
- Ensure the API key hasn't been deleted or revoked
- Try creating a new API key if the issue persists

**Issue: Tailscale auth key not working**

**Solution:**
- Verify the auth key hasn't expired (check expiration date in Tailscale admin console)
- Ensure the key is marked as "Reusable" and "Preauthorized"
- Check that you copied the complete key without truncation
- Generate a new auth key if needed

---

**Next Phase:** Once all prerequisites are verified, proceed to [Infrastructure Deployment Phase](#infrastructure-deployment-phase) to provision your AWS Lightsail instance.

---

## Infrastructure Deployment Phase

This phase provisions the AWS Lightsail instance and supporting infrastructure that will host the AI Website Builder. You have two deployment method options: Terraform or CloudFormation. Both methods create identical infrastructure, but differ in tooling and workflow.

**Phase Duration:** 10-15 minutes (infrastructure provisioning time)

**Prerequisites:**
- All items from [Pre-Deployment Prerequisites](#pre-deployment-prerequisites) completed
- AWS CLI configured and verified
- Either Terraform (>= 1.0) or AWS CLI for CloudFormation installed
- All required credentials accessible

**What Gets Created:**

Both deployment methods provision the following AWS resources:

1. **AWS Lightsail Instance**
   - Operating System: Ubuntu 22.04 LTS
   - Bundle: nano_2_0 (1 vCPU, 1GB RAM, 20GB SSD)
   - Monthly Cost: ~$7.00
   - Includes 1TB data transfer

2. **Static IP Address**
   - Persistent public IP address
   - Automatically attached to the instance
   - Free while attached to an instance

3. **Firewall Rules (Ports)**
   - Port 22 (SSH) - For server administration
   - Port 80 (HTTP) - For public web traffic
   - Port 443 (HTTPS) - For secure public web traffic
   - Port 41641 (UDP) - For Tailscale VPN

4. **Automatic Security Updates**
   - Configured via user-data script during instance creation
   - Daily security patch checks
   - Automatic installation of critical updates

5. **Directory Structure**
   - `/opt/website-builder/` - Application root directory
   - `/var/www/html/` - Public web root for NGINX

**Phase Overview:**

```text
Infrastructure Deployment Phase
├─ Step 1: Choose Deployment Method (Terraform or CloudFormation)
├─ Step 2: Configure Deployment Variables
├─ Step 3: Execute Infrastructure Deployment
├─ Step 4: Retrieve Deployment Outputs (Instance IP Address)
└─ Step 5: Verify Infrastructure Deployment
```

---

### Choosing Your Deployment Method

Before proceeding, you must choose between Terraform and CloudFormation. Both methods create identical infrastructure, but have different characteristics that may make one more suitable for your needs.

#### Decision Matrix

Use this matrix to determine which deployment method is best for your situation:

| **Criteria** | **Terraform** | **CloudFormation** |
|-------------|---------------|-------------------|
| **Best For** | Infrastructure-as-code workflows, multi-cloud environments, teams familiar with Terraform | AWS-native workflows, teams already using CloudFormation, AWS-centric organizations |
| **Learning Curve** | Moderate - requires learning HCL syntax and Terraform concepts | Moderate - requires learning CloudFormation template syntax (JSON/YAML) |
| **State Management** | Excellent - explicit state file with locking support | Good - AWS manages state automatically |
| **Tooling Required** | Terraform CLI + AWS CLI | AWS CLI only |
| **Configuration Format** | HCL (HashiCorp Configuration Language) - human-readable | JSON or YAML - more verbose |
| **Deployment Speed** | Fast - typically 5-8 minutes | Fast - typically 5-8 minutes |
| **Error Messages** | Clear and actionable | Can be verbose and AWS-specific |
| **Rollback Support** | Manual - requires `terraform destroy` or state manipulation | Automatic - CloudFormation rolls back on failure |
| **Change Preview** | Excellent - `terraform plan` shows exact changes | Good - change sets show modifications |
| **Multi-Cloud Support** | Yes - can manage AWS, Azure, GCP, etc. | No - AWS only |
| **Community Support** | Large community, extensive documentation | AWS official support, good documentation |
| **Version Control** | Easy - HCL files are git-friendly | Easy - JSON/YAML files are git-friendly |
| **Reusability** | High - modules and workspaces | Moderate - nested stacks and templates |
| **Cost** | Free (open source) | Free (AWS service) |

#### Advantages and Disadvantages

**Terraform Advantages:**

✅ **Better State Management**
- Explicit state file shows exactly what's deployed
- State locking prevents concurrent modifications
- Easy to inspect current infrastructure state

✅ **Superior Plan/Preview**
- `terraform plan` shows exactly what will change before applying
- Color-coded output clearly indicates additions, changes, and deletions
- Reduces risk of unexpected changes

✅ **More Readable Configuration**
- HCL syntax is designed for human readability
- Less verbose than CloudFormation JSON/YAML
- Easier to understand and maintain

✅ **Better Error Messages**
- Clear, actionable error messages
- Easier to debug configuration issues
- Better validation before deployment

✅ **Multi-Cloud Capability**
- Can manage resources across AWS, Azure, GCP, and other providers
- Useful if you plan to expand beyond AWS
- Consistent tooling across cloud providers

✅ **Extensive Module Ecosystem**
- Large library of community modules
- Easy to reuse and share configurations
- Active community support

**Terraform Disadvantages:**

❌ **Additional Tool Required**
- Must install and maintain Terraform CLI
- Another tool to learn and keep updated
- Requires understanding of Terraform-specific concepts

❌ **State File Management**
- State file must be stored and protected
- Risk of state file corruption or loss
- Requires careful handling in team environments

❌ **Manual Rollback**
- No automatic rollback on failure
- Must manually destroy or fix failed deployments
- Requires more operator intervention

❌ **Learning Curve**
- Need to learn HCL syntax
- Understanding of Terraform lifecycle (init, plan, apply)
- Concepts like state, providers, and resources

---

**CloudFormation Advantages:**

✅ **AWS Native Integration**
- Built into AWS, no additional tools required (beyond AWS CLI)
- Seamless integration with other AWS services
- Official AWS support and documentation

✅ **Automatic Rollback**
- Automatically rolls back on deployment failure
- Reduces risk of partial deployments
- Less manual intervention required

✅ **No State File Management**
- AWS manages state automatically
- No risk of state file loss or corruption
- Simpler for single-operator deployments

✅ **Simpler Tooling**
- Only requires AWS CLI (already needed for AWS access)
- No additional tools to install or maintain
- Fewer concepts to learn

✅ **AWS-Specific Features**
- Access to newest AWS features first
- Deep integration with AWS services
- CloudFormation-specific features (drift detection, stack sets)

**CloudFormation Disadvantages:**

❌ **More Verbose Configuration**
- JSON/YAML templates are longer and more complex
- Harder to read and understand
- More boilerplate code required

❌ **AWS-Only**
- Cannot manage resources outside AWS
- Locked into AWS ecosystem
- Not suitable for multi-cloud strategies

❌ **Less Clear Change Preview**
- Change sets can be harder to interpret
- Less intuitive than Terraform's plan output
- May require more careful review

❌ **Steeper Learning Curve for Templates**
- CloudFormation template syntax is complex
- Intrinsic functions (Ref, GetAtt, etc.) can be confusing
- More difficult to debug template errors

❌ **Limited Community Modules**
- Smaller ecosystem compared to Terraform
- Fewer reusable templates available
- Less community-driven innovation

---

#### Recommendation Based on Experience Level

**Choose Terraform if:**

- ✓ You're familiar with infrastructure-as-code concepts
- ✓ You value explicit state management and clear change previews
- ✓ You prefer more readable, concise configuration files
- ✓ You might expand to other cloud providers in the future
- ✓ You're comfortable installing and managing additional tools
- ✓ You want better error messages and debugging experience
- ✓ Your team already uses Terraform for other projects

**Choose CloudFormation if:**

- ✓ You prefer AWS-native tools and workflows
- ✓ You want automatic rollback on deployment failures
- ✓ You only need to manage AWS resources
- ✓ You want to minimize the number of tools to install
- ✓ Your organization has standardized on CloudFormation
- ✓ You prefer AWS official support and documentation
- ✓ You're already familiar with CloudFormation templates

**For First-Time Users:**

If you're new to both tools and deploying infrastructure-as-code:

- **Terraform is recommended** for this deployment because:
  - The configuration is simpler and easier to understand
  - Error messages are clearer and more actionable
  - The `terraform plan` command provides excellent visibility into what will happen
  - The deployment process is more straightforward
  - This guide provides detailed Terraform instructions

However, **CloudFormation is also a solid choice** if:
- You prefer to minimize tool installation
- You want automatic rollback protection
- You're committed to AWS-only infrastructure

**Both methods are fully supported and will create identical infrastructure.** Choose the one that best fits your preferences and organizational requirements.

---

#### Quick Comparison Example

Here's a side-by-side comparison of how the same configuration looks in both tools:

**Terraform (HCL)**:
```hcl
resource "aws_lightsail_instance" "app" {
  name              = "ai-website-builder"
  availability_zone = "us-east-1a"
  blueprint_id      = "ubuntu_22_04"
  bundle_id         = "nano_2_0"
  
  tags = {
    Environment = "production"
    Project     = "ai-website-builder"
  }
}
```

**CloudFormation (YAML)**:
```yaml
Resources:
  LightsailInstance:
    Type: AWS::Lightsail::Instance
    Properties:
      InstanceName: ai-website-builder
      AvailabilityZone: us-east-1a
      BlueprintId: ubuntu_22_04
      BundleId: nano_2_0
      Tags:
        - Key: Environment
          Value: production
        - Key: Project
          Value: ai-website-builder
```

As you can see, Terraform's HCL syntax is slightly more concise, while CloudFormation's YAML is more verbose but still readable.

---

### Next Steps

Once you've chosen your deployment method, proceed to the appropriate section:

- **Terraform Users**: Continue to [Terraform Deployment Path](#terraform-deployment-path) (Section 3.2)
- **CloudFormation Users**: Continue to [CloudFormation Deployment Path](#cloudformation-deployment-path) (Section 3.3)

Both paths will guide you through:
1. Configuring deployment variables
2. Executing the deployment
3. Retrieving deployment outputs (instance IP address)
4. Verifying the infrastructure is running correctly

**Important:** You only need to follow ONE deployment path. Do not attempt to deploy with both methods simultaneously, as this will create duplicate resources and incur additional costs.

---

### Terraform Deployment Path

This section guides you through deploying the AI Website Builder infrastructure using Terraform. Terraform will provision an AWS Lightsail instance, configure a static IP address, set up firewall rules, and prepare the server for application deployment.

**Prerequisites for This Section:**
- Terraform installed and verified (>= 1.0)
- AWS CLI configured with valid credentials
- All credentials from [Prerequisites](#pre-deployment-prerequisites) section accessible
- Domain name ready for configuration

**What This Section Covers:**
1. Configuring `terraform.tfvars` with your deployment variables
2. Initializing Terraform and downloading required providers
3. Reviewing the deployment plan
4. Executing the deployment
5. Retrieving and interpreting deployment outputs
6. Verifying the created infrastructure

**Estimated Time:** 10-15 minutes

---

#### Step 1: Navigate to Terraform Directory

First, navigate to the Terraform configuration directory in your local copy of the AI Website Builder repository:

```bash
cd infrastructure/terraform
```

**Verify you're in the correct directory:**

```bash
ls -la
```

**Expected Output:**
```text
-rw-r--r--  main.tf
-rw-r--r--  variables.tf
-rw-r--r--  outputs.tf
-rw-r--r--  terraform.tfvars.example
-rw-r--r--  user-data.sh
-rw-r--r--  README.md
```

If you don't see these files, ensure you've cloned the repository and are in the correct directory.

---

#### Step 2: Configure Terraform Variables

Terraform uses a `terraform.tfvars` file to store deployment-specific configuration values. You'll create this file from the provided example template.

**Create your configuration file:**

```bash
cp terraform.tfvars.example terraform.tfvars
```

**Edit the configuration file:**

```bash
# Use your preferred text editor
nano terraform.tfvars
# Or: vim terraform.tfvars
# Or: code terraform.tfvars (VS Code)
```

**Configuration Template:**

The `terraform.tfvars` file should contain the following variables. Replace the placeholder values with your actual configuration:

```hcl
# AWS Region - Choose a region close to your target audience
aws_region = "us-east-1"              # REPLACE: Your preferred AWS region

# Instance Name - Identifier for your Lightsail instance
instance_name = "ai-website-builder"  # OPTIONAL: Customize if deploying multiple instances

# Environment - Deployment environment identifier
environment = "production"            # OPTIONAL: production, staging, development, etc.

# Domain Name - Your registered domain name
domain = "yourdomain.com"             # REPLACE: Your actual domain (e.g., example.com)

# SSL Email - Email address for Let's Encrypt certificate notifications
ssl_email = "admin@yourdomain.com"    # REPLACE: Your email for SSL certificate alerts

# Anthropic API Key - For Claude AI integration
anthropic_api_key = "sk-ant-api03-xxxxx"  # REPLACE: Your actual Anthropic API key

# Tailscale Auth Key - For VPN setup
tailscale_auth_key = "tskey-auth-xxxxx"   # REPLACE: Your actual Tailscale auth key
```

**Variable Descriptions:**

| Variable | Required | Description | Example | Validation |
|----------|----------|-------------|---------|------------|
| `aws_region` | Yes | AWS region for deployment. Choose a region close to your users for better performance. | `us-east-1`, `us-west-2`, `eu-west-1` | Must be a valid AWS region with Lightsail support |
| `instance_name` | Yes | Name for the Lightsail instance. Used for identification in AWS console. | `ai-website-builder`, `my-website-prod` | Alphanumeric and hyphens only, 3-255 characters |
| `environment` | Yes | Environment identifier for tagging and organization. | `production`, `staging`, `dev` | Any string, typically: production, staging, development |
| `domain` | Yes | Your registered domain name. Used for SSL certificates and NGINX configuration. | `example.com`, `mysite.io` | Valid domain name format (no http://, no trailing slash) |
| `ssl_email` | Yes | Email address for Let's Encrypt SSL certificate notifications and renewal alerts. | `admin@example.com`, `ops@mysite.io` | Valid email address format |
| `anthropic_api_key` | Yes | Anthropic API key for Claude integration. Starts with `sk-ant-api03-`. | `sk-ant-api03-...` | Must start with `sk-ant-`, very long string |
| `tailscale_auth_key` | Yes | Tailscale authentication key for VPN setup. Starts with `tskey-auth-`. | `tskey-auth-...` | Must start with `tskey-auth-` or `tskey-` |

**Important Configuration Notes:**

⚠️ **Domain Name Format:**
- Use the root domain only (e.g., `example.com`)
- Do NOT include `http://` or `https://`
- Do NOT include `www.` prefix
- Do NOT include trailing slashes
- Examples:
  - ✅ Correct: `example.com`
  - ✅ Correct: `mysite.io`
  - ❌ Wrong: `https://example.com`
  - ❌ Wrong: `www.example.com`
  - ❌ Wrong: `example.com/`

⚠️ **SSL Email:**
- Use a valid, monitored email address
- You'll receive certificate expiration warnings (though renewal is automatic)
- Let's Encrypt may send important notifications to this address

⚠️ **API Keys:**
- Ensure you copy the complete key (they are very long)
- Do not add quotes, spaces, or line breaks
- Verify keys are valid before deploying (see [Prerequisites](#credential-acquisition-procedures))

⚠️ **AWS Region Selection:**
- Choose a region close to your target audience for better performance
- Verify Lightsail is available in your chosen region
- Common regions:
  - `us-east-1` (US East - N. Virginia) - Most services, lowest cost
  - `us-west-2` (US West - Oregon) - West coast US
  - `eu-west-1` (Europe - Ireland) - Europe
  - `ap-southeast-1` (Asia Pacific - Singapore) - Asia
- Full list: https://docs.aws.amazon.com/general/latest/gr/lightsail.html

**Security Reminder:**

🔒 The `terraform.tfvars` file contains sensitive credentials and is automatically excluded from version control via `.gitignore`. Never commit this file to Git or share it publicly.

**Verify your configuration:**

After editing, verify the file contains all required variables:

```bash
cat terraform.tfvars
```

Ensure all placeholder values have been replaced with your actual configuration.

---

#### Step 3: Initialize Terraform

Terraform initialization downloads the required provider plugins (AWS provider) and prepares the working directory for deployment.

**Run Terraform initialization:**

```bash
terraform init
```

**Expected Output:**

```text
Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v5.x.x...
- Installed hashicorp/aws v5.x.x (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

**What This Command Does:**

- Downloads the AWS provider plugin (enables Terraform to interact with AWS)
- Creates a `.terraform` directory with provider binaries
- Creates a `.terraform.lock.hcl` file to lock provider versions
- Initializes the Terraform state (creates `terraform.tfstate` after first apply)

**If initialization fails:**

**Error: "No valid credential sources found"**
```bash
# Solution: Reconfigure AWS credentials
aws configure

# Verify credentials work
aws sts get-caller-identity
```

**Error: "Failed to install provider"**
```bash
# Solution: Check internet connection and try again
# Or specify a different provider version in main.tf
terraform init -upgrade
```

**Error: "Terraform not found"**
```bash
# Solution: Ensure Terraform is installed and in PATH
terraform version

# If not found, reinstall Terraform (see Prerequisites section)
```

---

#### Step 4: Review the Deployment Plan

Before creating any resources, Terraform allows you to preview exactly what will be created, modified, or destroyed. This is one of Terraform's most powerful features.

**Generate and review the deployment plan:**

```bash
terraform plan
```

**Expected Output:**

Terraform will display a detailed plan showing all resources that will be created. The output will be color-coded (if your terminal supports it):

```text
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_lightsail_instance.website_builder will be created
  + resource "aws_lightsail_instance" "website_builder" {
      + arn               = (known after apply)
      + availability_zone = "us-east-1a"
      + blueprint_id      = "ubuntu_22_04"
      + bundle_id         = "nano_2_0"
      + cpu_count         = (known after apply)
      + created_at        = (known after apply)
      + id                = (known after apply)
      + ipv6_addresses    = (known after apply)
      + is_static_ip      = (known after apply)
      + key_pair_name     = (known after apply)
      + name              = "ai-website-builder"
      + private_ip_address = (known after apply)
      + public_ip_address  = (known after apply)
      + ram_size          = (known after apply)
      + tags              = {
          + "Environment" = "production"
          + "Project"     = "ai-website-builder"
        }
      + tags_all          = {
          + "Environment" = "production"
          + "Project"     = "ai-website-builder"
        }
      + user_data         = <<-EOT
            #!/bin/bash
            # User data script for initial server setup
            ...
        EOT
      + username          = (known after apply)
    }

  # aws_lightsail_static_ip.website_builder will be created
  + resource "aws_lightsail_static_ip" "website_builder" {
      + arn          = (known after apply)
      + id           = (known after apply)
      + ip_address   = (known after apply)
      + name         = "ai-website-builder-static-ip"
      + support_code = (known after apply)
    }

  # aws_lightsail_static_ip_attachment.website_builder will be created
  + resource "aws_lightsail_static_ip_attachment" "website_builder" {
      + id             = (known after apply)
      + instance_name  = "ai-website-builder"
      + ip_address     = (known after apply)
      + static_ip_name = "ai-website-builder-static-ip"
    }

  # aws_lightsail_instance_public_ports.website_builder will be created
  + resource "aws_lightsail_instance_public_ports" "website_builder" {
      + id            = (known after apply)
      + instance_name = "ai-website-builder"

      + port_info {
          + from_port = 22
          + protocol  = "tcp"
          + to_port   = 22
        }
      + port_info {
          + from_port = 80
          + protocol  = "tcp"
          + to_port   = 80
        }
      + port_info {
          + from_port = 443
          + protocol  = "tcp"
          + to_port   = 443
        }
      + port_info {
          + from_port = 41641
          + protocol  = "udp"
          + to_port   = 41641
        }
    }

Plan: 4 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + instance_id   = (known after apply)
  + instance_name = "ai-website-builder"
  + next_steps    = (known after apply)
  + public_ip     = (known after apply)
  + ssh_command   = (known after apply)
  + static_ip_name = "ai-website-builder-static-ip"
```

**Understanding the Plan Output:**

- **`+ create`**: Resources that will be created (green in color terminals)
- **`~ modify`**: Resources that will be modified (yellow) - should be none for initial deployment
- **`- destroy`**: Resources that will be destroyed (red) - should be none for initial deployment
- **`(known after apply)`**: Values that will be determined during deployment

**Resources Being Created:**

1. **`aws_lightsail_instance.website_builder`**
   - The main Lightsail instance running Ubuntu 22.04
   - Bundle: nano_2_0 (1 vCPU, 1GB RAM, 20GB SSD)
   - Includes user-data script for initial setup

2. **`aws_lightsail_static_ip.website_builder`**
   - A persistent static IP address
   - Remains even if instance is stopped or restarted

3. **`aws_lightsail_static_ip_attachment.website_builder`**
   - Attaches the static IP to the instance

4. **`aws_lightsail_instance_public_ports.website_builder`**
   - Firewall rules opening required ports:
     - Port 22 (SSH) - Server administration
     - Port 80 (HTTP) - Public web traffic
     - Port 443 (HTTPS) - Secure public web traffic
     - Port 41641 (UDP) - Tailscale VPN

**Verify the Plan:**

Before proceeding, verify:
- [ ] 4 resources will be created
- [ ] Instance name matches your `instance_name` variable
- [ ] All four required ports are listed (22, 80, 443, 41641)
- [ ] No unexpected resources are being created
- [ ] No resources are being destroyed (should be 0 for initial deployment)

**If the plan looks incorrect:**

- Review your `terraform.tfvars` file for typos or incorrect values
- Ensure you're in the correct directory (`infrastructure/terraform`)
- Check that `terraform init` completed successfully
- Verify your AWS credentials are configured correctly

**Common Plan Issues:**

**Issue: "Error: No configuration files"**
```bash
# Solution: Ensure you're in the terraform directory
pwd  # Should show: .../infrastructure/terraform
ls   # Should show: main.tf, variables.tf, etc.
```

**Issue: "Error: Required variable not set"**
```bash
# Solution: Ensure terraform.tfvars exists and contains all required variables
cat terraform.tfvars
```

**Issue: "Error: Invalid AWS credentials"**
```bash
# Solution: Reconfigure AWS CLI
aws configure
aws sts get-caller-identity
```

---

#### Step 5: Execute the Deployment

Once you've reviewed the plan and verified it's correct, you can proceed with the actual deployment.

**Apply the Terraform configuration:**

```bash
terraform apply
```

**Interactive Confirmation:**

Terraform will display the plan again and prompt for confirmation:

```
Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: 
```

**Type `yes` and press Enter to proceed with deployment.**

**Deployment Progress:**

Terraform will create resources and display progress in real-time:

```
aws_lightsail_static_ip.website_builder: Creating...
aws_lightsail_instance.website_builder: Creating...
aws_lightsail_static_ip.website_builder: Creation complete after 2s [id=ai-website-builder-static-ip]
aws_lightsail_instance.website_builder: Still creating... [10s elapsed]
aws_lightsail_instance.website_builder: Still creating... [20s elapsed]
aws_lightsail_instance.website_builder: Still creating... [30s elapsed]
aws_lightsail_instance.website_builder: Creation complete after 35s [id=ai-website-builder]
aws_lightsail_static_ip_attachment.website_builder: Creating...
aws_lightsail_instance_public_ports.website_builder: Creating...
aws_lightsail_static_ip_attachment.website_builder: Creation complete after 3s
aws_lightsail_instance_public_ports.website_builder: Creation complete after 4s

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

**Expected Duration:** 5-10 minutes for complete deployment

**What Happens During Deployment:**

1. **Static IP Creation** (2-5 seconds)
   - AWS allocates a persistent public IP address

2. **Instance Creation** (30-60 seconds)
   - AWS provisions the Lightsail instance
   - Ubuntu 22.04 is installed
   - User-data script begins execution

3. **IP Attachment** (2-5 seconds)
   - Static IP is attached to the instance

4. **Firewall Configuration** (2-5 seconds)
   - Port rules are applied to the instance

5. **Background Setup** (continues after Terraform completes)
   - User-data script installs system updates
   - Automatic security updates are configured
   - Directory structure is created
   - This continues in the background for 5-10 minutes

**If deployment fails:**

Terraform will display detailed error messages. Common issues:

**Error: "Error creating Lightsail Instance: InvalidInput"**
```
Cause: Invalid configuration value (instance name, region, etc.)
Solution: Review terraform.tfvars for typos, ensure instance_name is valid
```

**Error: "Error: UnauthorizedException"**
```
Cause: AWS credentials are invalid or lack permissions
Solution: Verify AWS credentials and IAM permissions
aws sts get-caller-identity
```

**Error: "Error: ResourceNotFoundException"**
```
Cause: Specified region doesn't support Lightsail or blueprint
Solution: Choose a different region or verify blueprint_id in main.tf
```

**Partial Deployment:**

If deployment fails partway through, Terraform will show which resources were created and which failed. You can:

1. **Fix the issue** and run `terraform apply` again (Terraform will only create missing resources)
2. **Destroy and retry**: Run `terraform destroy` to remove partial deployment, fix the issue, then `terraform apply` again

---

#### Step 6: Retrieve and Interpret Deployment Outputs

After successful deployment, Terraform displays output values containing important information you'll need for the next phases.

**View Deployment Outputs:**

If you missed the outputs or need to view them again:

```bash
terraform output
```

**Expected Output:**

```text
instance_id = "ai-website-builder"
instance_name = "ai-website-builder"
next_steps = <<EOT
Deployment complete! Next steps:

1. Point your domain DNS to: 54.123.45.67
2. SSH into the instance: ssh ubuntu@54.123.45.67
3. Check deployment logs: sudo journalctl -u website-builder
4. Access builder interface via Tailscale VPN on port 3000
5. Public website will be available at: https://yourdomain.com
EOT
public_ip = "54.123.45.67"
ssh_command = "ssh ubuntu@54.123.45.67"
static_ip_name = "ai-website-builder-static-ip"
```

**Output Descriptions:**

| Output | Description | Usage |
|--------|-------------|-------|
| `public_ip` | The static IP address of your instance | Use this for DNS configuration (next phase) |
| `ssh_command` | Ready-to-use SSH command | Copy and paste to connect to your server |
| `instance_id` | Lightsail instance identifier | Used for AWS console lookups and troubleshooting |
| `instance_name` | Human-readable instance name | Used for identification in AWS console |
| `static_ip_name` | Name of the static IP resource | Used for AWS console lookups |
| `next_steps` | Summary of what to do next | Follow these steps to continue deployment |

**Save Important Information:**

**Copy and save the following for use in subsequent phases:**

1. **Public IP Address**: `_________________` (from `public_ip` output)
   - You'll need this for DNS configuration in Phase 3
   - You'll use this to SSH into the server in Phase 4

2. **SSH Command**: `_________________` (from `ssh_command` output)
   - Ready-to-use command for connecting to your server

**View Specific Output:**

To view a single output value:

```bash
# View just the public IP
terraform output public_ip

# View just the SSH command
terraform output ssh_command

# View output in JSON format (useful for scripting)
terraform output -json
```

**Output in JSON Format:**

```bash
terraform output -json
```

```json
{
  "instance_id": {
    "sensitive": false,
    "type": "string",
    "value": "ai-website-builder"
  },
  "public_ip": {
    "sensitive": false,
    "type": "string",
    "value": "54.123.45.67"
  },
  "ssh_command": {
    "sensitive": false,
    "type": "string",
    "value": "ssh ubuntu@54.123.45.67"
  }
}
```

---

#### Step 7: Verify Infrastructure Deployment

Before proceeding to DNS configuration, verify that the infrastructure was created correctly and the instance is running.

**Verification Checklist:**

**1. Verify Instance is Running (AWS CLI):**

```bash
aws lightsail get-instance --instance-name ai-website-builder
```

**Expected Output:**

```json
{
    "instance": {
        "name": "ai-website-builder",
        "arn": "arn:aws:lightsail:us-east-1:...",
        "supportCode": "...",
        "createdAt": "2024-01-15T10:30:00Z",
        "location": {
            "availabilityZone": "us-east-1a",
            "regionName": "us-east-1"
        },
        "resourceType": "Instance",
        "blueprintId": "ubuntu_22_04",
        "blueprintName": "Ubuntu",
        "bundleId": "nano_2_0",
        "state": {
            "code": 16,
            "name": "running"
        },
        "publicIpAddress": "54.123.45.67",
        "privateIpAddress": "172.26.x.x",
        ...
    }
}
```

**Key fields to verify:**
- `"name": "running"` - Instance is running
- `"publicIpAddress"` - Matches the Terraform output
- `"blueprintId": "ubuntu_22_04"` - Correct OS
- `"bundleId": "nano_2_0"` - Correct instance size

**2. Verify Static IP is Attached:**

```bash
aws lightsail get-static-ip --static-ip-name ai-website-builder-static-ip
```

**Expected Output:**

```json
{
    "staticIp": {
        "name": "ai-website-builder-static-ip",
        "arn": "arn:aws:lightsail:us-east-1:...",
        "ipAddress": "54.123.45.67",
        "attachedTo": "ai-website-builder",
        "isAttached": true,
        ...
    }
}
```

**Key fields to verify:**
- `"isAttached": true` - IP is attached to instance
- `"attachedTo": "ai-website-builder"` - Attached to correct instance
- `"ipAddress"` - Matches the Terraform output

**3. Verify Firewall Rules:**

```bash
aws lightsail get-instance-port-states --instance-name ai-website-builder
```

**Expected Output:**

```json
{
    "portStates": [
        {
            "fromPort": 22,
            "toPort": 22,
            "protocol": "tcp",
            "state": "open"
        },
        {
            "fromPort": 80,
            "toPort": 80,
            "protocol": "tcp",
            "state": "open"
        },
        {
            "fromPort": 443,
            "toPort": 443,
            "protocol": "tcp",
            "state": "open"
        },
        {
            "fromPort": 41641,
            "toPort": 41641,
            "protocol": "udp",
            "state": "open"
        }
    ]
}
```

**Verify all four required ports are open:**
- [ ] Port 22 (TCP) - SSH
- [ ] Port 80 (TCP) - HTTP
- [ ] Port 443 (TCP) - HTTPS
- [ ] Port 41641 (UDP) - Tailscale VPN

**4. Test SSH Connectivity:**

```bash
# Use the SSH command from Terraform output
ssh ubuntu@54.123.45.67
```

**Expected Result:**

You should be able to connect to the instance. On first connection, you'll see:

```
The authenticity of host '54.123.45.67 (54.123.45.67)' can't be established.
ED25519 key fingerprint is SHA256:...
Are you sure you want to continue connecting (yes/no/[fingerprint])? 
```

Type `yes` and press Enter.

**If SSH connection succeeds**, you'll see the Ubuntu welcome message:

```
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-1045-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

ubuntu@ip-172-26-x-x:~$ 
```

**Type `exit` to disconnect** (we'll reconnect in Phase 4 for server configuration).

**If SSH connection fails:**

```bash
# Check if instance is running
aws lightsail get-instance-state --instance-name ai-website-builder

# Verify firewall allows SSH (port 22)
aws lightsail get-instance-port-states --instance-name ai-website-builder | grep -A 3 '"fromPort": 22'

# Check if you're using the correct IP
terraform output public_ip

# Try with verbose output to see connection details
ssh -v ubuntu@54.123.45.67
```

**Common SSH Issues:**

**Issue: "Connection timed out"**
```
Cause: Firewall blocking port 22, or instance not fully started
Solution: Wait 1-2 minutes for instance to fully boot, verify port 22 is open
```

**Issue: "Permission denied (publickey)"**
```
Cause: SSH key not configured correctly
Solution: Lightsail uses default SSH keys. Download from AWS console:
https://lightsail.aws.amazon.com/ls/webapp/account/keys
```

**Issue: "Host key verification failed"**
```
Cause: SSH host key changed (if redeploying to same IP)
Solution: Remove old host key:
ssh-keygen -R 54.123.45.67
```

**5. Verify User-Data Script Execution:**

The user-data script runs automatically during instance creation. Verify it completed successfully:

```bash
# SSH into the instance
ssh ubuntu@54.123.45.67

# Check user-data script logs
sudo cat /var/log/cloud-init-output.log | tail -50

# Verify automatic updates are configured
sudo cat /etc/apt/apt.conf.d/20auto-upgrades

# Verify directory structure was created
ls -la /opt/website-builder/

# Exit SSH session
exit
```

**Expected Results:**

- `/var/log/cloud-init-output.log` should show successful package installations
- `/etc/apt/apt.conf.d/20auto-upgrades` should exist and contain update configuration
- `/opt/website-builder/` directory should exist

**If user-data script failed:**

The script runs in the background and may take 5-10 minutes to complete. If it's still running:

```bash
# Check if cloud-init is still running
sudo cloud-init status

# Expected output if complete: "status: done"
# Expected output if running: "status: running"
```

If the script failed, you can manually run the setup commands in Phase 4 (Server Configuration).

---

#### Verification Summary

**Infrastructure Deployment Verification Checklist:**

- [ ] Terraform apply completed successfully (4 resources created)
- [ ] Public IP address retrieved from Terraform output
- [ ] Instance state is "running" (verified with AWS CLI)
- [ ] Static IP is attached to instance (verified with AWS CLI)
- [ ] All four required ports are open (22, 80, 443, 41641)
- [ ] SSH connection to instance successful
- [ ] User-data script completed (verified via cloud-init logs)
- [ ] Directory structure created (`/opt/website-builder/` exists)

**If all items are checked:** Your infrastructure is successfully deployed and ready for DNS configuration.

**If any items failed:** Review the troubleshooting steps above or consult the [Troubleshooting Guide](#troubleshooting-guide) section.

---

#### Terraform State Management

After deployment, Terraform creates a state file (`terraform.tfstate`) that tracks the resources it manages.

**Important State File Notes:**

🔒 **Security:**
- The state file contains sensitive information (IP addresses, resource IDs)
- It is excluded from version control via `.gitignore`
- Never commit `terraform.tfstate` to Git

💾 **Backup:**
- Terraform automatically creates `terraform.tfstate.backup` after each apply
- Keep backups of your state file in a secure location
- Consider using remote state storage (S3 + DynamoDB) for team environments

**View Current State:**

```bash
# List all resources in state
terraform state list

# Show details of a specific resource
terraform state show aws_lightsail_instance.website_builder
```

**State File Location:**

```bash
ls -la terraform.tfstate*
```

**Expected Output:**
```text
-rw-r--r--  terraform.tfstate
-rw-r--r--  terraform.tfstate.backup
```

---

#### Next Steps After Terraform Deployment

**Infrastructure deployment is complete!** You now have:

✅ A running AWS Lightsail instance with Ubuntu 22.04  
✅ A static IP address attached to the instance  
✅ Firewall rules configured for web traffic and VPN  
✅ Automatic security updates enabled  
✅ Directory structure prepared for the application  

**What You Need for the Next Phase:**

- **Public IP Address**: `_________________` (from Terraform output)
- **SSH Command**: `ssh ubuntu@[your-ip]`
- **Domain Name**: `_________________` (from your terraform.tfvars)

**Proceed to Phase 3: DNS Configuration**

In the next phase, you'll:
1. Configure DNS A records to point your domain to the instance IP
2. Wait for DNS propagation
3. Verify DNS resolution before SSL setup

**Continue to:** [DNS Configuration Phase](#dns-configuration-phase)

---

### CloudFormation Deployment Path

This section guides you through deploying the AI Website Builder infrastructure using AWS CloudFormation. CloudFormation will provision an AWS Lightsail instance, configure a static IP address, and prepare the server for application deployment. Unlike Terraform, CloudFormation is AWS-native and requires only the AWS CLI.

**Prerequisites for This Section:**
- AWS CLI installed and configured (>= 2.0)
- All credentials from [Prerequisites](#pre-deployment-prerequisites) section accessible
- Domain name ready for configuration

**What This Section Covers:**
1. Configuring `parameters.json` with your deployment variables
2. Validating the CloudFormation template
3. Creating the CloudFormation stack
4. Monitoring stack creation progress
5. Retrieving and interpreting stack outputs
6. Configuring firewall rules (CloudFormation limitation workaround)
7. Verifying the created infrastructure

**Estimated Time:** 10-15 minutes

---

#### Step 1: Navigate to CloudFormation Directory

First, navigate to the CloudFormation configuration directory in your local copy of the AI Website Builder repository:

```bash
cd infrastructure/cloudformation
```

**Verify you're in the correct directory:**

```bash
ls -la
```

**Expected Output:**
```text
-rw-r--r--  lightsail-stack.yaml
-rw-r--r--  parameters.json.example
-rwxr-xr-x  deploy-cloudformation.sh
-rwxr-xr-x  configure-firewall.sh
-rw-r--r--  README.md
```

If you don't see these files, ensure you've cloned the repository and are in the correct directory.

---

#### Step 2: Configure CloudFormation Parameters

CloudFormation uses a `parameters.json` file to store deployment-specific configuration values. You'll create this file from the provided example template.

**Create your parameters file:**

```bash
cp parameters.json.example parameters.json
```

**Edit the parameters file:**

```bash
# Use your preferred text editor
nano parameters.json
# Or: vim parameters.json
# Or: code parameters.json (VS Code)
```

**Parameters Template:**

The `parameters.json` file should contain the following parameters. Replace the placeholder values with your actual configuration:

```json
[
  {
    "ParameterKey": "InstanceName",
    "ParameterValue": "ai-website-builder"
  },
  {
    "ParameterKey": "Domain",
    "ParameterValue": "yourdomain.com"
  },
  {
    "ParameterKey": "SSLEmail",
    "ParameterValue": "admin@yourdomain.com"
  },
  {
    "ParameterKey": "AnthropicAPIKey",
    "ParameterValue": "sk-ant-api03-xxxxx"
  },
  {
    "ParameterKey": "TailscaleAuthKey",
    "ParameterValue": "tskey-auth-xxxxx"
  }
]
```

**Parameter Descriptions:**

| Parameter | Required | Description | Example | Validation |
|-----------|----------|-------------|---------|------------|
| `InstanceName` | Yes | Name for the Lightsail instance. Used for identification in AWS console. | `ai-website-builder`, `my-website-prod` | Alphanumeric and hyphens only, 3-255 characters |
| `Domain` | Yes | Your registered domain name. Used for SSL certificates and NGINX configuration. | `example.com`, `mysite.io` | Valid domain name format (no http://, no trailing slash) |
| `SSLEmail` | Yes | Email address for Let's Encrypt SSL certificate notifications and renewal alerts. | `admin@example.com`, `ops@mysite.io` | Valid email address format |
| `AnthropicAPIKey` | Yes | Anthropic API key for Claude integration. Starts with `sk-ant-api03-`. | `sk-ant-api03-...` | Must start with `sk-ant-`, very long string |
| `TailscaleAuthKey` | Yes | Tailscale authentication key for VPN setup. Starts with `tskey-auth-`. | `tskey-auth-...` | Must start with `tskey-auth-` or `tskey-` |

**Important Configuration Notes:**

⚠️ **Domain Name Format:**
- Use the root domain only (e.g., `example.com`)
- Do NOT include `http://` or `https://`
- Do NOT include `www.` prefix
- Do NOT include trailing slashes
- Examples:
  - ✅ Correct: `example.com`
  - ✅ Correct: `mysite.io`
  - ❌ Wrong: `https://example.com`
  - ❌ Wrong: `www.example.com`
  - ❌ Wrong: `example.com/`

⚠️ **SSL Email:**
- Use a valid, monitored email address
- You'll receive certificate expiration warnings (though renewal is automatic)
- Let's Encrypt may send important notifications to this address

⚠️ **API Keys:**
- Ensure you copy the complete key (they are very long)
- Use proper JSON string format (enclosed in quotes)
- Do not add extra spaces or line breaks
- Verify keys are valid before deploying (see [Prerequisites](#credential-acquisition-procedures))

⚠️ **JSON Format:**
- Ensure proper JSON syntax (commas between objects, no trailing comma)
- All values must be enclosed in double quotes
- Validate JSON syntax before deployment

**Security Reminder:**

🔒 The `parameters.json` file contains sensitive credentials and is automatically excluded from version control via `.gitignore`. Never commit this file to Git or share it publicly.

**Verify your configuration:**

After editing, verify the file contains valid JSON and all required parameters:

```bash
cat parameters.json
```

**Validate JSON syntax:**

```bash
# Using Python (pre-installed on most systems)
python3 -m json.tool parameters.json

# Or using jq (if installed)
jq . parameters.json
```

If the command outputs the formatted JSON without errors, your syntax is correct.

---

#### Step 3: Validate CloudFormation Template

Before creating the stack, validate that the CloudFormation template is syntactically correct and can be processed by AWS.

**Run template validation:**

```bash
aws cloudformation validate-template \
  --template-body file://lightsail-stack.yaml
```

**Expected Output:**

```json
{
    "Parameters": [
        {
            "ParameterKey": "InstanceName",
            "DefaultValue": "ai-website-builder",
            "NoEcho": false,
            "Description": "Name for the Lightsail instance"
        },
        {
            "ParameterKey": "Domain",
            "NoEcho": false,
            "Description": "Domain name for the website"
        },
        {
            "ParameterKey": "SSLEmail",
            "NoEcho": false,
            "Description": "Email address for Let's Encrypt SSL certificates"
        },
        {
            "ParameterKey": "AnthropicAPIKey",
            "NoEcho": true,
            "Description": "Anthropic API key for Claude integration"
        },
        {
            "ParameterKey": "TailscaleAuthKey",
            "NoEcho": true,
            "Description": "Tailscale authentication key for VPN setup"
        }
    ],
    "Description": "AI Website Builder - AWS Lightsail Infrastructure",
    "Capabilities": [],
    "CapabilitiesReason": "The template does not require any capabilities"
}
```

**What This Command Does:**

- Checks CloudFormation template syntax
- Validates resource definitions
- Confirms parameter definitions
- Verifies template can be processed by AWS
- Does NOT create any resources (safe to run)

**If validation fails:**

**Error: "Template format error"**
```bash
# Solution: Check YAML syntax in lightsail-stack.yaml
# Ensure proper indentation and no syntax errors
```

**Error: "Unable to validate template"**
```bash
# Solution: Verify AWS CLI is configured correctly
aws sts get-caller-identity

# Ensure you're using the correct file path
ls -la lightsail-stack.yaml
```

**Error: "Invalid template property or properties"**
```bash
# Solution: This indicates an issue with the template itself
# Verify you're using the correct version of the template
# Check for any manual modifications that may have introduced errors
```

---

#### Step 4: Create the CloudFormation Stack

Once the template is validated, you can create the CloudFormation stack to provision the infrastructure.

**Create the stack:**

```bash
aws cloudformation create-stack \
  --stack-name ai-website-builder \
  --template-body file://lightsail-stack.yaml \
  --parameters file://parameters.json \
  --region us-east-1
```

**Command Breakdown:**

- `--stack-name ai-website-builder`: Name for your CloudFormation stack (you can customize this)
- `--template-body file://lightsail-stack.yaml`: Path to the CloudFormation template
- `--parameters file://parameters.json`: Path to your parameters file
- `--region us-east-1`: AWS region for deployment (change if needed)

**Region Selection:**

Choose a region close to your target audience for better performance:
- `us-east-1` (US East - N. Virginia) - Most services, lowest cost
- `us-west-2` (US West - Oregon) - West coast US
- `eu-west-1` (Europe - Ireland) - Europe
- `ap-southeast-1` (Asia Pacific - Singapore) - Asia

Full list: https://docs.aws.amazon.com/general/latest/gr/lightsail.html

**Expected Output:**

```json
{
    "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/ai-website-builder/abc12345-1234-1234-1234-123456789abc"
}
```

The `StackId` confirms that stack creation has been initiated. The stack will now be created in the background.

**What Happens During Stack Creation:**

1. **CloudFormation validates parameters** (2-5 seconds)
2. **Resources are created in order** (5-10 minutes):
   - Static IP allocation
   - Lightsail instance provisioning
   - Static IP attachment
3. **User-data script executes** (continues in background after stack completes)

---

#### Step 5: Monitor Stack Creation Progress

CloudFormation stack creation takes several minutes. You can monitor progress using the AWS CLI.

**Check stack status:**

```bash
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query 'Stacks[0].StackStatus' \
  --output text
```

**Possible Status Values:**

- `CREATE_IN_PROGRESS` - Stack is being created (wait)
- `CREATE_COMPLETE` - Stack created successfully (proceed to next step)
- `CREATE_FAILED` - Stack creation failed (see troubleshooting below)
- `ROLLBACK_IN_PROGRESS` - CloudFormation is rolling back due to failure
- `ROLLBACK_COMPLETE` - Rollback completed, stack creation failed

**Watch stack events in real-time:**

```bash
aws cloudformation describe-stack-events \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query 'StackEvents[*].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId,ResourceStatusReason]' \
  --output table
```

This command displays a table of all stack events, showing which resources are being created and their status.

**Monitor with automatic refresh (Linux/macOS):**

```bash
watch -n 10 'aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query "Stacks[0].StackStatus" \
  --output text'
```

This will refresh the status every 10 seconds. Press `Ctrl+C` to stop.

**Expected Duration:** 5-10 minutes for stack creation to complete

**Wait for CREATE_COMPLETE status before proceeding to the next step.**

---

#### Step 6: Retrieve and Interpret Stack Outputs

After the stack reaches `CREATE_COMPLETE` status, you can retrieve the deployment outputs containing important information for the next phases.

**View all stack outputs:**

```bash
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query 'Stacks[0].Outputs' \
  --output table
```

**Expected Output:**

```text
-------------------------------------------------------------------------------------------------------------------------
|                                                    DescribeStacks                                                     |
+---------------+-------------------------------------------------------------------------------------------------------+
|   OutputKey   |                                             OutputValue                                               |
+---------------+-------------------------------------------------------------------------------------------------------+
|  InstanceId   |  ai-website-builder                                                                                   |
|  InstanceName |  ai-website-builder                                                                                   |
|  PublicIP     |  54.123.45.67                                                                                         |
|  SSHCommand   |  ssh ubuntu@54.123.45.67                                                                              |
|  StaticIPName |  ai-website-builder-static-ip                                                                         |
|  NextSteps    |  Deployment complete! Next steps:                                                                     |
|               |                                                                                                       |
|               |  1. Point your domain DNS to: 54.123.45.67                                                            |
|               |  2. SSH into the instance: ssh ubuntu@54.123.45.67                                                    |
|               |  3. Check deployment logs: sudo journalctl -u website-builder                                         |
|               |  4. Access builder interface via Tailscale VPN on port 3000                                           |
|               |  5. Public website will be available at: https://yourdomain.com                                       |
+---------------+-------------------------------------------------------------------------------------------------------+
```

**Output Descriptions:**

| Output | Description | Usage |
|--------|-------------|-------|
| `PublicIP` | The static IP address of your instance | Use this for DNS configuration (next phase) |
| `SSHCommand` | Ready-to-use SSH command | Copy and paste to connect to your server |
| `InstanceId` | Lightsail instance identifier | Used for AWS console lookups and troubleshooting |
| `InstanceName` | Human-readable instance name | Used for identification in AWS console |
| `StaticIPName` | Name of the static IP resource | Used for AWS console lookups |
| `NextSteps` | Summary of what to do next | Follow these steps to continue deployment |

**Retrieve specific output values:**

```bash
# Get just the public IP
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' \
  --output text

# Get just the SSH command
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`SSHCommand`].OutputValue' \
  --output text
```

**Save Important Information:**

**Copy and save the following for use in subsequent phases:**

1. **Public IP Address**: `_________________` (from `PublicIP` output)
   - You'll need this for DNS configuration in Phase 3
   - You'll use this to SSH into the server in Phase 4

2. **SSH Command**: `_________________` (from `SSHCommand` output)
   - Ready-to-use command for connecting to your server

**Export outputs to JSON file (optional):**

```bash
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query 'Stacks[0].Outputs' \
  --output json > stack-outputs.json
```

This creates a `stack-outputs.json` file you can reference later.

---

#### Step 7: Configure Firewall Rules

**Important:** CloudFormation for AWS Lightsail has limited support for port configuration. After stack creation, you must manually configure the firewall rules to open the required ports for web traffic and VPN.

**Required Ports:**
- Port 22 (TCP) - SSH (already open by default)
- Port 80 (TCP) - HTTP web traffic
- Port 443 (TCP) - HTTPS secure web traffic
- Port 41641 (UDP) - Tailscale VPN

**Option A: Use the Automated Script (Recommended)**

A convenience script is provided to configure all required ports:

```bash
./configure-firewall.sh
```

The script will:
1. Retrieve the instance name from the CloudFormation stack
2. Open ports 80, 443, and 41641
3. Verify the ports are open
4. Display the current firewall configuration

**Expected Output:**

```
Configuring firewall rules for ai-website-builder...
Opening port 80 (HTTP)...
Opening port 443 (HTTPS)...
Opening port 41641 (Tailscale VPN)...
Firewall configuration complete!

Current port configuration:
Port 22 (TCP): OPEN
Port 80 (TCP): OPEN
Port 443 (TCP): OPEN
Port 41641 (UDP): OPEN
```

**Option B: Manual Configuration**

If you prefer to configure ports manually:

```bash
# Get the instance name from CloudFormation
INSTANCE_NAME=$(aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`InstanceName`].OutputValue' \
  --output text)

# Open port 80 (HTTP)
aws lightsail open-instance-public-ports \
  --instance-name $INSTANCE_NAME \
  --port-info fromPort=80,toPort=80,protocol=tcp

# Open port 443 (HTTPS)
aws lightsail open-instance-public-ports \
  --instance-name $INSTANCE_NAME \
  --port-info fromPort=443,toPort=443,protocol=tcp

# Open port 41641 (Tailscale VPN - UDP)
aws lightsail open-instance-public-ports \
  --instance-name $INSTANCE_NAME \
  --port-info fromPort=41641,toPort=41641,protocol=udp
```

**Verify firewall configuration:**

```bash
aws lightsail get-instance-port-states \
  --instance-name $INSTANCE_NAME
```

**Expected Output:**

```json
{
    "portStates": [
        {
            "fromPort": 22,
            "toPort": 22,
            "protocol": "tcp",
            "state": "open"
        },
        {
            "fromPort": 80,
            "toPort": 80,
            "protocol": "tcp",
            "state": "open"
        },
        {
            "fromPort": 443,
            "toPort": 443,
            "protocol": "tcp",
            "state": "open"
        },
        {
            "fromPort": 41641,
            "toPort": 41641,
            "protocol": "udp",
            "state": "open"
        }
    ]
}
```

**Verify all four required ports are open:**
- [ ] Port 22 (TCP) - SSH
- [ ] Port 80 (TCP) - HTTP
- [ ] Port 443 (TCP) - HTTPS
- [ ] Port 41641 (UDP) - Tailscale VPN

---

#### Step 8: Verify Infrastructure Deployment

Before proceeding to DNS configuration, verify that the infrastructure was created correctly and the instance is running.

**Verification Checklist:**

**1. Verify Stack Status:**

```bash
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query 'Stacks[0].StackStatus' \
  --output text
```

**Expected Output:** `CREATE_COMPLETE`

**2. Verify Instance is Running:**

```bash
aws lightsail get-instance --instance-name ai-website-builder
```

**Expected Output:**

```json
{
    "instance": {
        "name": "ai-website-builder",
        "arn": "arn:aws:lightsail:us-east-1:...",
        "supportCode": "...",
        "createdAt": "2024-01-15T10:30:00Z",
        "location": {
            "availabilityZone": "us-east-1a",
            "regionName": "us-east-1"
        },
        "resourceType": "Instance",
        "blueprintId": "ubuntu_22_04",
        "blueprintName": "Ubuntu",
        "bundleId": "nano_2_0",
        "state": {
            "code": 16,
            "name": "running"
        },
        "publicIpAddress": "54.123.45.67",
        "privateIpAddress": "172.26.x.x",
        ...
    }
}
```

**Key fields to verify:**
- `"name": "running"` - Instance is running
- `"publicIpAddress"` - Matches the CloudFormation output
- `"blueprintId": "ubuntu_22_04"` - Correct OS
- `"bundleId": "nano_2_0"` - Correct instance size

**3. Verify Static IP is Attached:**

```bash
aws lightsail get-static-ip --static-ip-name ai-website-builder-static-ip
```

**Expected Output:**

```json
{
    "staticIp": {
        "name": "ai-website-builder-static-ip",
        "arn": "arn:aws:lightsail:us-east-1:...",
        "ipAddress": "54.123.45.67",
        "attachedTo": "ai-website-builder",
        "isAttached": true,
        ...
    }
}
```

**Key fields to verify:**
- `"isAttached": true` - IP is attached to instance
- `"attachedTo": "ai-website-builder"` - Attached to correct instance
- `"ipAddress"` - Matches the CloudFormation output

**4. Verify Firewall Rules:**

```bash
aws lightsail get-instance-port-states --instance-name ai-website-builder
```

**Verify all four required ports are open:**
- [ ] Port 22 (TCP) - SSH
- [ ] Port 80 (TCP) - HTTP
- [ ] Port 443 (TCP) - HTTPS
- [ ] Port 41641 (UDP) - Tailscale VPN

**5. Test SSH Connectivity:**

```bash
# Use the SSH command from CloudFormation output
ssh ubuntu@54.123.45.67
```

**Expected Result:**

You should be able to connect to the instance. On first connection, you'll see:

```
The authenticity of host '54.123.45.67 (54.123.45.67)' can't be established.
ED25519 key fingerprint is SHA256:...
Are you sure you want to continue connecting (yes/no/[fingerprint])? 
```

Type `yes` and press Enter.

**If SSH connection succeeds**, you'll see the Ubuntu welcome message:

```
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-1045-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

ubuntu@ip-172-26-x-x:~$ 
```

**Type `exit` to disconnect** (we'll reconnect in Phase 4 for server configuration).

**If SSH connection fails:**

```bash
# Check if instance is running
aws lightsail get-instance-state --instance-name ai-website-builder

# Verify firewall allows SSH (port 22)
aws lightsail get-instance-port-states --instance-name ai-website-builder | grep -A 3 '"fromPort": 22'

# Check if you're using the correct IP
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' \
  --output text

# Try with verbose output to see connection details
ssh -v ubuntu@54.123.45.67
```

**Common SSH Issues:**

**Issue: "Connection timed out"**
```
Cause: Firewall blocking port 22, or instance not fully started
Solution: Wait 1-2 minutes for instance to fully boot, verify port 22 is open
```

**Issue: "Permission denied (publickey)"**
```
Cause: SSH key not configured correctly
Solution: Lightsail uses default SSH keys. Download from AWS console:
https://lightsail.aws.amazon.com/ls/webapp/account/keys
```

**Issue: "Host key verification failed"**
```
Cause: SSH host key changed (if redeploying to same IP)
Solution: Remove old host key:
ssh-keygen -R 54.123.45.67
```

**6. Verify User-Data Script Execution:**

The user-data script runs automatically during instance creation. Verify it completed successfully:

```bash
# SSH into the instance
ssh ubuntu@54.123.45.67

# Check user-data script logs
sudo cat /var/log/user-data.log | tail -50

# Verify automatic updates are configured
sudo cat /etc/apt/apt.conf.d/20auto-upgrades

# Verify directory structure was created
ls -la /opt/website-builder/

# Exit SSH session
exit
```

**Expected Results:**

- `/var/log/user-data.log` should show successful package installations
- `/etc/apt/apt.conf.d/20auto-upgrades` should exist and contain update configuration
- `/opt/website-builder/` directory should exist with subdirectories (app, config, assets, etc.)

**If user-data script failed:**

The script runs in the background and may take 5-10 minutes to complete. If it's still running:

```bash
# Check if cloud-init is still running
sudo cloud-init status

# Expected output if complete: "status: done"
# Expected output if running: "status: running"
```

If the script failed, you can manually run the setup commands in Phase 4 (Server Configuration).

---

#### Verification Summary

**CloudFormation Deployment Verification Checklist:**

- [ ] CloudFormation stack status is `CREATE_COMPLETE`
- [ ] Public IP address retrieved from stack outputs
- [ ] Instance state is "running" (verified with AWS CLI)
- [ ] Static IP is attached to instance (verified with AWS CLI)
- [ ] All four required ports are open (22, 80, 443, 41641)
- [ ] SSH connection to instance successful
- [ ] User-data script completed (verified via cloud-init logs)
- [ ] Directory structure created (`/opt/website-builder/` exists)

**If all items are checked:** Your infrastructure is successfully deployed and ready for DNS configuration.

**If any items failed:** Review the troubleshooting steps above or consult the [Troubleshooting Guide](#troubleshooting-guide) section.

---

#### CloudFormation Stack Management

After deployment, you can manage your CloudFormation stack using the AWS CLI.

**View Stack Details:**

```bash
# View complete stack information
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --region us-east-1

# View stack resources
aws cloudformation list-stack-resources \
  --stack-name ai-website-builder \
  --region us-east-1
```

**Update Stack (if needed):**

If you need to modify the infrastructure:

```bash
aws cloudformation update-stack \
  --stack-name ai-website-builder \
  --template-body file://lightsail-stack.yaml \
  --parameters file://parameters.json \
  --region us-east-1
```

**Delete Stack (cleanup):**

To remove all resources (⚠️ **Warning:** This will delete the instance and all data):

```bash
aws cloudformation delete-stack \
  --stack-name ai-website-builder \
  --region us-east-1
```

**Monitor deletion:**

```bash
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query 'Stacks[0].StackStatus' \
  --output text
```

Status will change from `DELETE_IN_PROGRESS` to stack not found (deletion complete).

---

#### Troubleshooting CloudFormation Deployment

**Stack Creation Failed:**

If the stack status is `CREATE_FAILED` or `ROLLBACK_COMPLETE`, check the stack events for error details:

```bash
aws cloudformation describe-stack-events \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]' \
  --output table
```

**Common Issues:**

**Error: "Parameter validation failed"**
```
Cause: Invalid parameter values in parameters.json
Solution: Review parameters.json for typos, ensure all required parameters are present
Verify JSON syntax: python3 -m json.tool parameters.json
```

**Error: "User: ... is not authorized to perform: lightsail:CreateInstance"**
```
Cause: AWS credentials lack required permissions
Solution: Ensure IAM user has AmazonLightsailFullAccess policy attached
Verify credentials: aws sts get-caller-identity
```

**Error: "Template format error"**
```
Cause: Invalid CloudFormation template syntax
Solution: Validate template: aws cloudformation validate-template --template-body file://lightsail-stack.yaml
Ensure you're using the correct template file
```

**Error: "Resource creation cancelled"**
```
Cause: CloudFormation encountered an error and rolled back
Solution: Check stack events for the specific resource that failed
Review error messages in the ResourceStatusReason field
```

**Rollback Occurred:**

If CloudFormation rolled back the stack:

1. **Check what failed:**
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name ai-website-builder \
     --region us-east-1 \
     --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'
   ```

2. **Delete the failed stack:**
   ```bash
   aws cloudformation delete-stack \
     --stack-name ai-website-builder \
     --region us-east-1
   ```

3. **Fix the issue** (update parameters, check permissions, etc.)

4. **Retry deployment:**
   ```bash
   aws cloudformation create-stack \
     --stack-name ai-website-builder \
     --template-body file://lightsail-stack.yaml \
     --parameters file://parameters.json \
     --region us-east-1
   ```

---

#### Next Steps After CloudFormation Deployment

**Infrastructure deployment is complete!** You now have:

✅ A running AWS Lightsail instance with Ubuntu 22.04  
✅ A static IP address attached to the instance  
✅ Firewall rules configured for web traffic and VPN  
✅ Automatic security updates enabled  
✅ Directory structure prepared for the application  

**What You Need for the Next Phase:**

- **Public IP Address**: `_________________` (from CloudFormation output)
- **SSH Command**: `ssh ubuntu@[your-ip]`
- **Domain Name**: `_________________` (from your parameters.json)

**Proceed to Phase 3: DNS Configuration**

In the next phase, you'll:
1. Configure DNS A records to point your domain to the instance IP
2. Wait for DNS propagation
3. Verify DNS resolution before SSL setup

**Continue to:** [DNS Configuration Phase](#dns-configuration-phase)

---

## DNS Configuration Phase

The DNS Configuration Phase establishes the connection between your domain name and the AWS Lightsail instance. This phase is critical because SSL certificate generation (in Phase 4) requires valid DNS records pointing to your server. You'll either register a new domain or configure an existing domain to work with your deployment.

**Phase Duration:** 5-30 minutes (5 minutes for configuration + up to 30 minutes for DNS propagation)

**Prerequisites:**
- AWS Lightsail instance is running (from Phase 2)
- You have the instance's public IP address (from infrastructure deployment outputs)
- You have access to a domain registrar or DNS provider

**Phase Overview:**
1. Register a new domain OR prepare an existing domain
2. Configure DNS A records to point to your Lightsail instance
3. Wait for DNS propagation
4. Verify DNS resolution before proceeding to SSL setup

---

### Domain Registration and Preparation

Before configuring DNS records, you need a domain name. This section covers both registering a new domain and preparing an existing domain for use with the AI Website Builder.

#### Option A: Register a New Domain

If you don't have a domain name, you'll need to register one through a domain registrar. Choose a registrar based on your preferences for pricing, features, and integration with your infrastructure.

##### 1. AWS Route 53 (Recommended for AWS Integration)

**Advantages:**
- Seamless integration with AWS services
- Automatic DNS configuration (hosted zone created automatically)
- Programmatic domain management via AWS CLI/API
- Consolidated billing with other AWS services
- Built-in health checks and routing policies

**Disadvantages:**
- Slightly higher pricing than some competitors
- Requires AWS account and familiarity with AWS console

**Cost Estimates:**
- `.com` domain: ~$13/year
- `.net` domain: ~$11/year
- `.org` domain: ~$12/year
- `.io` domain: ~$39/year
- `.dev` domain: ~$12/year
- Full pricing: https://d32ze2gidvkk54.cloudfront.net/Amazon_Route_53_Domain_Registration_Pricing_20140731.pdf

**Registration Steps:**

1. **Access Route 53 Console:**
   ```bash
   # Open in browser
   https://console.aws.amazon.com/route53/
   ```

2. **Navigate to Domain Registration:**
   - Click "Registered domains" in the left sidebar
   - Click "Register domain" button

3. **Search for Available Domains:**
   - Enter your desired domain name in the search box
   - Click "Check" to see availability
   - Browse suggested alternatives if your first choice is taken
   - Select your preferred domain and click "Add to cart"

4. **Configure Domain Settings:**
   - **Duration:** Choose 1-10 years (1 year is typical)
   - **Auto-renew:** Enable to prevent accidental expiration
   - **Privacy protection:** Enable to hide your contact information in WHOIS (free with Route 53)

5. **Enter Contact Information:**
   - Provide registrant, administrative, and technical contact details
   - This information is required by ICANN regulations
   - With privacy protection enabled, this information is hidden from public WHOIS lookups

6. **Review and Complete Purchase:**
   - Review your order details
   - Accept the terms and conditions
   - Click "Complete purchase"
   - **Note:** Domain registration can take 10-15 minutes to complete

7. **Verify Email Address:**
   - Check your email for a verification message from AWS
   - Click the verification link within 15 days
   - **Important:** Failure to verify can result in domain suspension

8. **Wait for Registration Completion:**
   - Registration typically completes within 10-15 minutes
   - You'll receive an email confirmation when complete
   - The hosted zone is automatically created in Route 53

**Verification:**

```bash
# Check domain registration status
aws route53domains get-domain-detail --domain-name yourdomain.com

# List hosted zones (should include your new domain)
aws route53 list-hosted-zones
```

**Expected Output:**
```json
{
    "DomainName": "yourdomain.com",
    "RegistrationStatus": "REGISTERED",
    ...
}
```

**Next Steps After Route 53 Registration:**
- Your hosted zone is automatically created
- Name servers are automatically configured
- Proceed directly to "Configure DNS A Records" section below
- No additional DNS provider setup required

---

##### 2. Namecheap (Popular and Affordable)

**Advantages:**
- Competitive pricing (often cheaper than Route 53)
- Free WHOIS privacy protection for life
- User-friendly interface for beginners
- Frequent promotional discounts
- 24/7 customer support

**Disadvantages:**
- Requires separate DNS management (or use Namecheap's DNS)
- Less integration with AWS services
- Renewal prices higher than first-year prices

**Cost Estimates:**
- `.com` domain: ~$8.88/year (first year), ~$13.98/year (renewal)
- `.net` domain: ~$12.98/year
- `.org` domain: ~$12.98/year
- `.io` domain: ~$32.88/year
- `.dev` domain: ~$9.98/year (first year)
- Current pricing: https://www.namecheap.com/domains/

**Registration Steps:**

1. **Visit Namecheap:**
   ```
   https://www.namecheap.com/
   ```

2. **Search for Your Domain:**
   - Enter your desired domain name in the search box
   - Click "Search"
   - Review available domains and pricing
   - Click "Add to Cart" for your chosen domain

3. **Configure Domain Options:**
   - **WhoisGuard:** Keep enabled (free privacy protection)
   - **Auto-renew:** Enable to prevent expiration
   - **Premium DNS:** Optional ($4.88/year, provides better performance and DDoS protection)
   - **Email hosting:** Optional (not required for AI Website Builder)

4. **Complete Purchase:**
   - Click "View Cart"
   - Review your order
   - Create a Namecheap account or log in
   - Enter payment information
   - Click "Confirm Order"

5. **Verify Email Address:**
   - Check your email for a verification message
   - Click the verification link
   - **Important:** ICANN requires email verification within 15 days

6. **Access Domain Management:**
   - Log in to Namecheap
   - Go to "Domain List" in your dashboard
   - Click "Manage" next to your domain

**DNS Configuration Options with Namecheap:**

**Option 1: Use Namecheap's DNS (Simpler)**
- Namecheap provides free DNS hosting
- Configure A records directly in Namecheap's control panel
- See "Configure DNS A Records" section below for instructions

**Option 2: Use Route 53 for DNS (Better AWS Integration)**
- Create a hosted zone in Route 53 for your domain
- Update name servers in Namecheap to point to Route 53
- Provides better integration with AWS services

To use Route 53 DNS with a Namecheap domain:

```bash
# Create hosted zone in Route 53
aws route53 create-hosted-zone --name yourdomain.com --caller-reference $(date +%s)
```

**Expected Output:**
```json
{
    "HostedZone": {
        "Id": "/hostedzone/Z1234567890ABC",
        "Name": "yourdomain.com.",
        ...
    },
    "DelegationSet": {
        "NameServers": [
            "ns-1234.awsdns-12.org",
            "ns-5678.awsdns-34.com",
            "ns-9012.awsdns-56.net",
            "ns-3456.awsdns-78.co.uk"
        ]
    }
}
```

Then in Namecheap:
1. Go to Domain List → Manage → Domain tab
2. Find "Nameservers" section
3. Select "Custom DNS"
4. Enter the four Route 53 name servers from the output above
5. Click the checkmark to save
6. Wait 24-48 hours for name server propagation

**Next Steps After Namecheap Registration:**
- Choose your DNS provider (Namecheap DNS or Route 53)
- If using Namecheap DNS, proceed to "Configure DNS A Records" section
- If using Route 53 DNS, update name servers first, then configure A records

---

##### 3. GoDaddy (Widely Recognized)

**Advantages:**
- One of the largest domain registrars
- Extensive customer support (phone, chat, email)
- Frequent promotional pricing
- Integrated hosting and email services available

**Disadvantages:**
- Aggressive upselling during checkout
- Privacy protection costs extra ($9.99/year)
- Higher renewal prices
- Interface can be cluttered

**Cost Estimates:**
- `.com` domain: ~$11.99/year (first year), ~$19.99/year (renewal)
- `.net` domain: ~$14.99/year
- `.org` domain: ~$14.99/year
- `.io` domain: ~$49.99/year
- Domain privacy: +$9.99/year (not included by default)
- Current pricing: https://www.godaddy.com/domains

**Registration Steps:**

1. **Visit GoDaddy:**
   ```
   https://www.godaddy.com/
   ```

2. **Search for Your Domain:**
   - Enter your desired domain name in the search box
   - Click "Search Domain"
   - Select your domain from the results
   - Click "Add to Cart"

3. **Navigate Through Checkout:**
   - **Important:** GoDaddy will offer many add-ons during checkout
   - Decline unnecessary services (email, website builder, etc.)
   - Consider adding domain privacy if you want WHOIS protection (+$9.99/year)
   - Set registration period (1 year is typical)

4. **Complete Purchase:**
   - Create a GoDaddy account or log in
   - Enter payment information
   - Review your order carefully (remove unwanted add-ons)
   - Click "Complete Purchase"

5. **Verify Email Address:**
   - Check your email for verification message
   - Click the verification link
   - Complete verification within 15 days

6. **Access Domain Management:**
   - Log in to GoDaddy
   - Go to "My Products"
   - Find your domain and click "DNS" or "Manage DNS"

**DNS Configuration with GoDaddy:**

GoDaddy provides free DNS hosting. You can configure A records directly in their control panel (see "Configure DNS A Records" section below).

Alternatively, you can use Route 53 for DNS by updating name servers:

1. Create a hosted zone in Route 53 (see Route 53 instructions above)
2. In GoDaddy, go to Domain Settings → Nameservers
3. Click "Change Nameservers"
4. Select "I'll use my own nameservers"
5. Enter the four Route 53 name servers
6. Click "Save"
7. Wait 24-48 hours for propagation

**Next Steps After GoDaddy Registration:**
- Choose your DNS provider (GoDaddy DNS or Route 53)
- Configure A records as described in the next section

---

##### 4. Other Domain Registrars

**Google Domains** (https://domains.google.com/)
- **Cost:** .com domains ~$12/year
- **Advantages:** Clean interface, transparent pricing, free privacy protection
- **Disadvantages:** Limited to Google account holders

**Cloudflare Registrar** (https://www.cloudflare.com/products/registrar/)
- **Cost:** At-cost pricing (~$8-10/year for .com)
- **Advantages:** No markup pricing, integrated with Cloudflare DNS and CDN
- **Disadvantages:** Requires existing Cloudflare account, transfer-only (no new registrations for some TLDs)

**Porkbun** (https://porkbun.com/)
- **Cost:** .com domains ~$9.13/year
- **Advantages:** Competitive pricing, free WHOIS privacy, free SSL certificates
- **Disadvantages:** Smaller company, less name recognition

**Domain.com** (https://www.domain.com/)
- **Cost:** .com domains ~$9.99/year (first year)
- **Advantages:** Straightforward pricing, free privacy protection
- **Disadvantages:** Higher renewal rates

---

#### Option B: Use an Existing Domain

If you already own a domain name, you can use it with the AI Website Builder without registering a new one.

**Requirements:**
- You must have access to the domain's DNS management interface
- The domain must be active (not expired or suspended)
- You must be able to create or modify A records
- The domain should not be currently in use for another website (or you must be willing to redirect it)

**Compatibility:**
- **Any domain registrar is supported** (Namecheap, GoDaddy, Route 53, Google Domains, Cloudflare, etc.)
- **Any DNS provider is supported** (you can use a different DNS provider than your registrar)
- The AI Website Builder only requires standard A record support

**What You'll Need:**
1. **Domain registrar login credentials** (where you purchased the domain)
2. **DNS provider access** (may be the same as registrar, or separate like Route 53 or Cloudflare)
3. **Lightsail instance IP address** (from Phase 2 infrastructure deployment outputs)

**Preparation Steps:**

1. **Verify Domain Ownership:**
   - Log in to your domain registrar
   - Confirm the domain is active and not expired
   - Check the expiration date and enable auto-renewal if desired

2. **Locate DNS Management:**
   - Find the DNS management interface for your domain
   - This is typically in your registrar's control panel
   - Look for sections labeled "DNS Management", "DNS Settings", "Name Servers", or "Advanced DNS"

3. **Identify Current DNS Provider:**
   - Check which name servers your domain is using
   - If using registrar's default name servers, you'll configure DNS at the registrar
   - If using custom name servers (e.g., Route 53, Cloudflare), you'll configure DNS at that provider

   **Check name servers:**
   ```bash
   # Using dig
   dig NS yourdomain.com +short
   
   # Using nslookup
   nslookup -type=NS yourdomain.com
   ```

   **Example Output:**
   ```
   ns-1234.awsdns-12.org.
   ns-5678.awsdns-34.com.
   ns-9012.awsdns-56.net.
   ns-3456.awsdns-78.co.uk.
   ```
   
   This output indicates the domain is using Route 53 for DNS.

4. **Backup Existing DNS Records (Important!):**
   - Before making changes, document all existing DNS records
   - Take screenshots or export DNS records if possible
   - This allows you to restore the previous configuration if needed

   **Common record types to document:**
   - A records (IPv4 addresses)
   - AAAA records (IPv6 addresses)
   - CNAME records (aliases)
   - MX records (email routing)
   - TXT records (verification, SPF, DKIM)

5. **Understand Impact of Changes:**
   - **If the domain is currently in use:** Changing A records will redirect traffic to your new server
   - **If you have email on this domain:** Ensure MX records remain unchanged
   - **If you have subdomains:** You may need to preserve or migrate those records
   - **DNS propagation:** Changes take 5-30 minutes (sometimes up to 48 hours) to propagate globally

**Decision: Keep Existing DNS Provider or Switch to Route 53?**

**Option 1: Keep Existing DNS Provider (Simpler)**
- Configure A records directly in your current DNS provider
- No name server changes required
- Faster to implement (no name server propagation wait)
- **Recommended if:** You're comfortable with your current DNS provider

**Option 2: Switch to Route 53 (Better AWS Integration)**
- Create a hosted zone in Route 53
- Migrate existing DNS records to Route 53
- Update name servers at your registrar
- Wait 24-48 hours for name server propagation
- **Recommended if:** You want centralized AWS management or advanced Route 53 features

**To switch to Route 53:**

```bash
# Create hosted zone
aws route53 create-hosted-zone \
  --name yourdomain.com \
  --caller-reference $(date +%s)

# Note the name servers from the output
# Update name servers at your domain registrar to point to Route 53
# Wait 24-48 hours for name server propagation
# Then configure A records in Route 53
```

**Next Steps After Preparing Existing Domain:**
- Proceed to "Configure DNS A Records" section below
- Use your chosen DNS provider's interface to create the required records

---

### Summary: Domain Registration and Preparation

**Checklist:**
- [ ] Domain name registered OR existing domain prepared
- [ ] Access to DNS management interface confirmed
- [ ] DNS provider identified (registrar's DNS, Route 53, Cloudflare, etc.)
- [ ] Existing DNS records backed up (if using existing domain)
- [ ] Lightsail instance IP address available (from Phase 2)

**Cost Summary:**
- **New domain registration:** $8-50/year depending on TLD and registrar
- **Existing domain:** $0 (no additional cost)
- **DNS hosting:** Free with most registrars, free with Route 53 ($0.50/month for hosted zone + $0.40 per million queries)

**Time Estimate:**
- **New domain registration:** 10-20 minutes (plus email verification)
- **Existing domain preparation:** 5-10 minutes (review and backup)

**Next Steps:**
Once you have a domain name and access to DNS management, proceed to configure DNS A records to point your domain to the Lightsail instance.

**Continue to:** Configure DNS A Records (Task 4.2)

---

### Configure DNS A Records

Now that you have a domain name and access to DNS management, you need to create DNS A records that point your domain to the AWS Lightsail instance. This step is critical because SSL certificate generation (in the next phase) requires valid DNS records.

**What You'll Need:**
- Your domain name (e.g., `example.com`)
- Your Lightsail instance's public IP address (from Phase 2 infrastructure deployment outputs)
- Access to your DNS provider's management interface

**Retrieve Your Lightsail Instance IP Address:**

If you don't have your instance IP address from the infrastructure deployment, retrieve it:

**Using Terraform:**
```bash
cd terraform
terraform output instance_ip
```

**Using CloudFormation:**
```bash
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --query 'Stacks[0].Outputs[?OutputKey==`InstancePublicIP`].OutputValue' \
  --output text
```

**Using AWS CLI (if you know the instance name):**
```bash
aws lightsail get-instance \
  --instance-name ai-website-builder \
  --query 'instance.publicIpAddress' \
  --output text
```

**Expected Output:**
```
203.0.113.42
```

**Note:** This is your instance's public IPv4 address. Save this value as you'll need it for DNS configuration.

---

#### DNS Records Overview

You need to create **two A records** to make your website accessible via both the root domain and the www subdomain:

1. **Root Domain A Record:**
   - **Type:** A
   - **Name/Host:** `@` (or blank, or `example.com` depending on DNS provider)
   - **Value/Points to:** Your Lightsail instance IP address (e.g., `203.0.113.42`)
   - **TTL:** 300 seconds (5 minutes) or default
   - **Purpose:** Makes your site accessible at `https://example.com`

2. **WWW Subdomain A Record:**
   - **Type:** A
   - **Name/Host:** `www`
   - **Value/Points to:** Your Lightsail instance IP address (e.g., `203.0.113.42`)
   - **TTL:** 300 seconds (5 minutes) or default
   - **Purpose:** Makes your site accessible at `https://www.example.com`

**Why Both Records?**
- Users may type either `example.com` or `www.example.com`
- Both should work and point to the same server
- NGINX on your server will handle both hostnames
- SSL certificates will be issued for both variants

**About TTL (Time To Live):**
- TTL controls how long DNS resolvers cache the record
- Lower TTL (300 seconds) allows faster updates if you need to change the IP
- After DNS is stable, you can increase TTL to 3600 (1 hour) or 86400 (24 hours) for better performance
- During initial setup, keep TTL low (300-600 seconds)

---

#### DNS Configuration Instructions by Provider

Choose the instructions that match your DNS provider. The process is similar across all providers, but the interface differs.

##### AWS Route 53

**If you registered your domain with Route 53 or are using Route 53 for DNS:**

**Option 1: Using AWS Console (Graphical Interface)**

1. **Access Route 53 Console:**
   ```
   https://console.aws.amazon.com/route53/
   ```

2. **Navigate to Hosted Zones:**
   - Click "Hosted zones" in the left sidebar
   - Click on your domain name (e.g., `example.com`)

3. **Create Root Domain A Record:**
   - Click "Create record"
   - Configure the record:
     - **Record name:** Leave blank (this creates a record for the root domain)
     - **Record type:** A - Routes traffic to an IPv4 address
     - **Value:** Enter your Lightsail instance IP address (e.g., `203.0.113.42`)
     - **TTL:** 300 seconds
     - **Routing policy:** Simple routing
   - Click "Create records"

4. **Create WWW Subdomain A Record:**
   - Click "Create record" again
   - Configure the record:
     - **Record name:** `www`
     - **Record type:** A - Routes traffic to an IPv4 address
     - **Value:** Enter your Lightsail instance IP address (same as above)
     - **TTL:** 300 seconds
     - **Routing policy:** Simple routing
   - Click "Create records"

**Option 2: Using AWS CLI (Command Line)**

```bash
# Set your variables
DOMAIN="example.com"              # REPLACE: Your domain name
INSTANCE_IP="203.0.113.42"        # REPLACE: Your Lightsail instance IP
HOSTED_ZONE_ID="Z1234567890ABC"   # REPLACE: Your Route 53 hosted zone ID

# Get your hosted zone ID if you don't have it
aws route53 list-hosted-zones --query "HostedZones[?Name=='${DOMAIN}.'].Id" --output text

# Create a JSON file with both A records
cat > dns-records.json <<EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${DOMAIN}",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "${INSTANCE_IP}"}]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "www.${DOMAIN}",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "${INSTANCE_IP}"}]
      }
    }
  ]
}
EOF

# Apply the DNS changes
aws route53 change-resource-record-sets \
  --hosted-zone-id ${HOSTED_ZONE_ID} \
  --change-batch file://dns-records.json

# Clean up
rm dns-records.json
```

**Expected Output:**
```json
{
    "ChangeInfo": {
        "Id": "/change/C1234567890ABC",
        "Status": "PENDING",
        "SubmittedAt": "2024-01-15T10:30:00.000Z"
    }
}
```

**Verify Records Were Created:**

```bash
# List all records in your hosted zone
aws route53 list-resource-record-sets \
  --hosted-zone-id ${HOSTED_ZONE_ID} \
  --query "ResourceRecordSets[?Type=='A']"
```

**Expected Output:**
```json
[
    {
        "Name": "example.com.",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "203.0.113.42"}]
    },
    {
        "Name": "www.example.com.",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "203.0.113.42"}]
    }
]
```

---

##### Namecheap

**If you're using Namecheap for DNS:**

1. **Log in to Namecheap:**
   ```
   https://www.namecheap.com/myaccount/login/
   ```

2. **Access Domain List:**
   - Click "Domain List" in the left sidebar
   - Find your domain and click "Manage"

3. **Navigate to Advanced DNS:**
   - Click the "Advanced DNS" tab at the top

4. **Add Root Domain A Record:**
   - In the "Host Records" section, click "Add New Record"
   - Configure the record:
     - **Type:** A Record
     - **Host:** `@` (this represents the root domain)
     - **Value:** Your Lightsail instance IP address (e.g., `203.0.113.42`)
     - **TTL:** Automatic (or select 5 min / 300 seconds)
   - Click the green checkmark to save

5. **Add WWW Subdomain A Record:**
   - Click "Add New Record" again
   - Configure the record:
     - **Type:** A Record
     - **Host:** `www`
     - **Value:** Your Lightsail instance IP address (same as above)
     - **TTL:** Automatic (or select 5 min / 300 seconds)
   - Click the green checkmark to save

6. **Remove Conflicting Records (if present):**
   - If you see existing A records or CNAME records for `@` or `www` that point elsewhere, delete them
   - Click the trash icon next to any conflicting records
   - Confirm deletion

**Important Notes for Namecheap:**
- Namecheap may have default parking page records - remove these
- If you see a CNAME record for `www` pointing to a parking page, delete it before adding the A record
- Changes typically propagate within 5-30 minutes
- Namecheap's interface shows a warning if you have conflicting records

**Visual Reference:**

Your "Host Records" section should look like this after configuration:

```
Type    Host    Value           TTL
A       @       203.0.113.42    Automatic
A       www     203.0.113.42    Automatic
```

---

##### GoDaddy

**If you're using GoDaddy for DNS:**

1. **Log in to GoDaddy:**
   ```
   https://account.godaddy.com/
   ```

2. **Access Domain Management:**
   - Click "My Products"
   - Find your domain in the list
   - Click "DNS" or "Manage DNS" next to your domain

3. **Add Root Domain A Record:**
   - Scroll to the "Records" section
   - Look for an existing A record with Name `@`
   - If one exists pointing to a parking page, click the pencil icon to edit it
   - If none exists, click "Add" and select "A" record
   - Configure the record:
     - **Type:** A
     - **Name:** `@`
     - **Value:** Your Lightsail instance IP address (e.g., `203.0.113.42`)
     - **TTL:** 600 seconds (or Custom: 300 seconds)
   - Click "Save"

4. **Add WWW Subdomain A Record:**
   - Look for an existing A or CNAME record with Name `www`
   - If a CNAME exists, delete it first (click trash icon)
   - Click "Add" and select "A" record
   - Configure the record:
     - **Type:** A
     - **Name:** `www`
     - **Value:** Your Lightsail instance IP address (same as above)
     - **TTL:** 600 seconds (or Custom: 300 seconds)
   - Click "Save"

5. **Remove Parking Page Records:**
   - GoDaddy often includes default parking page records
   - Delete any A records pointing to `184.168.221.96` or similar parking IPs
   - Delete any CNAME records for `www` pointing to parking pages

**Important Notes for GoDaddy:**
- GoDaddy's default TTL is 600 seconds (10 minutes)
- You may need to delete default parking page records
- Changes can take 10-30 minutes to propagate
- GoDaddy may show a warning about removing parking page records - this is expected

**Visual Reference:**

Your DNS records should include:

```
Type    Name    Value           TTL
A       @       203.0.113.42    600 seconds
A       www     203.0.113.42    600 seconds
```

---

##### Cloudflare

**If you're using Cloudflare for DNS:**

1. **Log in to Cloudflare:**
   ```
   https://dash.cloudflare.com/login
   ```

2. **Select Your Domain:**
   - Click on your domain from the list

3. **Navigate to DNS Settings:**
   - Click "DNS" in the top navigation menu
   - You'll see the "DNS Management" page with existing records

4. **Add Root Domain A Record:**
   - Click "Add record"
   - Configure the record:
     - **Type:** A
     - **Name:** `@` (or your domain name will auto-populate)
     - **IPv4 address:** Your Lightsail instance IP address (e.g., `203.0.113.42`)
     - **Proxy status:** Click the cloud icon to toggle to "DNS only" (gray cloud)
       - **Important:** Disable Cloudflare proxy for initial setup
       - You can enable it later after SSL is configured
     - **TTL:** Auto (or select 5 minutes)
   - Click "Save"

5. **Add WWW Subdomain A Record:**
   - Click "Add record" again
   - Configure the record:
     - **Type:** A
     - **Name:** `www`
     - **IPv4 address:** Your Lightsail instance IP address (same as above)
     - **Proxy status:** DNS only (gray cloud icon)
     - **TTL:** Auto (or select 5 minutes)
   - Click "Save"

**Important Notes for Cloudflare:**
- **Proxy Status:** Keep "DNS only" (gray cloud) during initial setup
  - Orange cloud = Proxied through Cloudflare (can interfere with Let's Encrypt SSL setup)
  - Gray cloud = DNS only (direct connection to your server)
  - After SSL is configured, you can optionally enable the proxy for CDN and DDoS protection
- Cloudflare DNS changes propagate very quickly (often under 5 minutes)
- Cloudflare provides free SSL, but we're using Let's Encrypt on the server instead

**Visual Reference:**

Your DNS records should show:

```
Type    Name    Content         Proxy status    TTL
A       @       203.0.113.42    DNS only        Auto
A       www     203.0.113.42    DNS only        Auto
```

**After SSL Setup (Optional):**
- You can return to Cloudflare and enable the proxy (orange cloud) for both records
- This adds Cloudflare's CDN and DDoS protection
- Ensure "SSL/TLS encryption mode" is set to "Full (strict)" in Cloudflare settings

---

##### Google Domains

**If you're using Google Domains for DNS:**

1. **Log in to Google Domains:**
   ```
   https://domains.google.com/
   ```

2. **Select Your Domain:**
   - Click on your domain from "My domains"

3. **Navigate to DNS Settings:**
   - Click "DNS" in the left sidebar
   - Scroll to "Custom resource records"

4. **Add Root Domain A Record:**
   - In the "Custom resource records" section:
     - **Name:** Leave blank (or enter `@`)
     - **Type:** A
     - **TTL:** 5 (minutes)
     - **Data:** Your Lightsail instance IP address (e.g., `203.0.113.42`)
   - Click "Add"

5. **Add WWW Subdomain A Record:**
   - Add another record:
     - **Name:** `www`
     - **Type:** A
     - **TTL:** 5 (minutes)
     - **Data:** Your Lightsail instance IP address (same as above)
   - Click "Add"

**Important Notes for Google Domains:**
- Google Domains has a clean, straightforward interface
- TTL is specified in minutes (5 minutes = 300 seconds)
- Changes typically propagate within 5-15 minutes
- Google Domains automatically handles the root domain notation

**Visual Reference:**

Your custom resource records should show:

```
Name    Type    TTL    Data
@       A       5m     203.0.113.42
www     A       5m     203.0.113.42
```

---

##### Other DNS Providers

**If you're using a different DNS provider** (Porkbun, Domain.com, Hover, etc.), the process is similar:

**General Steps:**

1. **Log in to your DNS provider's control panel**
2. **Navigate to DNS management** (may be labeled "DNS Settings", "DNS Records", "Zone File", or "Advanced DNS")
3. **Create an A record for the root domain:**
   - **Type:** A or A Record
   - **Name/Host:** `@`, blank, or your domain name (varies by provider)
   - **Value/Points to/Address:** Your Lightsail instance IP address
   - **TTL:** 300 seconds (5 minutes) or the lowest available
4. **Create an A record for the www subdomain:**
   - **Type:** A or A Record
   - **Name/Host:** `www`
   - **Value/Points to/Address:** Your Lightsail instance IP address (same as above)
   - **TTL:** 300 seconds (5 minutes) or the lowest available
5. **Save changes** and wait for propagation

**Common Field Name Variations:**

Different DNS providers use different terminology for the same fields:

| Field Purpose | Common Names |
|---------------|--------------|
| Record type | Type, Record Type |
| Hostname | Name, Host, Host Name, Record Name |
| IP Address | Value, Points to, Address, IPv4 Address, Data, Content |
| Time to Live | TTL, Cache Time |

**Tips:**
- Look for documentation specific to your DNS provider (search "how to add A record [provider name]")
- Most providers have similar interfaces with slight variations in terminology
- If you're unsure, contact your DNS provider's support for guidance
- Take screenshots before making changes so you can revert if needed

---

#### DNS Configuration for Builder Interface and Static Server

The AI Website Builder uses your domain for two distinct purposes, but both use the same DNS configuration:

**1. Static Server (Public Website):**
- **Hostname:** `yourdomain.com` and `www.yourdomain.com`
- **Purpose:** Serves the generated HTML pages to the public
- **Access:** Publicly accessible via HTTPS
- **DNS Configuration:** The A records you just created
- **Port:** 443 (HTTPS) and 80 (HTTP, redirects to HTTPS)

**2. Builder Interface (VPN-Protected):**
- **Hostname:** Accessed via Tailscale IP address, not domain name
- **Purpose:** Content management and AI-powered website generation
- **Access:** Only accessible via Tailscale VPN
- **DNS Configuration:** No additional DNS records required
- **Port:** 3000 (HTTP only, protected by VPN)
- **URL Format:** `http://[tailscale-ip]:3000` (e.g., `http://100.64.0.5:3000`)

**Important Notes:**

- **No separate DNS records are needed for the Builder Interface**
  - The Builder Interface is accessed via Tailscale's internal IP address
  - Tailscale provides its own internal DNS (MagicDNS) if enabled
  - You do NOT need to create a subdomain like `builder.yourdomain.com`

- **The Static Server uses your domain name**
  - The A records you created point to the NGINX server
  - NGINX serves the static HTML files on ports 80 and 443
  - SSL certificates will be issued for `yourdomain.com` and `www.yourdomain.com`

- **Both services run on the same Lightsail instance**
  - The instance has one public IP address
  - NGINX listens on ports 80 and 443 (public)
  - The Builder Interface listens on port 3000 (VPN-only)
  - UFW firewall blocks port 3000 from public access

**Optional: Custom Subdomain for Builder Interface**

If you prefer to access the Builder Interface via a domain name instead of an IP address, you can optionally create a subdomain:

**Steps:**

1. **Create an A record for a subdomain:**
   - **Type:** A
   - **Name/Host:** `builder` (or `admin`, `manage`, etc.)
   - **Value:** Your Lightsail instance IP address
   - **TTL:** 300 seconds

2. **Configure NGINX to serve the Builder Interface on this subdomain** (requires custom NGINX configuration)

3. **Ensure the subdomain is only accessible via VPN** (firewall rules must block public access)

**Note:** This is optional and not covered in the standard deployment. The default configuration uses Tailscale IP addresses for Builder Interface access, which is simpler and more secure.

---

#### DNS Configuration Summary

**Checklist:**
- [ ] Retrieved Lightsail instance public IP address
- [ ] Created A record for root domain (`@` or blank) pointing to instance IP
- [ ] Created A record for www subdomain (`www`) pointing to instance IP
- [ ] Verified both records are saved in DNS provider
- [ ] Noted the time of DNS changes (for propagation tracking)

**DNS Records Created:**

```
Type    Name/Host    Value/Points to      TTL
A       @            [Your Instance IP]   300 seconds
A       www          [Your Instance IP]   300 seconds
```

**Example with Real Values:**

```
Type    Name/Host    Value/Points to    TTL
A       @            203.0.113.42       300 seconds
A       www          203.0.113.42       300 seconds
```

**What Happens Next:**

1. **DNS Propagation:** Your DNS changes will propagate across the internet (5-30 minutes typically)
2. **Verification:** You'll verify DNS resolution before proceeding to SSL setup
3. **SSL Configuration:** Let's Encrypt will use these DNS records to verify domain ownership and issue certificates

**Time Estimate:** 5-10 minutes for DNS configuration (not including propagation time)

**Next Steps:**
- Wait for DNS propagation (covered in Task 4.3)
- Verify DNS resolution before proceeding to server configuration
- Do NOT proceed to SSL setup until DNS is fully propagated

**Continue to:** DNS Verification Procedures (Task 4.3)

---

### DNS Verification Procedures

After configuring your DNS A records, you must verify that the DNS changes have propagated before proceeding to SSL certificate configuration. This section provides verification commands, expected outputs, and troubleshooting guidance for DNS resolution issues.

**Why DNS Verification is Critical:**
- SSL certificate generation (Let's Encrypt) requires valid DNS records pointing to your server
- If DNS hasn't propagated, SSL certificate requests will fail
- Proceeding without proper DNS resolution will cause deployment failures
- Verification ensures your domain is correctly configured before moving forward

**Phase Duration:** 5-30 minutes (typically 15-20 minutes for full propagation)

---

#### Understanding DNS Propagation

**What is DNS Propagation?**

DNS propagation is the process by which DNS changes (like your new A records) spread across the internet's DNS infrastructure. When you create or modify DNS records, the changes don't take effect instantly worldwide. Instead, they gradually propagate through various DNS servers and caching layers.

**Propagation Timeframes:**

- **Minimum:** 5 minutes (best case, with low TTL values)
- **Typical:** 15-30 minutes (most common experience)
- **Maximum:** 24-48 hours (rare, usually only for name server changes)
- **Our Configuration:** With TTL set to 300 seconds (5 minutes), expect 10-30 minutes for full propagation

**Factors Affecting Propagation Speed:**

1. **TTL (Time To Live):**
   - Lower TTL = Faster propagation (we use 300 seconds)
   - DNS resolvers cache records for the TTL duration
   - After TTL expires, resolvers fetch the updated record

2. **DNS Provider:**
   - Route 53: Typically 5-15 minutes
   - Namecheap: Typically 10-30 minutes
   - GoDaddy: Typically 10-30 minutes
   - Cloudflare: Typically 5-10 minutes (very fast)

3. **Geographic Location:**
   - DNS changes propagate to different regions at different speeds
   - Your local DNS resolver may see changes before others
   - Global propagation takes longer than local propagation

4. **DNS Resolver Caching:**
   - ISPs and public DNS services (Google DNS, Cloudflare DNS) cache records
   - Cached records aren't updated until TTL expires
   - Different resolvers may have different cache states

**Propagation Stages:**

1. **Authoritative Name Servers (Immediate):**
   - Your DNS provider's authoritative servers are updated immediately
   - Querying these directly shows the new records right away

2. **Public DNS Resolvers (5-15 minutes):**
   - Google DNS (8.8.8.8), Cloudflare DNS (1.1.1.1), etc.
   - These update relatively quickly after TTL expiration

3. **ISP DNS Resolvers (15-30 minutes):**
   - Your internet provider's DNS servers
   - May take longer to update due to caching policies

4. **Global Propagation (30 minutes - 48 hours):**
   - All DNS resolvers worldwide have the updated record
   - 99% of resolvers update within 30 minutes with low TTL

**Best Practices During Propagation:**

- **Be patient:** Don't repeatedly check every minute (it won't speed things up)
- **Check multiple sources:** Verify with different DNS resolvers to confirm propagation
- **Wait for full propagation:** Even if your local machine resolves correctly, wait for global propagation
- **Don't proceed prematurely:** SSL certificate generation requires DNS to be propagated to Let's Encrypt's servers

---

#### DNS Verification Commands

Use the following commands to verify that your DNS A records are correctly configured and have propagated. You should verify both the root domain and the www subdomain.

##### Using `dig` (Recommended)

`dig` (Domain Information Groper) is the most powerful and detailed DNS query tool. It's pre-installed on macOS and most Linux distributions.

**Verify Root Domain:**

```bash
dig yourdomain.com +short
```

**Expected Output:**
```
203.0.113.42
```

This should show your Lightsail instance's public IP address.

**Verify WWW Subdomain:**

```bash
dig www.yourdomain.com +short
```

**Expected Output:**
```
203.0.113.42
```

This should show the same IP address as the root domain.

**Detailed DNS Query (More Information):**

```bash
dig yourdomain.com A
```

**Expected Output:**
```
; <<>> DiG 9.10.6 <<>> yourdomain.com A
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;yourdomain.com.                IN      A

;; ANSWER SECTION:
yourdomain.com.         300     IN      A       203.0.113.42

;; Query time: 45 msec
;; SERVER: 8.8.8.8#53(8.8.8.8)
;; WHEN: Mon Jan 15 10:30:00 PST 2024
;; MSG SIZE  rcvd: 59
```

**Key Information in Detailed Output:**
- **status: NOERROR** - DNS query was successful
- **ANSWER SECTION** - Shows the A record with your IP address
- **300** - TTL in seconds (how long the record is cached)
- **203.0.113.42** - Your Lightsail instance IP address
- **SERVER: 8.8.8.8** - Which DNS resolver was queried (Google DNS in this example)

**Query Specific DNS Servers:**

You can query specific DNS servers to check propagation across different resolvers:

```bash
# Query Google DNS (8.8.8.8)
dig @8.8.8.8 yourdomain.com +short

# Query Cloudflare DNS (1.1.1.1)
dig @1.1.1.1 yourdomain.com +short

# Query your DNS provider's authoritative name server
# (Replace with your actual name server from DNS provider)
dig @ns1.yourdnsprovider.com yourdomain.com +short
```

**Expected Output for All:**
```
203.0.113.42
```

All DNS servers should return the same IP address once propagation is complete.

**If `dig` is not installed:**

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install dnsutils
```

**Linux (RHEL/CentOS/Fedora):**
```bash
sudo yum install bind-utils
```

**macOS:**
`dig` is pre-installed. If missing, install via Homebrew:
```bash
brew install bind
```

**Windows:**
`dig` is not included by default. Use `nslookup` (see below) or install BIND tools:
- Download from: https://www.isc.org/download/
- Or use Windows Subsystem for Linux (WSL)

---

##### Using `nslookup` (Cross-Platform Alternative)

`nslookup` is available on all operating systems (Windows, macOS, Linux) and provides basic DNS query functionality.

**Verify Root Domain:**

```bash
nslookup yourdomain.com
```

**Expected Output:**
```
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   yourdomain.com
Address: 203.0.113.42
```

**Key Information:**
- **Server: 8.8.8.8** - The DNS resolver that answered the query
- **Address: 203.0.113.42** - Your Lightsail instance IP address
- **Non-authoritative answer** - Normal for queries to recursive resolvers

**Verify WWW Subdomain:**

```bash
nslookup www.yourdomain.com
```

**Expected Output:**
```
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   www.yourdomain.com
Address: 203.0.113.42
```

**Query Specific DNS Servers:**

```bash
# Query Google DNS
nslookup yourdomain.com 8.8.8.8

# Query Cloudflare DNS
nslookup yourdomain.com 1.1.1.1

# Query OpenDNS
nslookup yourdomain.com 208.67.222.222
```

**Expected Output:**
All should return your Lightsail instance IP address (203.0.113.42).

---

##### Using `host` (Simple Alternative)

`host` is a simple DNS lookup utility available on macOS and Linux.

**Verify Root Domain:**

```bash
host yourdomain.com
```

**Expected Output:**
```
yourdomain.com has address 203.0.113.42
```

**Verify WWW Subdomain:**

```bash
host www.yourdomain.com
```

**Expected Output:**
```
www.yourdomain.com has address 203.0.113.42
```

---

##### Online DNS Propagation Checkers

In addition to command-line tools, you can use online services to check DNS propagation from multiple locations worldwide:

**Recommended Online Tools:**

1. **WhatsMyDNS.net** (Most Popular)
   ```
   https://www.whatsmydns.net/
   ```
   - Enter your domain name
   - Select "A" record type
   - Click "Search"
   - Shows DNS resolution from 20+ locations worldwide
   - Green checkmarks indicate successful resolution
   - All locations should show your Lightsail instance IP

2. **DNS Checker**
   ```
   https://dnschecker.org/
   ```
   - Enter your domain name
   - Select "A" record type
   - Shows propagation status from multiple global locations
   - Displays IP addresses returned by each location

3. **Google Admin Toolbox - Dig**
   ```
   https://toolbox.googleapps.com/apps/dig/
   ```
   - Web-based dig tool from Google
   - Enter your domain name
   - Select "A" record type
   - Shows detailed DNS query results

**How to Use Online Checkers:**

1. Visit one of the tools above
2. Enter your domain name (e.g., `yourdomain.com`)
3. Select record type: **A**
4. Click "Search" or "Check"
5. Review results from multiple locations
6. **Propagation is complete when:**
   - All (or most) locations show your Lightsail instance IP
   - No locations show old/incorrect IP addresses
   - No locations show "No record found" errors

**Interpreting Results:**

- **Green checkmarks / All locations show correct IP:** ✅ Propagation complete
- **Mixed results (some correct, some incorrect):** ⏳ Propagation in progress, wait 10-15 minutes
- **All locations show "No record found":** ❌ DNS records not configured correctly, review configuration
- **All locations show wrong IP:** ❌ DNS records point to incorrect IP, update records

---

#### Pre-SSL Verification Checklist

Before proceeding to SSL certificate configuration in the Server Configuration Phase, complete this verification checklist to ensure DNS is properly configured.

**DNS Verification Checklist:**

- [ ] **Root domain resolves to Lightsail instance IP**
  ```bash
  dig yourdomain.com +short
  # Should return: 203.0.113.42 (your instance IP)
  ```

- [ ] **WWW subdomain resolves to Lightsail instance IP**
  ```bash
  dig www.yourdomain.com +short
  # Should return: 203.0.113.42 (your instance IP)
  ```

- [ ] **DNS resolution works from multiple DNS resolvers**
  ```bash
  dig @8.8.8.8 yourdomain.com +short      # Google DNS
  dig @1.1.1.1 yourdomain.com +short      # Cloudflare DNS
  dig @208.67.222.222 yourdomain.com +short  # OpenDNS
  # All should return the same IP address
  ```

- [ ] **Online DNS checker shows global propagation**
  - Visit https://www.whatsmydns.net/
  - Enter your domain name
  - Verify most/all locations show correct IP
  - Check both root domain and www subdomain

- [ ] **No DNS errors or NXDOMAIN responses**
  ```bash
  dig yourdomain.com
  # Should show "status: NOERROR" in output
  # Should NOT show "status: NXDOMAIN" (domain not found)
  ```

- [ ] **Waited at least 10-15 minutes since DNS configuration**
  - Even if local checks pass, wait for global propagation
  - Let's Encrypt servers may be in different regions
  - Premature SSL setup will fail if DNS isn't fully propagated

- [ ] **Reverse DNS check (optional but recommended)**
  ```bash
  # Get IP from domain
  IP=$(dig yourdomain.com +short)
  echo "Domain resolves to: $IP"
  
  # Verify it matches your Lightsail instance IP
  # Compare with infrastructure deployment output
  ```

**All checks must pass before proceeding to Server Configuration Phase.**

---

#### Expected Output Summary

**Successful DNS Configuration:**

When DNS is correctly configured and fully propagated, you should see:

1. **Both domains resolve to the same IP:**
   ```bash
   $ dig yourdomain.com +short
   203.0.113.42
   
   $ dig www.yourdomain.com +short
   203.0.113.42
   ```

2. **Consistent results across DNS resolvers:**
   ```bash
   $ dig @8.8.8.8 yourdomain.com +short
   203.0.113.42
   
   $ dig @1.1.1.1 yourdomain.com +short
   203.0.113.42
   ```

3. **No errors in detailed query:**
   ```bash
   $ dig yourdomain.com
   ...
   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345
   ...
   ;; ANSWER SECTION:
   yourdomain.com.         300     IN      A       203.0.113.42
   ...
   ```

4. **Online checkers show green/success globally:**
   - WhatsMyDNS.net shows green checkmarks for all locations
   - All locations display your Lightsail instance IP
   - No "No record found" or timeout errors

**If All Checks Pass:**
✅ DNS is properly configured and propagated
✅ You can proceed to Server Configuration Phase
✅ SSL certificate generation will succeed

---

#### Troubleshooting DNS Issues

If DNS verification fails or shows unexpected results, use this troubleshooting guide to diagnose and resolve issues.

##### Issue 1: "No Record Found" or NXDOMAIN

**Symptom:**
```bash
$ dig yourdomain.com +short
# No output

$ dig yourdomain.com
...
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 12345
...
```

**Possible Causes:**
1. DNS A records were not created correctly
2. DNS records were created in the wrong hosted zone or DNS provider
3. Domain name is misspelled in DNS configuration
4. Name servers are not pointing to the correct DNS provider

**Solutions:**

1. **Verify DNS records exist in your DNS provider:**
   - Log in to your DNS provider (Route 53, Namecheap, GoDaddy, etc.)
   - Navigate to DNS management for your domain
   - Confirm A records for `@` (root) and `www` exist
   - Verify they point to your Lightsail instance IP

2. **Check name servers:**
   ```bash
   dig NS yourdomain.com +short
   ```
   - Verify name servers match your DNS provider
   - If using Route 53, should show `ns-xxxx.awsdns-xx.org` etc.
   - If name servers are wrong, update them at your domain registrar

3. **Wait longer for propagation:**
   - If you just changed name servers, wait 24-48 hours
   - If you just created A records, wait 15-30 minutes

4. **Query authoritative name servers directly:**
   ```bash
   # Get authoritative name servers
   NS=$(dig NS yourdomain.com +short | head -1)
   
   # Query authoritative server directly
   dig @$NS yourdomain.com +short
   ```
   - If authoritative server returns correct IP, propagation is in progress
   - If authoritative server returns nothing, records aren't configured

---

##### Issue 2: Wrong IP Address Returned

**Symptom:**
```bash
$ dig yourdomain.com +short
192.0.2.100  # Wrong IP address (not your Lightsail instance)
```

**Possible Causes:**
1. DNS A records point to incorrect IP address
2. Old DNS records are still cached
3. DNS records were updated but old TTL hasn't expired

**Solutions:**

1. **Verify IP address in DNS provider:**
   - Log in to your DNS provider
   - Check the A record values
   - Ensure they match your Lightsail instance IP from infrastructure deployment
   - Update if incorrect

2. **Get correct Lightsail instance IP:**
   ```bash
   # Using Terraform
   cd terraform && terraform output instance_ip
   
   # Using CloudFormation
   aws cloudformation describe-stacks \
     --stack-name ai-website-builder \
     --query 'Stacks[0].Outputs[?OutputKey==`InstancePublicIP`].OutputValue' \
     --output text
   
   # Using AWS CLI
   aws lightsail get-instance \
     --instance-name ai-website-builder \
     --query 'instance.publicIpAddress' \
     --output text
   ```

3. **Wait for TTL expiration:**
   - If you just updated the records, wait for the old TTL to expire
   - Check current TTL: `dig yourdomain.com` (look for TTL value in ANSWER SECTION)
   - Wait at least that many seconds, then check again

4. **Flush local DNS cache:**
   
   **macOS:**
   ```bash
   sudo dscacheutil -flushcache
   sudo killall -HUP mDNSResponder
   ```
   
   **Linux:**
   ```bash
   # Ubuntu/Debian with systemd-resolved
   sudo systemd-resolve --flush-caches
   
   # Or restart nscd if installed
   sudo /etc/init.d/nscd restart
   ```
   
   **Windows:**
   ```powershell
   ipconfig /flushdns
   ```

5. **Query different DNS resolvers:**
   ```bash
   # Try multiple resolvers to see if propagation is inconsistent
   dig @8.8.8.8 yourdomain.com +short
   dig @1.1.1.1 yourdomain.com +short
   dig @208.67.222.222 yourdomain.com +short
   ```

---

##### Issue 3: Inconsistent Results Across DNS Resolvers

**Symptom:**
```bash
$ dig @8.8.8.8 yourdomain.com +short
203.0.113.42  # Correct

$ dig @1.1.1.1 yourdomain.com +short
192.0.2.100   # Wrong or old IP
```

**Cause:**
- DNS propagation is in progress
- Different DNS resolvers have different cache states
- Some resolvers have updated records, others still have cached old records

**Solution:**
- **Wait for full propagation:** This is normal during propagation
- Check again in 10-15 minutes
- Propagation is complete when all resolvers return the same IP
- Don't proceed to SSL setup until all major resolvers are consistent

**Monitor propagation progress:**
```bash
# Check multiple resolvers every 5 minutes
watch -n 300 'echo "Google DNS:" && dig @8.8.8.8 yourdomain.com +short && echo "Cloudflare DNS:" && dig @1.1.1.1 yourdomain.com +short'
```

---

##### Issue 4: DNS Works Locally But Not Globally

**Symptom:**
- `dig yourdomain.com` works on your local machine
- Online DNS checkers show "No record found" or wrong IP in some locations

**Cause:**
- Your local DNS resolver has cached the new record
- Global propagation is still in progress
- Some regions haven't received the updated records yet

**Solution:**
- **Wait for global propagation:** This is normal
- Use online DNS checkers to monitor global propagation
- Don't proceed until most/all global locations show correct IP
- Let's Encrypt servers may be in regions that haven't propagated yet

**Recommended wait time:**
- If 50% of locations are correct: Wait 10-15 minutes
- If 80% of locations are correct: Wait 5-10 minutes
- If 95%+ of locations are correct: Safe to proceed

---

##### Issue 5: WWW Subdomain Doesn't Resolve

**Symptom:**
```bash
$ dig yourdomain.com +short
203.0.113.42  # Root domain works

$ dig www.yourdomain.com +short
# No output - www doesn't resolve
```

**Cause:**
- A record for `www` subdomain was not created
- A record for `www` was created incorrectly
- CNAME record for `www` is conflicting with A record

**Solutions:**

1. **Verify www A record exists:**
   - Log in to your DNS provider
   - Check for A record with host/name `www`
   - Ensure it points to your Lightsail instance IP

2. **Check for conflicting CNAME record:**
   ```bash
   dig www.yourdomain.com CNAME
   ```
   - If a CNAME record exists, delete it
   - CNAME and A records cannot coexist for the same name
   - Replace CNAME with A record pointing to your instance IP

3. **Create the missing www A record:**
   - Follow the DNS configuration instructions for your provider
   - Create A record: Host=`www`, Value=`203.0.113.42` (your instance IP)
   - Wait 10-15 minutes for propagation

---

##### Issue 6: DNS Propagation Taking Longer Than Expected

**Symptom:**
- More than 30 minutes have passed since DNS configuration
- DNS still not fully propagated globally

**Possible Causes:**
1. High TTL values on old records (if updating existing domain)
2. Name server changes (takes 24-48 hours)
3. DNS provider propagation delays
4. Aggressive caching by some DNS resolvers

**Solutions:**

1. **Check if you changed name servers:**
   - Name server changes take 24-48 hours to propagate globally
   - If you switched from registrar DNS to Route 53, this is expected
   - Wait the full 48 hours before troubleshooting further

2. **Verify authoritative name servers have correct records:**
   ```bash
   # Get authoritative name server
   NS=$(dig NS yourdomain.com +short | head -1)
   
   # Query it directly
   dig @$NS yourdomain.com +short
   ```
   - If authoritative server has correct IP, propagation is just slow
   - If authoritative server has wrong IP, fix records in DNS provider

3. **Check old TTL values:**
   - If you updated existing records, old TTL may be high (3600+ seconds)
   - Resolvers will cache old records until old TTL expires
   - Wait for old TTL duration, then check again

4. **Continue waiting:**
   - 99% of DNS propagation completes within 2 hours
   - If authoritative servers are correct, propagation will complete eventually
   - Use online checkers to monitor progress

5. **Proceed with caution:**
   - If 90%+ of global locations show correct IP, you can proceed
   - SSL certificate generation may still fail if Let's Encrypt servers haven't propagated
   - If SSL fails, wait longer and retry

---

#### When to Proceed to Next Phase

**You are ready to proceed to Server Configuration Phase when:**

✅ **All DNS verification checks pass:**
- Root domain resolves to Lightsail instance IP
- WWW subdomain resolves to Lightsail instance IP
- Multiple DNS resolvers return consistent results
- Online DNS checkers show global propagation (90%+ locations)

✅ **Sufficient time has passed:**
- At least 15 minutes since DNS record creation
- At least 30 minutes if you changed name servers
- Longer if you updated existing records with high TTL

✅ **No DNS errors:**
- No NXDOMAIN (domain not found) errors
- No timeout errors
- No inconsistent results across resolvers

**Do NOT proceed if:**
- ❌ DNS queries return "No record found"
- ❌ DNS returns wrong IP address
- ❌ Inconsistent results across DNS resolvers (some work, some don't)
- ❌ Online checkers show less than 80% global propagation
- ❌ Less than 10 minutes have passed since DNS configuration

**Why waiting is important:**
- Let's Encrypt (SSL certificate provider) must be able to resolve your domain
- If DNS isn't propagated to Let's Encrypt's servers, certificate generation will fail
- Failed certificate attempts count against Let's Encrypt's rate limits
- It's better to wait an extra 10 minutes than to fail SSL setup and have to troubleshoot

---

#### DNS Verification Summary

**Checklist:**
- [ ] DNS A records created for root domain and www subdomain
- [ ] Both records point to Lightsail instance IP address
- [ ] Waited at least 15 minutes for DNS propagation
- [ ] Verified DNS resolution using `dig` or `nslookup`
- [ ] Checked multiple DNS resolvers (Google DNS, Cloudflare DNS, etc.)
- [ ] Verified global propagation using online DNS checker
- [ ] All verification checks pass with consistent results
- [ ] No DNS errors or NXDOMAIN responses

**Time Estimate:**
- **DNS configuration:** 5-10 minutes (completed in previous section)
- **DNS propagation wait:** 10-30 minutes (varies by provider and location)
- **DNS verification:** 5 minutes (running verification commands)
- **Total:** 20-45 minutes for complete DNS configuration and verification

**What You've Accomplished:**
✅ Domain name is registered or prepared
✅ DNS A records are configured and pointing to your Lightsail instance
✅ DNS has propagated globally and is verified
✅ Your domain is ready for SSL certificate generation

**Next Steps:**
With DNS properly configured and verified, you can now proceed to the Server Configuration Phase, where you'll:
1. SSH into your Lightsail instance
2. Run configuration scripts for NGINX, firewall, VPN, and SSL
3. Configure systemd services for the application

**IMPORTANT:** The SSL certificate configuration script (configure-ssl.sh) in the next phase will use your domain name to request certificates from Let's Encrypt. The DNS verification you just completed ensures this process will succeed.

**Continue to:** [Server Configuration Phase](#server-configuration-phase)

---

## Server Configuration Phase

Now that your infrastructure is deployed and DNS is configured, it's time to configure the server by running a series of configuration scripts. This phase involves SSH access to the Lightsail instance and executing five configuration scripts in sequence.

**Phase Overview:**
1. Establish SSH access to the Lightsail instance
2. Run `configure-nginx.sh` - Set up NGINX web server
3. Run `configure-ufw.sh` - Configure firewall rules
4. Run `configure-tailscale.sh` - Set up VPN access
5. Run `configure-ssl.sh` - Install SSL certificates (requires DNS)
6. Run `configure-systemd.sh` - Create systemd service for the application

**Prerequisites:**
- Infrastructure deployment completed (Phase 2)
- DNS configuration completed and propagated (Phase 3)
- Lightsail instance public IP address (from infrastructure outputs)
- SSH client installed on your local machine

**Estimated Time:** 15-20 minutes

---

### SSH Access Setup

Before you can run the configuration scripts, you need to establish SSH access to your Lightsail instance. AWS Lightsail automatically creates an SSH key pair when you provision an instance, and you'll use this key to connect securely.

#### Understanding Lightsail SSH Keys

When you create a Lightsail instance through Terraform or CloudFormation, AWS automatically:
- Creates a default SSH key pair for your region (if one doesn't exist)
- Associates this key pair with your instance
- Stores the private key in the Lightsail console for download
- Configures the instance to accept connections using this key

**Default SSH Key Names by Region:**
- `LightsailDefaultKey-us-east-1` (US East - N. Virginia)
- `LightsailDefaultKey-us-west-2` (US West - Oregon)
- `LightsailDefaultKey-eu-west-1` (Europe - Ireland)
- Pattern: `LightsailDefaultKey-{region}`

**Default User:**
- Ubuntu instances use the `ubuntu` user (not `root`)
- This user has sudo privileges for administrative tasks

---

#### Step 1: Download Your SSH Key from Lightsail Console

If you haven't already downloaded your SSH key, follow these steps:

1. **Log in to the AWS Lightsail Console:**
   - Visit: https://lightsail.aws.amazon.com/
   - Select your region (same region where you deployed the instance)

2. **Navigate to Account Settings:**
   - Click on your account name in the top-right corner
   - Select "Account" from the dropdown menu
   - Or go directly to: https://lightsail.aws.amazon.com/ls/webapp/account/keys

3. **Download the SSH Key:**
   - In the "SSH keys" tab, you'll see your default key pair
   - Click "Download" next to the key for your region (e.g., `LightsailDefaultKey-us-east-1`)
   - Save the file to a secure location on your computer (e.g., `~/Downloads/LightsailDefaultKey-us-east-1.pem`)

**Alternative: Download via AWS CLI**

You can also retrieve your SSH key using the AWS CLI:

```bash
# List available SSH keys in your region
aws lightsail get-key-pairs --region us-east-1

# Download the private key (replace region as needed)
aws lightsail download-default-key-pair --region us-east-1 --query 'privateKeyBase64' --output text > LightsailDefaultKey-us-east-1.pem
```

---

#### Step 2: Set Up SSH Key Permissions

SSH requires that private key files have restricted permissions for security. If permissions are too open, SSH will refuse to use the key.

**macOS and Linux:**

```bash
# Move the key to a secure location (recommended)
mkdir -p ~/.ssh
mv ~/Downloads/LightsailDefaultKey-*.pem ~/.ssh/

# Set correct permissions (read-only for owner)
chmod 400 ~/.ssh/LightsailDefaultKey-*.pem

# Verify permissions
ls -l ~/.ssh/LightsailDefaultKey-*.pem
```

**Expected Output:**
```
-r-------- 1 username username 1704 Jan 15 10:30 /home/username/.ssh/LightsailDefaultKey-us-east-1.pem
```

The `-r--------` indicates read-only for owner, no permissions for group or others.

**Windows:**

If using Windows with OpenSSH:

```powershell
# Move the key to a secure location
mkdir $HOME\.ssh -Force
Move-Item -Path "$HOME\Downloads\LightsailDefaultKey-*.pem" -Destination "$HOME\.ssh\"

# Set permissions (remove inheritance and grant access only to current user)
$keyPath = "$HOME\.ssh\LightsailDefaultKey-us-east-1.pem"
icacls $keyPath /inheritance:r
icacls $keyPath /grant:r "$($env:USERNAME):(R)"
```

If using PuTTY on Windows:
1. Download PuTTYgen from: https://www.putty.org/
2. Open PuTTYgen and click "Load"
3. Select your `.pem` file (change file filter to "All Files")
4. Click "Save private key" to save as `.ppk` format
5. Use the `.ppk` file with PuTTY

---

#### Step 3: Get Your Instance IP Address

You need the public IP address of your Lightsail instance to connect via SSH. This was provided in the infrastructure deployment outputs.

**If using Terraform:**

```bash
cd terraform
terraform output public_ip
```

**Expected Output:**
```
"54.123.45.67"
```

**If using CloudFormation:**

```bash
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' \
  --output text
```

**Expected Output:**
```
54.123.45.67
```

**Alternative: Get IP from Lightsail Console:**

1. Visit: https://lightsail.aws.amazon.com/
2. Click on your instance name (e.g., `ai-website-builder`)
3. The public IP is displayed prominently on the instance details page

**Save this IP address** - you'll use it throughout the server configuration phase.

---

#### Step 4: Connect via SSH

Now you can connect to your Lightsail instance using SSH.

**macOS and Linux:**

```bash
# Basic SSH command
ssh -i ~/.ssh/LightsailDefaultKey-us-east-1.pem ubuntu@54.123.45.67

# Replace with your actual key path and IP address
ssh -i ~/.ssh/LightsailDefaultKey-YOUR-REGION.pem ubuntu@YOUR_INSTANCE_IP
```

**First Connection:**

On your first connection, you'll see a message about host authenticity:

```
The authenticity of host '54.123.45.67 (54.123.45.67)' can't be established.
ECDSA key fingerprint is SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Type `yes` and press Enter. This adds the server to your known hosts file.

**Expected Output (Successful Connection):**

```
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-1045-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Mon Jan 15 15:30:45 UTC 2024

  System load:  0.0               Processes:             95
  Usage of /:   15.2% of 19.21GB  Users logged in:       0
  Memory usage: 25%               IPv4 address for ens5: 172.26.x.x
  Swap usage:   0%

ubuntu@ip-172-26-x-x:~$
```

You are now connected to your Lightsail instance!

**Windows (OpenSSH):**

```powershell
ssh -i $HOME\.ssh\LightsailDefaultKey-us-east-1.pem ubuntu@54.123.45.67
```

**Windows (PuTTY):**

1. Open PuTTY
2. In "Host Name (or IP address)", enter: `ubuntu@54.123.45.67`
3. In the left sidebar, navigate to: Connection → SSH → Auth
4. Click "Browse" next to "Private key file for authentication"
5. Select your `.ppk` file (converted from `.pem` using PuTTYgen)
6. Click "Open" to connect
7. Accept the security alert on first connection

---

#### Step 5: Verify Instance Setup

Once connected, verify that the instance was provisioned correctly:

```bash
# Check Ubuntu version
lsb_release -a

# Check available disk space
df -h

# Check memory
free -h

# Check that user-data script completed
sudo cat /var/log/user-data.log | tail -20

# Verify application directories were created
ls -la /opt/website-builder/
```

**Expected Output for Directory Check:**
```
drwxr-x--- 7 ubuntu ubuntu 4096 Jan 15 15:00 .
drwxr-xr-x 3 root   root   4096 Jan 15 15:00 ..
drwxr-xr-x 2 ubuntu ubuntu 4096 Jan 15 15:00 app
drwxr-xr-x 3 ubuntu ubuntu 4096 Jan 15 15:00 assets
drwxr-xr-x 3 ubuntu ubuntu 4096 Jan 15 15:00 config
drwxr-xr-x 2 ubuntu ubuntu 4096 Jan 15 15:00 logs
drwxr-xr-x 2 ubuntu ubuntu 4096 Jan 15 15:00 versions
```

If the directories exist and the user-data log shows "User data script completed successfully!", your instance is ready for configuration.

---

### SSH Key Management Best Practices

Proper SSH key management is critical for maintaining secure access to your server. Follow these best practices to protect your infrastructure.

#### 1. Secure Key Storage

**Do:**
- Store private keys in `~/.ssh/` directory with `400` permissions (read-only for owner)
- Use a password manager to back up keys securely
- Keep keys on encrypted storage devices
- Maintain separate keys for different environments (dev, staging, production)

**Don't:**
- Never commit private keys to version control (Git repositories)
- Never share private keys via email, chat, or unencrypted channels
- Never store keys in cloud storage without encryption
- Never use the same key across multiple unrelated systems

#### 2. Key Rotation

**Recommended Schedule:**
- Rotate SSH keys every 90-180 days for production systems
- Rotate immediately if a key is compromised or an employee leaves
- Rotate after any security incident

**How to Rotate Keys:**

1. **Generate a new key pair in Lightsail:**
   ```bash
   # Create a new key pair via AWS CLI
   aws lightsail create-key-pair \
     --key-pair-name ai-website-builder-2024-01 \
     --region us-east-1 \
     --query 'privateKeyBase64' \
     --output text > ~/.ssh/ai-website-builder-2024-01.pem
   
   chmod 400 ~/.ssh/ai-website-builder-2024-01.pem
   ```

2. **Add the new public key to the instance:**
   ```bash
   # SSH into the instance with the old key
   ssh -i ~/.ssh/LightsailDefaultKey-us-east-1.pem ubuntu@YOUR_INSTANCE_IP
   
   # Add the new public key to authorized_keys
   # (Get the public key from Lightsail console or extract from private key)
   echo "ssh-rsa AAAAB3NzaC1yc2E... new-key-comment" >> ~/.ssh/authorized_keys
   
   # Verify the new key works (from another terminal)
   ssh -i ~/.ssh/ai-website-builder-2024-01.pem ubuntu@YOUR_INSTANCE_IP
   ```

3. **Remove the old key after verifying the new one works:**
   ```bash
   # Edit authorized_keys to remove the old key
   nano ~/.ssh/authorized_keys
   # Delete the line with the old key, save and exit
   ```

4. **Delete the old key from Lightsail:**
   ```bash
   aws lightsail delete-key-pair \
     --key-pair-name LightsailDefaultKey-us-east-1 \
     --region us-east-1
   ```

#### 3. Access Control

**Principle of Least Privilege:**
- Only grant SSH access to users who need it
- Use separate keys for each user (don't share keys)
- Remove access immediately when no longer needed

**Audit Access:**
- Regularly review `~/.ssh/authorized_keys` on the server
- Monitor SSH login attempts: `sudo grep 'sshd' /var/log/auth.log`
- Set up alerts for failed login attempts

#### 4. SSH Configuration Hardening

After initial setup, consider hardening SSH configuration on the server:

```bash
# Edit SSH daemon configuration
sudo nano /etc/ssh/sshd_config
```

**Recommended Settings:**

```
# Disable password authentication (key-only)
PasswordAuthentication no

# Disable root login
PermitRootLogin no

# Limit authentication attempts
MaxAuthTries 3

# Set idle timeout (15 minutes)
ClientAliveInterval 300
ClientAliveCountMax 2

# Disable X11 forwarding if not needed
X11Forwarding no

# Use only strong ciphers
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
```

**Apply changes:**
```bash
# Test configuration for syntax errors
sudo sshd -t

# Restart SSH service
sudo systemctl restart sshd
```

**⚠️ Warning:** Test SSH access from a second terminal before closing your current session to ensure you don't lock yourself out!

#### 5. SSH Config File for Convenience

Create an SSH config file to simplify connections:

```bash
# Create or edit SSH config
nano ~/.ssh/config
```

**Add an entry for your instance:**

```
Host ai-website-builder
    HostName 54.123.45.67
    User ubuntu
    IdentityFile ~/.ssh/LightsailDefaultKey-us-east-1.pem
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

**Now you can connect with a simple command:**

```bash
ssh ai-website-builder
```

**Set correct permissions on config file:**

```bash
chmod 600 ~/.ssh/config
```

#### 6. Backup and Recovery

**Backup Strategy:**
- Keep a secure backup of your private key in a password manager or encrypted vault
- Document which key is used for which server
- Store recovery procedures in a secure location

**Recovery Procedure (if key is lost):**

If you lose your SSH key and cannot access the instance:

1. **Use Lightsail Browser-Based SSH:**
   - Go to: https://lightsail.aws.amazon.com/
   - Click on your instance
   - Click "Connect using SSH" (browser-based terminal)
   - This provides emergency access without a key

2. **Add a new key from browser SSH:**
   ```bash
   # Generate a new key pair on your local machine
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/ai-website-builder-recovery
   
   # Copy the public key content
   cat ~/.ssh/ai-website-builder-recovery.pub
   
   # In the browser SSH session, add the public key
   echo "ssh-rsa AAAAB3NzaC1yc2E... your-public-key" >> ~/.ssh/authorized_keys
   
   # Test the new key from your local machine
   ssh -i ~/.ssh/ai-website-builder-recovery ubuntu@YOUR_INSTANCE_IP
   ```

3. **Update your SSH config with the new key**

---

### Troubleshooting Common SSH Connection Issues

If you encounter problems connecting to your Lightsail instance, use this troubleshooting guide to diagnose and resolve common issues.

#### Issue 1: "Permission denied (publickey)"

**Symptom:**
```
ubuntu@54.123.45.67: Permission denied (publickey).
```

**Possible Causes and Solutions:**

**A. Incorrect key file:**
```bash
# Verify you're using the correct key file
ls -l ~/.ssh/LightsailDefaultKey-*.pem

# Try specifying the key explicitly
ssh -i ~/.ssh/LightsailDefaultKey-us-east-1.pem ubuntu@YOUR_INSTANCE_IP
```

**B. Wrong username:**
```bash
# Ubuntu instances use 'ubuntu' user, not 'root' or 'ec2-user'
# Correct:
ssh -i ~/.ssh/LightsailDefaultKey-us-east-1.pem ubuntu@YOUR_INSTANCE_IP

# Incorrect:
ssh -i ~/.ssh/LightsailDefaultKey-us-east-1.pem root@YOUR_INSTANCE_IP
```

**C. Incorrect key permissions:**
```bash
# Check current permissions
ls -l ~/.ssh/LightsailDefaultKey-us-east-1.pem

# Fix permissions (must be 400 or 600)
chmod 400 ~/.ssh/LightsailDefaultKey-us-east-1.pem
```

**D. Wrong region key:**
```bash
# Ensure you downloaded the key for the correct region
# If your instance is in us-west-2, you need LightsailDefaultKey-us-west-2.pem

# List your key pairs
aws lightsail get-key-pairs --region us-west-2
```

**E. Key not associated with instance:**

Use Lightsail browser-based SSH to add your key:
1. Go to: https://lightsail.aws.amazon.com/
2. Click your instance → "Connect using SSH"
3. In the browser terminal:
   ```bash
   # View current authorized keys
   cat ~/.ssh/authorized_keys
   
   # Add your public key (get from local machine)
   echo "YOUR_PUBLIC_KEY_CONTENT" >> ~/.ssh/authorized_keys
   ```

---

#### Issue 2: "Connection timed out" or "No route to host"

**Symptom:**
```
ssh: connect to host 54.123.45.67 port 22: Connection timed out
```

**Possible Causes and Solutions:**

**A. Incorrect IP address:**
```bash
# Verify the instance IP address
aws lightsail get-instance --instance-name ai-website-builder \
  --query 'instance.publicIpAddress' --output text

# Or check Terraform outputs
cd terraform && terraform output public_ip
```

**B. Instance not running:**
```bash
# Check instance state
aws lightsail get-instance-state --instance-name ai-website-builder

# Expected output: {"state": {"name": "running"}}

# If stopped, start the instance
aws lightsail start-instance --instance-name ai-website-builder
```

**C. Firewall blocking SSH (port 22):**

SSH (port 22) should be open by default on Lightsail instances, but verify:

```bash
# Check firewall rules
aws lightsail get-instance-port-states --instance-name ai-website-builder

# Look for port 22 with "fromPort": 22, "toPort": 22, "protocol": "tcp"
```

If port 22 is not open:
```bash
# Open SSH port
aws lightsail open-instance-public-ports \
  --instance-name ai-website-builder \
  --port-info fromPort=22,toPort=22,protocol=tcp
```

**D. Local network/firewall issues:**
```bash
# Test connectivity to the instance
ping 54.123.45.67

# Test if port 22 is reachable
telnet 54.123.45.67 22
# Or using nc (netcat)
nc -zv 54.123.45.67 22

# Expected output: "Connection to 54.123.45.67 22 port [tcp/ssh] succeeded!"
```

If ping/telnet fails, check:
- Your local firewall settings
- Corporate VPN or proxy settings
- ISP blocking outbound SSH connections

**E. DNS propagation issues (if using hostname):**

If connecting via domain name instead of IP:
```bash
# Test DNS resolution
nslookup yourdomain.com
dig yourdomain.com

# If DNS not resolved, use IP address directly
ssh -i ~/.ssh/LightsailDefaultKey-us-east-1.pem ubuntu@54.123.45.67
```

---

#### Issue 3: "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED"

**Symptom:**
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
```

**Cause:**
This occurs when the server's SSH host key has changed, typically because:
- You destroyed and recreated the instance with the same IP
- The instance was restored from a snapshot
- The IP was previously used by a different server

**Solution:**

**A. If you know the change is legitimate (e.g., you recreated the instance):**

```bash
# Remove the old host key from known_hosts
ssh-keygen -R 54.123.45.67

# Or manually edit the known_hosts file
nano ~/.ssh/known_hosts
# Delete the line containing the old key for this IP
```

**B. Verify the new host key fingerprint:**

Use Lightsail browser-based SSH to get the current fingerprint:
```bash
# In browser SSH session
ssh-keygen -lf /etc/ssh/ssh_host_ecdsa_key.pub
```

Compare this with the fingerprint shown in the warning message.

**C. Reconnect:**
```bash
ssh -i ~/.ssh/LightsailDefaultKey-us-east-1.pem ubuntu@54.123.45.67
# Type 'yes' when prompted to accept the new host key
```

---

#### Issue 4: "Too many authentication failures"

**Symptom:**
```
Received disconnect from 54.123.45.67: 2: Too many authentication failures
```

**Cause:**
SSH tries multiple keys from your `~/.ssh/` directory before the correct one, exceeding the server's `MaxAuthTries` limit.

**Solution:**

**A. Specify the key explicitly:**
```bash
ssh -i ~/.ssh/LightsailDefaultKey-us-east-1.pem ubuntu@54.123.45.67
```

**B. Use SSH config to specify the key:**
```bash
# Edit SSH config
nano ~/.ssh/config

# Add:
Host ai-website-builder
    HostName 54.123.45.67
    User ubuntu
    IdentityFile ~/.ssh/LightsailDefaultKey-us-east-1.pem
    IdentitiesOnly yes  # Only use the specified key
```

**C. Disable SSH agent temporarily:**
```bash
ssh -o IdentitiesOnly=yes -i ~/.ssh/LightsailDefaultKey-us-east-1.pem ubuntu@54.123.45.67
```

---

#### Issue 5: "Connection closed by remote host" immediately after connecting

**Symptom:**
```
Connection to 54.123.45.67 closed by remote host.
Connection to 54.123.45.67 closed.
```

**Possible Causes and Solutions:**

**A. Disk space full:**

Use Lightsail browser-based SSH to check:
```bash
df -h
# If / is at 100%, free up space:
sudo apt-get clean
sudo apt-get autoremove
```

**B. SSH configuration error:**

Check SSH logs in browser SSH:
```bash
sudo tail -50 /var/log/auth.log
# Look for errors related to sshd
```

**C. User account issues:**

Verify the ubuntu user exists and has a valid shell:
```bash
# In browser SSH
grep ubuntu /etc/passwd
# Should show: ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash
```

---

#### Issue 6: Slow SSH connection or login

**Symptom:**
SSH connection takes 30+ seconds to establish.

**Possible Causes and Solutions:**

**A. DNS reverse lookup timeout:**

Add to your local SSH config:
```bash
nano ~/.ssh/config

# Add:
Host *
    GSSAPIAuthentication no
```

**B. Server-side DNS issues:**

In browser SSH or after connecting:
```bash
# Edit SSH daemon config
sudo nano /etc/ssh/sshd_config

# Add or modify:
UseDNS no

# Restart SSH
sudo systemctl restart sshd
```

---

#### Issue 7: "Could not resolve hostname"

**Symptom:**
```
ssh: Could not resolve hostname yourdomain.com: Name or service not known
```

**Cause:**
DNS not configured or not propagated yet.

**Solution:**

**A. Use IP address instead:**
```bash
ssh -i ~/.ssh/LightsailDefaultKey-us-east-1.pem ubuntu@54.123.45.67
```

**B. Wait for DNS propagation:**
```bash
# Check DNS status
dig yourdomain.com
nslookup yourdomain.com

# DNS can take 5-30 minutes to propagate
```

**C. Check DNS configuration:**
Verify your A record points to the correct IP in your DNS provider's control panel.

---

#### Emergency Access: Lightsail Browser-Based SSH

If you cannot connect via SSH from your local machine, use Lightsail's browser-based SSH as a fallback:

1. **Access the Console:**
   - Visit: https://lightsail.aws.amazon.com/
   - Navigate to your instance

2. **Connect via Browser:**
   - Click "Connect using SSH" button
   - A browser-based terminal will open
   - You're now connected as the `ubuntu` user

3. **Use for Troubleshooting:**
   - Check SSH configuration: `sudo nano /etc/ssh/sshd_config`
   - View SSH logs: `sudo tail -100 /var/log/auth.log`
   - Add new SSH keys: `nano ~/.ssh/authorized_keys`
   - Check firewall: `sudo ufw status`
   - Verify instance health: `df -h`, `free -h`, `systemctl status sshd`

**Limitations:**
- Browser SSH has limited terminal features (no tab completion, limited copy/paste)
- Not suitable for long-running tasks
- Use only for emergency access and troubleshooting

---

#### Diagnostic Commands Summary

Use these commands to diagnose SSH connection issues:

```bash
# Test connectivity
ping YOUR_INSTANCE_IP
telnet YOUR_INSTANCE_IP 22
nc -zv YOUR_INSTANCE_IP 22

# Verbose SSH connection (shows detailed debug info)
ssh -vvv -i ~/.ssh/LightsailDefaultKey-us-east-1.pem ubuntu@YOUR_INSTANCE_IP

# Check local SSH key permissions
ls -l ~/.ssh/LightsailDefaultKey-*.pem

# Verify instance is running
aws lightsail get-instance-state --instance-name ai-website-builder

# Check instance firewall rules
aws lightsail get-instance-port-states --instance-name ai-website-builder

# Get instance IP
aws lightsail get-instance --instance-name ai-website-builder \
  --query 'instance.publicIpAddress' --output text
```

---

### Next Steps

Once you have successfully established SSH access to your Lightsail instance and verified the instance setup, you're ready to proceed with server configuration.

**Checklist:**
- [ ] SSH key downloaded from Lightsail console
- [ ] SSH key permissions set to 400 (read-only for owner)
- [ ] Instance public IP address obtained
- [ ] Successfully connected to instance via SSH
- [ ] Verified instance setup (directories created, user-data completed)
- [ ] SSH config file created for convenience (optional but recommended)

**What's Next:**

The following sections will guide you through running the five configuration scripts:

1. **NGINX Configuration** - Set up the web server for serving static content
2. **UFW Firewall Configuration** - Configure firewall rules to secure the instance
3. **Tailscale VPN Configuration** - Set up VPN access to the Builder Interface
4. **SSL Certificate Configuration** - Install Let's Encrypt SSL certificates for HTTPS
5. **Systemd Service Configuration** - Create a systemd service to manage the application

Each script must be run in order, as later scripts depend on earlier configurations.

**Keep your SSH session open** as you proceed through the configuration steps. If you get disconnected, simply reconnect using:

```bash
ssh -i ~/.ssh/LightsailDefaultKey-us-east-1.pem ubuntu@YOUR_INSTANCE_IP
```

Or, if you set up an SSH config entry:

```bash
ssh ai-website-builder
```

---

### NGINX Configuration

Now that you have SSH access to your Lightsail instance, the first configuration step is to set up NGINX as the web server. NGINX will serve the static HTML files generated by the AI Website Builder to the public internet.

#### Purpose of configure-nginx.sh

The `configure-nginx.sh` script automates the installation and configuration of NGINX with the following features:

**What It Does:**
- Installs NGINX web server
- Creates the web root directory at `/var/www/html`
- Configures NGINX to serve static files with optimal performance settings
- Enables gzip compression for text content (HTML, CSS, JavaScript)
- Sets up cache headers for static assets (images, fonts, CSS, JS)
- Creates a custom 404 error page with professional styling
- Adds security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)
- Blocks access to hidden files and configuration files
- Creates a test index page to verify the configuration
- Enables NGINX to start automatically on system boot

**NGINX Configuration Details:**
- **Web Root:** `/var/www/html` (where your generated HTML files will be served from)
- **Default Port:** 80 (HTTP) - SSL will be configured in a later step
- **Gzip Compression:** Enabled for text-based content to reduce bandwidth
- **Cache Headers:** 
  - Static assets (images, CSS, JS): 1 year cache
  - HTML files: 1 hour cache (allows for frequent updates)
- **Security:** Prevents access to hidden files (`.git`, `.env`) and config files
- **Error Handling:** Custom 404 page with professional design

---

#### Execution Command

The script must be run with root privileges using `sudo`:

```bash
sudo bash /opt/website-builder/infrastructure/scripts/configure-nginx.sh
```

**No parameters are required** - the script uses sensible defaults for all configurations.

**Prerequisites:**
- SSH access to the Lightsail instance
- Internet connectivity (to download NGINX package)
- Sufficient disk space (NGINX requires ~10MB)

**Estimated Time:** 1-2 minutes

---

#### Expected Output

When you run the script, you should see output similar to this:

```
==========================================
NGINX Configuration for AI Website Builder
==========================================
Installing NGINX...
Hit:1 http://us-east-1.ec2.archive.ubuntu.com/ubuntu jammy InRelease
Get:2 http://us-east-1.ec2.archive.ubuntu.com/ubuntu jammy-updates InRelease [119 kB]
...
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  nginx nginx-common nginx-core
...
Setting up nginx (1.18.0-6ubuntu14.4) ...
Creating web root directory...
Creating 404 error page...
Creating test index page...
Test index page created at /var/www/html/index.html
Creating NGINX server configuration...
Configuring NGINX sites...
Testing NGINX configuration...
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
Restarting NGINX...
Enabling NGINX service...
Synchronizing state of nginx.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable nginx
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /lib/systemd/system/nginx.service.

NGINX Status:
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-01-15 16:45:23 UTC; 2s ago
       Docs: man:nginx(8)
    Process: 12345 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 12346 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 12347 (nginx)
      Tasks: 3 (limit: 1131)
     Memory: 3.2M
        CPU: 45ms
     CGroup: /system.slice/nginx.service
             ├─12347 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
             ├─12348 nginx: worker process
             └─12349 nginx: worker process

Jan 15 16:45:23 ip-172-26-x-x systemd[1]: Starting A high performance web server and a reverse proxy server...
Jan 15 16:45:23 ip-172-26-x-x systemd[1]: Started A high performance web server and a reverse proxy server.

==========================================
NGINX Configuration Complete!
==========================================

NGINX is now configured to:
  - Serve static files from /var/www/html
  - Use gzip compression for text content
  - Cache static assets with appropriate headers
  - Serve custom 404 error page
  - Block access to hidden and config files

Test your configuration:
  - Visit http://<server-ip>/ to see the test page
  - Visit http://<server-ip>/nonexistent to see the 404 page
  - Check gzip: curl -H 'Accept-Encoding: gzip' -I http://<server-ip>/

Next steps:
  1. Set up UFW firewall rules (Task 1.3)
  2. Configure Tailscale VPN (Task 1.4)
  3. Set up Let's Encrypt SSL (Task 1.5)
```

**Key Indicators of Success:**
- ✓ `nginx: configuration file /etc/nginx/nginx.conf test is successful`
- ✓ `Active: active (running)` in the status output
- ✓ No error messages during installation or configuration

---

#### NGINX Configuration Created

The script creates a custom NGINX server configuration at `/etc/nginx/sites-available/website-builder` with the following key settings:

**Server Block Configuration:**
```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name _;
    
    root /var/www/html;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Gzip compression enabled
    # Cache headers configured
    # Custom 404 error page
    # Hidden file protection
}
```

**What This Configuration Provides:**

1. **Port 80 Listening:** NGINX listens on HTTP port 80 (IPv4 and IPv6)
2. **Web Root:** Serves files from `/var/www/html`
3. **Default File:** Looks for `index.html` as the default page
4. **Security Headers:**
   - `X-Frame-Options: SAMEORIGIN` - Prevents clickjacking attacks
   - `X-Content-Type-Options: nosniff` - Prevents MIME type sniffing
   - `X-XSS-Protection: 1; mode=block` - Enables XSS protection in browsers
5. **Gzip Compression:** Reduces bandwidth for text content (HTML, CSS, JS, JSON, XML, SVG)
6. **Cache Control:**
   - Static assets (images, fonts, CSS, JS): 1 year cache with `immutable` flag
   - HTML files: 1 hour cache with `must-revalidate` flag
7. **Custom 404 Page:** Professional error page at `/var/www/html/404.html`
8. **File Protection:** Blocks access to hidden files (`.git`, `.env`) and config files

**Test Index Page:**

The script creates a test page at `/var/www/html/index.html` that displays:
- Confirmation that NGINX is working
- Configuration details (web root, gzip, cache headers, security headers)
- List of enabled features
- Next steps in the deployment process

This test page will be replaced with your actual website content when you deploy the application.

---

#### Verification Commands

After running the script, verify that NGINX is configured correctly:

**1. Check NGINX Service Status:**

```bash
systemctl status nginx
```

**Expected Output:**
```
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-01-15 16:45:23 UTC; 5m ago
```

**Key indicators:**
- `Loaded: loaded` - Service file is loaded
- `enabled` - Service will start on boot
- `Active: active (running)` - Service is currently running

**If the service is not running:**
```bash
# Start NGINX
sudo systemctl start nginx

# Check for errors
sudo journalctl -u nginx -n 50
```

---

**2. Test NGINX Configuration Syntax:**

```bash
sudo nginx -t
```

**Expected Output:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**If configuration test fails:**
- Check the error message for the specific file and line number
- Review the configuration file: `sudo nano /etc/nginx/sites-available/website-builder`
- Common issues: missing semicolons, unclosed braces, typos in directives

---

**3. Verify NGINX is Listening on Port 80:**

```bash
sudo netstat -tlnp | grep :80
```

**Expected Output:**
```
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      12347/nginx: master
tcp6       0      0 :::80                   :::*                    LISTEN      12347/nginx: master
```

**Alternative command (if netstat is not available):**
```bash
sudo ss -tlnp | grep :80
```

This confirms NGINX is listening on port 80 for both IPv4 and IPv6.

---

**4. Test HTTP Access from the Server:**

```bash
curl -I http://localhost/
```

**Expected Output:**
```
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Mon, 15 Jan 2024 16:50:00 GMT
Content-Type: text/html
Content-Length: 5432
Last-Modified: Mon, 15 Jan 2024 16:45:23 GMT
Connection: keep-alive
ETag: "65a5b123-1538"
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Accept-Ranges: bytes
```

**Key indicators:**
- `HTTP/1.1 200 OK` - Successful response
- `Server: nginx` - NGINX is serving the request
- Security headers are present (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)

---

**5. Test Gzip Compression:**

```bash
curl -H "Accept-Encoding: gzip" -I http://localhost/
```

**Expected Output:**
```
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Content-Type: text/html
Content-Encoding: gzip
...
```

**Key indicator:**
- `Content-Encoding: gzip` - Gzip compression is working

---

**6. Test Custom 404 Page:**

```bash
curl -I http://localhost/nonexistent-page
```

**Expected Output:**
```
HTTP/1.1 404 Not Found
Server: nginx/1.18.0 (Ubuntu)
Content-Type: text/html
...
```

**View the 404 page content:**
```bash
curl http://localhost/nonexistent-page
```

You should see the custom 404 HTML page with styled content.

---

**7. Verify Web Root Directory:**

```bash
ls -la /var/www/html/
```

**Expected Output:**
```
total 24
drwxr-xr-x 2 www-data www-data 4096 Jan 15 16:45 .
drwxr-xr-x 3 root     root     4096 Jan 15 16:45 ..
-rw-r--r-- 1 www-data www-data 2156 Jan 15 16:45 404.html
-rw-r--r-- 1 www-data www-data 5432 Jan 15 16:45 index.html
```

**Key indicators:**
- Directory owned by `www-data:www-data` (NGINX user)
- `404.html` and `index.html` files present
- Correct permissions (644 for files, 755 for directory)

---

**8. Test from Your Local Machine (Optional):**

If port 80 is open in your firewall (it will be after the next configuration step), you can test from your local machine:

```bash
# Replace with your instance IP
curl -I http://54.123.45.67/
```

**Note:** This may not work yet if the UFW firewall hasn't been configured to allow HTTP traffic. This is expected and will be resolved in the next step.

---

#### Troubleshooting NGINX Configuration

If you encounter issues with NGINX configuration, use these troubleshooting steps:

**Issue 1: NGINX fails to start**

**Symptom:**
```
Job for nginx.service failed because the control process exited with error code.
```

**Diagnosis:**
```bash
# Check NGINX error logs
sudo tail -50 /var/log/nginx/error.log

# Check systemd logs
sudo journalctl -u nginx -n 50

# Test configuration
sudo nginx -t
```

**Common Causes:**
- Configuration syntax error (check `nginx -t` output)
- Port 80 already in use by another service
- Insufficient permissions on web root directory

**Solutions:**

**A. Port 80 already in use:**
```bash
# Check what's using port 80
sudo netstat -tlnp | grep :80

# If Apache is running, stop it
sudo systemctl stop apache2
sudo systemctl disable apache2

# Restart NGINX
sudo systemctl restart nginx
```

**B. Configuration syntax error:**
```bash
# Review the configuration file
sudo nano /etc/nginx/sites-available/website-builder

# Look for missing semicolons, unclosed braces, or typos
# After fixing, test again
sudo nginx -t
sudo systemctl restart nginx
```

**C. Permission issues:**
```bash
# Fix web root permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod 755 /var/www/html
sudo chmod 644 /var/www/html/*.html

# Restart NGINX
sudo systemctl restart nginx
```

---

**Issue 2: 403 Forbidden Error**

**Symptom:**
```
HTTP/1.1 403 Forbidden
```

**Diagnosis:**
```bash
# Check file permissions
ls -la /var/www/html/

# Check NGINX error log
sudo tail -20 /var/log/nginx/error.log
```

**Common Causes:**
- Incorrect file permissions
- Missing index.html file
- SELinux blocking access (rare on Ubuntu)

**Solutions:**

**A. Fix permissions:**
```bash
sudo chown -R www-data:www-data /var/www/html
sudo chmod 755 /var/www/html
sudo chmod 644 /var/www/html/*.html
```

**B. Verify index.html exists:**
```bash
ls -l /var/www/html/index.html

# If missing, create a simple test page
echo "<h1>Test Page</h1>" | sudo tee /var/www/html/index.html
sudo chown www-data:www-data /var/www/html/index.html
```

---

**Issue 3: Gzip Compression Not Working**

**Symptom:**
No `Content-Encoding: gzip` header in response.

**Diagnosis:**
```bash
curl -H "Accept-Encoding: gzip" -I http://localhost/
```

**Common Causes:**
- File too small (gzip_min_length is 1024 bytes)
- Wrong content type
- Gzip module not loaded

**Solutions:**

**A. Test with a larger file:**
```bash
# Create a larger test file
dd if=/dev/zero of=/var/www/html/test.html bs=1024 count=2
sudo chown www-data:www-data /var/www/html/test.html

# Test gzip on the larger file
curl -H "Accept-Encoding: gzip" -I http://localhost/test.html
```

**B. Verify gzip configuration:**
```bash
sudo nginx -T | grep -A 10 "gzip"
```

---

**Issue 4: Cannot Access from Browser**

**Symptom:**
Browser shows "Unable to connect" or "Connection refused" when accessing `http://YOUR_INSTANCE_IP/`

**Common Causes:**
- Firewall blocking port 80 (expected at this stage)
- NGINX not running
- Wrong IP address

**Solutions:**

**A. Verify NGINX is running:**
```bash
sudo systemctl status nginx
```

**B. Test from the server itself:**
```bash
curl http://localhost/
```

If this works, the issue is firewall-related (will be resolved in the next step).

**C. Verify you're using the correct IP:**
```bash
# Get your instance public IP
curl http://169.254.169.254/latest/meta-data/public-ipv4
```

---

**Issue 5: Security Headers Not Present**

**Symptom:**
Security headers (X-Frame-Options, etc.) are missing from HTTP response.

**Diagnosis:**
```bash
curl -I http://localhost/ | grep -E "X-Frame|X-Content|X-XSS"
```

**Solution:**

Verify the configuration includes the security headers:
```bash
sudo grep -A 3 "Security headers" /etc/nginx/sites-available/website-builder
```

If missing, re-run the configuration script:
```bash
sudo bash /opt/website-builder/infrastructure/scripts/configure-nginx.sh
```

---

#### What Happens Next

After successfully configuring NGINX, the web server is ready to serve static content. However, it's not yet accessible from the internet because:

1. **Firewall is not configured** - The UFW firewall needs to be set up to allow HTTP (port 80) and HTTPS (port 443) traffic
2. **SSL is not configured** - HTTPS requires SSL certificates, which will be set up in a later step
3. **DNS may not be pointing to the server** - Your domain needs to resolve to the instance IP

**Current State:**
- ✓ NGINX installed and running
- ✓ Web root directory created at `/var/www/html`
- ✓ Test index page accessible locally
- ✓ Gzip compression enabled
- ✓ Security headers configured
- ✓ Custom 404 page created
- ✗ Not accessible from internet (firewall not configured yet)
- ✗ No HTTPS/SSL (will be configured later)

**Next Steps:**

1. **Configure UFW Firewall** (Section 5.3) - Open ports 22, 80, 443, and 41641
2. **Configure Tailscale VPN** (Section 5.4) - Set up VPN access to the Builder Interface
3. **Configure SSL Certificates** (Section 5.5) - Install Let's Encrypt certificates for HTTPS
4. **Configure Systemd Service** (Section 5.6) - Create service for the application

**Important:** Do not skip the firewall configuration step. Running a web server without a properly configured firewall is a security risk.

---

**Verification Checklist:**

Before proceeding to the next configuration step, ensure:

- [ ] NGINX service is active and running (`systemctl status nginx`)
- [ ] NGINX configuration test passes (`sudo nginx -t`)
- [ ] NGINX is listening on port 80 (`sudo netstat -tlnp | grep :80`)
- [ ] Test page is accessible locally (`curl http://localhost/`)
- [ ] Gzip compression is working (`curl -H "Accept-Encoding: gzip" -I http://localhost/`)
- [ ] Custom 404 page is accessible (`curl http://localhost/nonexistent`)
- [ ] Security headers are present (`curl -I http://localhost/ | grep X-Frame`)
- [ ] Web root directory exists with correct permissions (`ls -la /var/www/html/`)

Once all checks pass, you're ready to proceed to the firewall configuration.

---

### UFW Firewall Configuration

With NGINX configured and running, the next critical step is to set up the UFW (Uncomplicated Firewall) to secure your server. The firewall controls which network ports are accessible from the internet, blocking unauthorized access while allowing legitimate traffic.

#### Purpose of configure-ufw.sh

The `configure-ufw.sh` script automates the configuration of UFW with security-focused firewall rules tailored for the AI Website Builder deployment.

**What It Does:**
- Installs UFW if not already present
- Sets default policies (deny all incoming, allow all outgoing)
- Opens port 22 (SSH) to maintain remote access
- Opens port 80 (HTTP) for public web traffic
- Opens port 443 (HTTPS) for secure web traffic
- Opens port 41641 (UDP) for Tailscale VPN communication
- Blocks all other inbound traffic by default
- Enables UFW to start automatically on system boot
- Displays firewall status and active rules

**Security Model:**

The firewall implements a "deny by default" security model:
- **Default Incoming:** DENY (all inbound connections are blocked unless explicitly allowed)
- **Default Outgoing:** ALLOW (server can initiate outbound connections)

This ensures that only the specific ports required for the AI Website Builder are accessible from the internet.

**Ports Opened:**

| Port | Protocol | Purpose | Public Access |
|------|----------|---------|---------------|
| 22 | TCP | SSH remote access | Yes (required for administration) |
| 80 | TCP | HTTP web traffic | Yes (public website) |
| 443 | TCP | HTTPS web traffic | Yes (public website with SSL) |
| 41641 | UDP | Tailscale VPN | Yes (VPN communication) |

**Ports Kept Closed:**

| Port | Service | Why It's Blocked |
|------|---------|------------------|
| 3000 | Builder Interface | Protected by Tailscale VPN - NOT publicly accessible |
| 3306 | MySQL/MariaDB | No database exposed (if used in future) |
| 5432 | PostgreSQL | No database exposed (if used in future) |
| 27017 | MongoDB | No database exposed (if used in future) |
| All others | Various | Minimize attack surface |

**Critical Security Feature:**

The Builder Interface (port 3000) is **intentionally NOT exposed** to the public internet. It will only be accessible through the Tailscale VPN, which provides:
- End-to-end encryption
- Zero-trust network access
- No exposed attack surface for the admin interface
- Secure access from any device with Tailscale installed

---

#### Execution Command

The script must be run with root privileges using `sudo`:

```bash
sudo bash /opt/website-builder/infrastructure/scripts/configure-ufw.sh
```

**No parameters are required** - the script configures all necessary firewall rules automatically.

**Prerequisites:**
- SSH access to the Lightsail instance
- Internet connectivity (to install UFW if needed)
- NGINX configuration completed (previous step)

**Estimated Time:** 1-2 minutes

**⚠️ Important Warning:**

This script will enable the firewall and block all ports except those explicitly allowed. Ensure you're connected via SSH before running this script, as the script allows SSH (port 22) to prevent lockout. If you're using a non-standard SSH port, you must modify the script before running it.

---

#### Expected Output

When you run the script, you should see output similar to this:

```
[INFO] Starting UFW firewall configuration...
[INFO] Setting default policies...
Default incoming policy changed to 'deny'
(be sure to update your rules accordingly)
Default outgoing policy changed to 'allow'
(be sure to update your rules accordingly)
[INFO] Allowing SSH (port 22)...
Rule added
Rule added (v6)
[INFO] Allowing HTTP (port 80)...
Rule added
Rule added (v6)
[INFO] Allowing HTTPS (port 443)...
Rule added
Rule added (v6)
[INFO] Allowing Tailscale VPN (port 41641 UDP)...
Rule added
Rule added (v6)
[INFO] Enabling UFW...
Firewall is active and enabled on system startup
[INFO] UFW configuration complete!

[INFO] Current UFW status:
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere                   # SSH access
80/tcp                     ALLOW IN    Anywhere                   # HTTP web traffic
443/tcp                    ALLOW IN    Anywhere                   # HTTPS web traffic
41641/udp                  ALLOW IN    Anywhere                   # Tailscale VPN
22/tcp (v6)                ALLOW IN    Anywhere (v6)              # SSH access
80/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTP web traffic
443/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTPS web traffic
41641/udp (v6)             ALLOW IN    Anywhere (v6)              # Tailscale VPN

[INFO] Firewall rules summary:
  ✓ Port 22 (SSH) - ALLOWED
  ✓ Port 80 (HTTP) - ALLOWED
  ✓ Port 443 (HTTPS) - ALLOWED
  ✓ Port 41641 (Tailscale UDP) - ALLOWED
  ✓ All other inbound traffic - BLOCKED

[WARNING] Note: The Builder Interface (port 3000) is NOT exposed to the internet.
[WARNING] It will only be accessible through Tailscale VPN (Task 1.4).
```

**Key Indicators of Success:**
- ✓ `Firewall is active and enabled on system startup`
- ✓ `Status: active` in the UFW status output
- ✓ All four required ports (22, 80, 443, 41641) are listed as ALLOW IN
- ✓ Default policy shows `deny (incoming), allow (outgoing)`
- ✓ No error messages during configuration

---

#### Firewall Rules Created

The script creates the following UFW rules:

**1. Default Policies:**
```bash
ufw default deny incoming   # Block all inbound traffic by default
ufw default allow outgoing  # Allow all outbound traffic
```

**2. Explicit Allow Rules:**
```bash
ufw allow 22/tcp comment 'SSH access'              # Remote administration
ufw allow 80/tcp comment 'HTTP web traffic'        # Public website (HTTP)
ufw allow 443/tcp comment 'HTTPS web traffic'      # Public website (HTTPS)
ufw allow 41641/udp comment 'Tailscale VPN'        # VPN communication
```

**3. IPv6 Support:**

All rules are automatically applied to both IPv4 and IPv6, ensuring the firewall works correctly regardless of the IP protocol used.

**What Each Rule Does:**

- **Port 22 (SSH):** Allows you to connect to the server remotely for administration. Without this rule, you would be locked out after enabling the firewall.

- **Port 80 (HTTP):** Allows public access to your website over HTTP. This is required for:
  - Initial website access before SSL is configured
  - Let's Encrypt certificate validation (HTTP-01 challenge)
  - Automatic HTTP to HTTPS redirects (after SSL is configured)

- **Port 443 (HTTPS):** Allows public access to your website over HTTPS (secure). This is the primary port for serving your website after SSL certificates are installed.

- **Port 41641 (Tailscale UDP):** Allows Tailscale VPN communication. This port is used by Tailscale to establish encrypted peer-to-peer connections for accessing the Builder Interface.

**Ports Intentionally Blocked:**

- **Port 3000 (Builder Interface):** The admin interface is NOT exposed to the internet. It's only accessible through Tailscale VPN, providing an additional layer of security.

- **All other ports:** Any service running on other ports (databases, development servers, etc.) is not accessible from the internet, reducing the attack surface.

---

#### Verification Commands

After running the script, verify that UFW is configured correctly:

**1. Check UFW Status:**

```bash
sudo ufw status verbose
```

**Expected Output:**
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere                   # SSH access
80/tcp                     ALLOW IN    Anywhere                   # HTTP web traffic
443/tcp                    ALLOW IN    Anywhere                   # HTTPS web traffic
41641/udp                  ALLOW IN    Anywhere                   # Tailscale VPN
22/tcp (v6)                ALLOW IN    Anywhere (v6)              # SSH access
80/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTP web traffic
443/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTPS web traffic
41641/udp (v6)             ALLOW IN    Anywhere (v6)              # Tailscale VPN
```

**Key indicators:**
- `Status: active` - Firewall is enabled and running
- `Default: deny (incoming)` - All inbound traffic is blocked by default
- All four required ports are listed with `ALLOW IN`
- Comments are present for each rule (helps with documentation)

**If UFW is not active:**
```bash
# Enable UFW
sudo ufw enable

# Verify it's now active
sudo ufw status
```

---

**2. Check UFW Service Status:**

```bash
sudo systemctl status ufw
```

**Expected Output:**
```
● ufw.service - Uncomplicated firewall
     Loaded: loaded (/lib/systemd/system/ufw.service; enabled; vendor preset: enabled)
     Active: active (exited) since Mon 2024-01-15 17:00:00 UTC; 2min ago
       Docs: man:ufw(8)
   Main PID: 23456 (code=exited, status=0/SUCCESS)
      Tasks: 0 (limit: 1131)
     Memory: 0B
        CPU: 0
     CGroup: /system.slice/ufw.service

Jan 15 17:00:00 ip-172-26-x-x systemd[1]: Starting Uncomplicated firewall...
Jan 15 17:00:00 ip-172-26-x-x systemd[1]: Finished Uncomplicated firewall.
```

**Key indicators:**
- `Loaded: loaded` - Service file is loaded
- `enabled` - Service will start on boot
- `Active: active (exited)` - Service has started successfully (UFW runs as kernel rules, not a daemon)

---

**3. List Numbered Rules:**

```bash
sudo ufw status numbered
```

**Expected Output:**
```
Status: active

     To                         Action      From
     --                         ------      ----
[ 1] 22/tcp                     ALLOW IN    Anywhere                   # SSH access
[ 2] 80/tcp                     ALLOW IN    Anywhere                   # HTTP web traffic
[ 3] 443/tcp                    ALLOW IN    Anywhere                   # HTTPS web traffic
[ 4] 41641/udp                  ALLOW IN    Anywhere                   # Tailscale VPN
[ 5] 22/tcp (v6)                ALLOW IN    Anywhere (v6)              # SSH access
[ 6] 80/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTP web traffic
[ 7] 443/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTPS web traffic
[ 8] 41641/udp (v6)             ALLOW IN    Anywhere (v6)              # Tailscale VPN
```

This numbered view is useful if you need to delete or modify specific rules later.

---

**4. Test HTTP Access from Your Local Machine:**

Now that port 80 is open, you should be able to access the NGINX test page from your local machine:

```bash
# Replace with your instance IP
curl -I http://54.123.45.67/
```

**Expected Output:**
```
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Mon, 15 Jan 2024 17:05:00 GMT
Content-Type: text/html
...
```

**Or test in your web browser:**

Open your browser and navigate to: `http://YOUR_INSTANCE_IP/`

You should see the NGINX test page that was created in the previous step.

**If you cannot access the page:**
- Verify UFW is active: `sudo ufw status`
- Verify port 80 is allowed: `sudo ufw status | grep 80`
- Verify NGINX is running: `sudo systemctl status nginx`
- Check if you're using the correct IP address
- Try accessing from a different network (some corporate networks block port 80)

---

**5. Verify Port 3000 is Blocked:**

This is a critical security check to ensure the Builder Interface is NOT publicly accessible:

```bash
# From your local machine (replace with your instance IP)
curl -I http://54.123.45.67:3000/ --connect-timeout 5
```

**Expected Output:**
```
curl: (28) Connection timed out after 5000 milliseconds
```

Or:
```
curl: (7) Failed to connect to 54.123.45.67 port 3000: Connection refused
```

**This is the correct behavior!** Port 3000 should NOT be accessible from the internet. It will only be accessible through Tailscale VPN after the next configuration step.

**If port 3000 is accessible (returns HTTP response):**
- ⚠️ **SECURITY ISSUE** - The Builder Interface is exposed to the internet
- Verify UFW is active: `sudo ufw status`
- Check for any rules allowing port 3000: `sudo ufw status | grep 3000`
- If a rule exists, delete it: `sudo ufw delete allow 3000`

---

**6. Test Firewall Blocking:**

Verify that the firewall is blocking ports that are not explicitly allowed:

```bash
# Test a random port (should be blocked)
# From your local machine
nc -zv YOUR_INSTANCE_IP 8080
```

**Expected Output:**
```
nc: connect to YOUR_INSTANCE_IP port 8080 (tcp) failed: Connection refused
```

Or:
```
Connection timed out
```

This confirms the firewall is blocking ports that are not in the allow list.

---

**7. Check Firewall Logs (Optional):**

UFW logs blocked connection attempts, which can be useful for security monitoring:

```bash
# View recent firewall logs
sudo tail -50 /var/log/ufw.log
```

**Example Output:**
```
Jan 15 17:10:23 ip-172-26-x-x kernel: [UFW BLOCK] IN=eth0 OUT= MAC=... SRC=203.0.113.45 DST=172.26.x.x LEN=40 TOS=0x00 PREC=0x00 TTL=52 ID=54321 PROTO=TCP SPT=54321 DPT=3000 WINDOW=1024 RES=0x00 SYN URGP=0
```

This shows blocked connection attempts to port 3000 (Builder Interface), confirming the firewall is working correctly.

**To enable more detailed logging:**
```bash
sudo ufw logging medium
```

**To disable logging (if not needed):**
```bash
sudo ufw logging off
```

---

#### Troubleshooting UFW Configuration

If you encounter issues with UFW configuration, use these troubleshooting steps:

**Issue 1: Locked Out of SSH**

**Symptom:**
Cannot connect via SSH after enabling UFW.

**Cause:**
SSH port (22) was not allowed before enabling the firewall, or you're using a non-standard SSH port.

**Prevention:**
The script allows port 22 before enabling UFW to prevent lockout. However, if you're using a non-standard SSH port, you must modify the script.

**Recovery:**

If you're locked out, use Lightsail browser-based SSH:

1. Go to: https://lightsail.aws.amazon.com/
2. Click on your instance
3. Click "Connect using SSH" (browser-based terminal)
4. In the browser terminal:
   ```bash
   # Check UFW status
   sudo ufw status
   
   # Allow your SSH port (if using non-standard port)
   sudo ufw allow 2222/tcp  # Replace 2222 with your SSH port
   
   # Or disable UFW temporarily
   sudo ufw disable
   
   # Fix the configuration and re-enable
   sudo ufw enable
   ```

---

**Issue 2: Website Not Accessible After Enabling Firewall**

**Symptom:**
Cannot access the website at `http://YOUR_INSTANCE_IP/` after enabling UFW.

**Diagnosis:**
```bash
# Check if ports 80 and 443 are allowed
sudo ufw status | grep -E '80|443'

# Check if NGINX is running
sudo systemctl status nginx

# Test from the server itself
curl -I http://localhost/
```

**Solutions:**

**A. Ports not allowed:**
```bash
# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Verify
sudo ufw status
```

**B. NGINX not running:**
```bash
# Start NGINX
sudo systemctl start nginx

# Verify it's accessible
curl -I http://localhost/
```

**C. Lightsail firewall also blocking:**

AWS Lightsail has its own firewall (separate from UFW). Verify ports are open:

```bash
# Check Lightsail firewall rules
aws lightsail get-instance-port-states --instance-name ai-website-builder
```

If ports 80 and 443 are not open in Lightsail:
```bash
# Open HTTP port
aws lightsail open-instance-public-ports \
  --instance-name ai-website-builder \
  --port-info fromPort=80,toPort=80,protocol=tcp

# Open HTTPS port
aws lightsail open-instance-public-ports \
  --instance-name ai-website-builder \
  --port-info fromPort=443,toPort=443,protocol=tcp
```

---

**Issue 3: UFW Rules Not Persisting After Reboot**

**Symptom:**
Firewall rules are lost after server reboot.

**Diagnosis:**
```bash
# Check if UFW service is enabled
sudo systemctl is-enabled ufw
```

**Solution:**
```bash
# Enable UFW service to start on boot
sudo systemctl enable ufw

# Verify
sudo systemctl is-enabled ufw
# Should output: enabled
```

---

**Issue 4: Cannot Delete or Modify Rules**

**Symptom:**
Trying to delete a rule but getting errors.

**Solution:**

**A. Delete by rule number:**
```bash
# List rules with numbers
sudo ufw status numbered

# Delete a specific rule (e.g., rule #3)
sudo ufw delete 3

# Confirm deletion
sudo ufw status numbered
```

**B. Delete by rule specification:**
```bash
# Delete a specific rule
sudo ufw delete allow 80/tcp

# Verify
sudo ufw status
```

**C. Reset UFW completely (⚠️ Use with caution):**
```bash
# This will delete all rules and disable UFW
sudo ufw --force reset

# Re-run the configuration script
sudo bash /opt/website-builder/infrastructure/scripts/configure-ufw.sh
```

---

**Issue 5: UFW Blocking Legitimate Traffic**

**Symptom:**
A service you need is being blocked by the firewall.

**Diagnosis:**
```bash
# Check UFW logs for blocked connections
sudo tail -100 /var/log/ufw.log | grep BLOCK

# Look for the port being blocked
```

**Solution:**

**A. Allow a specific port:**
```bash
# Allow a TCP port
sudo ufw allow 8080/tcp comment 'Custom service'

# Allow a UDP port
sudo ufw allow 5353/udp comment 'mDNS'

# Verify
sudo ufw status
```

**B. Allow from a specific IP:**
```bash
# Allow all traffic from a specific IP
sudo ufw allow from 203.0.113.45

# Allow specific port from specific IP
sudo ufw allow from 203.0.113.45 to any port 3000

# Verify
sudo ufw status
```

---

**Issue 6: UFW Not Starting**

**Symptom:**
```
ERROR: problem running ufw-init
```

**Diagnosis:**
```bash
# Check UFW service status
sudo systemctl status ufw

# Check for errors
sudo journalctl -u ufw -n 50
```

**Common Causes:**
- Kernel modules not loaded
- Conflicting firewall rules
- Corrupted UFW configuration

**Solutions:**

**A. Reload kernel modules:**
```bash
# Load required modules
sudo modprobe ip_tables
sudo modprobe ip6_tables

# Restart UFW
sudo systemctl restart ufw
```

**B. Reset UFW configuration:**
```bash
# Disable UFW
sudo ufw disable

# Reset to defaults
sudo ufw --force reset

# Re-run configuration script
sudo bash /opt/website-builder/infrastructure/scripts/configure-ufw.sh
```

---

#### Security Best Practices

**1. Regular Rule Audits:**

Periodically review your firewall rules to ensure only necessary ports are open:

```bash
# Review current rules
sudo ufw status verbose

# Check for any unexpected rules
sudo ufw status numbered
```

**2. Monitor Blocked Attempts:**

Regularly check UFW logs for suspicious activity:

```bash
# View recent blocked connections
sudo tail -100 /var/log/ufw.log | grep BLOCK

# Count blocked attempts by source IP
sudo grep BLOCK /var/log/ufw.log | awk '{print $12}' | sort | uniq -c | sort -rn | head -10
```

**3. Principle of Least Privilege:**

Only open ports that are absolutely necessary. If you add new services:
- Document why the port needs to be open
- Use specific IP restrictions when possible
- Remove the rule when the service is no longer needed

**4. Defense in Depth:**

UFW is one layer of security. Also implement:
- Strong SSH key authentication (no password login)
- Regular security updates: `sudo apt-get update && sudo apt-get upgrade`
- Application-level security (authentication, input validation)
- Monitoring and logging
- Regular backups

**5. Fail2Ban Integration (Optional):**

Consider installing Fail2Ban to automatically block IPs with repeated failed login attempts:

```bash
# Install Fail2Ban
sudo apt-get install fail2ban

# Configure for SSH protection
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

---

#### What Happens Next

After successfully configuring UFW, your server is now protected by a firewall that:
- ✓ Blocks all inbound traffic by default
- ✓ Allows SSH access for administration
- ✓ Allows HTTP and HTTPS for public website access
- ✓ Allows Tailscale VPN communication
- ✓ Blocks the Builder Interface (port 3000) from public access

**Current State:**
- ✓ NGINX installed and running
- ✓ UFW firewall configured and active
- ✓ Website accessible from the internet (HTTP only, no SSL yet)
- ✓ Builder Interface protected (not publicly accessible)
- ✗ Tailscale VPN not configured yet (Builder Interface not accessible)
- ✗ No HTTPS/SSL (will be configured later)

**Next Steps:**

1. **Configure Tailscale VPN** (Section 5.4) - Set up VPN access to the Builder Interface
2. **Configure SSL Certificates** (Section 5.5) - Install Let's Encrypt certificates for HTTPS
3. **Configure Systemd Service** (Section 5.6) - Create service for the application

**Important Security Note:**

Your server is now more secure with the firewall enabled, but the website is still only accessible over HTTP (not encrypted). The next steps will configure Tailscale VPN for secure admin access and SSL certificates for encrypted public website access.

---

**Verification Checklist:**

Before proceeding to the next configuration step, ensure:

- [ ] UFW is active and enabled (`sudo ufw status`)
- [ ] UFW service is enabled for boot (`sudo systemctl is-enabled ufw`)
- [ ] Port 22 (SSH) is allowed (`sudo ufw status | grep 22`)
- [ ] Port 80 (HTTP) is allowed (`sudo ufw status | grep 80`)
- [ ] Port 443 (HTTPS) is allowed (`sudo ufw status | grep 443`)
- [ ] Port 41641 (Tailscale) is allowed (`sudo ufw status | grep 41641`)
- [ ] Default policy is deny incoming (`sudo ufw status verbose`)
- [ ] Website is accessible from your local machine (`curl -I http://YOUR_INSTANCE_IP/`)
- [ ] Port 3000 is NOT accessible from the internet (security check)
- [ ] SSH connection still works (you're not locked out)

Once all checks pass, you're ready to proceed to Tailscale VPN configuration.

---

### Tailscale VPN Configuration

With NGINX and UFW configured, the next critical step is to set up Tailscale VPN to provide secure access to the Builder Interface. Tailscale creates an encrypted virtual private network that allows you to access the admin interface from any device without exposing it to the public internet.

#### Purpose of configure-tailscale.sh

The `configure-tailscale.sh` script automates the installation and configuration of Tailscale VPN with security-focused access control for the AI Website Builder.

**What It Does:**
- Installs Tailscale VPN client from the official repository
- Authenticates the server with your Tailscale network using an auth key
- Retrieves the server's Tailscale IP address (e.g., 100.x.x.x)
- Configures the Builder Interface to bind only to the Tailscale IP address
- Creates systemd service overrides to enforce VPN-only access
- Verifies firewall configuration (ensures port 3000 is NOT publicly exposed)
- Generates a configuration file with access instructions
- Displays connection status and access URL

**Security Model:**

Tailscale provides a zero-trust network architecture:
- **End-to-End Encryption:** All traffic between devices is encrypted using WireGuard
- **No Public Exposure:** The Builder Interface (port 3000) is never exposed to the internet
- **Device Authentication:** Only devices in your Tailscale network can access the Builder Interface
- **No VPN Server:** Tailscale uses peer-to-peer connections (no central VPN server to compromise)
- **Automatic Key Rotation:** Encryption keys are automatically rotated for security

**What Gets Protected:**

| Component | Access Method | Security |
|-----------|---------------|----------|
| Builder Interface (port 3000) | Tailscale VPN only | ✓ Encrypted, authenticated, not publicly accessible |
| Static Website (ports 80/443) | Public internet | ✓ HTTPS encrypted (after SSL setup) |
| SSH (port 22) | Public internet | ✓ Key-based authentication |

**How It Works:**

1. **Tailscale Network:** When you install Tailscale on your devices and the server, they all join a private network
2. **Private IP Addresses:** Each device gets a Tailscale IP address (100.x.x.x range)
3. **Builder Interface Binding:** The Builder Interface is configured to listen only on the Tailscale IP
4. **Firewall Protection:** UFW blocks port 3000 from the public internet
5. **Secure Access:** You can access the Builder Interface from any device with Tailscale installed

**Why This Matters:**

Without Tailscale VPN:
- ❌ Builder Interface would need to be publicly accessible
- ❌ Would require complex authentication and security measures
- ❌ Vulnerable to brute force attacks and exploits
- ❌ Requires managing SSL certificates for the admin interface

With Tailscale VPN:
- ✓ Builder Interface is never exposed to the internet
- ✓ Zero-trust security with device authentication
- ✓ End-to-end encryption for all admin traffic
- ✓ Simple access from any device (laptop, phone, tablet)
- ✓ No need for complex authentication systems

---

#### Execution Command

The script requires a Tailscale auth key as a parameter and must be run with root privileges:

```bash
sudo bash /opt/website-builder/infrastructure/scripts/configure-tailscale.sh TAILSCALE_AUTH_KEY
```

**Replace `TAILSCALE_AUTH_KEY` with your actual auth key** obtained from the Tailscale admin console (see Prerequisites section for instructions on obtaining the key).

**Example:**

```bash
sudo bash /opt/website-builder/infrastructure/scripts/configure-tailscale.sh tskey-auth-k1234567890abcdefghijklmnopqrstuvwxyz
```

**Prerequisites:**
- SSH access to the Lightsail instance
- UFW firewall configured (previous step) - port 41641 must be open
- Internet connectivity (to download Tailscale package and connect to Tailscale network)
- Tailscale auth key obtained from https://login.tailscale.com/admin/settings/keys

**Estimated Time:** 2-3 minutes

**⚠️ Important Notes:**

- **Auth Key Security:** The auth key is sensitive. Do not share it or commit it to version control.
- **One-Time Use:** The auth key is used once during setup. After authentication, the server maintains its connection.
- **Reusable Keys:** If you created a reusable auth key, you can use it for multiple servers or re-deployments.
- **Key Expiration:** Auth keys expire after a set period (default 90 days). Ensure your key is valid.

---

#### Expected Output

When you run the script, you should see output similar to this:

```
[INFO] Starting Tailscale VPN configuration...

[INFO] Installing Tailscale...
[INFO] Adding Tailscale repository...
[INFO] Updating package list...
Hit:1 http://us-east-1.ec2.archive.ubuntu.com/ubuntu jammy InRelease
Get:2 http://us-east-1.ec2.archive.ubuntu.com/ubuntu jammy-updates InRelease [119 kB]
Get:3 https://pkgs.tailscale.com/stable/ubuntu jammy InRelease [5,432 B]
...
Reading package lists... Done
[INFO] Installing Tailscale package...
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  tailscale
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 12.3 MB of archives.
After this operation, 35.8 MB of additional disk space will be used.
Get:1 https://pkgs.tailscale.com/stable/ubuntu jammy/main amd64 tailscale amd64 1.56.1 [12.3 MB]
Fetched 12.3 MB in 1s (10.2 MB/s)
Selecting previously unselected package tailscale.
(Reading database ... 123456 files and directories currently installed.)
Preparing to unpack .../tailscale_1.56.1_amd64.deb ...
Unpacking tailscale (1.56.1) ...
Setting up tailscale (1.56.1) ...
Created symlink /etc/systemd/system/multi-user.target.wants/tailscaled.service → /lib/systemd/system/tailscaled.service.
[INFO] Tailscale installed successfully

[INFO] Authenticating with Tailscale...
Success.
[INFO] Tailscale authentication successful

[INFO] Configuring Builder Interface access control...
[INFO] Tailscale IP: 100.101.102.103
[INFO] Builder Interface configured to bind to Tailscale IP only
[INFO] Configuration saved to /opt/website-builder-tailscale.conf

[INFO] Verifying firewall configuration...
[INFO] Firewall configuration verified

[INFO] Tailscale VPN Status:

100.101.102.103  ip-172-26-x-x        linux   -
100.101.102.104  your-laptop          macOS   -
100.101.102.105  your-phone           iOS     -

[INFO] Configuration Summary:
  Tailscale IP: 100.101.102.103
  Builder Interface Port: 3000
  Builder Interface URL: http://100.101.102.103:3000

[INFO] Access Instructions:
  1. Connect to Tailscale VPN on your client device
  2. Access Builder Interface at: http://100.101.102.103:3000
  3. The Builder Interface is NOT accessible from the public internet

[INFO] Configuration file: /opt/website-builder-tailscale.conf

[INFO] Tailscale VPN configuration complete!
[INFO] 
[INFO] Requirements validated:
[INFO]   ✓ Requirement 2.3: Builder Interface accessible only through Tailscale VPN
[INFO]   ✓ Requirement 2.5: System denies access to Builder Interface without Tailscale
```

**Key Indicators of Success:**
- ✓ `Tailscale installed successfully`
- ✓ `Success.` after authentication (indicates successful connection to Tailscale network)
- ✓ `Tailscale IP: 100.x.x.x` (server has been assigned a Tailscale IP address)
- ✓ `Builder Interface configured to bind to Tailscale IP only`
- ✓ `Firewall configuration verified`
- ✓ Tailscale status shows the server and other connected devices
- ✓ No error messages during installation or configuration

**What the Tailscale IP Address Means:**

The Tailscale IP address (e.g., `100.101.102.103`) is a private IP address in the `100.x.x.x` range that is only accessible within your Tailscale network. This IP address:
- Is stable and doesn't change (persists across reboots)
- Is only accessible from devices in your Tailscale network
- Is not routable on the public internet
- Is used to access the Builder Interface securely

---

#### Configuration Files Created

The script creates several configuration files and systemd overrides:

**1. Systemd Service Override:**

Location: `/etc/systemd/system/website-builder.service.d/tailscale-binding.conf`

```ini
[Service]
# Bind Builder Interface only to Tailscale IP
# This ensures the service is only accessible through VPN
Environment="BIND_ADDRESS=100.101.102.103"
Environment="PORT=3000"
```

**Purpose:** This override ensures that when the website-builder service starts (configured in a later step), it will bind only to the Tailscale IP address, making it impossible to access from the public internet.

**2. Tailscale Configuration File:**

Location: `/opt/website-builder-tailscale.conf`

```bash
# Tailscale VPN Configuration for AI Website Builder
# Generated on Mon Jan 15 17:30:00 UTC 2024

TAILSCALE_IP=100.101.102.103
BUILDER_PORT=3000
BUILDER_URL=http://100.101.102.103:3000

# Access Instructions:
# 1. Ensure you are connected to the Tailscale network
# 2. Access the Builder Interface at: http://100.101.102.103:3000
# 3. The Builder Interface is NOT accessible from the public internet
```

**Purpose:** This file serves as a reference for the Tailscale configuration and provides the access URL for the Builder Interface. You can view this file anytime to get the connection details.

**View the configuration file:**
```bash
cat /opt/website-builder-tailscale.conf
```

---

#### Verification Commands

After running the script, verify that Tailscale is configured correctly:

**1. Check Tailscale Service Status:**

```bash
sudo systemctl status tailscaled
```

**Expected Output:**
```
● tailscaled.service - Tailscale node agent
     Loaded: loaded (/lib/systemd/system/tailscaled.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-01-15 17:30:00 UTC; 2min ago
       Docs: https://tailscale.com/
   Main PID: 34567 (tailscaled)
      Tasks: 10 (limit: 1131)
     Memory: 45.2M
        CPU: 1.234s
     CGroup: /system.slice/tailscaled.service
             └─34567 /usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641

Jan 15 17:30:00 ip-172-26-x-x systemd[1]: Started Tailscale node agent.
Jan 15 17:30:01 ip-172-26-x-x tailscaled[34567]: netcheck: [v1] report: udp=true v6=false v6os=true mapvarydest= hair= portmap= v4a=54.123.45.67:41641 derp=1 derpdist=1v4:10ms,2v4:25ms
```

**Key indicators:**
- `Loaded: loaded` - Service file is loaded
- `enabled` - Service will start on boot
- `Active: active (running)` - Tailscale daemon is running
- Port 41641 is shown in the command line (Tailscale's UDP port)

**If the service is not running:**
```bash
# Start Tailscale daemon
sudo systemctl start tailscaled

# Check for errors
sudo journalctl -u tailscaled -n 50
```

---

**2. Check Tailscale Connection Status:**

```bash
tailscale status
```

**Expected Output:**
```
100.101.102.103  ip-172-26-x-x        linux   -
100.101.102.104  your-laptop          macOS   -
100.101.102.105  your-phone           iOS     -
```

This shows:
- The server's Tailscale IP (100.101.102.103)
- The server's hostname (ip-172-26-x-x)
- Other devices connected to your Tailscale network

**If no devices are shown:**
- Ensure you have Tailscale installed on at least one client device
- Verify the client device is connected to the same Tailscale network
- Check the Tailscale admin console: https://login.tailscale.com/admin/machines

---

**3. Get Tailscale IP Address:**

```bash
tailscale ip -4
```

**Expected Output:**
```
100.101.102.103
```

This is the IP address you'll use to access the Builder Interface.

**Save this IP address** - you'll need it to access the Builder Interface after the application is deployed.

---

**4. Verify Tailscale Network Connectivity:**

From your local machine (with Tailscale installed and connected), test connectivity to the server:

```bash
# Ping the server's Tailscale IP
ping 100.101.102.103

# Expected output: replies from 100.101.102.103
```

**Expected Output:**
```
PING 100.101.102.103 (100.101.102.103): 56 data bytes
64 bytes from 100.101.102.103: icmp_seq=0 ttl=64 time=15.2 ms
64 bytes from 100.101.102.103: icmp_seq=1 ttl=64 time=14.8 ms
64 bytes from 100.101.102.103: icmp_seq=2 ttl=64 time=15.1 ms
```

**If ping fails:**
- Ensure Tailscale is running on your local machine: `tailscale status`
- Verify both devices are in the same Tailscale network
- Check the Tailscale admin console for connection status
- Ensure your local firewall allows Tailscale traffic

---

**5. Verify Firewall Configuration:**

Confirm that port 3000 is NOT exposed to the public internet:

```bash
# Check UFW rules
sudo ufw status | grep 3000
```

**Expected Output:**
```
(no output - port 3000 should NOT be in the firewall rules)
```

**This is correct!** Port 3000 should not be allowed through the firewall. It's only accessible via Tailscale VPN.

**If port 3000 is allowed (SECURITY ISSUE):**
```bash
# Remove the rule immediately
sudo ufw delete allow 3000

# Verify it's removed
sudo ufw status | grep 3000
```

---

**6. Verify Tailscale Port is Open:**

Confirm that Tailscale's UDP port (41641) is allowed:

```bash
sudo ufw status | grep 41641
```

**Expected Output:**
```
41641/udp                  ALLOW IN    Anywhere                   # Tailscale VPN
41641/udp (v6)             ALLOW IN    Anywhere (v6)              # Tailscale VPN
```

**If port 41641 is not allowed:**
```bash
# Add the rule
sudo ufw allow 41641/udp comment 'Tailscale VPN'

# Verify
sudo ufw status | grep 41641
```

---

**7. View Tailscale Configuration File:**

```bash
cat /opt/website-builder-tailscale.conf
```

**Expected Output:**
```
# Tailscale VPN Configuration for AI Website Builder
# Generated on Mon Jan 15 17:30:00 UTC 2024

TAILSCALE_IP=100.101.102.103
BUILDER_PORT=3000
BUILDER_URL=http://100.101.102.103:3000

# Access Instructions:
# 1. Ensure you are connected to the Tailscale network
# 2. Access the Builder Interface at: http://100.101.102.103:3000
# 3. The Builder Interface is NOT accessible from the public internet
```

This file contains the access URL and configuration details for future reference.

---

**8. Test VPN Access (After Application Deployment):**

**Note:** This test will only work after you complete the Application Deployment phase (Phase 5). For now, just verify the Tailscale connection is working.

After the application is deployed, test access from your local machine (with Tailscale connected):

```bash
# From your local machine with Tailscale connected
curl -I http://100.101.102.103:3000/
```

**Expected Output (after application deployment):**
```
HTTP/1.1 200 OK
Content-Type: text/html
...
```

**If you get "Connection refused" now:**
- This is expected - the application hasn't been deployed yet
- The test will work after completing the Application Deployment phase

---

#### Troubleshooting Tailscale Configuration

If you encounter issues with Tailscale configuration, use these troubleshooting steps:

**Issue 1: Authentication Failed**

**Symptom:**
```
Error: authentication failed
```

**Possible Causes and Solutions:**

**A. Invalid or expired auth key:**
```bash
# Generate a new auth key at: https://login.tailscale.com/admin/settings/keys
# Ensure the key is:
#   - Not expired
#   - Reusable (if you plan to use it multiple times)
#   - Preauthorized (for automatic approval)

# Re-run the script with the new key
sudo bash /opt/website-builder/infrastructure/scripts/configure-tailscale.sh tskey-auth-NEW_KEY
```

**B. Network connectivity issues:**
```bash
# Test internet connectivity
ping -c 3 8.8.8.8

# Test DNS resolution
nslookup login.tailscale.com

# If DNS fails, check /etc/resolv.conf
cat /etc/resolv.conf
```

**C. Firewall blocking Tailscale:**
```bash
# Ensure port 41641 is open
sudo ufw allow 41641/udp

# Restart Tailscale
sudo systemctl restart tailscaled

# Try authentication again
sudo tailscale up --authkey=YOUR_AUTH_KEY
```

---

**Issue 2: Cannot Get Tailscale IP Address**

**Symptom:**
```
[ERROR] Failed to get Tailscale IP address
```

**Diagnosis:**
```bash
# Check Tailscale status
tailscale status

# Check if Tailscale is connected
tailscale ip -4
```

**Solutions:**

**A. Tailscale not authenticated:**
```bash
# Check authentication status
tailscale status

# If not authenticated, run:
sudo tailscale up --authkey=YOUR_AUTH_KEY
```

**B. Tailscale daemon not running:**
```bash
# Check service status
sudo systemctl status tailscaled

# Start the service
sudo systemctl start tailscaled

# Enable for boot
sudo systemctl enable tailscaled
```

**C. Network configuration issues:**
```bash
# Check Tailscale logs
sudo journalctl -u tailscaled -n 100

# Look for errors related to network configuration or connectivity
```

---

**Issue 3: Cannot Connect to Server from Client Device**

**Symptom:**
Cannot ping or access the server's Tailscale IP from your local machine.

**Diagnosis:**
```bash
# On the server, check Tailscale status
tailscale status

# On your local machine, check Tailscale status
tailscale status

# Try pinging the server from your local machine
ping 100.101.102.103
```

**Solutions:**

**A. Client device not connected to Tailscale:**
```bash
# On your local machine, check if Tailscale is running
tailscale status

# If not connected, start Tailscale
# macOS/Linux:
sudo tailscale up

# Windows: Start Tailscale from the system tray
```

**B. Devices in different Tailscale networks:**
- Verify both devices are logged into the same Tailscale account
- Check the Tailscale admin console: https://login.tailscale.com/admin/machines
- Ensure both devices appear in the same network

**C. Tailscale ACLs blocking access:**
- Check your Tailscale Access Control Lists (ACLs)
- Visit: https://login.tailscale.com/admin/acls
- Ensure there are no rules blocking access between devices
- Default ACL allows all devices to communicate

**D. Local firewall on client device:**
- Ensure your local firewall allows Tailscale traffic
- macOS: System Preferences → Security & Privacy → Firewall → Allow Tailscale
- Windows: Windows Defender Firewall → Allow an app → Tailscale
- Linux: `sudo ufw allow in on tailscale0`

---

**Issue 4: Port 3000 is Publicly Accessible (SECURITY ISSUE)**

**Symptom:**
Can access port 3000 from the public internet without Tailscale VPN.

**Diagnosis:**
```bash
# From a machine NOT connected to Tailscale, try:
curl -I http://YOUR_PUBLIC_IP:3000/ --connect-timeout 5

# This should FAIL (connection timeout or refused)
```

**If it succeeds (CRITICAL SECURITY ISSUE):**

**A. Check UFW rules:**
```bash
# Port 3000 should NOT be in the firewall rules
sudo ufw status | grep 3000

# If it's there, remove it immediately
sudo ufw delete allow 3000
```

**B. Check application binding:**
```bash
# After application deployment, verify it's bound to Tailscale IP only
sudo netstat -tlnp | grep 3000

# Should show: 100.x.x.x:3000 (Tailscale IP), NOT 0.0.0.0:3000 (all interfaces)
```

**C. Check Lightsail firewall:**
```bash
# Verify port 3000 is not open in Lightsail
aws lightsail get-instance-port-states --instance-name ai-website-builder | grep 3000

# If it's open, close it:
aws lightsail close-instance-public-ports \
  --instance-name ai-website-builder \
  --port-info fromPort=3000,toPort=3000,protocol=tcp
```

---

**Issue 5: Tailscale Service Not Starting on Boot**

**Symptom:**
After reboot, Tailscale is not running.

**Diagnosis:**
```bash
# Check if service is enabled
sudo systemctl is-enabled tailscaled
```

**Solution:**
```bash
# Enable Tailscale to start on boot
sudo systemctl enable tailscaled

# Verify
sudo systemctl is-enabled tailscaled
# Should output: enabled

# Start the service now
sudo systemctl start tailscaled

# Check status
sudo systemctl status tailscaled
```

---

**Issue 6: Slow VPN Connection**

**Symptom:**
Accessing the Builder Interface through Tailscale is slow.

**Diagnosis:**
```bash
# Check Tailscale connection details
tailscale status --json | grep -A 5 "CurAddr"

# Check for DERP relay usage (slower than direct connection)
tailscale netcheck
```

**Common Causes:**

**A. Using DERP relay instead of direct connection:**
- Tailscale prefers direct peer-to-peer connections
- If direct connection fails, it uses DERP relay servers (slower)
- Check if your network/firewall is blocking UDP traffic

**B. Network latency:**
```bash
# Test latency to the server
ping 100.101.102.103

# Check for high latency or packet loss
```

**Solutions:**

**A. Enable direct connections:**
- Ensure UDP port 41641 is open on both client and server
- Check if your router supports UPnP or NAT-PMP
- Configure port forwarding if needed

**B. Use Tailscale's MagicDNS:**
```bash
# Enable MagicDNS in Tailscale admin console
# Visit: https://login.tailscale.com/admin/dns
# Enable "MagicDNS"

# Access server by hostname instead of IP
# e.g., http://ip-172-26-x-x:3000/
```

---

**Issue 7: Lost Tailscale Configuration After Reboot**

**Symptom:**
Tailscale IP address changed or connection lost after server reboot.

**Diagnosis:**
```bash
# Check Tailscale status
tailscale status

# Check if IP address changed
tailscale ip -4
```

**Solutions:**

**A. Tailscale state not persisted:**
```bash
# Check if state file exists
ls -l /var/lib/tailscale/tailscaled.state

# If missing, re-authenticate
sudo tailscale up --authkey=YOUR_AUTH_KEY
```

**B. Ephemeral auth key used:**
- If you used an ephemeral auth key, the device is removed when it goes offline
- Use a non-ephemeral, reusable auth key for servers
- Generate a new key at: https://login.tailscale.com/admin/settings/keys
- Ensure "Ephemeral" is NOT checked

**C. Re-run configuration script:**
```bash
# If configuration is lost, re-run the script
sudo bash /opt/website-builder/infrastructure/scripts/configure-tailscale.sh YOUR_AUTH_KEY
```

---

#### Tailscale Admin Console

The Tailscale admin console provides a web interface for managing your Tailscale network:

**Access:** https://login.tailscale.com/admin

**Key Features:**

**1. Machines:**
- View all devices connected to your Tailscale network
- See connection status (online/offline)
- View Tailscale IP addresses
- Disable or remove devices
- View device details (OS, last seen, etc.)

**2. DNS:**
- Enable MagicDNS for hostname-based access
- Configure custom DNS servers
- Set up DNS search domains

**3. Access Controls (ACLs):**
- Define which devices can communicate with each other
- Create groups and tags for organization
- Set up fine-grained access policies

**4. Settings:**
- Generate and manage auth keys
- Configure key expiration
- Enable/disable features (SSH, MagicDNS, etc.)

**5. Activity:**
- View connection logs
- Monitor network activity
- Audit device connections

**Recommended Settings for AI Website Builder:**

1. **Enable MagicDNS:**
   - Go to DNS settings
   - Enable "MagicDNS"
   - Access server by hostname: `http://ip-172-26-x-x:3000/`

2. **Create a Tag for the Server:**
   - Go to Access Controls
   - Add a tag: `tag:webserver`
   - Apply the tag to your server in the Machines list

3. **Set Up ACLs (Optional):**
   - Restrict access to port 3000 to specific devices or users
   - Example ACL:
     ```json
     {
       "acls": [
         {
           "action": "accept",
           "src": ["autogroup:members"],
           "dst": ["tag:webserver:3000"]
         }
       ]
     }
     ```

---

#### What Happens Next

After successfully configuring Tailscale VPN, your server is now part of a secure private network:

**Current State:**
- ✓ NGINX installed and running
- ✓ UFW firewall configured and active
- ✓ Tailscale VPN installed and connected
- ✓ Server has a Tailscale IP address (100.x.x.x)
- ✓ Builder Interface configured to bind to Tailscale IP only
- ✓ Port 3000 is NOT publicly accessible (protected by firewall)
- ✗ SSL certificates not configured yet (will be configured next)
- ✗ Application not deployed yet (will be deployed in Phase 5)

**Security Posture:**

Your deployment now has strong security:
1. **Firewall Protection:** UFW blocks all unnecessary ports
2. **VPN-Only Admin Access:** Builder Interface is only accessible through Tailscale
3. **Zero-Trust Network:** Tailscale provides device authentication and encryption
4. **No Public Exposure:** Admin interface is never exposed to the internet

**Next Steps:**

1. **Configure SSL Certificates** (Section 5.5) - Install Let's Encrypt certificates for HTTPS
2. **Configure Systemd Service** (Section 5.6) - Create service for the application
3. **Deploy Application** (Phase 5) - Deploy the Node.js application and start the Builder Interface

**Important Notes:**

- **Save the Tailscale IP:** You'll need it to access the Builder Interface after deployment
- **Install Tailscale on Client Devices:** Install Tailscale on your laptop, phone, or tablet to access the Builder Interface
- **Test VPN Connection:** After application deployment, test accessing the Builder Interface via Tailscale

**Access URL (after application deployment):**
```
http://YOUR_TAILSCALE_IP:3000/
```

Replace `YOUR_TAILSCALE_IP` with the IP address shown in the configuration output (e.g., `100.101.102.103`).

---

**Verification Checklist:**

Before proceeding to the next configuration step, ensure:

- [ ] Tailscale service is active and running (`sudo systemctl status tailscaled`)
- [ ] Tailscale is authenticated and connected (`tailscale status`)
- [ ] Server has a Tailscale IP address (`tailscale ip -4`)
- [ ] Can ping server's Tailscale IP from local machine (with Tailscale connected)
- [ ] Port 41641 (Tailscale) is allowed in UFW (`sudo ufw status | grep 41641`)
- [ ] Port 3000 is NOT allowed in UFW (`sudo ufw status | grep 3000` returns nothing)
- [ ] Configuration file exists (`cat /opt/website-builder-tailscale.conf`)
- [ ] Systemd override created (`ls /etc/systemd/system/website-builder.service.d/`)
- [ ] Server appears in Tailscale admin console (https://login.tailscale.com/admin/machines)
- [ ] Tailscale service is enabled for boot (`sudo systemctl is-enabled tailscaled`)

Once all checks pass, you're ready to proceed to SSL certificate configuration.

---

### 5.5 SSL Certificate Configuration

This section guides you through configuring SSL/TLS certificates using Let's Encrypt to enable HTTPS for your public website. The `configure-ssl.sh` script automates certificate acquisition, NGINX SSL configuration, and sets up automatic renewal with monitoring.

**Purpose:**
- Obtain free SSL/TLS certificates from Let's Encrypt for your domain
- Configure NGINX to serve content over HTTPS (port 443)
- Set up automatic HTTP to HTTPS redirects
- Configure automatic certificate renewal with retry logic
- Implement certificate expiration monitoring

**Prerequisites:**
- NGINX must be installed and running (Section 5.2 completed)
- UFW firewall must allow ports 80 and 443 (Section 5.3 completed)
- DNS A records must be configured and propagated (Phase 3 completed)
- Your domain must resolve to the Lightsail instance IP address

**CRITICAL:** This script requires valid DNS records pointing to your server. Let's Encrypt validates domain ownership by making HTTP requests to your domain. If DNS is not properly configured or hasn't propagated, certificate acquisition will fail.

---

#### Execute SSL Configuration Script

SSH into your Lightsail instance and run the SSL configuration script with required environment variables:

```bash
sudo DOMAIN=yourdomain.com SSL_EMAIL=admin@yourdomain.com /opt/ai-website-builder/infrastructure/scripts/configure-ssl.sh
```

**Replace the following values:**
- `yourdomain.com` - Your actual domain name (e.g., `example.com`, `mysite.io`)
- `admin@yourdomain.com` - Your email address for SSL certificate notifications

**Parameter Details:**

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `DOMAIN` | Yes | Your registered domain name. Must match DNS A records. | `example.com` |
| `SSL_EMAIL` | Yes | Email for Let's Encrypt notifications and renewal alerts. | `admin@example.com` |

**Important Notes:**
- Use your root domain (e.g., `example.com`), not `www.example.com`
- The email address will receive certificate expiration warnings (though renewal is automatic)
- Let's Encrypt may send important security notifications to this address
- Use a valid, monitored email address

---

#### Expected Output

The script will perform the following actions and display progress:

```
=== Let's Encrypt SSL Automation Setup ===

Domain: example.com
Email: admin@example.com

Creating log directory...
Installing certbot...
✓ Certbot installed
Checking NGINX status...
✓ NGINX is running
Obtaining SSL certificate from Let's Encrypt...
✓ SSL certificate obtained successfully
Updating NGINX configuration for SSL...
✓ NGINX configuration is valid
✓ NGINX reloaded
Creating renewal script with retry logic...
✓ Renewal script created
Creating certificate monitoring script...
✓ Monitoring script created
Setting up cron jobs...
✓ Cron jobs configured
Running initial certificate check...
[2024-01-15 10:30:00] Certificate expires in 90 days (on Apr 15 12:30:00 2024 GMT)
[2024-01-15 10:30:00] OK: Certificate is valid for 90 more days

=== SSL Automation Setup Complete ===

Configuration Summary:
  Domain: example.com
  Email: admin@example.com
  Certificate: /etc/letsencrypt/live/example.com/
  Renewal Script: /usr/local/bin/ssl-renewal-with-retry.sh
  Monitor Script: /usr/local/bin/ssl-monitor.sh
  Logs: /var/log/ssl-automation/

Automatic Tasks:
  - Certificate expiration check: Daily at 3 AM
  - Renewal attempts: Twice daily at 2 AM and 2 PM
  - Renewal threshold: 30 days before expiration
  - Retry logic: Up to 5 attempts with exponential backoff

Manual Commands:
  - Check certificate: openssl x509 -enddate -noout -in /etc/letsencrypt/live/example.com/cert.pem
  - Force renewal: certbot renew --force-renewal
  - Test renewal: certbot renew --dry-run
  - View logs: tail -f /var/log/ssl-automation/renewal.log

✓ Task 1.5 Complete
```

**What the Script Does:**

1. **Validates Parameters:** Ensures DOMAIN and SSL_EMAIL are provided
2. **Installs Certbot:** Installs Let's Encrypt client and NGINX plugin
3. **Checks NGINX:** Verifies NGINX is running (required for certificate validation)
4. **Obtains Certificate:** Requests SSL certificate from Let's Encrypt using HTTP-01 challenge
5. **Updates NGINX Configuration:** Configures NGINX to use SSL certificates and redirect HTTP to HTTPS
6. **Creates Renewal Script:** Sets up automatic renewal with exponential backoff retry logic
7. **Creates Monitoring Script:** Implements certificate expiration monitoring
8. **Configures Cron Jobs:** Schedules automatic renewal attempts and expiration checks
9. **Runs Initial Check:** Verifies certificate is valid and displays expiration date

---

#### Let's Encrypt Certificate Acquisition Process

Let's Encrypt uses the ACME protocol to verify domain ownership and issue certificates. The script uses the **HTTP-01 challenge** method:

**How It Works:**

1. **Certificate Request:** Certbot sends a certificate request to Let's Encrypt for your domain
2. **Challenge Issued:** Let's Encrypt responds with a unique challenge token
3. **Challenge File Created:** Certbot creates a file at `http://yourdomain.com/.well-known/acme-challenge/[token]`
4. **Domain Validation:** Let's Encrypt makes an HTTP request to verify the challenge file
5. **Certificate Issued:** If validation succeeds, Let's Encrypt issues the certificate
6. **Certificate Installed:** Certbot saves the certificate files to `/etc/letsencrypt/live/yourdomain.com/`

**Certificate Files Created:**

```
/etc/letsencrypt/live/yourdomain.com/
├── cert.pem          # Server certificate
├── chain.pem         # Intermediate certificates
├── fullchain.pem     # cert.pem + chain.pem (used by NGINX)
├── privkey.pem       # Private key (keep secure!)
└── README            # Information about the certificate
```

**Certificate Validity:**
- Let's Encrypt certificates are valid for **90 days**
- Automatic renewal is configured to run **twice daily**
- Renewal attempts start **30 days before expiration**
- Certificates are renewed automatically without manual intervention

**Rate Limits:**
- Let's Encrypt has rate limits to prevent abuse
- **50 certificates per registered domain per week**
- **5 failed validation attempts per account per hostname per hour**
- If you hit rate limits, you must wait before retrying
- See: https://letsencrypt.org/docs/rate-limits/

---

#### NGINX SSL Configuration

The script updates NGINX to serve content over HTTPS with security best practices:

**HTTP Server (Port 80):**
- Allows Let's Encrypt challenge requests (`/.well-known/acme-challenge/`)
- Redirects all other traffic to HTTPS (301 permanent redirect)

**HTTPS Server (Port 443):**
- Serves content over SSL/TLS with HTTP/2 support
- Uses Let's Encrypt certificates
- Implements modern TLS protocols (TLSv1.2 and TLSv1.3)
- Configures secure cipher suites
- Enables SSL session caching for performance
- Implements OCSP stapling for certificate validation
- Adds security headers (HSTS, X-Frame-Options, etc.)
- Enables gzip compression for text content
- Configures caching for static assets

**Security Headers Added:**
- `Strict-Transport-Security`: Forces HTTPS for 1 year
- `X-Frame-Options`: Prevents clickjacking attacks
- `X-Content-Type-Options`: Prevents MIME type sniffing
- `X-XSS-Protection`: Enables browser XSS protection

**Configuration File:**
- Location: `/etc/nginx/sites-available/default`
- Backup created before modification: `/etc/nginx/sites-available/default.backup-[timestamp]`
- Automatically reloaded after successful configuration test

---

#### Automatic Renewal Configuration

The script sets up a robust automatic renewal system with retry logic and monitoring:

**Renewal Script:** `/usr/local/bin/ssl-renewal-with-retry.sh`
- Attempts certificate renewal using `certbot renew`
- Implements exponential backoff retry logic (up to 5 attempts)
- Initial retry delay: 60 seconds, doubles with each attempt
- Reloads NGINX after successful renewal
- Logs all renewal attempts to `/var/log/ssl-automation/renewal.log`

**Monitoring Script:** `/usr/local/bin/ssl-monitor.sh`
- Checks certificate expiration date daily
- Triggers renewal if certificate expires within 30 days
- Logs certificate status to `/var/log/ssl-automation/monitor.log`
- Alerts if renewal fails (check logs for details)

**Cron Jobs:** `/etc/cron.d/ssl-automation`
- **Daily at 3 AM:** Certificate expiration check
- **Twice daily at 2 AM and 2 PM:** Renewal attempts (only renews if needed)

**Why Twice Daily Renewal Attempts?**
- Certbot only renews certificates within 30 days of expiration
- Multiple daily attempts ensure renewal succeeds even if one attempt fails
- Provides redundancy in case of temporary network issues
- Let's Encrypt recommends running renewal checks at least once per day

**Retry Logic:**
- If renewal fails, the script retries up to 5 times
- Exponential backoff: 1 min, 2 min, 4 min, 8 min, 16 min
- Total retry window: ~31 minutes
- Handles temporary network issues or Let's Encrypt API downtime

---

#### Verification Commands

After running the SSL configuration script, verify that SSL certificates are installed and HTTPS is working correctly.

**1. Check Certificate Files Exist:**

```bash
sudo ls -la /etc/letsencrypt/live/yourdomain.com/
```

**Expected Output:**
```
total 12
drwxr-xr-x 2 root root 4096 Jan 15 10:30 .
drwx------ 3 root root 4096 Jan 15 10:30 ..
lrwxrwxrwx 1 root root   37 Jan 15 10:30 cert.pem -> ../../archive/yourdomain.com/cert1.pem
lrwxrwxrwx 1 root root   38 Jan 15 10:30 chain.pem -> ../../archive/yourdomain.com/chain1.pem
lrwxrwxrwx 1 root root   42 Jan 15 10:30 fullchain.pem -> ../../archive/yourdomain.com/fullchain1.pem
lrwxrwxrwx 1 root root   40 Jan 15 10:30 privkey.pem -> ../../archive/yourdomain.com/privkey1.pem
-rw-r--r-- 1 root root  692 Jan 15 10:30 README
```

**If verification fails:** Certificate files are missing. Check the script output for errors during certificate acquisition.

---

**2. Check Certificate Expiration Date:**

```bash
sudo openssl x509 -enddate -noout -in /etc/letsencrypt/live/yourdomain.com/cert.pem
```

**Expected Output:**
```
notAfter=Apr 15 12:30:00 2024 GMT
```

This shows the certificate expiration date (90 days from issuance).

---

**3. Check Certificate Details:**

```bash
sudo openssl x509 -text -noout -in /etc/letsencrypt/live/yourdomain.com/cert.pem | grep -A2 "Subject:"
```

**Expected Output:**
```
Subject: CN = yourdomain.com
Subject Public Key Info:
    Public Key Algorithm: rsaEncryption
```

Verify the CN (Common Name) matches your domain.

---

**4. Test HTTPS Connection:**

```bash
curl -I https://yourdomain.com
```

**Expected Output:**
```
HTTP/2 200
server: nginx
date: Mon, 15 Jan 2024 10:35:00 GMT
content-type: text/html
content-length: 615
last-modified: Mon, 15 Jan 2024 09:00:00 GMT
etag: "659a1234-267"
strict-transport-security: max-age=31536000; includeSubDomains
x-frame-options: SAMEORIGIN
x-content-type-options: nosniff
x-xss-protection: 1; mode=block
accept-ranges: bytes
```

**Key indicators of success:**
- `HTTP/2 200` - HTTPS is working with HTTP/2
- `strict-transport-security` header is present
- Security headers are included

**If verification fails:**
- Check NGINX error logs: `sudo tail -f /var/log/nginx/error.log`
- Verify DNS is resolving correctly: `dig yourdomain.com`
- Ensure firewall allows port 443: `sudo ufw status | grep 443`

---

**5. Test HTTP to HTTPS Redirect:**

```bash
curl -I http://yourdomain.com
```

**Expected Output:**
```
HTTP/1.1 301 Moved Permanently
server: nginx
date: Mon, 15 Jan 2024 10:35:00 GMT
content-type: text/html
content-length: 169
location: https://yourdomain.com/
connection: keep-alive
```

**Key indicators:**
- `301 Moved Permanently` - Permanent redirect
- `location: https://yourdomain.com/` - Redirects to HTTPS

This confirms HTTP traffic is automatically redirected to HTTPS.

---

**6. Test SSL Certificate in Browser:**

Open your domain in a web browser:
```
https://yourdomain.com
```

**Expected Result:**
- Browser shows a padlock icon (🔒) in the address bar
- No security warnings or errors
- Certificate is valid and trusted
- Certificate is issued by "Let's Encrypt Authority"

**To view certificate details in browser:**
- **Chrome/Edge:** Click the padlock → "Connection is secure" → Certificate icon
- **Firefox:** Click the padlock → "Connection secure" → "More information" → "View Certificate"
- **Safari:** Click the padlock → "Show Certificate"

**Certificate should show:**
- Issued to: yourdomain.com
- Issued by: Let's Encrypt Authority X3 (or similar)
- Valid from: [today's date]
- Valid until: [90 days from today]

---

**7. Verify NGINX SSL Configuration:**

```bash
sudo nginx -t
```

**Expected Output:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

---

**8. Check NGINX is Using SSL:**

```bash
sudo netstat -tlnp | grep nginx
```

**Expected Output:**
```
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      1234/nginx: master
tcp        0      0 0.0.0.0:443             0.0.0.0:*               LISTEN      1234/nginx: master
tcp6       0      0 :::80                   :::*                    LISTEN      1234/nginx: master
tcp6       0      0 :::443                  :::*                    LISTEN      1234/nginx: master
```

NGINX should be listening on both port 80 (HTTP) and port 443 (HTTPS).

---

**9. Verify Cron Jobs are Configured:**

```bash
sudo cat /etc/cron.d/ssl-automation
```

**Expected Output:**
```
# SSL Certificate Automation Cron Jobs
# Requirements: 3.2, 3.5

# Set environment variables
DOMAIN=yourdomain.com
SSL_EMAIL=admin@yourdomain.com
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Check certificate expiration daily at 3 AM
0 3 * * * root /usr/local/bin/ssl-monitor.sh >> /var/log/ssl-automation/monitor.log 2>&1

# Attempt renewal twice daily (certbot will only renew if needed)
0 2,14 * * * root /usr/local/bin/ssl-renewal-with-retry.sh >> /var/log/ssl-automation/renewal.log 2>&1
```

---

**10. Test Automatic Renewal (Dry Run):**

```bash
sudo certbot renew --dry-run
```

**Expected Output:**
```
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/yourdomain.com.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Cert not yet due for renewal

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The following simulated renewals succeeded:
  /etc/letsencrypt/live/yourdomain.com/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

This confirms automatic renewal will work when the certificate approaches expiration.

---

**11. Check Renewal Logs:**

```bash
sudo tail -20 /var/log/ssl-automation/renewal.log
```

**Expected Output:**
```
[2024-01-15 10:30:00] Starting certificate renewal process
[2024-01-15 10:30:00] Renewal attempt 1 of 5
[2024-01-15 10:30:05] SUCCESS: Certificate renewed successfully
[2024-01-15 10:30:05] SUCCESS: NGINX reloaded with new certificate
[2024-01-15 10:30:05] Renewal process completed with exit code: 0
```

---

**12. Check Monitoring Logs:**

```bash
sudo tail -20 /var/log/ssl-automation/monitor.log
```

**Expected Output:**
```
[2024-01-15 10:30:00] Certificate expires in 90 days (on Apr 15 12:30:00 2024 GMT)
[2024-01-15 10:30:00] OK: Certificate is valid for 90 more days
```

---

#### Troubleshooting SSL Configuration Issues

**Issue: Certificate Acquisition Fails with "DNS Problem"**

**Symptom:**
```
Failed to obtain SSL certificate
Error: DNS problem: NXDOMAIN looking up A for yourdomain.com
```

**Root Cause:** DNS records are not configured or haven't propagated to Let's Encrypt's servers.

**Solution:**
1. Verify DNS A records are configured correctly (see Phase 3)
2. Check DNS resolution: `dig yourdomain.com`
3. Wait for DNS propagation (up to 30 minutes)
4. Use online DNS checkers to verify global propagation
5. Retry the SSL configuration script after DNS propagates

---

**Issue: Certificate Acquisition Fails with "Connection Refused"**

**Symptom:**
```
Failed to obtain SSL certificate
Error: Connection refused
```

**Root Cause:** NGINX is not running or port 80 is blocked.

**Solution:**
1. Check NGINX status: `sudo systemctl status nginx`
2. Start NGINX if stopped: `sudo systemctl start nginx`
3. Verify port 80 is open: `sudo ufw status | grep 80`
4. Check NGINX is listening on port 80: `sudo netstat -tlnp | grep :80`
5. Retry the SSL configuration script

---

**Issue: Certificate Acquisition Fails with "Rate Limit Exceeded"**

**Symptom:**
```
Failed to obtain SSL certificate
Error: too many certificates already issued for exact set of domains
```

**Root Cause:** You've hit Let's Encrypt's rate limit (50 certificates per domain per week).

**Solution:**
1. Wait for the rate limit window to reset (1 week)
2. Use the staging environment for testing: `certbot certonly --staging ...`
3. Avoid repeated failed attempts (each attempt counts toward the limit)
4. See rate limits: https://letsencrypt.org/docs/rate-limits/

---

**Issue: NGINX Configuration Test Fails**

**Symptom:**
```
nginx: [emerg] cannot load certificate "/etc/letsencrypt/live/yourdomain.com/fullchain.pem"
nginx: configuration file /etc/nginx/nginx.conf test failed
```

**Root Cause:** Certificate files don't exist or have incorrect permissions.

**Solution:**
1. Check certificate files exist: `sudo ls -la /etc/letsencrypt/live/yourdomain.com/`
2. Verify certificate permissions: `sudo ls -l /etc/letsencrypt/archive/yourdomain.com/`
3. Restore NGINX backup if needed: `sudo cp /etc/nginx/sites-available/default.backup-* /etc/nginx/sites-available/default`
4. Re-run the SSL configuration script

---

**Issue: Browser Shows "Certificate Not Trusted" Warning**

**Symptom:** Browser displays security warning when accessing `https://yourdomain.com`

**Root Cause:** Certificate chain is incomplete or browser cache is stale.

**Solution:**
1. Verify fullchain.pem is used in NGINX config (not just cert.pem)
2. Check NGINX configuration: `sudo grep ssl_certificate /etc/nginx/sites-available/default`
3. Reload NGINX: `sudo systemctl reload nginx`
4. Clear browser cache and retry
5. Test in incognito/private browsing mode
6. Verify certificate chain: `openssl s_client -connect yourdomain.com:443 -showcerts`

---

**Issue: Automatic Renewal Fails**

**Symptom:** Renewal logs show repeated failures

**Root Cause:** Network issues, DNS changes, or Let's Encrypt API downtime.

**Solution:**
1. Check renewal logs: `sudo tail -50 /var/log/ssl-automation/renewal.log`
2. Test renewal manually: `sudo certbot renew --dry-run`
3. Verify DNS still resolves correctly: `dig yourdomain.com`
4. Check NGINX is running: `sudo systemctl status nginx`
5. Verify port 80 is accessible: `curl -I http://yourdomain.com/.well-known/acme-challenge/test`
6. The retry logic will automatically retry up to 5 times
7. If all retries fail, check logs and manually run: `sudo /usr/local/bin/ssl-renewal-with-retry.sh`

---

**Issue: Certificate Expires Despite Automatic Renewal**

**Symptom:** Certificate expires and website shows security warning

**Root Cause:** Cron jobs not running or renewal script failing silently.

**Solution:**
1. Check cron service is running: `sudo systemctl status cron`
2. Verify cron jobs exist: `sudo cat /etc/cron.d/ssl-automation`
3. Check renewal logs for errors: `sudo tail -100 /var/log/ssl-automation/renewal.log`
4. Manually force renewal: `sudo certbot renew --force-renewal`
5. Reload NGINX: `sudo systemctl reload nginx`
6. Monitor logs for future renewal attempts

---

#### Manual Certificate Management Commands

While automatic renewal is configured, you may occasionally need to manage certificates manually:

**Force Certificate Renewal:**
```bash
sudo certbot renew --force-renewal
sudo systemctl reload nginx
```

**Test Renewal Without Actually Renewing:**
```bash
sudo certbot renew --dry-run
```

**View All Certificates:**
```bash
sudo certbot certificates
```

**Revoke a Certificate:**
```bash
sudo certbot revoke --cert-path /etc/letsencrypt/live/yourdomain.com/cert.pem
```

**Delete a Certificate:**
```bash
sudo certbot delete --cert-name yourdomain.com
```

**View Certbot Logs:**
```bash
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

**View Renewal Logs:**
```bash
sudo tail -f /var/log/ssl-automation/renewal.log
```

**View Monitoring Logs:**
```bash
sudo tail -f /var/log/ssl-automation/monitor.log
```

**Manually Run Renewal Script:**
```bash
sudo /usr/local/bin/ssl-renewal-with-retry.sh
```

**Manually Run Monitoring Script:**
```bash
sudo DOMAIN=yourdomain.com /usr/local/bin/ssl-monitor.sh
```

---

#### Security Considerations

**Certificate Private Key Security:**
- Private key is stored at `/etc/letsencrypt/live/yourdomain.com/privkey.pem`
- File permissions are restricted to root only (600)
- Never share or expose the private key
- If compromised, revoke the certificate immediately and request a new one

**HTTPS Best Practices:**
- The configuration uses modern TLS protocols (TLSv1.2 and TLSv1.3)
- Weak ciphers are disabled
- HSTS header forces HTTPS for 1 year (browsers will remember)
- Security headers protect against common web vulnerabilities

**Certificate Monitoring:**
- Monitor renewal logs regularly: `sudo tail -f /var/log/ssl-automation/renewal.log`
- Set up email alerts for renewal failures (optional, requires mail configuration)
- Check certificate expiration periodically: `sudo openssl x509 -enddate -noout -in /etc/letsencrypt/live/yourdomain.com/cert.pem`

**Backup Considerations:**
- Certificate files are stored in `/etc/letsencrypt/`
- Backup this directory if you need to restore certificates
- Certificates can be re-issued if lost (no backup required, but causes downtime)

---

#### Next Steps

**After SSL Configuration:**

1. **Configure Systemd Service** (Section 5.6) - Create service for the application
2. **Deploy Application** (Phase 5) - Deploy the Node.js application and start the Builder Interface
3. **Verify HTTPS Access** (Phase 6) - Test public website access over HTTPS

**Important Notes:**

- **HTTPS is now enabled:** Your public website will be accessible at `https://yourdomain.com`
- **HTTP redirects to HTTPS:** All HTTP traffic is automatically redirected to HTTPS
- **Automatic renewal is configured:** Certificates will renew automatically 30 days before expiration
- **Monitor renewal logs:** Check logs periodically to ensure renewal is working

**Access URLs (after application deployment):**
- **Public Website:** `https://yourdomain.com` (HTTPS enabled)
- **Builder Interface:** `http://[tailscale-ip]:3000` (via Tailscale VPN, HTTP only)

**Note:** The Builder Interface uses HTTP (not HTTPS) because it's only accessible via Tailscale VPN, which provides encryption at the network layer. The public website uses HTTPS for secure public access.

---

**Verification Checklist:**

Before proceeding to the next configuration step, ensure:

- [ ] SSL certificate files exist (`sudo ls /etc/letsencrypt/live/yourdomain.com/`)
- [ ] Certificate is valid for 90 days (`sudo openssl x509 -enddate -noout -in /etc/letsencrypt/live/yourdomain.com/cert.pem`)
- [ ] HTTPS works in browser (`https://yourdomain.com` shows padlock icon)
- [ ] HTTP redirects to HTTPS (`curl -I http://yourdomain.com` returns 301)
- [ ] NGINX configuration is valid (`sudo nginx -t`)
- [ ] NGINX is listening on port 443 (`sudo netstat -tlnp | grep :443`)
- [ ] Security headers are present (`curl -I https://yourdomain.com | grep strict-transport-security`)
- [ ] Renewal script exists (`ls -l /usr/local/bin/ssl-renewal-with-retry.sh`)
- [ ] Monitoring script exists (`ls -l /usr/local/bin/ssl-monitor.sh`)
- [ ] Cron jobs are configured (`sudo cat /etc/cron.d/ssl-automation`)
- [ ] Renewal dry run succeeds (`sudo certbot renew --dry-run`)
- [ ] Renewal logs exist (`sudo ls -l /var/log/ssl-automation/renewal.log`)
- [ ] Monitoring logs exist (`sudo ls -l /var/log/ssl-automation/monitor.log`)

Once all checks pass, you're ready to proceed to systemd service configuration.

---

### 5.6 Systemd Service Configuration

This section guides you through creating and configuring the systemd service for the AI Website Builder application. The `configure-systemd.sh` script automates the creation of the systemd service file, sets up the application directory structure, and configures automatic startup and restart policies.

**Purpose:**
- Create systemd service file for the website-builder application
- Configure automatic startup on system boot
- Set up automatic restart on failure with resource limits
- Create application directory structure with proper permissions
- Configure VPN-only access binding (if Tailscale is configured)
- Generate placeholder environment configuration file
- Implement security hardening for the service

**Prerequisites:**
- NGINX must be installed and configured (Section 5.2 completed)
- UFW firewall must be configured (Section 5.3 completed)
- Tailscale VPN should be configured (Section 5.4 completed, recommended but optional)
- SSL certificates should be installed (Section 5.5 completed)

**Important Notes:**
- This script creates the service configuration but does NOT start the service
- The application code must be deployed before the service can start (Phase 5)
- If Tailscale is configured, the service will bind only to the Tailscale IP (VPN-only access)
- If Tailscale is not configured, the service will bind to all interfaces (0.0.0.0)

---

#### Execute Systemd Configuration Script

SSH into your Lightsail instance and run the systemd configuration script:

```bash
sudo /opt/ai-website-builder/infrastructure/scripts/configure-systemd.sh
```

**No parameters required** - the script automatically detects Tailscale configuration and sets up the service accordingly.

---

#### Expected Output

The script will perform the following actions and display progress:

```
ℹ Creating systemd service files for AI Website Builder...
========================================
✓ Tailscale IP detected: 100.64.1.2
ℹ Creating systemd service file...
✓ Systemd service file created: /etc/systemd/system/website-builder.service
ℹ Creating Tailscale binding override...
✓ Tailscale binding override created: /etc/systemd/system/website-builder.service.d/tailscale-binding.conf
ℹ Creating application directory structure...
✓ Application directory structure created
ℹ Creating placeholder .env file...
✓ Placeholder .env file created: /opt/website-builder/.env
⚠ Remember to update /opt/website-builder/.env with your actual values
ℹ Reloading systemd daemon...
✓ Systemd daemon reloaded
ℹ Enabling service to start on boot...
✓ Service enabled
ℹ Creating service management helper script...
✓ Service management helper created: /usr/local/bin/website-builder-service

========================================
✓ Systemd service configuration complete!
========================================

Service Details:
  Service Name: website-builder.service
  Service File: /etc/systemd/system/website-builder.service
  Application Directory: /opt/website-builder
  User: www-data
  Group: www-data
  Bind Address: 100.64.1.2
  Port: 3000

Service Features:
  ✓ Automatic restart on failure
  ✓ Restart delay: 10 seconds
  ✓ Start limit: 3 attempts in 5 minutes
  ✓ Memory limit: 512MB
  ✓ CPU quota: 80%
  ✓ Security hardening enabled
  ✓ Logging to systemd journal
  ✓ Enabled to start on boot

VPN Configuration:
  ✓ Tailscale binding configured
  ✓ Builder Interface accessible at: http://100.64.1.2:3000
  ✓ VPN-only access enforced

Service Management Commands:
  Start:   website-builder-service start
  Stop:    website-builder-service stop
  Restart: website-builder-service restart
  Status:  website-builder-service status
  Logs:    website-builder-service logs

Or use systemctl directly:
  systemctl start website-builder.service
  systemctl status website-builder.service
  journalctl -u website-builder.service -f

Next Steps:
  1. Update /opt/website-builder/.env with your actual values
  2. Deploy your application code to /opt/website-builder/app/
  3. Start the service: website-builder-service start
  4. Check status: website-builder-service status
  5. View logs: website-builder-service logs

⚠ Note: The service will not start until you deploy the application code
```

**What the Script Does:**

1. **Detects Tailscale Configuration:** Checks if Tailscale is installed and retrieves the VPN IP address
2. **Creates Systemd Service File:** Generates `/etc/systemd/system/website-builder.service` with production-ready configuration
3. **Configures VPN Binding:** If Tailscale is detected, creates an override to bind only to the Tailscale IP
4. **Creates Directory Structure:** Sets up application directories for code, config, assets, versions, and logs
5. **Sets Permissions:** Configures proper ownership (www-data) and permissions for security
6. **Generates Placeholder .env:** Creates a template environment file with required variables
7. **Reloads Systemd:** Refreshes systemd to recognize the new service
8. **Enables Auto-Start:** Configures the service to start automatically on system boot
9. **Creates Helper Script:** Generates a convenience script for service management

---

#### Systemd Service File Configuration

The script creates a comprehensive systemd service file with the following configuration:

**Service File Location:** `/etc/systemd/system/website-builder.service`

**Key Configuration Elements:**

**Unit Section:**
- **Description:** AI Website Builder - Builder Interface
- **After:** Starts after network and Tailscale are available
- **Wants:** Depends on Tailscale service (soft dependency)

**Service Section:**
- **Type:** Simple (foreground process)
- **User/Group:** www-data (non-privileged user for security)
- **WorkingDirectory:** /opt/website-builder/app
- **Environment Variables:**
  - `NODE_ENV=production` - Production mode
  - `PORT=3000` - Application port
  - `BIND_ADDRESS` - Tailscale IP (VPN-only) or 0.0.0.0 (all interfaces)
  - `CONFIG_DIR` - Configuration directory
  - `ASSETS_DIR` - Asset storage directory
  - `PUBLIC_DIR` - Public HTML output directory (/var/www/html)
  - `VERSIONS_DIR` - Version history directory
  - `LOG_DIR` - Application logs directory
- **EnvironmentFile:** Loads additional variables from `/opt/website-builder/.env`
- **ExecStart:** `/usr/bin/node server.js` - Starts the Node.js application

**Restart Policy:**
- **Restart:** on-failure (automatically restarts if the process crashes)
- **RestartSec:** 10s (waits 10 seconds before restarting)
- **StartLimitInterval:** 5min (rate limiting window)
- **StartLimitBurst:** 3 (maximum 3 restart attempts in 5 minutes)

**Resource Limits:**
- **MemoryLimit:** 512M (prevents memory leaks from consuming all RAM)
- **CPUQuota:** 80% (prevents CPU monopolization)

**Security Hardening:**
- **NoNewPrivileges:** Prevents privilege escalation
- **PrivateTmp:** Isolates /tmp directory
- **ProtectSystem:** Strict read-only filesystem protection
- **ProtectHome:** Prevents access to user home directories
- **ReadWritePaths:** Explicitly allows writes only to required directories

**Logging:**
- **StandardOutput/StandardError:** journal (logs to systemd journal)
- **SyslogIdentifier:** website-builder (for easy log filtering)

**Install Section:**
- **WantedBy:** multi-user.target (starts in multi-user mode)

---

#### Application Directory Structure

The script creates the following directory structure:

```
/opt/website-builder/
├── app/                          # Application code (deployed in Phase 5)
│   ├── server.js                 # Main application entry point
│   ├── package.json              # Node.js dependencies
│   └── ...                       # Other application files
├── config/                       # Configuration files
│   ├── pages/                    # Page configurations
│   └── *.json                    # Other config files
├── assets/                       # Asset storage
│   ├── uploads/                  # User-uploaded images
│   └── processed/                # Processed images
│       ├── 320/                  # Mobile size (320px)
│       ├── 768/                  # Tablet size (768px)
│       └── 1920/                 # Desktop size (1920px)
├── versions/                     # Version history
├── logs/                         # Application logs
└── .env                          # Environment variables (secrets)
```

**Directory Ownership:**
- All directories owned by `www-data:www-data`
- Application runs as non-privileged user for security

**Directory Permissions:**
- `/opt/website-builder/` - 750 (owner read/write/execute, group read/execute)
- `/opt/website-builder/.env` - 600 (owner read/write only, contains secrets)
- `/opt/website-builder/config/*.json` - 640 (owner read/write, group read)

---

#### VPN-Only Access Configuration

If Tailscale is configured (Section 5.4 completed), the service automatically binds only to the Tailscale IP address, ensuring the Builder Interface is accessible only via VPN.

**Tailscale Binding Override:** `/etc/systemd/system/website-builder.service.d/tailscale-binding.conf`

This override file sets:
- `BIND_ADDRESS` to the Tailscale IP (e.g., 100.64.1.2)
- Ensures the application listens only on the VPN interface
- Prevents public access to the Builder Interface

**Security Benefits:**
- Builder Interface is not accessible from the public internet
- Only users connected to your Tailscale network can access port 3000
- Firewall rules (UFW) provide additional protection by blocking port 3000 from public access

**If Tailscale is Not Configured:**
- Service binds to `0.0.0.0` (all interfaces)
- Builder Interface is accessible on all network interfaces
- **WARNING:** Without Tailscale, the Builder Interface may be publicly accessible if firewall rules are misconfigured
- **Recommendation:** Always configure Tailscale (Section 5.4) before deploying the application

---

#### Environment Configuration File

The script creates a placeholder `.env` file at `/opt/website-builder/.env` with the following template:

```bash
# AI Website Builder Environment Variables
# Copy this file and fill in your actual values

# Claude API Configuration
ANTHROPIC_API_KEY=your-api-key-here

# Domain Configuration
DOMAIN=example.com
SSL_EMAIL=admin@example.com

# Security
SESSION_SECRET=<randomly-generated-32-byte-hex>
ALLOWED_ORIGINS=https://example.com

# Rate Limiting
MAX_REQUESTS_PER_MINUTE=10
MONTHLY_TOKEN_THRESHOLD=1000000

# Monitoring
LOG_LEVEL=info
LOG_ROTATION_SIZE=100MB
LOG_RETENTION_DAYS=30
```

**Important Notes:**
- The `SESSION_SECRET` is automatically generated using `openssl rand -hex 32`
- You MUST update this file with your actual values before starting the service (Phase 5)
- The file has 600 permissions (owner read/write only) to protect secrets
- Never commit this file to version control

**Required Variables:**
- `ANTHROPIC_API_KEY` - Your Claude API key (obtained in Prerequisites)
- `DOMAIN` - Your domain name (e.g., example.com)
- `SSL_EMAIL` - Your email for SSL notifications

**Optional Variables:**
- `SESSION_SECRET` - Pre-generated, but you can change it
- `ALLOWED_ORIGINS` - CORS configuration (defaults to your domain)
- `MAX_REQUESTS_PER_MINUTE` - Rate limiting (default: 10)
- `MONTHLY_TOKEN_THRESHOLD` - Claude API usage limit (default: 1,000,000 tokens)
- `LOG_LEVEL` - Logging verbosity (default: info)
- `LOG_ROTATION_SIZE` - Log file size limit (default: 100MB)
- `LOG_RETENTION_DAYS` - Log retention period (default: 30 days)

---

#### Service Management Helper Script

The script creates a convenience wrapper at `/usr/local/bin/website-builder-service` for easy service management.

**Available Commands:**

**Start the service:**
```bash
website-builder-service start
```

**Stop the service:**
```bash
website-builder-service stop
```

**Restart the service:**
```bash
website-builder-service restart
```

**Check service status:**
```bash
website-builder-service status
```

**View live logs:**
```bash
website-builder-service logs
```

**Enable auto-start on boot:**
```bash
website-builder-service enable
```

**Disable auto-start on boot:**
```bash
website-builder-service disable
```

**Alternative: Using systemctl Directly**

You can also use standard systemctl commands:

```bash
# Start the service
sudo systemctl start website-builder.service

# Stop the service
sudo systemctl stop website-builder.service

# Restart the service
sudo systemctl restart website-builder.service

# Check status
sudo systemctl status website-builder.service

# View logs
sudo journalctl -u website-builder.service -f

# Enable auto-start
sudo systemctl enable website-builder.service

# Disable auto-start
sudo systemctl disable website-builder.service
```

---

#### Verification Commands

After running the systemd configuration script, verify that the service is properly configured.

**1. Check Service File Exists:**

```bash
ls -l /etc/systemd/system/website-builder.service
```

**Expected Output:**
```
-rw-r--r-- 1 root root 1234 Jan 15 11:00 /etc/systemd/system/website-builder.service
```

**If verification fails:** Service file was not created. Check script output for errors.

---

**2. Check Service is Enabled:**

```bash
systemctl is-enabled website-builder.service
```

**Expected Output:**
```
enabled
```

This confirms the service will start automatically on system boot.

---

**3. Check Service Status:**

```bash
systemctl status website-builder.service
```

**Expected Output:**
```
● website-builder.service - AI Website Builder - Builder Interface
     Loaded: loaded (/etc/systemd/system/website-builder.service; enabled; vendor preset: enabled)
     Active: inactive (dead)
       Docs: https://github.com/your-repo/ai-website-builder
```

**Key indicators:**
- **Loaded:** Service file is recognized by systemd
- **enabled:** Service will start on boot
- **Active: inactive (dead):** Service is not running (expected, application not deployed yet)

**Note:** The service will show as "inactive (dead)" until you deploy the application code and start it in Phase 5.

---

**4. Check Application Directory Structure:**

```bash
ls -la /opt/website-builder/
```

**Expected Output:**
```
total 32
drwxr-x--- 8 www-data www-data 4096 Jan 15 11:00 .
drwxr-xr-x 3 root     root     4096 Jan 15 11:00 ..
drwxr-xr-x 2 www-data www-data 4096 Jan 15 11:00 app
drwxr-xr-x 3 www-data www-data 4096 Jan 15 11:00 assets
drwxr-xr-x 3 www-data www-data 4096 Jan 15 11:00 config
-rw------- 1 www-data www-data  512 Jan 15 11:00 .env
drwxr-xr-x 2 www-data www-data 4096 Jan 15 11:00 logs
drwxr-xr-x 2 www-data www-data 4096 Jan 15 11:00 versions
```

**Key indicators:**
- All directories owned by `www-data:www-data`
- `.env` file has 600 permissions (owner read/write only)
- Directory structure is complete

---

**5. Check Environment File Exists:**

```bash
ls -l /opt/website-builder/.env
```

**Expected Output:**
```
-rw------- 1 www-data www-data 512 Jan 15 11:00 /opt/website-builder/.env
```

**Verify permissions are secure (600):**
```bash
stat -c "%a %n" /opt/website-builder/.env
```

**Expected Output:**
```
600 /opt/website-builder/.env
```

---

**6. Check Tailscale Binding (if Tailscale is configured):**

```bash
cat /etc/systemd/system/website-builder.service.d/tailscale-binding.conf
```

**Expected Output (if Tailscale is configured):**
```
[Service]
# Override BIND_ADDRESS to use Tailscale IP
Environment="BIND_ADDRESS=100.64.1.2"
Environment="PORT=3000"
```

**If Tailscale is not configured:** This file will not exist (expected).

---

**7. Check Service Management Helper:**

```bash
ls -l /usr/local/bin/website-builder-service
```

**Expected Output:**
```
-rwxr-xr-x 1 root root 1024 Jan 15 11:00 /usr/local/bin/website-builder-service
```

**Test the helper script:**
```bash
website-builder-service status
```

**Expected Output:** Same as `systemctl status website-builder.service`

---

**8. View Service Configuration:**

```bash
systemctl cat website-builder.service
```

**Expected Output:** Displays the complete service file content, including any overrides.

---

**9. Check Systemd Journal Configuration:**

```bash
journalctl -u website-builder.service --no-pager | head -5
```

**Expected Output:**
```
-- No entries --
```

This is expected since the service hasn't been started yet. After starting the service in Phase 5, logs will appear here.

---

#### Troubleshooting Systemd Configuration Issues

**Issue: Service File Not Created**

**Symptom:**
```
ls: cannot access '/etc/systemd/system/website-builder.service': No such file or directory
```

**Root Cause:** Script failed to create the service file.

**Solution:**
1. Check script output for errors
2. Verify you ran the script with sudo: `sudo ./configure-systemd.sh`
3. Check disk space: `df -h`
4. Verify systemd directory exists: `ls -ld /etc/systemd/system/`
5. Re-run the script

---

**Issue: Service Not Enabled**

**Symptom:**
```
systemctl is-enabled website-builder.service
disabled
```

**Root Cause:** Service was not enabled during configuration.

**Solution:**
```bash
sudo systemctl enable website-builder.service
```

---

**Issue: Permission Denied on .env File**

**Symptom:**
```
cat: /opt/website-builder/.env: Permission denied
```

**Root Cause:** .env file has restrictive permissions (600) for security.

**Solution:**
```bash
# View as root
sudo cat /opt/website-builder/.env

# Or switch to www-data user
sudo -u www-data cat /opt/website-builder/.env
```

This is expected behavior - the .env file should only be readable by the application user (www-data).

---

**Issue: Directory Structure Not Created**

**Symptom:**
```
ls: cannot access '/opt/website-builder/': No such file or directory
```

**Root Cause:** Script failed to create directories.

**Solution:**
1. Check script output for errors
2. Verify disk space: `df -h`
3. Check permissions on /opt: `ls -ld /opt`
4. Manually create directories:
```bash
sudo mkdir -p /opt/website-builder/{app,config,config/pages,assets/uploads,assets/processed/{320,768,1920},versions,logs}
sudo chown -R www-data:www-data /opt/website-builder
sudo chmod 750 /opt/website-builder
```

---

**Issue: Tailscale IP Not Detected**

**Symptom:**
```
⚠ Tailscale not configured or not running
⚠ Service will bind to 0.0.0.0 (all interfaces)
```

**Root Cause:** Tailscale is not installed or not running.

**Solution:**
1. Verify Tailscale is installed: `which tailscale`
2. Check Tailscale status: `sudo tailscale status`
3. If not configured, run Section 5.4 first: `sudo ./configure-tailscale.sh`
4. Re-run systemd configuration script after Tailscale is configured

**Note:** This is a warning, not an error. The service will still work but will bind to all interfaces instead of VPN-only.

---

**Issue: Service Fails to Start (After Application Deployment)**

**Symptom:**
```
systemctl status website-builder.service
Active: failed (Result: exit-code)
```

**Root Cause:** Application code not deployed or .env file not configured.

**Solution:**
1. Check service logs: `journalctl -u website-builder.service -n 50`
2. Verify application code exists: `ls -l /opt/website-builder/app/server.js`
3. Verify .env file is configured: `sudo cat /opt/website-builder/.env`
4. Check Node.js is installed: `node --version`
5. Verify dependencies are installed: `ls -l /opt/website-builder/app/node_modules`

**Note:** This issue will be addressed in Phase 5 (Application Deployment).

---

#### Security Considerations

**Service User:**
- The service runs as `www-data`, a non-privileged user
- This limits the damage if the application is compromised
- The user has access only to required directories

**File Permissions:**
- `.env` file has 600 permissions (owner read/write only)
- Protects sensitive credentials (API keys, secrets)
- Only www-data and root can read the file

**Resource Limits:**
- Memory limit (512MB) prevents memory exhaustion
- CPU quota (80%) prevents CPU monopolization
- Protects other services on the server

**Security Hardening:**
- `NoNewPrivileges` prevents privilege escalation attacks
- `PrivateTmp` isolates temporary files
- `ProtectSystem=strict` makes most of the filesystem read-only
- `ProtectHome` prevents access to user home directories
- `ReadWritePaths` explicitly allows writes only where needed

**Network Binding:**
- If Tailscale is configured, binds only to VPN IP (not publicly accessible)
- If Tailscale is not configured, binds to 0.0.0.0 (all interfaces)
- Firewall rules (UFW) provide additional protection

**Restart Policy:**
- Automatic restart on failure ensures high availability
- Rate limiting (3 attempts in 5 minutes) prevents restart loops
- 10-second delay between restarts prevents rapid failure cycles

---

#### Next Steps

**After Systemd Configuration:**

1. **Deploy Application Code** (Phase 5) - Transfer application code to `/opt/website-builder/app/`
2. **Configure Environment Variables** (Phase 5) - Update `/opt/website-builder/.env` with actual values
3. **Install Dependencies** (Phase 5) - Run `npm install` in the application directory
4. **Build Application** (Phase 5) - Compile TypeScript code
5. **Start Service** (Phase 5) - Start the website-builder service
6. **Verify Service** (Phase 6) - Confirm the Builder Interface is accessible

**Important Notes:**

- **Service is configured but not started:** The service will not start until application code is deployed
- **Environment file needs configuration:** Update `/opt/website-builder/.env` with your actual API keys and domain
- **VPN access is recommended:** Ensure Tailscale is configured for secure VPN-only access
- **Auto-start is enabled:** The service will automatically start on system boot after application deployment

**Access URLs (after application deployment):**
- **Builder Interface:** `http://[tailscale-ip]:3000` (via Tailscale VPN)
- **Public Website:** `https://yourdomain.com` (HTTPS enabled)

---

**Verification Checklist:**

Before proceeding to application deployment, ensure:

- [ ] Service file exists (`ls -l /etc/systemd/system/website-builder.service`)
- [ ] Service is enabled (`systemctl is-enabled website-builder.service` returns "enabled")
- [ ] Service status shows "loaded" (`systemctl status website-builder.service`)
- [ ] Application directory structure exists (`ls -la /opt/website-builder/`)
- [ ] All directories owned by www-data (`ls -la /opt/website-builder/`)
- [ ] .env file exists with 600 permissions (`ls -l /opt/website-builder/.env`)
- [ ] Tailscale binding configured if VPN is set up (`cat /etc/systemd/system/website-builder.service.d/tailscale-binding.conf`)
- [ ] Service management helper exists (`ls -l /usr/local/bin/website-builder-service`)
- [ ] Helper script is executable (`website-builder-service status` works)
- [ ] Systemd daemon reloaded (service appears in `systemctl list-unit-files | grep website-builder`)

Once all checks pass, you're ready to proceed to application deployment (Phase 5).

---

**Server Configuration Phase Complete!**

You have successfully completed all server configuration steps:
- ✓ NGINX web server configured (Section 5.2)
- ✓ UFW firewall configured (Section 5.3)
- ✓ Tailscale VPN configured (Section 5.4)
- ✓ SSL certificates installed (Section 5.5)
- ✓ Systemd service configured (Section 5.6)

**Continue to:** [Application Deployment Phase](#application-deployment-phase)

---

## Application Deployment Phase

This phase covers deploying the AI Website Builder application code to your configured AWS Lightsail instance. By this point, you should have completed the Server Configuration Phase, with NGINX, UFW, Tailscale, SSL, and systemd all properly configured.

**Prerequisites for this phase:**
- AWS Lightsail instance is running and accessible via SSH
- Server configuration scripts have been executed successfully (Phase 4)
- You have the instance IP address from the Infrastructure Deployment Phase
- You have SSH access to the server

**What this phase accomplishes:**
- Transfer application code to the server
- Install Node.js dependencies
- Configure environment variables
- Build the TypeScript application
- Start the website-builder service

**Estimated Time:** 10-15 minutes

---

### Code Transfer Methods

The first step in deploying the application is transferring the code to your AWS Lightsail instance. There are two primary methods for transferring code: using Git (recommended) or using SCP (secure copy). Choose the method that best fits your workflow.

#### Method 1: Git Clone (Recommended)

Using Git to clone the repository directly on the server is the recommended approach. This method is cleaner, easier to maintain, and simplifies future updates.

**Advantages:**
- Simple and straightforward
- Easy to pull updates with `git pull`
- Preserves Git history for troubleshooting
- No need to transfer files from your local machine
- Works well with CI/CD pipelines

**Prerequisites:**
- Your code is committed to a Git repository (GitHub, GitLab, Bitbucket, etc.)
- The repository is accessible from the server (public repo or SSH keys configured)

**Steps:**

1. **SSH into your Lightsail instance:**

   ```bash
   ssh ubuntu@YOUR_INSTANCE_IP
   ```

   Replace `YOUR_INSTANCE_IP` with the IP address from your infrastructure deployment outputs.

2. **Navigate to the desired installation directory:**

   ```bash
   cd /opt
   ```

   **Note:** `/opt` is a common location for third-party applications. You can choose a different directory if preferred (e.g., `/home/ubuntu/apps`).

3. **Clone the repository:**

   **For public repositories:**
   ```bash
   sudo git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git website-builder
   ```

   **For private repositories using HTTPS (will prompt for credentials):**
   ```bash
   sudo git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git website-builder
   ```

   **For private repositories using SSH (requires SSH key setup):**
   ```bash
   sudo git clone git@github.com:YOUR_USERNAME/YOUR_REPO.git website-builder
   ```

   Replace:
   - `YOUR_USERNAME` with your GitHub/GitLab username or organization
   - `YOUR_REPO` with your repository name
   - `website-builder` with your desired directory name

4. **Set proper ownership:**

   ```bash
   sudo chown -R ubuntu:ubuntu /opt/website-builder
   ```

   This ensures the `ubuntu` user owns the files and can run npm commands without sudo.

5. **Verify the code was transferred:**

   ```bash
   ls -la /opt/website-builder
   ```

   **Expected Output:** You should see your application files including `package.json`, `src/`, `infrastructure/`, etc.

**Setting Up SSH Keys for Private Repositories (Optional):**

If you're using a private repository and want to avoid entering credentials, set up SSH keys:

1. **Generate an SSH key on the server (if not already present):**

   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

   Press Enter to accept the default location (`~/.ssh/id_ed25519`).

2. **Display the public key:**

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

3. **Add the public key to your Git provider:**
   - **GitHub:** Settings → SSH and GPG keys → New SSH key
   - **GitLab:** Preferences → SSH Keys → Add new key
   - **Bitbucket:** Personal settings → SSH keys → Add key

4. **Test the SSH connection:**

   ```bash
   ssh -T git@github.com
   ```

   **Expected Output:** `Hi USERNAME! You've successfully authenticated...`

**Troubleshooting Git Clone:**

- **Permission denied (publickey):** SSH keys are not configured correctly. Follow the SSH key setup steps above.
- **Repository not found:** Check the repository URL and ensure you have access to the repository.
- **Authentication failed:** For HTTPS, verify your username and password/token. Consider using SSH instead.
- **fatal: destination path 'website-builder' already exists:** The directory already exists. Either remove it (`sudo rm -rf website-builder`) or clone to a different name.

---

#### Method 2: SCP (Secure Copy)

SCP allows you to copy files from your local machine to the server. This method is useful if you have local changes that aren't committed to Git, or if you prefer to build locally and transfer the built application.

**Advantages:**
- Works without a Git repository
- Can transfer locally modified code
- Useful for quick testing or one-off deployments

**Disadvantages:**
- More manual process
- Harder to track changes and updates
- Need to transfer files from your local machine each time
- Can miss hidden files or directories if not careful

**Prerequisites:**
- Application code is on your local machine
- SSH access to the Lightsail instance
- SCP client installed (included with SSH on most systems)

**Steps:**

1. **Navigate to your local project directory:**

   ```bash
   cd /path/to/your/local/website-builder
   ```

2. **Create a tarball of your application (optional but recommended):**

   This ensures all files are transferred together and preserves permissions.

   ```bash
   tar -czf website-builder.tar.gz \
     --exclude='node_modules' \
     --exclude='.git' \
     --exclude='dist' \
     --exclude='.env' \
     .
   ```

   **Explanation:**
   - `-c`: Create archive
   - `-z`: Compress with gzip
   - `-f`: Specify filename
   - `--exclude`: Skip directories that will be regenerated or contain sensitive data
   - `.`: Include all files in current directory

3. **Transfer the tarball to the server:**

   ```bash
   scp website-builder.tar.gz ubuntu@YOUR_INSTANCE_IP:/tmp/
   ```

   Replace `YOUR_INSTANCE_IP` with your Lightsail instance IP address.

   **Expected Output:**
   ```
   website-builder.tar.gz                100%   15MB   5.2MB/s   00:03
   ```

4. **SSH into the server:**

   ```bash
   ssh ubuntu@YOUR_INSTANCE_IP
   ```

5. **Create the application directory:**

   ```bash
   sudo mkdir -p /opt/website-builder
   sudo chown ubuntu:ubuntu /opt/website-builder
   ```

6. **Extract the tarball:**

   ```bash
   cd /opt/website-builder
   tar -xzf /tmp/website-builder.tar.gz
   ```

7. **Clean up the tarball:**

   ```bash
   rm /tmp/website-builder.tar.gz
   ```

8. **Verify the code was transferred:**

   ```bash
   ls -la /opt/website-builder
   ```

   **Expected Output:** You should see your application files including `package.json`, `src/`, `infrastructure/`, etc.

**Alternative: Direct SCP Without Tarball**

If you prefer to copy files directly without creating a tarball:

```bash
# From your local machine
scp -r \
  -o "ControlMaster=auto" \
  -o "ControlPath=/tmp/ssh-%r@%h:%p" \
  /path/to/your/local/website-builder \
  ubuntu@YOUR_INSTANCE_IP:/opt/
```

**Note:** This method is slower and may miss hidden files. The tarball method is recommended.

**Troubleshooting SCP:**

- **Permission denied:** Ensure you have SSH access to the server and the destination directory has proper permissions.
- **No such file or directory:** The destination directory doesn't exist. Create it first with `ssh ubuntu@YOUR_INSTANCE_IP "sudo mkdir -p /opt/website-builder"`.
- **Connection refused:** Check that the instance IP is correct and the firewall allows SSH (port 22).
- **scp: command not found:** Install OpenSSH client on your local machine.

---

### Choosing Between Git Clone and SCP

**Use Git Clone if:**
- ✓ Your code is in a Git repository
- ✓ You want easy updates with `git pull`
- ✓ You prefer a clean, version-controlled deployment
- ✓ You're setting up a production environment
- ✓ You want to integrate with CI/CD pipelines

**Use SCP if:**
- ✓ You have local changes not committed to Git
- ✓ You're doing quick testing or development
- ✓ You don't have a Git repository set up
- ✓ You need to transfer specific files or directories
- ✓ You're troubleshooting and need to quickly replace files

**Recommendation:** For production deployments, use Git Clone (Method 1). It's cleaner, more maintainable, and aligns with modern deployment best practices.

---

### Next Steps

Once you've transferred the code using either method, proceed to:
1. **Install Node.js dependencies** (Task 7.2)
2. **Configure environment variables** (Task 7.3)
3. **Build the TypeScript application** (Task 7.4)
4. **Start the website-builder service** (Task 7.4)

**Verification Checkpoint:**

Before proceeding, verify the code is in place:

```bash
# SSH into the server (if not already connected)
ssh ubuntu@YOUR_INSTANCE_IP

# Check the application directory exists and contains files
ls -la /opt/website-builder

# Verify package.json exists (required for npm install)
cat /opt/website-builder/package.json
```

**Expected Output:** You should see your `package.json` file content displayed, confirming the application code is properly transferred.

**If verification fails:**
- Ensure you followed all steps in your chosen transfer method
- Check that the directory path is correct (`/opt/website-builder`)
- Verify file ownership is set to `ubuntu:ubuntu`
- Review any error messages from the git clone or scp commands

---

### Installing Node.js Dependencies

After transferring the application code to the server, you must install the Node.js dependencies required to build and run the AI Website Builder. This step uses npm (Node Package Manager) to download and install all packages specified in the `package.json` file.

**Prerequisites:**
- Application code has been transferred to `/opt/website-builder` (or your chosen directory)
- Node.js and npm are installed on the server (verified during Server Configuration Phase)
- You have SSH access to the server

**What this step accomplishes:**
- Downloads all production and development dependencies from npm registry
- Creates the `node_modules` directory with all required packages
- Generates or updates the `package-lock.json` file for dependency locking
- Prepares the application for the build process

**Estimated Time:** 3-5 minutes (depending on network speed and number of dependencies)

---

#### Installation Steps

1. **SSH into your Lightsail instance (if not already connected):**

   ```bash
   ssh ubuntu@YOUR_INSTANCE_IP
   ```

   Replace `YOUR_INSTANCE_IP` with your instance IP address.

2. **Navigate to the application directory:**

   ```bash
   cd /opt/website-builder
   ```

   **Note:** If you installed the application in a different directory, adjust the path accordingly.

3. **Install Node.js dependencies:**

   ```bash
   npm install
   ```

   **What this command does:**
   - Reads the `package.json` file to determine required dependencies
   - Downloads packages from the npm registry (https://registry.npmjs.org/)
   - Installs both `dependencies` (required for production) and `devDependencies` (required for building)
   - Creates the `node_modules` directory containing all installed packages
   - Generates `package-lock.json` to lock dependency versions

   **Expected Output:**

   ```
   npm WARN deprecated <package>@<version>: <deprecation message>
   
   added 543 packages, and audited 544 packages in 2m
   
   89 packages are looking for funding
     run `npm fund` for details
   
   found 0 vulnerabilities
   ```

   **Output Explanation:**
   - **Deprecation warnings:** Some dependencies may use deprecated packages. These are usually safe to ignore unless they affect core functionality.
   - **added X packages:** Shows the total number of packages installed (including dependencies of dependencies).
   - **audited X packages:** npm automatically checks for known security vulnerabilities.
   - **found 0 vulnerabilities:** Indicates no known security issues (ideal state).
   - **packages looking for funding:** Informational message about open-source package funding.

   **Expected Duration:**
   - **First-time installation:** 2-5 minutes (depending on network speed and number of dependencies)
   - **Subsequent installations:** 30 seconds - 2 minutes (npm uses cache when possible)
   - **Slow network:** Up to 10 minutes in some cases

4. **Verify the installation:**

   ```bash
   ls -la node_modules
   ```

   **Expected Output:** A list of directories, each representing an installed package.

   ```bash
   npm list --depth=0
   ```

   **Expected Output:** A tree view of top-level installed packages.

   ```
   website-builder@1.0.0 /opt/website-builder
   ├── @anthropic-ai/sdk@0.x.x
   ├── express@4.x.x
   ├── typescript@5.x.x
   └── ... (other packages)
   ```

---

#### Understanding npm Install Output

**Normal Messages (Safe to Ignore):**

- **Deprecation warnings:** 
  ```
  npm WARN deprecated package@version: This package is deprecated
  ```
  These indicate that some dependencies use older packages. Unless they directly affect your application, they can be safely ignored. The package maintainers will update these over time.

- **Funding messages:**
  ```
  89 packages are looking for funding
  ```
  Informational message about open-source sustainability. No action required.

- **Peer dependency warnings:**
  ```
  npm WARN ERESOLVE overriding peer dependency
  ```
  npm is resolving version conflicts automatically. Usually safe to ignore.

**Messages Requiring Attention:**

- **Vulnerabilities found:**
  ```
  found 3 vulnerabilities (1 moderate, 2 high)
  ```
  Security issues detected. See the [Troubleshooting](#troubleshooting-npm-install-failures) section below for resolution steps.

- **EACCES permission errors:**
  ```
  Error: EACCES: permission denied
  ```
  Permission issue. See troubleshooting section below.

- **Network errors:**
  ```
  Error: network timeout
  ```
  Network connectivity issue. See troubleshooting section below.

---

#### Troubleshooting npm Install Failures

##### Issue 1: Permission Denied Errors

**Symptom:**
```
Error: EACCES: permission denied, mkdir '/opt/website-builder/node_modules'
```

**Root Cause:** The current user doesn't have write permissions to the application directory.

**Solution:**

1. **Check current ownership:**
   ```bash
   ls -la /opt/website-builder
   ```

2. **Fix ownership (if needed):**
   ```bash
   sudo chown -R ubuntu:ubuntu /opt/website-builder
   ```

3. **Retry npm install:**
   ```bash
   cd /opt/website-builder
   npm install
   ```

**Prevention:** Always ensure the application directory is owned by the user running npm commands (typically `ubuntu` on Lightsail instances).

---

##### Issue 2: Network Timeout or Connection Errors

**Symptom:**
```
npm ERR! network request to https://registry.npmjs.org/package failed, reason: connect ETIMEDOUT
npm ERR! network This is a problem related to network connectivity.
```

**Root Cause:** Network connectivity issues, firewall blocking npm registry, or npm registry is temporarily unavailable.

**Solution:**

1. **Verify internet connectivity:**
   ```bash
   ping -c 3 registry.npmjs.org
   ```

   **Expected Output:** Successful ping responses.

2. **Check DNS resolution:**
   ```bash
   nslookup registry.npmjs.org
   ```

   **Expected Output:** IP address of the npm registry.

3. **Retry with increased timeout:**
   ```bash
   npm install --fetch-timeout=60000
   ```

   This increases the timeout to 60 seconds (default is 30 seconds).

4. **Clear npm cache and retry:**
   ```bash
   npm cache clean --force
   npm install
   ```

5. **Check firewall rules:**
   ```bash
   sudo ufw status
   ```

   Ensure outbound HTTPS (port 443) is allowed. The UFW configuration script should have allowed outbound connections by default.

**If the issue persists:**
- Wait a few minutes and retry (npm registry may be experiencing temporary issues)
- Check AWS Lightsail network status in the AWS console
- Verify the instance has internet access: `curl -I https://www.google.com`

---

##### Issue 3: Security Vulnerabilities Found

**Symptom:**
```
found 3 vulnerabilities (1 moderate, 2 high)
  run `npm audit fix` to fix them, or `npm audit` for details
```

**Root Cause:** Some installed packages have known security vulnerabilities.

**Solution:**

1. **Review the vulnerabilities:**
   ```bash
   npm audit
   ```

   This displays detailed information about each vulnerability, including:
   - Severity level (low, moderate, high, critical)
   - Affected package and version
   - Vulnerability description
   - Recommended fix

2. **Attempt automatic fix:**
   ```bash
   npm audit fix
   ```

   This attempts to update vulnerable packages to patched versions without breaking changes.

   **Expected Output:**
   ```
   fixed 2 of 3 vulnerabilities in 544 packages
   1 vulnerability required manual review and could not be updated
   ```

3. **Force fix for remaining vulnerabilities (use with caution):**
   ```bash
   npm audit fix --force
   ```

   **Warning:** This may introduce breaking changes by updating packages to new major versions. Only use if you understand the implications and can test the application afterward.

4. **Verify the fixes:**
   ```bash
   npm audit
   ```

   **Expected Output:** `found 0 vulnerabilities` (ideal) or reduced number of vulnerabilities.

**When to be concerned:**
- **Critical or high vulnerabilities** in production dependencies should be addressed
- **Moderate or low vulnerabilities** in development dependencies are less urgent
- **Vulnerabilities with no fix available** may require waiting for package maintainers to release patches

**Best Practice:** Run `npm audit` regularly and keep dependencies updated to minimize security risks.

---

##### Issue 4: Disk Space Exhausted

**Symptom:**
```
npm ERR! ENOSPC: no space left on device, write
```

**Root Cause:** The server has run out of disk space.

**Solution:**

1. **Check available disk space:**
   ```bash
   df -h
   ```

   **Expected Output:**
   ```
   Filesystem      Size  Used Avail Use% Mounted on
   /dev/xvda1       40G   25G   15G  63% /
   ```

   If `Use%` is at or near 100%, you need to free up space.

2. **Check what's using disk space:**
   ```bash
   du -sh /opt/website-builder/* | sort -h
   ```

3. **Clear npm cache:**
   ```bash
   npm cache clean --force
   ```

4. **Remove old log files (if any):**
   ```bash
   sudo journalctl --vacuum-time=7d
   ```

5. **Retry npm install:**
   ```bash
   npm install
   ```

**If disk space is still insufficient:**
- Consider upgrading to a larger Lightsail instance
- Remove unnecessary files or applications
- Check for large log files: `sudo find / -type f -size +100M 2>/dev/null`

---

##### Issue 5: Package Not Found or Version Mismatch

**Symptom:**
```
npm ERR! 404 Not Found - GET https://registry.npmjs.org/package-name - Not found
npm ERR! 404  'package-name@version' is not in this registry.
```

**Root Cause:** The package name or version specified in `package.json` doesn't exist in the npm registry.

**Solution:**

1. **Check the package name in package.json:**
   ```bash
   cat package.json | grep "package-name"
   ```

2. **Search for the correct package name:**
   ```bash
   npm search package-name
   ```

3. **Update package.json with the correct package name or version:**
   ```bash
   nano package.json
   ```

   Fix the package name or version, save, and exit.

4. **Retry npm install:**
   ```bash
   npm install
   ```

**Common causes:**
- Typo in package name
- Package has been unpublished from npm registry
- Private package that requires authentication
- Version number doesn't exist

---

##### Issue 6: Corrupted package-lock.json

**Symptom:**
```
npm ERR! Unexpected end of JSON input while parsing near '...'
```

**Root Cause:** The `package-lock.json` file is corrupted or incomplete.

**Solution:**

1. **Delete the corrupted lock file:**
   ```bash
   rm package-lock.json
   ```

2. **Delete node_modules (if it exists):**
   ```bash
   rm -rf node_modules
   ```

3. **Reinstall dependencies:**
   ```bash
   npm install
   ```

   This will regenerate a fresh `package-lock.json` file.

**Prevention:** Ensure file transfers complete successfully and avoid manually editing `package-lock.json`.

---

#### Verification Checklist

After successfully installing dependencies, verify the installation:

**1. Check node_modules directory exists:**
```bash
ls -la /opt/website-builder/node_modules
```

**Expected Output:** A directory listing with many subdirectories (one for each installed package).

**2. Verify key dependencies are installed:**
```bash
npm list @anthropic-ai/sdk express typescript
```

**Expected Output:**
```
website-builder@1.0.0 /opt/website-builder
├── @anthropic-ai/sdk@0.x.x
├── express@4.x.x
└── typescript@5.x.x
```

**3. Check for vulnerabilities:**
```bash
npm audit
```

**Expected Output:** `found 0 vulnerabilities` or a manageable number of low-severity issues.

**4. Verify package-lock.json was created:**
```bash
ls -la package-lock.json
```

**Expected Output:** The file exists and has a recent timestamp.

**Checklist:**
- [ ] `npm install` completed without critical errors
- [ ] `node_modules` directory exists and contains packages
- [ ] Key dependencies are installed and listed by `npm list`
- [ ] No critical or high security vulnerabilities (or they have been addressed)
- [ ] `package-lock.json` file exists

**If all checks pass:** You're ready to proceed to the next step (Environment Configuration - Task 7.3).

**If any checks fail:** Review the troubleshooting section above and resolve issues before proceeding.

---

### Next Steps After Dependency Installation

Once dependencies are successfully installed, proceed to:

1. **Configure environment variables** (Task 7.3)
   - Create and configure the `.env` file with required variables
   - Set Anthropic API key, domain name, and other configuration

2. **Build the TypeScript application** (Task 7.4)
   - Compile TypeScript code to JavaScript
   - Prepare the application for production

3. **Start the website-builder service** (Task 7.4)
   - Enable and start the systemd service
   - Verify the application is running

**Important:** Do not skip the environment configuration step. The application will not start without a properly configured `.env` file.

---

### Configuring Environment Variables

After installing dependencies, you must configure the application's environment variables. The AI Website Builder uses a `.env` file to store configuration settings, including sensitive credentials like API keys. This file must be created and properly configured before building and starting the application.

**Prerequisites:**
- Application code has been transferred to `/opt/website-builder`
- Node.js dependencies have been installed successfully
- You have the Anthropic API key obtained during the Prerequisites phase
- You have your domain name from the DNS Configuration phase

**What this step accomplishes:**
- Creates the `.env` configuration file
- Configures API credentials and domain settings
- Sets up security parameters
- Configures file system paths and logging
- Establishes rate limiting and monitoring settings

**Estimated Time:** 5-10 minutes

---

#### Creating the .env File

The application includes a `.env.example` template file that shows all required and optional environment variables. You'll create a `.env` file based on this template and fill in your specific values.

**Steps:**

1. **SSH into your Lightsail instance (if not already connected):**

   ```bash
   ssh ubuntu@YOUR_INSTANCE_IP
   ```

2. **Navigate to the application directory:**

   ```bash
   cd /opt/website-builder
   ```

3. **Copy the example file to create your .env file:**

   ```bash
   cp .env.example .env
   ```

   **Note:** The `.env` file is listed in `.gitignore` and should never be committed to version control.

4. **Edit the .env file with your configuration:**

   ```bash
   nano .env
   ```

   **Alternative editors:** You can use `vim`, `vi`, or any text editor you prefer.

---

#### Required Environment Variables

The following variables **must** be configured for the application to function correctly. Replace the placeholder values with your actual configuration.

##### 1. Anthropic API Configuration

```bash
ANTHROPIC_API_KEY=sk-ant-your-api-key-here
```

**Description:** Your Anthropic API key for accessing Claude AI models.

**How to set:**
- Replace `sk-ant-your-api-key-here` with the API key you obtained from the Anthropic Console during the Prerequisites phase
- The key should start with `sk-ant-api03-` and be approximately 100+ characters long

**Example:**
```bash
ANTHROPIC_API_KEY=sk-ant-api03-abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890abcdefghijklmnopqrstuvwxyz
```

**Security Note:** This is a sensitive credential. See the [Security Considerations](#security-considerations-for-env-file) section below.

---

##### 2. Domain Configuration

```bash
DOMAIN=example.com
SSL_EMAIL=admin@example.com
```

**DOMAIN:**
- **Description:** Your domain name configured during the DNS Configuration phase
- **How to set:** Replace `example.com` with your actual domain name (without `https://` or `www.`)
- **Example:** `DOMAIN=mywebsite.com`

**SSL_EMAIL:**
- **Description:** Email address for SSL certificate notifications from Let's Encrypt
- **How to set:** Replace `admin@example.com` with your email address
- **Example:** `SSL_EMAIL=webmaster@mywebsite.com`
- **Note:** This email receives expiration warnings and renewal notifications for SSL certificates

---

##### 3. Session Secret

```bash
SESSION_SECRET=generate-a-random-secret-here
```

**Description:** A random secret string used to sign session cookies and secure user sessions.

**How to generate a secure secret:**

**Option 1: Using OpenSSL (recommended):**
```bash
openssl rand -base64 32
```

**Option 2: Using Node.js:**
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

**Option 3: Using /dev/urandom:**
```bash
head -c 32 /dev/urandom | base64
```

**Example output:**
```
Xk7mp9Qw3vR8nL2jH5tY1pF6dS4aG9bN0cM8xZ3wE=
```

**How to set:**
1. Run one of the commands above to generate a random string
2. Copy the output
3. Replace `generate-a-random-secret-here` with the generated string

**Example:**
```bash
SESSION_SECRET=Xk7mp9Qw3vR8nL2jH5tY1pF6dS4aG9bN0cM8xZ3wE=
```

**Security Note:** Never use a predictable value or share this secret. Generate a unique secret for each deployment.

---

#### Optional Environment Variables (with Defaults)

The following variables have sensible defaults but can be customized based on your requirements.

##### Server Configuration

```bash
NODE_ENV=production
PORT=3000
BIND_ADDRESS=0.0.0.0
```

**NODE_ENV:**
- **Description:** Node.js environment mode
- **Default:** `production`
- **Options:** `production`, `development`, `test`
- **Recommendation:** Keep as `production` for deployed instances

**PORT:**
- **Description:** Port number the application listens on
- **Default:** `3000`
- **Recommendation:** Keep as `3000` (matches systemd service configuration)
- **Note:** If you change this, you must also update the systemd service file

**BIND_ADDRESS:**
- **Description:** Network interface the application binds to
- **Default:** `0.0.0.0` (all interfaces)
- **Options:** 
  - `0.0.0.0` - Listen on all network interfaces (default)
  - `127.0.0.1` - Listen only on localhost (more secure if using reverse proxy)
  - Tailscale IP - Listen only on VPN interface (most secure)
- **Recommendation:** Keep as `0.0.0.0` unless you have specific security requirements

---

##### Security Configuration

```bash
ALLOWED_ORIGINS=https://example.com
```

**Description:** Comma-separated list of allowed origins for CORS (Cross-Origin Resource Sharing).

**How to set:**
- Replace `example.com` with your domain
- Include both root and www if needed: `https://example.com,https://www.example.com`
- For development, you might add: `http://localhost:3000`

**Example:**
```bash
ALLOWED_ORIGINS=https://mywebsite.com,https://www.mywebsite.com
```

---

##### File System Paths

```bash
CONFIG_DIR=/opt/website-builder/config
ASSETS_DIR=/opt/website-builder/assets
PUBLIC_DIR=/var/www/html
VERSIONS_DIR=/opt/website-builder/versions
LOG_DIR=/opt/website-builder/logs
```

**Description:** Directory paths for application data storage.

**Defaults:**
- **CONFIG_DIR:** Application configuration files
- **ASSETS_DIR:** Uploaded images and media files
- **PUBLIC_DIR:** Generated static HTML files (served by NGINX)
- **VERSIONS_DIR:** Version history of generated pages
- **LOG_DIR:** Application log files

**Recommendation:** Keep the default paths unless you have specific requirements. These paths are created automatically by the configure-systemd.sh script.

**Note:** If you change these paths, ensure:
1. The directories exist and have proper permissions
2. The systemd service has access to these directories
3. NGINX is configured to serve from the PUBLIC_DIR

---

##### Rate Limiting

```bash
MAX_REQUESTS_PER_MINUTE=10
MONTHLY_TOKEN_THRESHOLD=1000000
```

**MAX_REQUESTS_PER_MINUTE:**
- **Description:** Maximum API requests allowed per minute per user
- **Default:** `10`
- **Purpose:** Prevents abuse and controls API costs
- **Recommendation:** Start with `10` and adjust based on usage patterns

**MONTHLY_TOKEN_THRESHOLD:**
- **Description:** Maximum Claude API tokens allowed per month
- **Default:** `1000000` (1 million tokens)
- **Purpose:** Prevents unexpected API costs
- **Cost Estimate:** ~$3-15 per million tokens (depending on model and usage)
- **Recommendation:** Set based on your budget and expected usage
- **Note:** When this threshold is reached, the application will stop making API calls until the next month

---

##### Monitoring and Logging

```bash
LOG_LEVEL=info
LOG_ROTATION_SIZE=100MB
LOG_RETENTION_DAYS=30
```

**LOG_LEVEL:**
- **Description:** Logging verbosity level
- **Default:** `info`
- **Options:** `error`, `warn`, `info`, `debug`, `trace`
- **Recommendation:** 
  - Use `info` for production (balanced logging)
  - Use `debug` for troubleshooting
  - Use `error` to minimize log volume

**LOG_ROTATION_SIZE:**
- **Description:** Maximum size of a single log file before rotation
- **Default:** `100MB`
- **Recommendation:** Keep default unless disk space is limited

**LOG_RETENTION_DAYS:**
- **Description:** Number of days to keep old log files
- **Default:** `30` days
- **Recommendation:** Adjust based on compliance requirements and disk space

---

#### Complete .env File Template

Here's a complete example `.env` file with all variables configured:

```bash
# Anthropic API Configuration
ANTHROPIC_API_KEY=sk-ant-api03-your-actual-api-key-here

# Server Configuration
NODE_ENV=production
PORT=3000
BIND_ADDRESS=0.0.0.0
DOMAIN=mywebsite.com
SSL_EMAIL=admin@mywebsite.com

# Security
SESSION_SECRET=Xk7mp9Qw3vR8nL2jH5tY1pF6dS4aG9bN0cM8xZ3wE=
ALLOWED_ORIGINS=https://mywebsite.com,https://www.mywebsite.com

# File System Paths
CONFIG_DIR=/opt/website-builder/config
ASSETS_DIR=/opt/website-builder/assets
PUBLIC_DIR=/var/www/html
VERSIONS_DIR=/opt/website-builder/versions
LOG_DIR=/opt/website-builder/logs

# Rate Limiting
MAX_REQUESTS_PER_MINUTE=10
MONTHLY_TOKEN_THRESHOLD=1000000

# Monitoring and Logging
LOG_LEVEL=info
LOG_ROTATION_SIZE=100MB
LOG_RETENTION_DAYS=30
```

**Customization Checklist:**
- [ ] Replace `ANTHROPIC_API_KEY` with your actual API key
- [ ] Replace `DOMAIN` with your domain name
- [ ] Replace `SSL_EMAIL` with your email address
- [ ] Generate and set a unique `SESSION_SECRET`
- [ ] Update `ALLOWED_ORIGINS` with your domain(s)
- [ ] Review and adjust rate limiting values if needed
- [ ] Review and adjust logging settings if needed

---

#### Security Considerations for .env File

The `.env` file contains sensitive credentials that must be protected. Follow these security best practices:

##### 1. File Permissions

Set restrictive permissions so only the application user can read the file:

```bash
# Set ownership to the application user
sudo chown ubuntu:ubuntu /opt/website-builder/.env

# Set permissions to read/write for owner only
chmod 600 /opt/website-builder/.env
```

**Verify permissions:**
```bash
ls -l /opt/website-builder/.env
```

**Expected Output:**
```
-rw------- 1 ubuntu ubuntu 1234 Jan 15 10:30 /opt/website-builder/.env
```

The `-rw-------` indicates only the owner (ubuntu) can read and write the file.

---

##### 2. Never Commit to Version Control

The `.env` file should **never** be committed to Git or any version control system.

**Verify .env is ignored:**
```bash
cat /opt/website-builder/.gitignore | grep .env
```

**Expected Output:**
```
.env
```

**If .env is not in .gitignore:**
```bash
echo ".env" >> /opt/website-builder/.gitignore
```

---

##### 3. Backup Securely

If you need to backup your `.env` file:

**DO:**
- Store backups in a secure password manager
- Use encrypted storage for backups
- Limit access to backups to authorized personnel only

**DON'T:**
- Email the `.env` file
- Store in unencrypted cloud storage
- Share via messaging apps
- Include in documentation or wikis

---

##### 4. Rotate Credentials Regularly

**Best Practices:**
- Rotate `ANTHROPIC_API_KEY` every 90 days
- Regenerate `SESSION_SECRET` if compromised
- Update `SSL_EMAIL` if the contact person changes
- Review and update all credentials during security audits

**How to rotate the Anthropic API key:**
1. Create a new API key in the Anthropic Console
2. Update the `.env` file with the new key
3. Restart the application: `sudo systemctl restart website-builder`
4. Verify the application works with the new key
5. Delete the old API key in the Anthropic Console

---

##### 5. Monitor for Unauthorized Access

**Check file access logs:**
```bash
# View recent access to the .env file
sudo ausearch -f /opt/website-builder/.env 2>/dev/null || echo "Audit logging not configured"
```

**Monitor API usage:**
- Regularly check Anthropic Console for unexpected API usage
- Set up billing alerts in AWS for unexpected costs
- Review application logs for suspicious activity

---

##### 6. Principle of Least Privilege

**Access Control:**
- Only the application user (ubuntu) should have read access to `.env`
- System administrators should use `sudo` to view the file when needed
- Never make the file world-readable (`chmod 644` or `chmod 777` is dangerous)

**Service Account:**
- The systemd service runs as the `ubuntu` user (or `www-data` depending on configuration)
- Ensure the service user has read access to `.env`
- No other users should have access

---

#### Validation Commands

After configuring the `.env` file, verify the configuration is correct before proceeding to build the application.

##### 1. Verify .env File Exists

```bash
ls -l /opt/website-builder/.env
```

**Expected Output:**
```
-rw------- 1 ubuntu ubuntu 1234 Jan 15 10:30 /opt/website-builder/.env
```

**If the file doesn't exist:** Review the steps above and ensure you created the file.

---

##### 2. Verify File Permissions

```bash
stat -c "%a %U:%G %n" /opt/website-builder/.env
```

**Expected Output:**
```
600 ubuntu:ubuntu /opt/website-builder/.env
```

**If permissions are incorrect:**
```bash
sudo chown ubuntu:ubuntu /opt/website-builder/.env
chmod 600 /opt/website-builder/.env
```

---

##### 3. Verify Required Variables Are Set

```bash
# Check for required variables (without exposing values)
grep -E "^(ANTHROPIC_API_KEY|DOMAIN|SSL_EMAIL|SESSION_SECRET)=" /opt/website-builder/.env | cut -d= -f1
```

**Expected Output:**
```
ANTHROPIC_API_KEY
DOMAIN
SSL_EMAIL
SESSION_SECRET
```

**If any variables are missing:** Edit the `.env` file and add the missing variables.

---

##### 4. Verify API Key Format

```bash
# Check API key starts with correct prefix (without exposing the full key)
grep "^ANTHROPIC_API_KEY=" /opt/website-builder/.env | grep -q "sk-ant-" && echo "✓ API key format looks correct" || echo "✗ API key format may be incorrect"
```

**Expected Output:**
```
✓ API key format looks correct
```

**If format is incorrect:** Verify you copied the complete API key from the Anthropic Console.

---

##### 5. Verify Domain Configuration

```bash
# Display domain configuration
grep -E "^(DOMAIN|SSL_EMAIL|ALLOWED_ORIGINS)=" /opt/website-builder/.env
```

**Expected Output:**
```
DOMAIN=mywebsite.com
SSL_EMAIL=admin@mywebsite.com
ALLOWED_ORIGINS=https://mywebsite.com,https://www.mywebsite.com
```

**Verify:**
- Domain matches your DNS configuration
- SSL email is a valid email address you have access to
- Allowed origins include your domain with `https://` prefix

---

##### 6. Test Environment Variable Loading

You can test that Node.js can load the environment variables:

```bash
cd /opt/website-builder
node -e "require('dotenv').config(); console.log('✓ Environment variables loaded successfully'); console.log('Domain:', process.env.DOMAIN);"
```

**Expected Output:**
```
✓ Environment variables loaded successfully
Domain: mywebsite.com
```

**If you see an error:**
- Ensure the `dotenv` package is installed: `npm list dotenv`
- Check the `.env` file syntax (no spaces around `=`, no quotes unless needed)
- Verify the file is in the correct location

---

#### Common Configuration Issues

##### Issue 1: Application Won't Start - Missing API Key

**Symptom:**
```
Error: ANTHROPIC_API_KEY environment variable is required
```

**Root Cause:** The `ANTHROPIC_API_KEY` variable is not set or is empty in the `.env` file.

**Solution:**
1. Open the `.env` file: `nano /opt/website-builder/.env`
2. Verify the line `ANTHROPIC_API_KEY=sk-ant-...` exists and has a value
3. Ensure there are no spaces around the `=` sign
4. Ensure the key is not wrapped in quotes (unless the key itself contains spaces)
5. Save the file and restart the application

---

##### Issue 2: Invalid API Key Error

**Symptom:**
```
Error: Invalid API key provided
```

**Root Cause:** The API key is incorrect, expired, or has been revoked.

**Solution:**
1. Log in to the Anthropic Console: https://console.anthropic.com/settings/keys
2. Verify the API key is still active
3. If the key is invalid, create a new key
4. Update the `.env` file with the new key
5. Restart the application: `sudo systemctl restart website-builder`

---

##### Issue 3: Permission Denied Reading .env File

**Symptom:**
```
Error: EACCES: permission denied, open '/opt/website-builder/.env'
```

**Root Cause:** The application user doesn't have read permissions for the `.env` file.

**Solution:**
```bash
# Fix ownership and permissions
sudo chown ubuntu:ubuntu /opt/website-builder/.env
chmod 600 /opt/website-builder/.env

# Verify
ls -l /opt/website-builder/.env
```

---

##### Issue 4: Syntax Error in .env File

**Symptom:**
```
SyntaxError: Unexpected token in .env file
```

**Root Cause:** Invalid syntax in the `.env` file (extra spaces, missing values, etc.).

**Solution:**
1. Check for common syntax issues:
   ```bash
   # Look for lines with spaces around =
   grep " = " /opt/website-builder/.env
   
   # Look for empty values
   grep "=$" /opt/website-builder/.env
   ```

2. Ensure proper format:
   - No spaces around `=`: `KEY=value` (not `KEY = value`)
   - No trailing spaces after values
   - Comments start with `#`
   - Multi-line values should be quoted

3. Compare with the template in `.env.example`

---

##### Issue 5: Domain Mismatch Errors

**Symptom:**
```
Warning: DOMAIN does not match SSL certificate
```

**Root Cause:** The `DOMAIN` variable doesn't match the domain configured during SSL setup.

**Solution:**
1. Verify your domain: `grep "^DOMAIN=" /opt/website-builder/.env`
2. Check SSL certificate domain: `sudo certbot certificates`
3. Ensure they match exactly (no `www.` prefix in `DOMAIN` unless your certificate includes it)
4. Update the `.env` file if needed
5. Restart the application

---

#### Configuration Checklist

Before proceeding to build the application, verify all configuration steps are complete:

- [ ] `.env` file created from `.env.example` template
- [ ] `ANTHROPIC_API_KEY` set with valid API key from Anthropic Console
- [ ] `DOMAIN` set to your domain name (matches DNS configuration)
- [ ] `SSL_EMAIL` set to your email address
- [ ] `SESSION_SECRET` generated and set with a random secure value
- [ ] `ALLOWED_ORIGINS` updated with your domain(s)
- [ ] File permissions set to `600` (read/write for owner only)
- [ ] File ownership set to `ubuntu:ubuntu` (or application user)
- [ ] All required variables verified with validation commands
- [ ] `.env` file is in `.gitignore` (never committed to version control)

**If all checks pass:** You're ready to proceed to building the TypeScript application (Task 7.4).

**If any checks fail:** Review the relevant sections above and resolve issues before proceeding.

---

### Next Steps After Environment Configuration

Once the `.env` file is properly configured and validated, proceed to:

1. **Build the TypeScript application** (Task 7.4)
   - Compile TypeScript code to JavaScript
   - Prepare the application for production

2. **Start the website-builder service** (Task 7.4)
   - Enable and start the systemd service
   - Verify the application is running
   - Check application logs for any startup errors

**Critical Reminder:** The application will not start without a properly configured `.env` file. All required variables must be set with valid values.

---

### Building and Starting the Application

After configuring environment variables, you're ready to build the TypeScript application and start the website-builder service. This final step in the Application Deployment Phase compiles the TypeScript code to JavaScript and launches the application as a systemd service that runs automatically on server startup.

**Prerequisites:**
- Application code has been transferred to `/opt/website-builder`
- Node.js dependencies have been installed successfully
- `.env` file has been created and configured with all required variables
- Server configuration scripts have been executed (NGINX, UFW, Tailscale, SSL, systemd)

**What this step accomplishes:**
- Compiles TypeScript source code to JavaScript
- Generates production-ready build artifacts in the `dist/` directory
- Starts the website-builder systemd service
- Enables automatic service startup on server boot
- Verifies the application is running correctly

**Estimated Time:** 5-10 minutes

---

#### Building the TypeScript Application

The AI Website Builder is written in TypeScript, which must be compiled to JavaScript before it can run in Node.js. The build process uses the TypeScript compiler (`tsc`) to transpile the code and generate the production build.

**Steps:**

1. **SSH into your Lightsail instance (if not already connected):**

   ```bash
   ssh ubuntu@YOUR_INSTANCE_IP
   ```

2. **Navigate to the application directory:**

   ```bash
   cd /opt/website-builder
   ```

3. **Run the build command:**

   ```bash
   npm run build
   ```

   **What this command does:**
   - Executes the `build` script defined in `package.json`
   - Runs the TypeScript compiler (`tsc`) to compile `.ts` files to `.js` files
   - Performs type checking to catch potential errors
   - Generates source maps for debugging (if configured)
   - Outputs compiled JavaScript files to the `dist/` directory
   - Copies any necessary static assets

   **Expected Output:**

   ```
   > website-builder@1.0.0 build
   > tsc
   
   ```

   **Note:** A successful build typically produces minimal output. If there are no TypeScript errors, the command completes silently or with a brief success message.

   **Expected Duration:**
   - **First-time build:** 10-30 seconds (depending on codebase size)
   - **Subsequent builds:** 5-15 seconds (TypeScript uses incremental compilation)

4. **Verify the build was successful:**

   ```bash
   ls -la dist/
   ```

   **Expected Output:** A directory listing showing compiled JavaScript files:

   ```
   total 48
   drwxrwxr-x  3 ubuntu ubuntu  4096 Jan 15 10:45 .
   drwxrwxr-x 10 ubuntu ubuntu  4096 Jan 15 10:45 ..
   -rw-rw-r--  1 ubuntu ubuntu  2345 Jan 15 10:45 index.js
   -rw-rw-r--  1 ubuntu ubuntu  1234 Jan 15 10:45 server.js
   drwxrwxr-x  2 ubuntu ubuntu  4096 Jan 15 10:45 routes
   drwxrwxr-x  2 ubuntu ubuntu  4096 Jan 15 10:45 services
   ...
   ```

   **Key indicators of successful build:**
   - `dist/` directory exists
   - Contains `.js` files (compiled from `.ts` source files)
   - Directory structure mirrors the `src/` directory
   - File timestamps are recent (just created)

5. **Check for TypeScript compilation errors (if any):**

   If the build fails, you'll see error messages like:

   ```
   src/server.ts:15:10 - error TS2304: Cannot find name 'Express'.
   
   15   const app: Express = express();
              ~~~~~~~
   
   Found 1 error.
   ```

   See the [Troubleshooting Build Failures](#troubleshooting-build-failures) section below for solutions.

---

#### Understanding the Build Process

**What Gets Compiled:**

- **TypeScript files (`.ts`)** → JavaScript files (`.js`)
- **Type definitions** → Removed (types are only for development)
- **Modern JavaScript syntax** → Compatible JavaScript (based on `tsconfig.json` target)
- **Import statements** → Resolved and bundled (if using a bundler)

**Build Configuration:**

The build process is configured in `tsconfig.json`:

```bash
cat tsconfig.json
```

**Key configuration options:**
- `target`: JavaScript version to compile to (e.g., ES2020)
- `module`: Module system to use (e.g., CommonJS, ESNext)
- `outDir`: Output directory for compiled files (typically `dist/`)
- `rootDir`: Source directory (typically `src/`)
- `strict`: Enable strict type checking
- `esModuleInterop`: Enable compatibility with CommonJS modules

**Build Artifacts:**

After a successful build, the `dist/` directory contains:
- Compiled JavaScript files (`.js`)
- Source maps (`.js.map`) for debugging (if enabled)
- Declaration files (`.d.ts`) for type definitions (if enabled)
- Copied static assets (if configured)

**Why Build is Necessary:**

- Node.js cannot directly execute TypeScript files (requires `ts-node` or similar)
- Production deployments should use compiled JavaScript for better performance
- Type checking during build catches errors before runtime
- Compiled code is optimized for production use

---

#### Troubleshooting Build Failures

##### Issue 1: TypeScript Compilation Errors

**Symptom:**
```
src/server.ts:15:10 - error TS2304: Cannot find name 'Express'.

Found 1 error.
```

**Root Cause:** TypeScript type errors in the source code.

**Solution:**

1. **Review the error messages carefully:**
   - Note the file path and line number
   - Understand what type error occurred

2. **Common TypeScript errors and fixes:**

   **Missing type definitions:**
   ```bash
   # Install missing type definitions
   npm install --save-dev @types/express @types/node
   ```

   **Import errors:**
   - Verify import statements are correct
   - Check that imported modules are installed
   - Ensure file paths are correct

   **Type mismatches:**
   - Review the code at the specified line
   - Ensure variable types match expected types
   - Add type annotations if needed

3. **Retry the build:**
   ```bash
   npm run build
   ```

**If errors persist:**
- Review the TypeScript documentation: https://www.typescriptlang.org/docs/
- Check the project's `tsconfig.json` for configuration issues
- Ensure you're using a compatible TypeScript version: `npm list typescript`

---

##### Issue 2: Module Not Found Errors

**Symptom:**
```
Error: Cannot find module '@anthropic-ai/sdk'
```

**Root Cause:** Required dependencies are not installed.

**Solution:**

1. **Verify dependencies are installed:**
   ```bash
   npm list @anthropic-ai/sdk
   ```

2. **Reinstall dependencies if needed:**
   ```bash
   npm install
   ```

3. **Retry the build:**
   ```bash
   npm run build
   ```

---

##### Issue 3: Out of Memory Error

**Symptom:**
```
FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory
```

**Root Cause:** TypeScript compiler ran out of memory (common with large codebases).

**Solution:**

1. **Increase Node.js memory limit:**
   ```bash
   NODE_OPTIONS="--max-old-space-size=4096" npm run build
   ```

   This increases the memory limit to 4GB.

2. **If the issue persists, check available memory:**
   ```bash
   free -h
   ```

3. **Consider upgrading to a larger Lightsail instance** if memory is consistently insufficient.

---

##### Issue 4: Permission Denied Writing to dist/

**Symptom:**
```
Error: EACCES: permission denied, mkdir '/opt/website-builder/dist'
```

**Root Cause:** The current user doesn't have write permissions to create the `dist/` directory.

**Solution:**

1. **Fix ownership:**
   ```bash
   sudo chown -R ubuntu:ubuntu /opt/website-builder
   ```

2. **Retry the build:**
   ```bash
   npm run build
   ```

---

##### Issue 5: tsconfig.json Not Found

**Symptom:**
```
error TS5058: The specified path does not exist: 'tsconfig.json'.
```

**Root Cause:** The `tsconfig.json` file is missing or in the wrong location.

**Solution:**

1. **Verify the file exists:**
   ```bash
   ls -la /opt/website-builder/tsconfig.json
   ```

2. **If missing, check if it was transferred:**
   - If using Git: Ensure the file is committed to the repository
   - If using SCP: Ensure the file was included in the transfer

3. **Create a basic tsconfig.json if needed:**
   ```bash
   cat > tsconfig.json << 'EOF'
   {
     "compilerOptions": {
       "target": "ES2020",
       "module": "commonjs",
       "outDir": "./dist",
       "rootDir": "./src",
       "strict": true,
       "esModuleInterop": true,
       "skipLibCheck": true,
       "forceConsistentCasingInFileNames": true
     },
     "include": ["src/**/*"],
     "exclude": ["node_modules", "dist"]
   }
   EOF
   ```

4. **Retry the build:**
   ```bash
   npm run build
   ```

---

#### Build Verification Checklist

After a successful build, verify the following:

**1. dist/ directory exists:**
```bash
ls -la dist/
```

**Expected Output:** Directory listing with `.js` files.

**2. Main entry point exists:**
```bash
ls -la dist/index.js
```

**Expected Output:** The main application file exists.

**3. Build is recent:**
```bash
stat dist/index.js | grep Modify
```

**Expected Output:** Timestamp shows the file was just created/modified.

**4. No TypeScript errors:**
```bash
echo $?
```

**Expected Output:** `0` (indicates the last command succeeded).

**Checklist:**
- [ ] `npm run build` completed without errors
- [ ] `dist/` directory exists and contains `.js` files
- [ ] Main entry point (`dist/index.js` or similar) exists
- [ ] File timestamps are recent (just created)
- [ ] No TypeScript compilation errors in output

**If all checks pass:** You're ready to start the systemd service.

**If any checks fail:** Review the troubleshooting section above and resolve issues before proceeding.

---

#### Starting the Website-Builder Service

After successfully building the application, you'll start it as a systemd service. The systemd service was configured during the Server Configuration Phase (Task 5.6) and provides automatic startup, restart on failure, and log management.

**Steps:**

1. **Verify the systemd service file exists:**

   ```bash
   sudo systemctl cat website-builder
   ```

   **Expected Output:** The service file content, showing the service configuration.

   **If the service doesn't exist:**
   - Ensure you ran the `configure-systemd.sh` script during Server Configuration Phase
   - Review Task 5.6 documentation and re-run the script if needed

2. **Start the website-builder service:**

   ```bash
   sudo systemctl start website-builder
   ```

   **What this command does:**
   - Starts the website-builder service immediately
   - Runs the application as defined in the service file
   - Redirects output to systemd journal (logs)

   **Expected Output:** No output (command completes silently if successful).

   **Expected Duration:** 2-5 seconds for the service to start.

3. **Verify the service started successfully:**

   ```bash
   sudo systemctl status website-builder
   ```

   **Expected Output:**

   ```
   ● website-builder.service - AI Website Builder Application
        Loaded: loaded (/etc/systemd/system/website-builder.service; disabled; vendor preset: enabled)
        Active: active (running) since Mon 2024-01-15 10:50:23 UTC; 5s ago
      Main PID: 12345 (node)
         Tasks: 11 (limit: 1234)
        Memory: 45.2M
        CGroup: /system.slice/website-builder.service
                └─12345 /usr/bin/node /opt/website-builder/dist/index.js

   Jan 15 10:50:23 ip-172-26-1-1 systemd[1]: Started AI Website Builder Application.
   Jan 15 10:50:24 ip-172-26-1-1 node[12345]: Server listening on port 3000
   Jan 15 10:50:24 ip-172-26-1-1 node[12345]: Environment: production
   ```

   **Key indicators of successful startup:**
   - **Active:** `active (running)` (green text)
   - **Main PID:** Shows a process ID number
   - **Recent logs:** Show "Server listening on port 3000" or similar startup message

   **If the service failed to start:**
   - Status will show `active (failed)` or `inactive (dead)`
   - See the [Troubleshooting Service Startup Failures](#troubleshooting-service-startup-failures) section below

4. **Enable the service to start automatically on boot:**

   ```bash
   sudo systemctl enable website-builder
   ```

   **What this command does:**
   - Creates a symbolic link to enable the service at boot time
   - Ensures the application starts automatically when the server reboots
   - Does not start the service immediately (use `start` for that)

   **Expected Output:**

   ```
   Created symlink /etc/systemd/system/multi-user.target.wants/website-builder.service → /etc/systemd/system/website-builder.service.
   ```

   **Verification:**

   ```bash
   sudo systemctl is-enabled website-builder
   ```

   **Expected Output:** `enabled`

5. **Verify the application is listening on port 3000:**

   ```bash
   sudo ss -tlnp | grep 3000
   ```

   **Expected Output:**

   ```
   LISTEN 0      511          0.0.0.0:3000       0.0.0.0:*    users:(("node",pid=12345,fd=18))
   ```

   **Explanation:**
   - `LISTEN`: The application is listening for connections
   - `0.0.0.0:3000`: Listening on all interfaces, port 3000
   - `node`: The Node.js process
   - `pid=12345`: The process ID

   **Alternative verification command:**

   ```bash
   curl -I http://localhost:3000
   ```

   **Expected Output:**

   ```
   HTTP/1.1 200 OK
   Content-Type: text/html; charset=utf-8
   ...
   ```

   **Note:** The exact response depends on your application's root route handler.

---

#### Viewing Application Logs

Systemd captures all application output (stdout and stderr) in the systemd journal. You can view logs using the `journalctl` command.

**Basic Log Viewing:**

1. **View recent logs:**

   ```bash
   sudo journalctl -u website-builder -n 50
   ```

   **Explanation:**
   - `-u website-builder`: Show logs for the website-builder service only
   - `-n 50`: Show the last 50 lines

   **Expected Output:**

   ```
   Jan 15 10:50:23 ip-172-26-1-1 systemd[1]: Started AI Website Builder Application.
   Jan 15 10:50:24 ip-172-26-1-1 node[12345]: Loading environment variables...
   Jan 15 10:50:24 ip-172-26-1-1 node[12345]: Connecting to Anthropic API...
   Jan 15 10:50:24 ip-172-26-1-1 node[12345]: Server listening on port 3000
   Jan 15 10:50:24 ip-172-26-1-1 node[12345]: Environment: production
   ```

2. **Follow logs in real-time (like tail -f):**

   ```bash
   sudo journalctl -u website-builder -f
   ```

   **Explanation:**
   - `-f`: Follow mode (shows new log entries as they appear)
   - Press `Ctrl+C` to exit

   **Use case:** Monitor the application in real-time to see incoming requests, errors, or other activity.

3. **View logs since a specific time:**

   ```bash
   # Logs from the last hour
   sudo journalctl -u website-builder --since "1 hour ago"
   
   # Logs from today
   sudo journalctl -u website-builder --since today
   
   # Logs from a specific date/time
   sudo journalctl -u website-builder --since "2024-01-15 10:00:00"
   ```

4. **View logs with timestamps:**

   ```bash
   sudo journalctl -u website-builder -n 50 -o short-iso
   ```

   **Explanation:**
   - `-o short-iso`: Output format with ISO 8601 timestamps

5. **View only error messages:**

   ```bash
   sudo journalctl -u website-builder -p err
   ```

   **Explanation:**
   - `-p err`: Priority level "error" and above (includes critical, alert, emergency)

6. **Search logs for specific text:**

   ```bash
   sudo journalctl -u website-builder | grep "error"
   ```

   **Use case:** Find specific error messages or events in the logs.

7. **View logs with full output (no truncation):**

   ```bash
   sudo journalctl -u website-builder -n 50 --no-pager
   ```

   **Explanation:**
   - `--no-pager`: Don't use a pager (less), output directly to terminal
   - Useful for piping to other commands or saving to a file

8. **Export logs to a file:**

   ```bash
   sudo journalctl -u website-builder --since today > /tmp/website-builder-logs.txt
   ```

   **Use case:** Save logs for analysis or sharing with support.

---

#### Understanding Log Output

**Normal Startup Logs:**

```
Jan 15 10:50:23 ip-172-26-1-1 systemd[1]: Started AI Website Builder Application.
Jan 15 10:50:24 ip-172-26-1-1 node[12345]: Loading environment variables...
Jan 15 10:50:24 ip-172-26-1-1 node[12345]: Connecting to Anthropic API...
Jan 15 10:50:24 ip-172-26-1-1 node[12345]: Server listening on port 3000
Jan 15 10:50:24 ip-172-26-1-1 node[12345]: Environment: production
```

**What to look for:**
- ✓ "Started AI Website Builder Application" - systemd started the service
- ✓ "Loading environment variables" - .env file loaded successfully
- ✓ "Server listening on port 3000" - Application is ready to accept connections
- ✓ "Environment: production" - Running in production mode

**Request Logs:**

```
Jan 15 10:51:15 ip-172-26-1-1 node[12345]: GET / 200 45ms
Jan 15 10:51:20 ip-172-26-1-1 node[12345]: POST /api/generate 200 1234ms
```

**What to look for:**
- HTTP method (GET, POST, etc.)
- Request path
- Status code (200 = success, 404 = not found, 500 = server error)
- Response time in milliseconds

**Error Logs:**

```
Jan 15 10:52:30 ip-172-26-1-1 node[12345]: Error: ANTHROPIC_API_KEY is invalid
Jan 15 10:52:30 ip-172-26-1-1 node[12345]:     at validateApiKey (/opt/website-builder/dist/services/anthropic.js:15:11)
```

**What to look for:**
- Error messages and descriptions
- Stack traces showing where the error occurred
- File paths and line numbers for debugging

**Warning Logs:**

```
Jan 15 10:53:00 ip-172-26-1-1 node[12345]: Warning: Monthly token limit approaching (85% used)
```

**What to look for:**
- Non-critical issues that may require attention
- Performance warnings
- Configuration warnings

---

#### Troubleshooting Service Startup Failures

##### Issue 1: Service Failed to Start - Missing .env File

**Symptom:**
```bash
sudo systemctl status website-builder
```

**Output:**
```
● website-builder.service - AI Website Builder Application
     Loaded: loaded (/etc/systemd/system/website-builder.service; enabled; vendor preset: enabled)
     Active: failed (Result: exit-code) since Mon 2024-01-15 10:50:25 UTC; 5s ago
```

**Logs:**
```bash
sudo journalctl -u website-builder -n 20
```

```
Jan 15 10:50:25 ip-172-26-1-1 node[12345]: Error: .env file not found
```

**Root Cause:** The `.env` file doesn't exist or is in the wrong location.

**Solution:**

1. **Verify .env file exists:**
   ```bash
   ls -la /opt/website-builder/.env
   ```

2. **If missing, create it:**
   - Review Task 7.3 (Environment Configuration)
   - Create the `.env` file with all required variables

3. **Restart the service:**
   ```bash
   sudo systemctl restart website-builder
   ```

---

##### Issue 2: Service Failed to Start - Invalid API Key

**Symptom:**

**Logs:**
```
Jan 15 10:50:25 ip-172-26-1-1 node[12345]: Error: Invalid API key provided
```

**Root Cause:** The `ANTHROPIC_API_KEY` in the `.env` file is invalid or expired.

**Solution:**

1. **Verify the API key in Anthropic Console:**
   - Visit: https://console.anthropic.com/settings/keys
   - Check if the key is still active

2. **Update the .env file with a valid key:**
   ```bash
   nano /opt/website-builder/.env
   ```

3. **Restart the service:**
   ```bash
   sudo systemctl restart website-builder
   ```

---

##### Issue 3: Service Failed to Start - Port Already in Use

**Symptom:**

**Logs:**
```
Jan 15 10:50:25 ip-172-26-1-1 node[12345]: Error: listen EADDRINUSE: address already in use :::3000
```

**Root Cause:** Another process is already using port 3000.

**Solution:**

1. **Find the process using port 3000:**
   ```bash
   sudo ss -tlnp | grep 3000
   ```

   **Output:**
   ```
   LISTEN 0      511          0.0.0.0:3000       0.0.0.0:*    users:(("node",pid=11111,fd=18))
   ```

2. **Stop the conflicting process:**
   ```bash
   sudo kill 11111
   ```

   Or if it's another instance of website-builder:
   ```bash
   sudo systemctl stop website-builder
   ```

3. **Start the service again:**
   ```bash
   sudo systemctl start website-builder
   ```

---

##### Issue 4: Service Failed to Start - Module Not Found

**Symptom:**

**Logs:**
```
Jan 15 10:50:25 ip-172-26-1-1 node[12345]: Error: Cannot find module '@anthropic-ai/sdk'
```

**Root Cause:** Dependencies are not installed or the build is incomplete.

**Solution:**

1. **Reinstall dependencies:**
   ```bash
   cd /opt/website-builder
   npm install
   ```

2. **Rebuild the application:**
   ```bash
   npm run build
   ```

3. **Restart the service:**
   ```bash
   sudo systemctl restart website-builder
   ```

---

##### Issue 5: Service Failed to Start - Permission Denied

**Symptom:**

**Logs:**
```
Jan 15 10:50:25 ip-172-26-1-1 node[12345]: Error: EACCES: permission denied, open '/opt/website-builder/.env'
```

**Root Cause:** The service user doesn't have permission to read required files.

**Solution:**

1. **Fix ownership and permissions:**
   ```bash
   sudo chown -R ubuntu:ubuntu /opt/website-builder
   chmod 600 /opt/website-builder/.env
   ```

2. **Verify the service user in the service file:**
   ```bash
   sudo systemctl cat website-builder | grep User
   ```

   **Expected Output:** `User=ubuntu` (or the appropriate user)

3. **Restart the service:**
   ```bash
   sudo systemctl restart website-builder
   ```

---

##### Issue 6: Service Starts But Immediately Crashes

**Symptom:**

**Status:**
```
Active: activating (auto-restart) (Result: exit-code)
```

**Root Cause:** The application is crashing immediately after startup.

**Solution:**

1. **View detailed logs:**
   ```bash
   sudo journalctl -u website-builder -n 100
   ```

2. **Look for error messages or stack traces** that indicate the cause.

3. **Common causes:**
   - Missing environment variables
   - Invalid configuration
   - Database connection failures
   - Uncaught exceptions in startup code

4. **Test the application manually:**
   ```bash
   cd /opt/website-builder
   node dist/index.js
   ```

   This runs the application in the foreground, showing all output directly.

5. **Fix the identified issue** and restart the service.

---

#### Service Management Commands Reference

**Starting and Stopping:**

```bash
# Start the service
sudo systemctl start website-builder

# Stop the service
sudo systemctl stop website-builder

# Restart the service (stop then start)
sudo systemctl restart website-builder

# Reload configuration without restarting (if supported)
sudo systemctl reload website-builder
```

**Enabling and Disabling:**

```bash
# Enable service to start on boot
sudo systemctl enable website-builder

# Disable service from starting on boot
sudo systemctl disable website-builder

# Check if service is enabled
sudo systemctl is-enabled website-builder
```

**Status and Monitoring:**

```bash
# Check service status
sudo systemctl status website-builder

# Check if service is running
sudo systemctl is-active website-builder

# Check if service failed
sudo systemctl is-failed website-builder
```

**Logs:**

```bash
# View recent logs
sudo journalctl -u website-builder -n 50

# Follow logs in real-time
sudo journalctl -u website-builder -f

# View logs since last boot
sudo journalctl -u website-builder -b

# View logs with timestamps
sudo journalctl -u website-builder -o short-iso
```

---

#### Application Deployment Verification Checklist

After completing all steps in the Application Deployment Phase, verify the following:

**Build Verification:**
- [ ] `npm run build` completed without errors
- [ ] `dist/` directory exists and contains compiled JavaScript files
- [ ] No TypeScript compilation errors

**Service Verification:**
- [ ] `sudo systemctl status website-builder` shows `active (running)`
- [ ] Service has a valid process ID (PID)
- [ ] Service is enabled for automatic startup: `sudo systemctl is-enabled website-builder` returns `enabled`

**Application Verification:**
- [ ] Application is listening on port 3000: `sudo ss -tlnp | grep 3000`
- [ ] Logs show successful startup: `sudo journalctl -u website-builder -n 20`
- [ ] No error messages in recent logs
- [ ] Can connect to localhost:3000: `curl -I http://localhost:3000` returns HTTP 200

**Configuration Verification:**
- [ ] `.env` file exists and has correct permissions (600)
- [ ] All required environment variables are set
- [ ] API key is valid (check logs for authentication errors)

**If all checks pass:** The Application Deployment Phase is complete! Proceed to the Post-Deployment Verification Phase (Phase 6) to verify all components are working together correctly.

**If any checks fail:** Review the troubleshooting sections above and resolve issues before proceeding.

---

### Application Deployment Phase Summary

You have successfully completed the Application Deployment Phase! Here's what you accomplished:

1. ✓ **Transferred application code** to the server using Git clone or SCP
2. ✓ **Installed Node.js dependencies** with `npm install`
3. ✓ **Configured environment variables** in the `.env` file
4. ✓ **Built the TypeScript application** with `npm run build`
5. ✓ **Started the website-builder service** with systemd
6. ✓ **Enabled automatic startup** on server boot
7. ✓ **Verified the application is running** and listening on port 3000

**What's Next:**

Proceed to the **Post-Deployment Verification Phase** (Phase 6) to:
- Verify all components (NGINX, UFW, Tailscale, SSL, Application) are working correctly
- Test end-to-end functionality
- Confirm the Builder Interface is accessible via VPN
- Confirm the Static Server is publicly accessible
- Perform security verification

**Important Reminders:**

- The application is currently running and will automatically restart on server reboot
- View logs anytime with: `sudo journalctl -u website-builder -f`
- Restart the service after configuration changes: `sudo systemctl restart website-builder`
- Monitor API usage in the Anthropic Console to manage costs

**Common Post-Deployment Tasks:**

- **Update application code:** `cd /opt/website-builder && git pull && npm install && npm run build && sudo systemctl restart website-builder`
- **View application logs:** `sudo journalctl -u website-builder -f`
- **Check service status:** `sudo systemctl status website-builder`
- **Restart the service:** `sudo systemctl restart website-builder`

---

## Post-Deployment Verification Phase

After completing the application deployment, it's critical to verify that all components are functioning correctly. This phase provides comprehensive health checks for each system component, along with expected outputs and troubleshooting guidance.

**Verification Checklist Overview:**
- [ ] NGINX is serving static content
- [ ] UFW firewall rules are active and correct
- [ ] Tailscale VPN is connected
- [ ] SSL certificates are installed and valid
- [ ] Builder Interface is accessible via VPN
- [ ] Static Server is publicly accessible
- [ ] Builder Interface is NOT publicly accessible (security verification)

**Estimated Time:** 5-10 minutes

---

### Component Health Checks

This section provides commands to verify each infrastructure component is working correctly. Run these checks in sequence to ensure a complete and secure deployment.

#### 1. Verify NGINX is Serving Static Content

NGINX is the web server that serves your generated static HTML pages to the public. This check confirms NGINX is running and properly configured.

**Check NGINX Service Status:**

```bash
sudo systemctl status nginx
```

**Expected Output:**

```
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since [date/time]
       Docs: man:nginx(8)
    Process: [PID] ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: [PID] ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: [PID] (nginx)
      Tasks: [number]
     Memory: [amount]
        CPU: [time]
     CGroup: /system.slice/nginx.service
             ├─[PID] nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
             └─[PID] nginx: worker process
```

**Key Indicators:**
- `Active: active (running)` - NGINX is running
- `enabled` - NGINX will start automatically on boot
- No error messages in the output

**Test NGINX Configuration:**

```bash
sudo nginx -t
```

**Expected Output:**

```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**Verify NGINX is Listening on Correct Ports:**

```bash
sudo ss -tlnp | grep nginx
```

**Expected Output:**

```
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=[PID],fd=6))
LISTEN 0      511          0.0.0.0:443       0.0.0.0:*    users:(("nginx",pid=[PID],fd=7))
LISTEN 0      511             [::]:80           [::]:*    users:(("nginx",pid=[PID],fd=8))
LISTEN 0      511             [::]:443          [::]:*    users:(("nginx",pid=[PID],fd=9))
```

**Key Indicators:**
- NGINX is listening on port 80 (HTTP)
- NGINX is listening on port 443 (HTTPS)
- Both IPv4 (0.0.0.0) and IPv6 (::) are configured

**Test HTTP Response (from the server):**

```bash
curl -I http://localhost
```

**Expected Output:**

```
HTTP/1.1 301 Moved Permanently
Server: nginx
Date: [current date/time]
Content-Type: text/html
Content-Length: 169
Connection: keep-alive
Location: https://yourdomain.com/
```

**Key Indicators:**
- HTTP 301 redirect from HTTP to HTTPS (this is correct and expected)
- Server header shows "nginx"
- Location header redirects to your HTTPS domain

**Test HTTPS Response (from the server):**

```bash
curl -I https://yourdomain.com
```

**Expected Output:**

```
HTTP/2 200
server: nginx
date: [current date/time]
content-type: text/html
content-length: [size]
last-modified: [date/time]
etag: "[etag-value]"
accept-ranges: bytes
```

**Key Indicators:**
- HTTP/2 200 OK status (successful response)
- Server header shows "nginx"
- Content-Type is text/html
- No SSL/TLS errors

**If NGINX Verification Fails:**

**Problem:** NGINX service is not running
```bash
# Check NGINX error logs
sudo journalctl -u nginx -n 50

# Attempt to start NGINX
sudo systemctl start nginx

# If start fails, check configuration
sudo nginx -t
```

**Problem:** NGINX configuration test fails
```bash
# Review the error message from nginx -t
# Common issues:
# - Syntax errors in /etc/nginx/sites-available/default
# - Missing SSL certificate files
# - Incorrect file paths

# Check the main configuration file
sudo nano /etc/nginx/sites-available/default

# After fixing, test again
sudo nginx -t

# Reload NGINX if test passes
sudo systemctl reload nginx
```

**Problem:** NGINX not listening on port 80 or 443
```bash
# Check if another process is using the ports
sudo ss -tlnp | grep ':80\|:443'

# Check firewall rules (covered in next section)
sudo ufw status

# Verify NGINX configuration includes listen directives
sudo grep -r "listen" /etc/nginx/sites-enabled/
```

**Problem:** curl commands fail with connection errors
```bash
# Verify NGINX is running
sudo systemctl status nginx

# Check if firewall is blocking connections
sudo ufw status

# Check NGINX error logs
sudo tail -f /var/log/nginx/error.log

# Test with verbose output
curl -v http://localhost
```

---

#### 2. Verify UFW Firewall Rules are Active

The UFW (Uncomplicated Firewall) protects your server by controlling which ports are accessible from the internet. This check confirms the firewall is active and configured correctly.

**Check UFW Status:**

```bash
sudo ufw status verbose
```

**Expected Output:**

```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
41641/udp                  ALLOW IN    Anywhere
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                ALLOW IN    Anywhere (v6)
443/tcp (v6)               ALLOW IN    Anywhere (v6)
41641/udp (v6)             ALLOW IN    Anywhere (v6)
```

**Key Indicators:**
- `Status: active` - Firewall is enabled and running
- `Default: deny (incoming)` - All incoming connections are blocked by default (secure)
- Port 22 (SSH) is allowed - Required for remote administration
- Port 80 (HTTP) is allowed - Required for web traffic (redirects to HTTPS)
- Port 443 (HTTPS) is allowed - Required for secure web traffic
- Port 41641/udp (Tailscale) is allowed - Required for VPN connectivity
- **Port 3000 is NOT listed** - Builder Interface is not publicly accessible (correct!)

**Verify Firewall is Enabled:**

```bash
sudo ufw status | grep -i status
```

**Expected Output:**

```
Status: active
```

**List Numbered Rules (for detailed inspection):**

```bash
sudo ufw status numbered
```

**Expected Output:**

```
Status: active

     To                         Action      From
     --                         ------      ----
[ 1] 22/tcp                     ALLOW IN    Anywhere
[ 2] 80/tcp                     ALLOW IN    Anywhere
[ 3] 443/tcp                    ALLOW IN    Anywhere
[ 4] 41641/udp                  ALLOW IN    Anywhere
[ 5] 22/tcp (v6)                ALLOW IN    Anywhere (v6)
[ 6] 80/tcp (v6)                ALLOW IN    Anywhere (v6)
[ 7] 443/tcp (v6)               ALLOW IN    Anywhere (v6)
[ 8] 41641/udp (v6)             ALLOW IN    Anywhere (v6)
```

**Verify Port 3000 is NOT Publicly Accessible (Security Check):**

```bash
sudo ufw status | grep 3000
```

**Expected Output:**

```
(no output - port 3000 should NOT be listed)
```

**Key Indicator:** No output means port 3000 is blocked by the firewall, which is correct. The Builder Interface should only be accessible via Tailscale VPN, not from the public internet.

**Test Firewall from External Location (Optional):**

From your local machine (not the server), test that only allowed ports are accessible:

```bash
# Test SSH (should connect)
nc -zv YOUR_SERVER_IP 22

# Test HTTP (should connect)
nc -zv YOUR_SERVER_IP 80

# Test HTTPS (should connect)
nc -zv YOUR_SERVER_IP 443

# Test port 3000 (should be blocked/timeout)
nc -zv -w 5 YOUR_SERVER_IP 3000
```

**Expected Results:**
- Ports 22, 80, 443: Connection succeeds
- Port 3000: Connection times out or is refused (this is correct - port is blocked)

**If UFW Verification Fails:**

**Problem:** UFW status shows "inactive"
```bash
# Enable UFW
sudo ufw enable

# Verify it's now active
sudo ufw status
```

**Problem:** Required ports are missing
```bash
# Add missing rules (example for port 443)
sudo ufw allow 443/tcp

# Verify the rule was added
sudo ufw status
```

**Problem:** Port 3000 is listed (SECURITY ISSUE!)
```bash
# Remove the rule immediately
sudo ufw delete allow 3000/tcp

# Verify it's removed
sudo ufw status | grep 3000

# The Builder Interface should only be accessible via Tailscale VPN
```

**Problem:** UFW is blocking legitimate traffic
```bash
# Check UFW logs for blocked connections
sudo tail -f /var/log/ufw.log

# If you need to allow a specific IP or port, use:
sudo ufw allow from TRUSTED_IP to any port PORT_NUMBER

# Reload UFW after changes
sudo ufw reload
```

**Problem:** Default policy is not "deny incoming"
```bash
# Set correct default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Reload UFW
sudo ufw reload

# Verify
sudo ufw status verbose
```

---

#### 3. Verify Tailscale VPN is Connected

Tailscale provides secure VPN access to the Builder Interface. This check confirms the server is connected to your Tailscale network and accessible via VPN.

**Check Tailscale Service Status:**

```bash
sudo systemctl status tailscaled
```

**Expected Output:**

```
● tailscaled.service - Tailscale node agent
     Loaded: loaded (/lib/systemd/system/tailscaled.service; enabled; vendor preset: enabled)
     Active: active (running) since [date/time]
       Docs: https://tailscale.com/
   Main PID: [PID] (tailscaled)
      Tasks: [number]
     Memory: [amount]
        CPU: [time]
     CGroup: /system.slice/tailscaled.service
             └─[PID] /usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641
```

**Key Indicators:**
- `Active: active (running)` - Tailscale daemon is running
- `enabled` - Tailscale will start automatically on boot
- Port 41641 is configured (Tailscale's default port)

**Check Tailscale Connection Status:**

```bash
sudo tailscale status
```

**Expected Output:**

```
100.x.x.x   your-server-name     your-user@   linux   -
100.y.y.y   your-laptop          your-user@   macOS   active; relay "nyc", tx 1234 rx 5678
```

**Key Indicators:**
- Your server appears in the list with a 100.x.x.x IP address (Tailscale's CGNAT range)
- Connection status shows "active" or "-" (dash means this is the current device)
- Other devices in your Tailscale network are listed

**Get Server's Tailscale IP Address:**

```bash
sudo tailscale ip -4
```

**Expected Output:**

```
100.x.x.x
```

**Key Indicator:** A valid IP address in the 100.x.x.x range (Tailscale's CGNAT space)

**Verify Tailscale Network Connectivity:**

```bash
sudo tailscale ping myip
```

**Expected Output:**

```
pong from your-server-name (100.x.x.x) via [relay or direct] in [time]ms
```

**Key Indicators:**
- Successful pong response
- Shows the connection type (direct or relay)
- Low latency (typically <100ms for direct, <200ms for relay)

**Check Tailscale Configuration:**

```bash
sudo tailscale status --json | jq '.Self'
```

**Expected Output (formatted JSON):**

```json
{
  "ID": "n[node-id]",
  "PublicKey": "[public-key]",
  "HostName": "your-server-name",
  "DNSName": "your-server-name.your-tailnet.ts.net.",
  "OS": "linux",
  "UserID": [user-id],
  "TailscaleIPs": [
    "100.x.x.x",
    "fd7a:xxxx:xxxx:xxxx::x"
  ],
  "Online": true
}
```

**Key Indicators:**
- `"Online": true` - Server is connected to Tailscale
- `TailscaleIPs` contains valid IP addresses
- `DNSName` shows the MagicDNS hostname (if enabled)

**Test VPN Access to Builder Interface (from your local machine):**

First, ensure your local machine is connected to the same Tailscale network:

```bash
# On your local machine (not the server)
tailscale status
```

Then test access to the Builder Interface:

```bash
# Replace 100.x.x.x with your server's Tailscale IP
curl -I http://100.x.x.x:3000
```

**Expected Output:**

```
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: text/html; charset=utf-8
Content-Length: [size]
ETag: "[etag]"
Date: [date/time]
Connection: keep-alive
Keep-Alive: timeout=5
```

**Key Indicators:**
- HTTP 200 OK status (successful response)
- X-Powered-By: Express (Node.js application is running)
- No connection errors

**If Tailscale Verification Fails:**

**Problem:** Tailscale service is not running
```bash
# Start Tailscale
sudo systemctl start tailscaled

# Enable auto-start on boot
sudo systemctl enable tailscaled

# Verify status
sudo systemctl status tailscaled
```

**Problem:** Tailscale status shows "Logged out" or no devices
```bash
# Check if authentication is needed
sudo tailscale status

# If logged out, re-authenticate with your auth key
sudo tailscale up --authkey=tskey-auth-YOUR-KEY-HERE

# Verify connection
sudo tailscale status
```

**Problem:** Cannot get Tailscale IP address
```bash
# Check Tailscale logs
sudo journalctl -u tailscaled -n 50

# Verify Tailscale is authenticated
sudo tailscale status

# Try to bring Tailscale up
sudo tailscale up

# Check firewall allows Tailscale port
sudo ufw status | grep 41641
```

**Problem:** Cannot access Builder Interface via Tailscale IP
```bash
# Verify the application is running
sudo systemctl status website-builder

# Check if the application is listening on port 3000
sudo ss -tlnp | grep :3000

# Test locally on the server first
curl -I http://localhost:3000

# Check application logs
sudo journalctl -u website-builder -n 50

# Verify your local machine is connected to Tailscale
tailscale status  # Run on your local machine
```

**Problem:** Tailscale connection uses relay instead of direct
```bash
# This is not a failure, but direct connections are faster
# Check if UDP port 41641 is accessible from the internet
# Some networks block UDP, forcing relay connections

# Verify firewall allows UDP 41641
sudo ufw status | grep 41641

# Check Tailscale connection details
sudo tailscale status --json | jq '.Peer'
```

---

#### 4. Verify SSL Certificates are Installed and Valid

SSL certificates enable HTTPS encryption for your public website. This check confirms Let's Encrypt certificates are properly installed and valid.

**Check Certificate Files Exist:**

```bash
sudo ls -la /etc/letsencrypt/live/yourdomain.com/
```

**Expected Output:**

```
total 12
drwxr-xr-x 2 root root 4096 [date] .
drwx------ 3 root root 4096 [date] ..
lrwxrwxrwx 1 root root   37 [date] cert.pem -> ../../archive/yourdomain.com/cert1.pem
lrwxrwxrwx 1 root root   38 [date] chain.pem -> ../../archive/yourdomain.com/chain1.pem
lrwxrwxrwx 1 root root   42 [date] fullchain.pem -> ../../archive/yourdomain.com/fullchain1.pem
lrwxrwxrwx 1 root root   40 [date] privkey.pem -> ../../archive/yourdomain.com/privkey1.pem
-rw-r--r-- 1 root root  692 [date] README
```

**Key Indicators:**
- All four certificate files exist: `cert.pem`, `chain.pem`, `fullchain.pem`, `privkey.pem`
- Files are symbolic links to the archive directory (Let's Encrypt's structure)
- Files have appropriate permissions (readable by root)

**Check Certificate Validity and Expiration:**

```bash
sudo certbot certificates
```

**Expected Output:**

```
Found the following certs:
  Certificate Name: yourdomain.com
    Serial Number: [serial-number]
    Key Type: RSA
    Domains: yourdomain.com www.yourdomain.com
    Expiry Date: [date] (VALID: [days] days)
    Certificate Path: /etc/letsencrypt/live/yourdomain.com/fullchain.pem
    Private Key Path: /etc/letsencrypt/live/yourdomain.com/privkey.pem
```

**Key Indicators:**
- Certificate status shows "VALID"
- Expiry date is in the future (typically 90 days from issuance)
- Both `yourdomain.com` and `www.yourdomain.com` are listed in domains
- Certificate paths are correct

**Verify Certificate Details:**

```bash
sudo openssl x509 -in /etc/letsencrypt/live/yourdomain.com/fullchain.pem -noout -text | grep -A 2 "Validity"
```

**Expected Output:**

```
        Validity
            Not Before: [start date]
            Not After : [expiry date]
```

**Key Indicators:**
- "Not Before" date is in the past (certificate is active)
- "Not After" date is in the future (certificate hasn't expired)
- Typically 90 days between "Not Before" and "Not After" (Let's Encrypt standard)

**Test SSL Certificate from Browser Perspective:**

```bash
echo | openssl s_client -servername yourdomain.com -connect yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates
```

**Expected Output:**

```
notBefore=[start date]
notAfter=[expiry date]
```

**Verify Certificate Chain is Complete:**

```bash
echo | openssl s_client -servername yourdomain.com -connect yourdomain.com:443 2>/dev/null | grep -A 5 "Certificate chain"
```

**Expected Output:**

```
Certificate chain
 0 s:CN = yourdomain.com
   i:C = US, O = Let's Encrypt, CN = [Intermediate CA]
 1 s:C = US, O = Let's Encrypt, CN = [Intermediate CA]
   i:C = US, O = Internet Security Research Group, CN = ISRG Root X1
```

**Key Indicators:**
- Certificate chain has at least 2 levels (leaf certificate + intermediate)
- Issuer is Let's Encrypt
- Chain is complete (no missing intermediate certificates)

**Test HTTPS Connection with SSL Verification:**

```bash
curl -vI https://yourdomain.com 2>&1 | grep -E "SSL|certificate|subject"
```

**Expected Output:**

```
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* Server certificate:
*  subject: CN=yourdomain.com
*  start date: [date]
*  expire date: [date]
*  subjectAltName: host "yourdomain.com" matched cert's "yourdomain.com"
*  issuer: C=US; O=Let's Encrypt; CN=[Intermediate CA]
*  SSL certificate verify ok.
```

**Key Indicators:**
- SSL connection established successfully
- TLS version is 1.2 or 1.3 (secure)
- Certificate subject matches your domain
- "SSL certificate verify ok" message appears
- No certificate warnings or errors

**Check Certbot Auto-Renewal Configuration:**

```bash
sudo systemctl status certbot.timer
```

**Expected Output:**

```
● certbot.timer - Run certbot twice daily
     Loaded: loaded (/lib/systemd/system/certbot.timer; enabled; vendor preset: enabled)
     Active: active (waiting) since [date/time]
    Trigger: [next trigger date/time]
   Triggers: ● certbot.service

[date] [hostname] systemd[1]: Started Run certbot twice daily.
```

**Key Indicators:**
- Timer is `active (waiting)` - Auto-renewal is scheduled
- `enabled` - Timer will persist across reboots
- Next trigger date is shown (certbot runs twice daily to check for renewal)

**Test Certificate Renewal (Dry Run):**

```bash
sudo certbot renew --dry-run
```

**Expected Output:**

```
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/yourdomain.com.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Account registered.
Simulating renewal of an existing certificate for yourdomain.com and www.yourdomain.com

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Congratulations, all simulated renewals succeeded:
  /etc/letsencrypt/live/yourdomain.com/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

**Key Indicators:**
- "Congratulations, all simulated renewals succeeded" message
- No errors during the dry run
- Certificate renewal process is working correctly

**If SSL Certificate Verification Fails:**

**Problem:** Certificate files do not exist
```bash
# Check if certbot is installed
certbot --version

# Check certbot logs for errors
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Verify DNS is pointing to your server
dig yourdomain.com +short

# Re-run the SSL configuration script
cd /path/to/infrastructure/scripts
sudo DOMAIN=yourdomain.com SSL_EMAIL=admin@yourdomain.com ./configure-ssl.sh
```

**Problem:** Certificate is expired or expiring soon
```bash
# Check certificate expiry
sudo certbot certificates

# Manually renew certificates
sudo certbot renew

# Reload NGINX to use new certificates
sudo systemctl reload nginx

# Verify new expiry date
sudo certbot certificates
```

**Problem:** Certificate doesn't include www subdomain
```bash
# Re-issue certificate with both domains
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Verify both domains are included
sudo certbot certificates
```

**Problem:** SSL certificate verify fails in curl test
```bash
# Check certificate chain
echo | openssl s_client -servername yourdomain.com -connect yourdomain.com:443 2>/dev/null | grep -A 10 "Certificate chain"

# Verify NGINX is using the correct certificate
sudo nginx -T | grep ssl_certificate

# Check for mixed content or configuration issues
sudo tail -f /var/log/nginx/error.log

# Reload NGINX configuration
sudo systemctl reload nginx
```

**Problem:** Certbot timer is not active
```bash
# Enable and start the timer
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Verify it's running
sudo systemctl status certbot.timer

# Check when next renewal will run
sudo systemctl list-timers | grep certbot
```

**Problem:** Dry run renewal fails
```bash
# Check certbot logs for specific errors
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Common issues:
# - DNS not pointing to server (verify with: dig yourdomain.com)
# - Port 80 blocked by firewall (verify with: sudo ufw status)
# - NGINX not running (verify with: sudo systemctl status nginx)
# - Rate limits hit (wait 1 hour and try again)

# Verify DNS resolution
dig yourdomain.com +short

# Verify port 80 is accessible
curl -I http://yourdomain.com

# Check NGINX configuration
sudo nginx -t
```

---

### Verification Summary

After completing all component health checks, verify the following checklist:

**Component Health Checklist:**
- [ ] NGINX service is active and running
- [ ] NGINX is listening on ports 80 and 443
- [ ] NGINX configuration test passes
- [ ] HTTP requests redirect to HTTPS
- [ ] HTTPS requests return 200 OK
- [ ] UFW firewall is active
- [ ] UFW allows ports 22, 80, 443, and 41641/udp
- [ ] UFW does NOT allow port 3000 (security check)
- [ ] Tailscale service is active and running
- [ ] Server has a valid Tailscale IP address
- [ ] Tailscale status shows "Online"
- [ ] SSL certificate files exist in /etc/letsencrypt/live/
- [ ] SSL certificates are valid and not expired
- [ ] SSL certificates include both root and www domains
- [ ] Certbot auto-renewal timer is active
- [ ] Certbot renewal dry run succeeds

**If all checks pass:** Your infrastructure components are correctly configured and healthy. Proceed to verify application-level functionality in the next section.

**If any checks fail:** Review the troubleshooting guidance for the specific component above. Do not proceed to application verification until all component health checks pass, as application issues may be caused by infrastructure problems.

---

### Application Verification

After verifying that all infrastructure components are healthy, the next step is to verify that the application itself is working correctly. This section tests both the Builder Interface (VPN-protected) and the Static Server (public-facing) to ensure end-to-end functionality.

**Application Verification Checklist:**
- [ ] Builder Interface is accessible via Tailscale VPN
- [ ] Builder Interface returns valid HTML responses
- [ ] Static Server is publicly accessible via HTTPS
- [ ] Static Server serves the default homepage
- [ ] End-to-end workflow: Create a page and verify public access

---

#### 5. Verify Builder Interface is Accessible via VPN

The Builder Interface is the web application where users create and manage website content. It runs on port 3000 and is only accessible via Tailscale VPN for security.

**Prerequisites:**
- Your local machine must be connected to the same Tailscale network as the server
- You must have the server's Tailscale IP address (obtained in the Tailscale verification step above)

**Get Server's Tailscale IP (if you don't have it):**

On the server, run:

```bash
sudo tailscale ip -4
```

**Expected Output:**
```
100.x.x.x
```

**Test Builder Interface Accessibility from Your Local Machine:**

From your local machine (not the server), ensure you're connected to Tailscale:

```bash
# Verify your local machine is connected to Tailscale
tailscale status
```

**Expected Output:**
```
100.x.x.x   your-server-name     your-user@   linux   -
100.y.y.y   your-laptop          your-user@   macOS   active; relay "nyc"
```

**Key Indicator:** Both your server and local machine appear in the Tailscale network.

**Test HTTP Access to Builder Interface:**

Replace `100.x.x.x` with your server's actual Tailscale IP address:

```bash
curl -I http://100.x.x.x:3000
```

**Expected Output:**

```
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: text/html; charset=utf-8
Content-Length: [size]
ETag: "[etag]"
Date: [date/time]
Connection: keep-alive
Keep-Alive: timeout=5
```

**Key Indicators:**
- HTTP 200 OK status (successful response)
- `X-Powered-By: Express` header (Node.js application is running)
- `Content-Type: text/html` (serving HTML content)
- No connection errors or timeouts

**Test Builder Interface in Browser:**

Open your web browser and navigate to:

```
http://100.x.x.x:3000
```

(Replace `100.x.x.x` with your server's Tailscale IP)

**Expected Result:**
- The AI Website Builder interface loads successfully
- You see the onboarding wizard or dashboard (depending on whether initial setup is complete)
- No connection errors or "site can't be reached" messages
- The page loads within a few seconds

**Verify Application is Running on the Server:**

If you have issues accessing the Builder Interface, verify the application is running on the server:

```bash
# Check website-builder service status
sudo systemctl status website-builder
```

**Expected Output:**

```
● website-builder.service - AI Website Builder
     Loaded: loaded (/etc/systemd/system/website-builder.service; enabled; vendor preset: enabled)
     Active: active (running) since [date/time]
   Main PID: [PID] (node)
      Tasks: [number]
     Memory: [amount]
        CPU: [time]
     CGroup: /system.slice/website-builder.service
             └─[PID] node /opt/ai-website-builder/dist/server.js
```

**Key Indicators:**
- `Active: active (running)` - Application is running
- `enabled` - Application will start automatically on boot
- Process is running `node /opt/ai-website-builder/dist/server.js`

**Verify Application is Listening on Port 3000:**

```bash
sudo ss -tlnp | grep :3000
```

**Expected Output:**

```
LISTEN 0      511          0.0.0.0:3000       0.0.0.0:*    users:(("node",pid=[PID],fd=19))
```

**Key Indicator:** Node.js process is listening on port 3000 on all interfaces (0.0.0.0).

**Check Application Logs:**

```bash
sudo journalctl -u website-builder -n 50 --no-pager
```

**Expected Output:**

```
[date/time] [hostname] node[PID]: Server starting...
[date/time] [hostname] node[PID]: Environment: production
[date/time] [hostname] node[PID]: Port: 3000
[date/time] [hostname] node[PID]: Static files directory: /var/www/html
[date/time] [hostname] node[PID]: Server is running on port 3000
```

**Key Indicators:**
- "Server is running on port 3000" message appears
- No error messages or stack traces
- Application started successfully

**If Builder Interface Verification Fails:**

**Problem:** Cannot connect to Builder Interface from local machine

```bash
# On your local machine, verify Tailscale connection
tailscale status

# Verify you can ping the server via Tailscale
tailscale ping your-server-name

# Test if port 3000 is reachable
nc -zv 100.x.x.x 3000

# If connection times out, check server firewall (should allow Tailscale traffic)
# On the server:
sudo ufw status
```

**Problem:** Connection refused on port 3000

```bash
# On the server, check if application is running
sudo systemctl status website-builder

# If not running, start it
sudo systemctl start website-builder

# Check if it's listening on port 3000
sudo ss -tlnp | grep :3000

# If not listening, check application logs for errors
sudo journalctl -u website-builder -n 100 --no-pager
```

**Problem:** Application service fails to start

```bash
# Check detailed error logs
sudo journalctl -u website-builder -n 100 --no-pager

# Common issues:
# - Missing .env file or environment variables
# - Node.js not installed or wrong version
# - Application build failed
# - Port 3000 already in use by another process

# Verify .env file exists and has correct permissions
ls -la /opt/ai-website-builder/.env

# Verify Node.js version
node --version  # Should be >= 18

# Check if another process is using port 3000
sudo ss -tlnp | grep :3000

# Try running the application manually to see errors
cd /opt/ai-website-builder
node dist/server.js
```

**Problem:** Application runs but returns errors

```bash
# Check application logs for specific errors
sudo journalctl -u website-builder -f

# Common issues:
# - Invalid Anthropic API key (check .env file)
# - Database or file system permission issues
# - Missing dependencies

# Verify environment variables are set correctly
sudo systemctl show website-builder --property=Environment

# Test API key validity (if error mentions API authentication)
# See the Anthropic API key verification section in Prerequisites
```

---

#### 6. Verify Static Server is Publicly Accessible

The Static Server (NGINX) serves the generated HTML pages to the public internet via HTTPS. This check confirms that your website is accessible to anyone on the internet.

**Test Public HTTPS Access:**

From your local machine (or any device with internet access), test access to your public domain:

```bash
curl -I https://yourdomain.com
```

(Replace `yourdomain.com` with your actual domain)

**Expected Output:**

```
HTTP/2 200
server: nginx
date: [current date/time]
content-type: text/html
content-length: [size]
last-modified: [date/time]
etag: "[etag-value]"
accept-ranges: bytes
```

**Key Indicators:**
- HTTP/2 200 OK status (successful response)
- `server: nginx` header (NGINX is serving the content)
- `content-type: text/html` (serving HTML content)
- No SSL/TLS errors
- No certificate warnings

**Test WWW Subdomain:**

```bash
curl -I https://www.yourdomain.com
```

**Expected Output:**

```
HTTP/2 200
server: nginx
date: [current date/time]
content-type: text/html
content-length: [size]
last-modified: [date/time]
etag: "[etag-value]"
accept-ranges: bytes
```

**Key Indicator:** Both the root domain and www subdomain return successful responses.

**Test HTTP to HTTPS Redirect:**

```bash
curl -I http://yourdomain.com
```

**Expected Output:**

```
HTTP/1.1 301 Moved Permanently
Server: nginx
Date: [current date/time]
Content-Type: text/html
Content-Length: 169
Connection: keep-alive
Location: https://yourdomain.com/
```

**Key Indicators:**
- HTTP 301 Moved Permanently (redirect status)
- `Location` header points to HTTPS version
- HTTP traffic is automatically redirected to HTTPS (secure)

**Retrieve and Verify Homepage Content:**

```bash
curl -s https://yourdomain.com | head -n 20
```

**Expected Output:**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>[Your Site Title]</title>
    [... additional HTML content ...]
</head>
<body>
    [... page content ...]
</body>
</html>
```

**Key Indicators:**
- Valid HTML5 document structure
- Proper DOCTYPE declaration
- Meta tags for charset and viewport
- Your site's title and content appear
- No error messages or placeholder content

**Test SSL Certificate Validity:**

```bash
curl -vI https://yourdomain.com 2>&1 | grep -E "SSL|certificate|subject"
```

**Expected Output:**

```
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* Server certificate:
*  subject: CN=yourdomain.com
*  start date: [date]
*  expire date: [date]
*  subjectAltName: host "yourdomain.com" matched cert's "yourdomain.com"
*  issuer: C=US; O=Let's Encrypt; CN=[Intermediate CA]
*  SSL certificate verify ok.
```

**Key Indicators:**
- SSL connection established successfully
- Certificate subject matches your domain
- "SSL certificate verify ok" message
- No certificate warnings or errors

**Test Public Access in Browser:**

Open your web browser and navigate to:

```
https://yourdomain.com
```

**Expected Result:**
- Your website loads successfully
- Browser shows a secure connection (padlock icon in address bar)
- No SSL/TLS warnings or errors
- Website content displays correctly
- Page loads within a few seconds

**Verify Default Homepage Exists:**

On the server, check that the default homepage file exists:

```bash
ls -la /var/www/html/index.html
```

**Expected Output:**

```
-rw-r--r-- 1 www-data www-data [size] [date] /var/www/html/index.html
```

**Key Indicators:**
- File exists at `/var/www/html/index.html`
- File is owned by `www-data` (NGINX user)
- File has read permissions (r--r--r--)

**Check Homepage Content:**

```bash
head -n 10 /var/www/html/index.html
```

**Expected Output:**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>[Your Site Title]</title>
    [... additional HTML ...]
```

**Key Indicator:** Valid HTML content exists in the file.

**If Static Server Verification Fails:**

**Problem:** curl returns "Could not resolve host"

```bash
# Verify DNS is configured correctly
dig yourdomain.com +short

# Expected: Your server's public IP address
# If no result, DNS is not configured or hasn't propagated yet

# Check DNS propagation status
# Visit: https://www.whatsmydns.net/#A/yourdomain.com

# If DNS is not configured, return to the DNS Configuration Phase
```

**Problem:** Connection times out or refused

```bash
# Verify NGINX is running
sudo systemctl status nginx

# Verify firewall allows ports 80 and 443
sudo ufw status | grep -E '80|443'

# Verify NGINX is listening on ports 80 and 443
sudo ss -tlnp | grep nginx

# Check NGINX error logs
sudo tail -f /var/log/nginx/error.log

# Test locally on the server first
curl -I http://localhost
```

**Problem:** SSL certificate errors or warnings

```bash
# Verify SSL certificates are installed
sudo certbot certificates

# Check certificate expiry
sudo openssl x509 -in /etc/letsencrypt/live/yourdomain.com/fullchain.pem -noout -dates

# Test SSL configuration
echo | openssl s_client -servername yourdomain.com -connect yourdomain.com:443 2>/dev/null | grep -A 5 "Certificate chain"

# If certificates are missing or expired, re-run SSL configuration
cd /path/to/infrastructure/scripts
sudo DOMAIN=yourdomain.com SSL_EMAIL=admin@yourdomain.com ./configure-ssl.sh
```

**Problem:** 404 Not Found error

```bash
# Verify index.html exists
ls -la /var/www/html/index.html

# If missing, create a default homepage
sudo nano /var/www/html/index.html

# Add basic HTML content:
# <!DOCTYPE html>
# <html><head><title>Welcome</title></head>
# <body><h1>Welcome to AI Website Builder</h1></body></html>

# Set correct permissions
sudo chown www-data:www-data /var/www/html/index.html
sudo chmod 644 /var/www/html/index.html

# Test again
curl -I https://yourdomain.com
```

**Problem:** 502 Bad Gateway or 503 Service Unavailable

```bash
# These errors indicate NGINX is running but can't reach the backend
# For static content, this shouldn't happen

# Check NGINX configuration
sudo nginx -t

# Check NGINX error logs for specific issues
sudo tail -f /var/log/nginx/error.log

# Verify NGINX configuration for static files
sudo cat /etc/nginx/sites-available/default | grep -A 10 "location /"

# Reload NGINX configuration
sudo systemctl reload nginx
```

---

#### 7. Test End-to-End Workflow

The final verification step is to test the complete workflow: creating content in the Builder Interface and verifying it appears on the public Static Server.

**Step 1: Access Builder Interface**

From your local machine (connected to Tailscale VPN), open your browser and navigate to:

```
http://100.x.x.x:3000
```

(Replace `100.x.x.x` with your server's Tailscale IP)

**Step 2: Complete Onboarding (if not already done)**

If this is your first time accessing the Builder Interface:

1. Complete the onboarding wizard with your site information
2. Provide business details, contact information, and branding
3. Submit the onboarding form
4. Wait for the initial site generation to complete (typically 30-60 seconds)

**Step 3: Create or Edit a Page**

1. Navigate to the page editor in the Builder Interface
2. Select an existing page (e.g., "Home") or create a new page
3. Make a simple, identifiable change:
   - Add a unique heading like "Test Update [Current Time]"
   - Or modify existing content with a distinctive phrase
4. Save the changes
5. Wait for the page to be regenerated (typically 10-30 seconds)

**Step 4: Verify Changes Appear on Public Site**

From any device with internet access, open your browser and navigate to:

```
https://yourdomain.com
```

**Expected Result:**
- The changes you made in the Builder Interface appear on the public website
- The unique heading or content you added is visible
- Changes are reflected within 1-2 minutes of saving

**Step 5: Verify with curl (Optional)**

You can also verify the changes using curl:

```bash
curl -s https://yourdomain.com | grep "Test Update"
```

**Expected Output:**

```html
<h1>Test Update [Current Time]</h1>
```

(Or whatever unique content you added)

**Key Indicator:** The content you created in the Builder Interface is now publicly accessible on your domain.

**End-to-End Workflow Verification Checklist:**

- [ ] Builder Interface is accessible via Tailscale VPN
- [ ] Onboarding wizard completes successfully (if applicable)
- [ ] Page editor loads and allows content editing
- [ ] Changes can be saved in the Builder Interface
- [ ] Site generation completes without errors
- [ ] Changes appear on the public website at https://yourdomain.com
- [ ] Public website is accessible from any internet-connected device
- [ ] SSL certificate is valid (browser shows secure connection)
- [ ] Website content displays correctly in browser

**If End-to-End Workflow Fails:**

**Problem:** Changes don't appear on public site

```bash
# On the server, check if files are being generated
ls -la /var/www/html/

# Check file modification times
ls -lt /var/www/html/ | head -n 10

# Verify NGINX is serving from the correct directory
sudo nginx -T | grep "root"

# Check application logs for generation errors
sudo journalctl -u website-builder -n 100 --no-pager | grep -i error

# Verify file permissions
sudo ls -la /var/www/html/
# Files should be owned by www-data or readable by www-data
```

**Problem:** Site generation fails or times out

```bash
# Check application logs for specific errors
sudo journalctl -u website-builder -f

# Common issues:
# - Anthropic API key invalid or rate limited
# - Insufficient disk space
# - File system permission issues

# Verify API key is valid
# Check Anthropic Console: https://console.anthropic.com/settings/usage

# Check disk space
df -h /var/www/html

# Verify application has write permissions to /var/www/html
sudo -u www-data touch /var/www/html/test.txt
sudo rm /var/www/html/test.txt
```

**Problem:** Builder Interface shows errors during editing

```bash
# Check browser console for JavaScript errors (F12 in most browsers)

# Check application logs on server
sudo journalctl -u website-builder -f

# Verify all environment variables are set correctly
sudo cat /opt/ai-website-builder/.env

# Restart the application
sudo systemctl restart website-builder

# Wait 10 seconds and verify it's running
sudo systemctl status website-builder
```

---

### Security Verification

After verifying that all components are functioning correctly, it's critical to perform security checks to ensure the Builder Interface is properly protected and only intended services are exposed to the public internet.

**Security Verification Checklist:**
- [ ] Builder Interface (port 3000) is NOT publicly accessible
- [ ] Only required ports are open to the internet
- [ ] Firewall rules are correctly configured
- [ ] VPN is the only access method for Builder Interface

**Estimated Time:** 3-5 minutes

---

#### 8. Verify Builder Interface is NOT Publicly Accessible

This is the most critical security check. The Builder Interface must NEVER be accessible from the public internet - it should only be accessible via Tailscale VPN.

**Why This Matters:**
- The Builder Interface has administrative capabilities for managing website content
- Public exposure could allow unauthorized access to your website management system
- The VPN provides authentication and encryption for secure access

**Test from External Location (Recommended):**

The most reliable way to verify the Builder Interface is not publicly accessible is to test from a device that is NOT connected to your Tailscale VPN.

**Option A: Test from a different device or network**

From a computer, phone, or tablet that is NOT connected to your Tailscale VPN:

1. Open a web browser
2. Try to access: `http://YOUR_SERVER_PUBLIC_IP:3000`
3. Also try: `http://yourdomain.com:3000`

**Expected Result:**
- Connection times out (browser shows "This site can't be reached" or similar)
- Connection is refused
- Request hangs indefinitely and eventually fails

**SECURITY ISSUE - If you CAN access the Builder Interface:**
- This is a critical security vulnerability
- Port 3000 is exposed to the public internet
- Immediately proceed to the troubleshooting section below to close the port

**Option B: Test using online port checker**

Use an online port scanning service to verify port 3000 is closed:

1. Visit a port checker service such as:
   - https://www.yougetsignal.com/tools/open-ports/
   - https://portchecker.co/
   - https://www.canyouseeme.org/

2. Enter your server's public IP address (or domain name)
3. Enter port: `3000`
4. Click "Check Port" or equivalent

**Expected Result:**
- Port status: "Closed" or "Filtered"
- Message: "Port 3000 is closed" or "I could not see your service on port 3000"

**SECURITY ISSUE - If port shows as "Open":**
- This is a critical security vulnerability
- Immediately proceed to the troubleshooting section below

**Option C: Test using nmap (if installed locally)**

From your local machine (not the server), run:

```bash
# Replace YOUR_SERVER_IP with your server's public IP address
nmap -p 3000 YOUR_SERVER_IP
```

**Expected Output:**

```
Starting Nmap 7.x.x ( https://nmap.org )
Nmap scan report for YOUR_SERVER_IP
Host is up (0.050s latency).

PORT     STATE    SERVICE
3000/tcp filtered unknown

Nmap done: 1 IP address (1 host up) scanned in 2.05 seconds
```

**Key Indicators:**
- Port state is "filtered" or "closed" (NOT "open")
- This confirms the firewall is blocking port 3000

**SECURITY ISSUE - If port state is "open":**
- This is a critical security vulnerability
- Immediately proceed to the troubleshooting section below

**Verify Firewall Configuration on Server:**

On the server, verify that port 3000 is NOT allowed in the firewall:

```bash
sudo ufw status | grep 3000
```

**Expected Output:**

```
(no output - port 3000 should NOT be listed)
```

**Key Indicator:** No output means port 3000 is not explicitly allowed, which is correct.

**Double-Check UFW Default Policy:**

```bash
sudo ufw status verbose | grep Default
```

**Expected Output:**

```
Default: deny (incoming), allow (outgoing), disabled (routed)
```

**Key Indicator:** Default policy is "deny (incoming)" - this blocks all ports that aren't explicitly allowed.

**Verify Application is Only Listening on Localhost (Optional Additional Security):**

For maximum security, you can configure the application to only listen on localhost or the Tailscale interface. Check what the application is currently listening on:

```bash
sudo ss -tlnp | grep :3000
```

**Current Expected Output:**

```
LISTEN 0      511          0.0.0.0:3000       0.0.0.0:*    users:(("node",pid=[PID],fd=19))
```

**Note:** The application listens on `0.0.0.0:3000` (all interfaces), but the firewall blocks external access. This is secure as long as the firewall is properly configured.

**Alternative (More Restrictive) Configuration:**

If you want the application to only listen on the Tailscale interface for additional security:

```
LISTEN 0      511      100.x.x.x:3000       0.0.0.0:*    users:(("node",pid=[PID],fd=19))
```

This would require modifying the application configuration, which is beyond the scope of this deployment guide.

**If Builder Interface IS Publicly Accessible (CRITICAL SECURITY ISSUE):**

If any of the above tests show that port 3000 is accessible from the public internet, take immediate action:

**Step 1: Verify and fix firewall rules**

```bash
# Check current UFW status
sudo ufw status numbered

# If port 3000 is listed, remove it immediately
sudo ufw delete allow 3000/tcp

# Verify it's removed
sudo ufw status | grep 3000

# Ensure UFW is enabled
sudo ufw enable

# Verify default policy is deny incoming
sudo ufw default deny incoming

# Reload UFW
sudo ufw reload
```

**Step 2: Verify the fix**

```bash
# From an external device, test again
# Port 3000 should now be blocked

# Or use online port checker again
# Port should show as "Closed"
```

**Step 3: Check AWS Lightsail firewall**

AWS Lightsail has its own firewall (in addition to UFW). Verify port 3000 is not open there:

1. Log in to AWS Lightsail Console: https://lightsail.aws.amazon.com/
2. Click on your instance
3. Go to the "Networking" tab
4. Review the "Firewall" section
5. Ensure port 3000 is NOT listed in the firewall rules
6. If port 3000 is listed, delete that rule immediately

**Step 4: Verify access via VPN still works**

After closing port 3000 to the public, verify you can still access the Builder Interface via Tailscale VPN:

```bash
# From your local machine (connected to Tailscale)
curl -I http://100.x.x.x:3000
```

**Expected Output:** HTTP 200 OK (access via VPN should still work)

---

#### 9. Verify Only Correct Ports Are Open

In addition to ensuring port 3000 is closed, verify that only the required ports are open to the public internet.

**Required Open Ports:**
- **Port 22 (SSH):** Required for remote server administration
- **Port 80 (HTTP):** Required for web traffic (redirects to HTTPS)
- **Port 443 (HTTPS):** Required for secure web traffic
- **Port 41641/udp (Tailscale):** Required for VPN connectivity

**All Other Ports Should Be Closed**

**Check UFW Firewall Rules:**

```bash
sudo ufw status verbose
```

**Expected Output:**

```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
41641/udp                  ALLOW IN    Anywhere
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                ALLOW IN    Anywhere (v6)
443/tcp (v6)               ALLOW IN    Anywhere (v6)
41641/udp (v6)             ALLOW IN    Anywhere (v6)
```

**Verification Checklist:**
- [ ] Only ports 22, 80, 443, and 41641/udp are listed
- [ ] No other ports are explicitly allowed
- [ ] Default policy is "deny (incoming)"
- [ ] Status is "active"

**If additional ports are open:**

```bash
# List rules with numbers
sudo ufw status numbered

# Delete unwanted rules (replace N with the rule number)
sudo ufw delete N

# Verify the rule is removed
sudo ufw status
```

**Check AWS Lightsail Firewall:**

AWS Lightsail has its own firewall layer that must also be configured correctly.

1. Log in to AWS Lightsail Console: https://lightsail.aws.amazon.com/
2. Click on your instance
3. Go to the "Networking" tab
4. Review the "Firewall" section

**Expected Firewall Rules:**

| Application | Protocol | Port or range |
|-------------|----------|---------------|
| SSH         | TCP      | 22            |
| HTTP        | TCP      | 80            |
| HTTPS       | TCP      | 443           |
| Custom      | UDP      | 41641         |

**Verification Checklist:**
- [ ] Only the four rules above are present
- [ ] No rule exists for port 3000
- [ ] No other custom rules are present

**If additional rules exist:**
- Click the "X" or "Delete" button next to unwanted rules
- Confirm the deletion
- Verify the rule is removed from the list

**Scan All Open Ports (Optional):**

For a comprehensive security audit, you can scan all open ports from an external location:

```bash
# From your local machine (not the server)
# Replace YOUR_SERVER_IP with your server's public IP
nmap -p- YOUR_SERVER_IP
```

**Expected Output:**

```
Starting Nmap 7.x.x ( https://nmap.org )
Nmap scan report for YOUR_SERVER_IP
Host is up (0.050s latency).
Not shown: 65531 filtered ports
PORT      STATE SERVICE
22/tcp    open  ssh
80/tcp    open  http
443/tcp   open  https
41641/udp open  unknown

Nmap done: 1 IP address (1 host up) scanned in 120.45 seconds
```

**Key Indicators:**
- Only ports 22, 80, 443, and 41641 show as "open"
- All other ports show as "filtered" or "closed"
- Port 3000 is NOT in the open ports list

**If unexpected ports are open:**
- Investigate what service is listening on that port: `sudo ss -tlnp | grep :PORT`
- Determine if the service is necessary
- If not necessary, stop the service and block the port with UFW
- If necessary, ensure it's properly secured (authentication, encryption, etc.)

---

#### Security Verification Checklist

After completing all security checks, confirm the following:

**Critical Security Checks:**
- [ ] Builder Interface (port 3000) is NOT accessible from public internet
- [ ] Builder Interface (port 3000) IS accessible via Tailscale VPN
- [ ] Port 3000 is not listed in UFW firewall rules
- [ ] Port 3000 is not listed in AWS Lightsail firewall rules
- [ ] Online port checker confirms port 3000 is closed

**Firewall Configuration:**
- [ ] UFW firewall is active and enabled
- [ ] UFW default policy is "deny (incoming)"
- [ ] Only ports 22, 80, 443, and 41641/udp are allowed in UFW
- [ ] AWS Lightsail firewall only allows ports 22, 80, 443, and 41641/udp
- [ ] No unexpected ports are open to the public internet

**Access Control:**
- [ ] SSH access works (port 22)
- [ ] Public website is accessible via HTTP/HTTPS (ports 80/443)
- [ ] Tailscale VPN is connected (port 41641/udp)
- [ ] Builder Interface is only accessible via VPN, not publicly

**SSL/TLS Security:**
- [ ] HTTPS is working correctly with valid certificate
- [ ] HTTP traffic redirects to HTTPS
- [ ] No SSL/TLS warnings in browser
- [ ] Certificate is from a trusted CA (Let's Encrypt)

**If all security checks pass:** Your deployment is properly secured. The Builder Interface is protected by VPN, and only necessary services are exposed to the public internet.

**If any security checks fail:** Immediately address the security issues using the troubleshooting guidance above. Do not proceed with production use until all security checks pass.

**Security Best Practices:**
- Regularly review firewall rules and open ports
- Monitor SSH access logs for unauthorized attempts: `sudo tail -f /var/log/auth.log`
- Keep all software up to date with security patches
- Use strong SSH keys and disable password authentication
- Consider implementing fail2ban for additional SSH protection
- Regularly review Tailscale connected devices and revoke access for unused devices
- Monitor application logs for suspicious activity
- Set up alerts for unusual traffic patterns or failed authentication attempts

---

### Post-Deployment Verification Summary

After completing all verification steps, confirm the following comprehensive checklist:

**Infrastructure Components:**
- [ ] NGINX service is active and running
- [ ] NGINX is listening on ports 80 and 443
- [ ] NGINX configuration test passes
- [ ] UFW firewall is active with correct rules
- [ ] UFW does NOT allow port 3000 (security check)
- [ ] Tailscale service is active and connected
- [ ] Server has a valid Tailscale IP address
- [ ] SSL certificates are installed and valid
- [ ] Certbot auto-renewal is configured

**Application Components:**
- [ ] Builder Interface is accessible via Tailscale VPN (http://100.x.x.x:3000)
- [ ] Builder Interface returns valid HTML responses
- [ ] website-builder service is active and running
- [ ] Application is listening on port 3000
- [ ] Application logs show no errors

**Public Website:**
- [ ] Static Server is publicly accessible via HTTPS (https://yourdomain.com)
- [ ] WWW subdomain works (https://www.yourdomain.com)
- [ ] HTTP traffic redirects to HTTPS
- [ ] SSL certificate is valid (no browser warnings)
- [ ] Homepage content loads correctly
- [ ] Browser shows secure connection (padlock icon)

**End-to-End Functionality:**
- [ ] Can access Builder Interface via VPN
- [ ] Can create/edit content in Builder Interface
- [ ] Changes save successfully
- [ ] Site generation completes without errors
- [ ] Changes appear on public website
- [ ] Public website is accessible from any internet-connected device

**Security Verification:**
- [ ] Builder Interface is NOT publicly accessible (port 3000 blocked)
- [ ] Only required ports are open (22, 80, 443, 41641/udp)
- [ ] SSL/TLS encryption is working correctly
- [ ] Firewall rules are active and correct

**If all checks pass:** Congratulations! Your AI Website Builder deployment is complete and fully operational. You can now:
- Provide access instructions to end users (see [User Access Instructions](#user-access-instructions))
- Begin using the Builder Interface to create and manage website content
- Monitor the system using the procedures in [Maintenance Procedures](#maintenance-procedures)
- Track costs using the guidance in [Cost Management](#cost-management)

**If any checks fail:** Review the troubleshooting guidance for the specific component or workflow above. Common issues and solutions are provided inline. For additional help, consult the [Troubleshooting Guide](#troubleshooting-guide) section.

**Next Steps:**
1. Share access instructions with end users who need to use the Builder Interface
2. Set up monitoring and alerting for the production system
3. Schedule regular maintenance tasks (updates, backups, certificate renewal checks)
4. Review cost monitoring procedures to stay within budget

---

## User Access Instructions

After successfully deploying the AI Website Builder, end users need to install and configure Tailscale VPN client software to access the Builder Interface. This section provides step-by-step installation instructions for all major platforms, along with configuration guidance and access procedures.

### Overview

The AI Website Builder uses a dual-access model:

1. **Builder Interface (VPN-Protected):**
   - Accessible only through Tailscale VPN
   - Used for content management and AI-powered website generation
   - Accessed at: `http://[tailscale-ip]:3000`
   - Requires Tailscale client installation and network connection

2. **Public Website (Open Access):**
   - Accessible to anyone on the internet
   - Serves the generated HTML pages
   - Accessed at: `https://yourdomain.com`
   - No VPN required

**Why Tailscale VPN?**
- Provides secure, encrypted access to the Builder Interface without exposing it to the public internet
- Eliminates the need for complex firewall rules or VPN server configuration
- Works seamlessly across different networks (home, office, mobile)
- Zero-trust security model with device authentication

### Tailscale Client Installation

To access the Builder Interface, users must install the Tailscale client on their device and connect to the same Tailscale network (tailnet) as the server.

#### Prerequisites

Before installing Tailscale, ensure you have:
- Access to the Tailscale network (tailnet) where the server is connected
- Permission to add devices to the Tailscale network (or an admin can pre-authorize your device)
- Internet connectivity on your device

#### Installation by Platform

##### macOS

**Installation Methods:**

**Option 1: Download from Tailscale Website (Recommended)**

1. Visit the official Tailscale download page:
   - https://tailscale.com/download/mac

2. Click "Download for macOS" to download the installer package

3. Open the downloaded `.pkg` file and follow the installation wizard

4. When prompted, grant the necessary permissions:
   - Allow Tailscale to add VPN configurations
   - Grant network extension permissions in System Preferences

5. Tailscale will appear in your menu bar (top-right corner)

**Option 2: Using Homebrew**

```bash
# Install Tailscale using Homebrew
brew install --cask tailscale

# Launch Tailscale
open -a Tailscale
```

**Option 3: Mac App Store**

1. Open the Mac App Store
2. Search for "Tailscale"
3. Click "Get" or "Install"
4. Launch Tailscale from Applications or Spotlight

**System Requirements:**
- macOS 10.15 (Catalina) or later
- Apple Silicon (M1/M2) and Intel Macs supported

**Verification:**

After installation, you should see the Tailscale icon in your menu bar (looks like a small network diagram).

---

##### Linux

**Installation Methods:**

Tailscale provides native packages for most Linux distributions.

**Ubuntu / Debian:**

```bash
# Add Tailscale's package signing key and repository
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

# Install Tailscale
sudo apt-get update
sudo apt-get install tailscale

# Start Tailscale
sudo tailscale up
```

**Fedora / RHEL / CentOS:**

```bash
# Add Tailscale repository
sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo

# Install Tailscale
sudo dnf install tailscale

# Enable and start Tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
```

**Arch Linux:**

```bash
# Install from official repositories
sudo pacman -S tailscale

# Enable and start Tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
```

**Other Distributions:**

For other Linux distributions, visit: https://tailscale.com/download/linux

**System Requirements:**
- Linux kernel 2.6.23 or later
- systemd (for most distributions)

**Verification:**

```bash
# Check Tailscale status
tailscale status

# Check Tailscale version
tailscale version
```

**Expected Output:**
```
# Health check:
#     - not logged in
```

(This is normal before connecting to your network)

---

##### Windows

**Installation Methods:**

**Option 1: Download from Tailscale Website (Recommended)**

1. Visit the official Tailscale download page:
   - https://tailscale.com/download/windows

2. Click "Download for Windows" to download the installer (`.msi` file)

3. Run the downloaded installer:
   - Double-click the `.msi` file
   - Follow the installation wizard
   - Click "Install" when prompted
   - Grant administrator permissions if requested

4. Tailscale will start automatically after installation

5. Look for the Tailscale icon in your system tray (bottom-right corner, near the clock)

**Option 2: Using Windows Package Manager (winget)**

```powershell
# Install Tailscale using winget
winget install tailscale.tailscale
```

**Option 3: Using Chocolatey**

```powershell
# Install Tailscale using Chocolatey
choco install tailscale
```

**System Requirements:**
- Windows 10 or later
- Windows Server 2019 or later
- Administrator access for installation

**Verification:**

After installation, you should see the Tailscale icon in your system tray. Click it to open the Tailscale menu.

---

##### iOS (iPhone / iPad)

**Installation:**

1. Open the **App Store** on your iOS device

2. Search for "Tailscale"

3. Tap "Get" or the download icon to install the app

4. Once installed, tap "Open" to launch Tailscale

5. The app will guide you through the setup process

**Alternative:** Direct App Store link:
- https://apps.apple.com/us/app/tailscale/id1470499037

**System Requirements:**
- iOS 14.0 or later
- iPadOS 14.0 or later
- Compatible with iPhone, iPad, and iPod touch

**Features:**
- Background connectivity (stays connected even when app is closed)
- On-demand VPN (connects automatically when needed)
- Network extension support for seamless integration

---

##### Android

**Installation:**

1. Open the **Google Play Store** on your Android device

2. Search for "Tailscale"

3. Tap "Install" to download and install the app

4. Once installed, tap "Open" to launch Tailscale

5. The app will guide you through the setup process

**Alternative:** Direct Play Store link:
- https://play.google.com/store/apps/details?id=com.tailscale.ipn

**Alternative Installation (F-Droid):**

Tailscale is also available on F-Droid for users who prefer open-source app stores:
- https://f-droid.org/packages/com.tailscale.ipn/

**System Requirements:**
- Android 6.0 (Marshmallow) or later
- VPN permission (granted during setup)

**Features:**
- Always-on VPN support
- Battery-optimized connectivity
- Works on mobile data and Wi-Fi

---

### Client Configuration Steps

After installing the Tailscale client on your device, follow these steps to connect to the Tailscale network and access the Builder Interface.

#### Step 1: Launch Tailscale

**macOS:**
- Click the Tailscale icon in the menu bar (top-right)
- If Tailscale isn't running, open it from Applications or Spotlight

**Linux:**
- Tailscale runs as a background service
- Use the command line: `sudo tailscale up`
- Or use the GUI if available (depends on distribution)

**Windows:**
- Click the Tailscale icon in the system tray (bottom-right)
- If Tailscale isn't running, search for "Tailscale" in the Start menu

**iOS / Android:**
- Open the Tailscale app from your home screen

#### Step 2: Sign In to Tailscale

When you first launch Tailscale, you'll be prompted to sign in.

1. **Click "Sign In" or "Log In"**

2. **Choose Your Authentication Method:**
   - Tailscale supports multiple identity providers:
     - Google
     - Microsoft
     - GitHub
     - Apple
     - Email (magic link)
   - Choose the same authentication method used by the administrator who set up the Tailscale network

3. **Authenticate:**
   - You'll be redirected to a web browser to complete authentication
   - Sign in with your chosen identity provider
   - Grant Tailscale the necessary permissions

4. **Device Authorization:**
   - After signing in, your device will appear in the Tailscale admin console
   - If the administrator has enabled auto-approval, your device will be automatically authorized
   - Otherwise, an administrator must approve your device before you can connect

**Important Notes:**
- You must use the same Tailscale account/organization as the server
- If you're unsure which account to use, ask the administrator who deployed the server
- The first time you connect, you may need to wait for device approval

#### Step 3: Connect to the Tailscale Network

Once signed in and authorized:

**macOS / Windows:**
1. Click the Tailscale icon in the menu bar / system tray
2. Ensure the toggle is set to "Connected" or click "Connect"
3. You should see a green indicator showing you're connected

**Linux:**
```bash
# Connect to Tailscale network
sudo tailscale up

# Verify connection
tailscale status
```

**Expected Output:**
```
100.x.x.x   your-device-name    user@   linux   -
100.x.x.x   server-name         user@   linux   active; relay "nyc", tx 1234 rx 5678
```

**iOS / Android:**
1. Open the Tailscale app
2. Tap the toggle to connect
3. Grant VPN permissions if prompted
4. You should see "Connected" status

#### Step 4: Verify Connection

After connecting, verify that you can see the server in your Tailscale network:

**macOS / Windows:**
1. Click the Tailscale icon
2. Look for the server in the list of connected devices
3. Note the server's Tailscale IP address (format: `100.x.x.x`)

**Linux:**
```bash
# List all devices in your Tailscale network
tailscale status

# Ping the server (replace with actual server name or IP)
ping 100.x.x.x
```

**iOS / Android:**
1. Open the Tailscale app
2. Tap "Machines" or "Devices"
3. Look for the server in the list
4. Note the server's Tailscale IP address

**If you don't see the server:**
- Ensure you're signed in to the correct Tailscale account
- Verify the server is online and connected to Tailscale
- Check with the administrator that your device has been approved
- Try disconnecting and reconnecting to Tailscale

#### Step 5: Access the Builder Interface

Once connected to the Tailscale network, you can access the Builder Interface:

1. **Find the Server's Tailscale IP Address:**
   - Check the Tailscale client (as described in Step 4)
   - Or ask the administrator for the server's Tailscale IP
   - Format: `100.x.x.x` (e.g., `100.64.0.5`)

2. **Open Your Web Browser:**
   - Use any modern web browser (Chrome, Firefox, Safari, Edge)

3. **Navigate to the Builder Interface:**
   ```
   http://[tailscale-ip]:3000
   ```
   
   **Example:**
   ```
   http://100.64.0.5:3000
   ```

4. **Verify Access:**
   - You should see the AI Website Builder interface
   - If you see a connection error, verify:
     - You're connected to Tailscale (check the client)
     - The IP address is correct
     - The server is running (check with administrator)
     - Port 3000 is accessible (firewall rules)

**Important Notes:**
- The Builder Interface uses HTTP (not HTTPS) over the VPN
- This is secure because Tailscale provides encrypted connectivity
- The interface is only accessible via Tailscale VPN, not from the public internet
- Bookmark the URL for easy access in the future

### Accessing the Public Website

The public website (static pages generated by the Builder Interface) is accessible to anyone on the internet without VPN:

**Public Website URL:**
```
https://yourdomain.com
```

**Example:**
```
https://example.com
https://www.example.com
```

**Key Differences:**
- **No VPN required** - accessible from any device with internet access
- **HTTPS enabled** - secured with Let's Encrypt SSL certificate
- **Read-only** - visitors can view pages but cannot edit content
- **Public access** - anyone can visit the website

**Verification:**

Test public access from any device (even without Tailscale):

```bash
# Test public website access
curl -I https://yourdomain.com
```

**Expected Output:**
```
HTTP/2 200
server: nginx
content-type: text/html
...
```

This confirms the public website is accessible and serving content correctly.

### Summary: VPN-Protected vs Public Access

| Feature | Builder Interface | Public Website |
|---------|------------------|----------------|
| **Access Method** | Tailscale VPN required | Direct internet access |
| **URL Format** | `http://[tailscale-ip]:3000` | `https://yourdomain.com` |
| **Protocol** | HTTP (encrypted by VPN) | HTTPS (SSL certificate) |
| **Purpose** | Content management, AI generation | Serve generated pages to visitors |
| **Who Can Access** | Authorized Tailscale users only | Anyone on the internet |
| **Security** | Protected by VPN authentication | Public, read-only access |

### Connection Troubleshooting

This section provides solutions to common connection issues users may encounter when trying to access the Builder Interface or public website.

#### Tailscale Connection Issues

##### Issue 1: Cannot Connect to Tailscale Network

**Symptoms:**
- Tailscale client shows "Disconnected" or "Not Connected" status
- Cannot see any devices in the Tailscale network
- Authentication fails or times out

**Diagnostic Steps:**

1. **Check Tailscale Service Status:**

   **macOS / Windows:**
   - Check if the Tailscale icon appears in menu bar / system tray
   - Click the icon and verify the status

   **Linux:**
   ```bash
   # Check if Tailscale service is running
   sudo systemctl status tailscaled
   
   # Check Tailscale status
   tailscale status
   ```

2. **Verify Internet Connectivity:**
   ```bash
   # Test basic internet connectivity
   ping -c 4 8.8.8.8
   
   # Test DNS resolution
   nslookup tailscale.com
   ```

3. **Check Tailscale Logs:**

   **macOS:**
   ```bash
   # View Tailscale logs
   log show --predicate 'process == "Tailscale"' --last 5m
   ```

   **Linux:**
   ```bash
   # View Tailscale logs
   sudo journalctl -u tailscaled -n 50
   ```

   **Windows:**
   - Open Event Viewer
   - Navigate to: Windows Logs → Application
   - Filter for "Tailscale" events

**Solutions:**

**Solution A: Restart Tailscale Service**

**macOS:**
```bash
# Quit Tailscale from menu bar, then relaunch from Applications
# Or use command line:
sudo killall Tailscale
open -a Tailscale
```

**Linux:**
```bash
# Restart Tailscale service
sudo systemctl restart tailscaled

# Reconnect to network
sudo tailscale up
```

**Windows:**
- Right-click Tailscale icon in system tray
- Select "Quit Tailscale"
- Relaunch Tailscale from Start menu

**Solution B: Re-authenticate**

If authentication fails:

1. Sign out of Tailscale:
   - Click Tailscale icon → Settings → Sign Out
   - Or on Linux: `sudo tailscale logout`

2. Sign back in:
   - Click Tailscale icon → Sign In
   - Or on Linux: `sudo tailscale up`

3. Complete authentication in the browser window that opens

**Solution C: Check Firewall / Network Restrictions**

Tailscale requires outbound connectivity on specific ports:

- **UDP port 41641** (preferred for direct connections)
- **TCP port 443** (fallback for HTTPS relay)

If you're on a corporate or restricted network:
- Ensure these ports are not blocked by firewall
- Tailscale can work through most firewalls using HTTPS relay
- Contact your network administrator if connectivity issues persist

**Solution D: Update Tailscale Client**

Outdated clients may have connectivity issues:

**macOS:**
```bash
# Update via Homebrew
brew upgrade --cask tailscale

# Or download latest version from https://tailscale.com/download/mac
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get upgrade tailscale

# Fedora/RHEL
sudo dnf upgrade tailscale
```

**Windows:**
- Download the latest installer from https://tailscale.com/download/windows
- Run the installer to upgrade

---

##### Issue 2: Device Not Authorized / Not Visible in Network

**Symptoms:**
- Successfully signed in to Tailscale
- Client shows "Connected" but cannot see server
- Server doesn't appear in device list

**Diagnostic Steps:**

1. **Check Device Authorization Status:**
   - Visit Tailscale admin console: https://login.tailscale.com/admin/machines
   - Look for your device in the list
   - Check if it shows "Needs approval" or "Unauthorized"

2. **Verify Account/Organization:**
   - Ensure you're signed in to the correct Tailscale account
   - The server and your device must be in the same Tailscale network (tailnet)
   - Check the account email/organization name in the Tailscale client

**Solutions:**

**Solution A: Approve Device in Admin Console**

If your device needs approval:

1. Ask the Tailscale network administrator to:
   - Visit https://login.tailscale.com/admin/machines
   - Find your device in the list
   - Click the "..." menu next to your device
   - Select "Approve" or "Authorize"

2. After approval, disconnect and reconnect:
   - Click Tailscale icon → Disconnect
   - Click Tailscale icon → Connect

**Solution B: Use Correct Tailscale Account**

If you're signed in to the wrong account:

1. Sign out of Tailscale:
   - Click Tailscale icon → Settings → Sign Out

2. Sign in with the correct account:
   - Use the same authentication method as the administrator
   - Verify the account email/organization matches the server's network

**Solution C: Check Access Control Lists (ACLs)**

If your device is authorized but still cannot see the server:

1. Ask the administrator to check ACL configuration:
   - Visit https://login.tailscale.com/admin/acls
   - Ensure your device/user has permission to access the server
   - ACLs may restrict which devices can communicate

2. Common ACL issues:
   - Device tags may restrict access
   - User-based rules may not include your account
   - Server may be in a different ACL group

---

##### Issue 3: Cannot Access Builder Interface (Connection Refused)

**Symptoms:**
- Connected to Tailscale successfully
- Can see server in device list
- Browser shows "Connection refused" or "Unable to connect" when accessing `http://[tailscale-ip]:3000`

**Diagnostic Steps:**

1. **Verify Tailscale Connectivity to Server:**
   ```bash
   # Ping the server's Tailscale IP
   ping 100.x.x.x
   
   # Test if port 3000 is reachable (requires netcat/nc)
   nc -zv 100.x.x.x 3000
   ```

   **Expected Output:**
   ```
   Connection to 100.x.x.x 3000 port [tcp/*] succeeded!
   ```

2. **Check if Application is Running on Server:**

   SSH into the server and check:
   ```bash
   # Check if website-builder service is running
   sudo systemctl status website-builder
   
   # Check if port 3000 is listening
   sudo netstat -tlnp | grep 3000
   # Or using ss:
   sudo ss -tlnp | grep 3000
   ```

   **Expected Output:**
   ```
   tcp        0      0 0.0.0.0:3000            0.0.0.0:*               LISTEN      12345/node
   ```

3. **Check Application Logs:**
   ```bash
   # View recent application logs
   sudo journalctl -u website-builder -n 50 --no-pager
   
   # Follow logs in real-time
   sudo journalctl -u website-builder -f
   ```

**Solutions:**

**Solution A: Start the Application Service**

If the service is not running:

```bash
# Start the website-builder service
sudo systemctl start website-builder

# Enable it to start on boot
sudo systemctl enable website-builder

# Verify it's running
sudo systemctl status website-builder
```

**Solution B: Check Firewall Rules on Server**

Ensure UFW allows traffic on port 3000:

```bash
# Check UFW status
sudo ufw status

# If port 3000 is not listed, add it:
sudo ufw allow 3000/tcp

# Reload UFW
sudo ufw reload
```

**Note:** Port 3000 should be accessible via Tailscale but not from the public internet. The UFW configuration should allow Tailscale traffic.

**Solution C: Verify Application Configuration**

Check the application's environment configuration:

```bash
# View .env file (on server)
cat /opt/website-builder/.env

# Ensure PORT is set correctly (should be 3000)
# Ensure other required variables are present
```

If configuration is incorrect, edit the `.env` file and restart the service:

```bash
sudo nano /opt/website-builder/.env
sudo systemctl restart website-builder
```

**Solution D: Check Application Errors**

If the service starts but crashes immediately:

```bash
# Check for errors in logs
sudo journalctl -u website-builder -n 100 --no-pager | grep -i error

# Common issues:
# - Missing environment variables
# - Database connection failures
# - Port already in use
# - Node.js module errors
```

Fix any errors found and restart the service.

---

##### Issue 4: Slow or Intermittent Connection

**Symptoms:**
- Builder Interface loads slowly
- Connection drops intermittently
- High latency when accessing the interface

**Diagnostic Steps:**

1. **Check Tailscale Connection Type:**
   ```bash
   # View detailed Tailscale status
   tailscale status --json | grep -A 5 "relay"
   
   # Or simpler:
   tailscale status
   ```

   Look for connection type:
   - **Direct connection:** Best performance (shows IP addresses)
   - **Relay connection:** Slower (shows "relay" with location)

2. **Test Network Latency:**
   ```bash
   # Ping the server to measure latency
   ping -c 10 100.x.x.x
   
   # Check average latency in output
   ```

3. **Check Local Network Quality:**
   ```bash
   # Test internet speed
   # Use speedtest-cli or visit speedtest.net
   
   # Check for packet loss
   ping -c 100 8.8.8.8 | grep loss
   ```

**Solutions:**

**Solution A: Force Direct Connection**

If Tailscale is using relay (slower):

1. Check if direct connections are blocked:
   - Ensure UDP port 41641 is not blocked on your network
   - Try from a different network (e.g., mobile hotspot) to test

2. Disable relay-only mode (if enabled):
   ```bash
   # On Linux
   sudo tailscale up --accept-routes
   ```

3. Check NAT traversal settings in Tailscale admin console:
   - Visit https://login.tailscale.com/admin/settings
   - Ensure "Enable direct connections" is checked

**Solution B: Improve Local Network**

- Connect to a faster Wi-Fi network or use Ethernet
- Close bandwidth-intensive applications
- Move closer to Wi-Fi router if signal is weak

**Solution C: Use Tailscale Exit Node (Advanced)**

If your local network has restrictions:

1. Set up a Tailscale exit node in a better network location
2. Route traffic through the exit node
3. See Tailscale documentation: https://tailscale.com/kb/1103/exit-nodes/

---

#### Browser Compatibility Issues

##### Supported Browsers

The Builder Interface is compatible with modern web browsers:

**Fully Supported:**
- **Google Chrome** (version 90+)
- **Mozilla Firefox** (version 88+)
- **Microsoft Edge** (version 90+)
- **Safari** (version 14+)
- **Brave** (version 1.24+)

**Partially Supported:**
- Older browser versions may work but are not tested
- Some features may not work in older browsers

**Not Supported:**
- Internet Explorer (all versions)
- Browsers with JavaScript disabled

##### Issue 5: Browser Shows Security Warning for HTTP

**Symptoms:**
- Browser displays "Not Secure" warning in address bar
- Warning about HTTP connection instead of HTTPS

**Explanation:**

This is **expected behavior** and **not a security issue**:

- The Builder Interface uses HTTP (not HTTPS) over the Tailscale VPN
- Tailscale provides end-to-end encryption for all traffic
- The connection is secure even though the browser shows HTTP
- HTTPS is not needed because Tailscale encrypts the entire connection

**Solution:**

You can safely ignore this warning. The connection is encrypted by Tailscale.

**Optional: Enable HTTPS for Builder Interface (Advanced)**

If you prefer HTTPS in the browser:

1. Configure Tailscale HTTPS certificates:
   - Visit https://login.tailscale.com/admin/dns
   - Enable "HTTPS Certificates"
   - Use the Tailscale hostname instead of IP: `https://server-name.tailnet-name.ts.net:3000`

2. Configure the application to use HTTPS:
   - Requires SSL certificate configuration in the Node.js application
   - See application documentation for HTTPS setup

---

##### Issue 6: Browser Blocks Mixed Content

**Symptoms:**
- Some resources fail to load
- Browser console shows "Mixed Content" errors
- Images or scripts don't display

**Explanation:**

Mixed content occurs when an HTTPS page loads HTTP resources. This typically doesn't affect the Builder Interface since it uses HTTP throughout.

**Solution:**

If you encounter mixed content issues:

1. **Check Browser Console:**
   - Open Developer Tools (F12)
   - Check Console tab for specific errors

2. **Ensure Consistent Protocol:**
   - Access Builder Interface using HTTP: `http://[tailscale-ip]:3000`
   - Don't mix HTTP and HTTPS in the same session

3. **Clear Browser Cache:**
   ```
   Chrome/Edge: Ctrl+Shift+Delete (Cmd+Shift+Delete on Mac)
   Firefox: Ctrl+Shift+Delete (Cmd+Shift+Delete on Mac)
   Safari: Cmd+Option+E
   ```

---

##### Issue 7: Browser Caches Old Version

**Symptoms:**
- Changes to the interface don't appear
- Old content is displayed after updates
- Interface looks outdated

**Solution:**

**Hard Refresh the Browser:**

- **Chrome/Edge (Windows/Linux):** Ctrl+Shift+R or Ctrl+F5
- **Chrome/Edge (Mac):** Cmd+Shift+R
- **Firefox (Windows/Linux):** Ctrl+Shift+R or Ctrl+F5
- **Firefox (Mac):** Cmd+Shift+R
- **Safari (Mac):** Cmd+Option+R

**Clear Browser Cache Completely:**

1. Open browser settings
2. Navigate to Privacy/Clear browsing data
3. Select "Cached images and files"
4. Clear cache for "All time"
5. Reload the Builder Interface

---

#### Public Website Connection Issues

##### Issue 8: Cannot Access Public Website (DNS Issues)

**Symptoms:**
- Browser shows "Site can't be reached" or "DNS_PROBE_FINISHED_NXDOMAIN"
- Public website URL doesn't resolve

**Diagnostic Steps:**

1. **Check DNS Resolution:**
   ```bash
   # Check if domain resolves to correct IP
   nslookup yourdomain.com
   
   # Or using dig:
   dig yourdomain.com
   
   # Check www subdomain:
   nslookup www.yourdomain.com
   ```

   **Expected Output:**
   ```
   Name:    yourdomain.com
   Address: [Your Lightsail Instance IP]
   ```

2. **Check DNS Propagation:**
   - Visit: https://www.whatsmydns.net/
   - Enter your domain name
   - Check if DNS has propagated globally

**Solutions:**

**Solution A: Wait for DNS Propagation**

DNS changes can take time to propagate:
- Typical time: 5-30 minutes
- Maximum time: 24-48 hours
- Check propagation status at https://www.whatsmydns.net/

**Solution B: Verify DNS Records**

1. Log in to your domain registrar/DNS provider
2. Verify A records are configured correctly:
   - `@` (root) → Your Lightsail instance IP
   - `www` → Your Lightsail instance IP
3. Ensure there are no conflicting records (CNAME, AAAA)

**Solution C: Flush DNS Cache**

Clear your local DNS cache:

**Windows:**
```powershell
ipconfig /flushdns
```

**macOS:**
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

**Linux:**
```bash
# Ubuntu/Debian (if systemd-resolved is used)
sudo systemd-resolve --flush-caches

# Or restart DNS service
sudo systemctl restart systemd-resolved
```

**Solution D: Use Alternative DNS Server**

Temporarily use a public DNS server to test:

- Google DNS: 8.8.8.8, 8.8.4.4
- Cloudflare DNS: 1.1.1.1, 1.0.0.1

Configure in your network settings or test with:
```bash
nslookup yourdomain.com 8.8.8.8
```

---

##### Issue 9: SSL Certificate Error on Public Website

**Symptoms:**
- Browser shows "Your connection is not private" or "NET::ERR_CERT_AUTHORITY_INVALID"
- SSL certificate warning when accessing `https://yourdomain.com`

**Diagnostic Steps:**

1. **Check SSL Certificate Status:**
   ```bash
   # Test SSL certificate
   curl -vI https://yourdomain.com 2>&1 | grep -A 5 "SSL certificate"
   
   # Or use openssl:
   openssl s_client -connect yourdomain.com:443 -servername yourdomain.com
   ```

2. **Check Certificate Expiration:**
   ```bash
   # Check certificate expiration date
   echo | openssl s_client -connect yourdomain.com:443 -servername yourdomain.com 2>/dev/null | openssl x509 -noout -dates
   ```

**Solutions:**

**Solution A: Wait for Certificate Issuance**

If you just configured SSL:
- Let's Encrypt certificate issuance can take a few minutes
- Check server logs: `sudo journalctl -u nginx -n 50`
- Verify certbot ran successfully: `sudo certbot certificates`

**Solution B: Renew Expired Certificate**

If certificate has expired:

```bash
# SSH into server
ssh ubuntu@your-server-ip

# Renew certificate manually
sudo certbot renew

# Restart NGINX
sudo systemctl restart nginx
```

**Solution C: Verify DNS Before SSL**

SSL certificates require valid DNS:
- Ensure DNS is fully propagated before requesting SSL certificate
- Let's Encrypt validates domain ownership via DNS
- If DNS changed recently, wait for propagation and retry

**Solution D: Check Certificate Configuration**

```bash
# Verify NGINX SSL configuration
sudo nginx -t

# Check certificate files exist
sudo ls -la /etc/letsencrypt/live/yourdomain.com/

# Should show:
# - fullchain.pem
# - privkey.pem
```

If files are missing, re-run the SSL configuration script:
```bash
sudo DOMAIN=yourdomain.com SSL_EMAIL=admin@yourdomain.com /opt/website-builder/infrastructure/scripts/configure-ssl.sh
```

---

#### Diagnostic Commands Summary

Quick reference for troubleshooting connectivity:

**Tailscale Diagnostics:**
```bash
# Check Tailscale status
tailscale status

# Check Tailscale version
tailscale version

# View Tailscale IP addresses
tailscale ip

# Test connectivity to server
ping [server-tailscale-ip]

# Test port 3000 connectivity
nc -zv [server-tailscale-ip] 3000
```

**DNS Diagnostics:**
```bash
# Check DNS resolution
nslookup yourdomain.com
dig yourdomain.com

# Check DNS propagation
# Visit: https://www.whatsmydns.net/

# Flush local DNS cache (OS-specific, see above)
```

**SSL Diagnostics:**
```bash
# Test SSL certificate
curl -vI https://yourdomain.com

# Check certificate details
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com

# Check certificate expiration
echo | openssl s_client -connect yourdomain.com:443 -servername yourdomain.com 2>/dev/null | openssl x509 -noout -dates
```

**Server Diagnostics (SSH required):**
```bash
# Check application service
sudo systemctl status website-builder

# Check application logs
sudo journalctl -u website-builder -n 50

# Check if port 3000 is listening
sudo ss -tlnp | grep 3000

# Check NGINX status
sudo systemctl status nginx

# Check firewall rules
sudo ufw status
```

---

### Installation Summary Checklist

Use this checklist to verify successful Tailscale client installation and configuration:

- [ ] Tailscale client installed on your device
- [ ] Tailscale client launched and running
- [ ] Signed in to Tailscale with correct account
- [ ] Device authorized in Tailscale admin console
- [ ] Connected to Tailscale network (green/connected status)
- [ ] Server visible in Tailscale device list
- [ ] Server's Tailscale IP address identified
- [ ] Builder Interface accessible at `http://[tailscale-ip]:3000`
- [ ] Public website accessible at `https://yourdomain.com`

**Estimated Time:** 5-10 minutes per device for installation and configuration

**Next Steps:** 
- If you encounter connection issues, see the [Troubleshooting Guide](#troubleshooting-guide) section
- For ongoing maintenance and updates, see the [Maintenance Procedures](#maintenance-procedures) section
- To understand costs and monitor usage, see the [Cost Management](#cost-management) section

---

## Troubleshooting Guide

This section provides solutions to common issues that may occur during deployment. Issues are organized by deployment phase to help you quickly find relevant troubleshooting information.

### Infrastructure Deployment Issues

This section covers problems that may occur during Phase 2 (Infrastructure Deployment) when provisioning AWS Lightsail resources using Terraform or CloudFormation.

---

#### Issue: Terraform/CloudFormation Deployment Fails with "Invalid Credentials"

**Symptom:**
```
Error: error configuring Terraform AWS Provider: no valid credential sources for Terraform AWS Provider found
```

Or for CloudFormation:
```
An error occurred (InvalidClientTokenId) when calling the CreateStack operation: The security token included in the request is invalid
```

**Root Cause:**
AWS credentials are not configured correctly or are invalid.

**Diagnostic Commands:**
```bash
# Verify AWS credentials are configured
aws sts get-caller-identity

# Check AWS credential file
cat ~/.aws/credentials

# Check AWS config file
cat ~/.aws/config
```

**Solution:**

1. **Reconfigure AWS credentials:**
   ```bash
   aws configure
   ```
   Enter your Access Key ID and Secret Access Key when prompted.

2. **Verify credentials are correct:**
   - Log in to AWS IAM Console: https://console.aws.amazon.com/iam/
   - Navigate to "Users" → Select your user → "Security credentials"
   - Verify the Access Key ID matches what you configured
   - If the key is incorrect or compromised, create a new access key and reconfigure

3. **Check credential file permissions:**
   ```bash
   # Credentials file should have restricted permissions
   chmod 600 ~/.aws/credentials
   ```

4. **Verify IAM permissions:**
   - Ensure your IAM user has the `AmazonLightsailFullAccess` policy attached
   - Check in IAM Console: Users → [Your User] → Permissions tab

**Prevention:**
- Store AWS credentials securely and never commit them to version control
- Use `aws configure` to set up credentials rather than manually editing files
- Rotate access keys regularly (every 90 days)

---

#### Issue: Terraform/CloudFormation Fails with "Region Not Supported"

**Symptom:**
```
Error: error creating Lightsail Instance: InvalidInput: The specified region is not supported
```

Or:
```
Lightsail is not available in the requested region
```

**Root Cause:**
AWS Lightsail is not available in all AWS regions. You've specified a region where Lightsail is not supported.

**Diagnostic Commands:**
```bash
# List all available Lightsail regions
aws lightsail get-regions

# Check your configured region
aws configure get region
```

**Solution:**

1. **Choose a supported Lightsail region:**

   Common Lightsail-supported regions:
   - `us-east-1` (US East - N. Virginia)
   - `us-east-2` (US East - Ohio)
   - `us-west-2` (US West - Oregon)
   - `eu-west-1` (Europe - Ireland)
   - `eu-west-2` (Europe - London)
   - `eu-central-1` (Europe - Frankfurt)
   - `ap-south-1` (Asia Pacific - Mumbai)
   - `ap-southeast-1` (Asia Pacific - Singapore)
   - `ap-southeast-2` (Asia Pacific - Sydney)
   - `ap-northeast-1` (Asia Pacific - Tokyo)

2. **Update your region configuration:**

   **For Terraform:**
   ```bash
   # Edit terraform.tfvars
   nano terraform/terraform.tfvars
   
   # Update the region variable
   region = "us-east-1"  # Change to a supported region
   ```

   **For CloudFormation:**
   ```bash
   # Update your AWS CLI default region
   aws configure set region us-east-1
   
   # Or specify region in the deployment command
   aws cloudformation create-stack \
     --region us-east-1 \
     --stack-name ai-website-builder \
     ...
   ```

3. **Re-run the deployment:**
   ```bash
   # For Terraform
   terraform plan
   terraform apply
   
   # For CloudFormation
   ./deploy-cloudformation.sh
   ```

**Prevention:**
- Always verify Lightsail availability in your target region before deployment
- Use `aws lightsail get-regions` to check supported regions
- Choose regions close to your target audience for better performance

---

#### Issue: Lightsail Instance Creation Fails with "Insufficient Capacity"

**Symptom:**
```
Error: error creating Lightsail Instance: ServiceException: We currently do not have sufficient capacity in the Availability Zone you requested
```

**Root Cause:**
AWS temporarily doesn't have available capacity for the requested instance type in the selected availability zone.

**Diagnostic Commands:**
```bash
# Check available instance bundles in your region
aws lightsail get-bundles --region us-east-1

# Check current instances
aws lightsail get-instances --region us-east-1
```

**Solution:**

1. **Wait and retry:**
   - Capacity issues are usually temporary
   - Wait 15-30 minutes and retry the deployment
   - AWS typically resolves capacity issues quickly

2. **Try a different availability zone:**

   **For Terraform:**
   ```bash
   # Edit main.tf to specify a different availability zone
   nano terraform/main.tf
   
   # Change the availability_zone parameter
   availability_zone = "us-east-1b"  # Try a different zone (a, b, c, etc.)
   ```

   **For CloudFormation:**
   ```bash
   # Edit lightsail-stack.yaml
   nano cloudformation/lightsail-stack.yaml
   
   # Update the AvailabilityZone parameter
   ```

3. **Try a different instance bundle:**
   - If using a specific instance size, try a different bundle
   - The default `micro_2_0` bundle is usually available
   - Check available bundles: `aws lightsail get-bundles`

4. **Try a different region:**
   - As a last resort, deploy to a different AWS region
   - Follow the "Region Not Supported" solution above

**Prevention:**
- Deploy during off-peak hours when capacity is more available
- Have a backup region identified in case of capacity issues
- Monitor AWS Service Health Dashboard: https://status.aws.amazon.com/

---

#### Issue: Terraform State Lock Error

**Symptom:**
```
Error: Error acquiring the state lock

Error message: ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Path:      terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@hostname
  Version:   1.x.x
  Created:   2024-01-01 12:00:00.000000 UTC
```

**Root Cause:**
Terraform uses state locking to prevent concurrent modifications. A previous Terraform operation was interrupted or is still running, leaving the state locked.

**Diagnostic Commands:**
```bash
# Check if Terraform processes are running
ps aux | grep terraform

# Check the Terraform state file
ls -la terraform/terraform.tfstate*
```

**Solution:**

1. **Verify no Terraform operations are running:**
   ```bash
   # Check for running Terraform processes
   ps aux | grep terraform
   
   # If found, wait for them to complete or kill them if stuck
   kill [process-id]
   ```

2. **Force unlock the state (use with caution):**
   ```bash
   cd terraform
   terraform force-unlock [LOCK_ID]
   ```
   
   Replace `[LOCK_ID]` with the ID shown in the error message.

   **WARNING:** Only use `force-unlock` if you're certain no other Terraform operations are running. Forcing an unlock while another operation is in progress can corrupt your state.

3. **If using remote state (S3 backend):**
   ```bash
   # Check the DynamoDB lock table
   aws dynamodb scan --table-name terraform-state-lock
   
   # Delete the lock item if stuck
   aws dynamodb delete-item \
     --table-name terraform-state-lock \
     --key '{"LockID": {"S": "terraform-state-lock-id"}}'
   ```

**Prevention:**
- Always let Terraform operations complete fully
- Don't interrupt Terraform with Ctrl+C unless necessary
- If you must interrupt, run `terraform force-unlock` afterward
- Use remote state with locking for team environments

---

#### Issue: CloudFormation Stack Creation Fails with "Rollback Complete"

**Symptom:**
```
CREATE_FAILED
Stack creation failed. Stack rolled back to previous state.
```

When checking stack status:
```bash
aws cloudformation describe-stacks --stack-name ai-website-builder
```

Shows: `"StackStatus": "ROLLBACK_COMPLETE"`

**Root Cause:**
One or more resources in the CloudFormation stack failed to create, causing AWS to automatically roll back all changes.

**Diagnostic Commands:**
```bash
# Get detailed stack events to see what failed
aws cloudformation describe-stack-events \
  --stack-name ai-website-builder \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'

# Get stack failure reason
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --query 'Stacks[0].StackStatusReason'
```

**Solution:**

1. **Identify the failed resource:**
   ```bash
   # View stack events in chronological order
   aws cloudformation describe-stack-events \
     --stack-name ai-website-builder \
     --query 'StackEvents[*].[Timestamp,ResourceType,ResourceStatus,ResourceStatusReason]' \
     --output table
   ```

2. **Common failure reasons and fixes:**

   **a) Invalid parameter values:**
   - Check `parameters.json` for typos or invalid values
   - Verify domain name format is correct
   - Ensure API keys are valid and complete

   **b) Resource limits exceeded:**
   - Check AWS service quotas: https://console.aws.amazon.com/servicequotas/
   - Request quota increases if needed

   **c) Insufficient permissions:**
   - Verify IAM user has required permissions
   - Check CloudFormation service role (if using one)

3. **Delete the failed stack:**
   ```bash
   # CloudFormation won't let you update a ROLLBACK_COMPLETE stack
   # You must delete it first
   aws cloudformation delete-stack --stack-name ai-website-builder
   
   # Wait for deletion to complete
   aws cloudformation wait stack-delete-complete --stack-name ai-website-builder
   ```

4. **Fix the issue and redeploy:**
   ```bash
   # After fixing the root cause, redeploy
   ./deploy-cloudformation.sh
   ```

**Prevention:**
- Validate all parameters before deployment
- Test with a small stack first to verify permissions and configuration
- Use CloudFormation change sets to preview changes before applying
- Keep CloudFormation templates under version control

---

#### Issue: AWS Permission Denied Errors

**Symptom:**
```
Error: error creating Lightsail Instance: AccessDeniedException: User: arn:aws:iam::123456789012:user/deployer is not authorized to perform: lightsail:CreateInstances
```

Or:
```
An error occurred (AccessDenied) when calling the CreateStack operation: User is not authorized to perform cloudformation:CreateStack
```

**Root Cause:**
The IAM user or role doesn't have sufficient permissions to perform the requested AWS operations.

**Diagnostic Commands:**
```bash
# Check current IAM identity
aws sts get-caller-identity

# List attached policies for your user
aws iam list-attached-user-policies --user-name [your-username]

# Get policy details
aws iam get-policy --policy-arn [policy-arn]
```

**Solution:**

1. **Verify required permissions:**

   For Lightsail deployment, you need:
   - `AmazonLightsailFullAccess` (managed policy)
   
   For CloudFormation deployment, you also need:
   - `cloudformation:CreateStack`
   - `cloudformation:DescribeStacks`
   - `cloudformation:DeleteStack`
   - `cloudformation:UpdateStack`

2. **Attach the required policy:**

   **Via AWS Console:**
   - Go to IAM Console: https://console.aws.amazon.com/iam/
   - Navigate to Users → [Your User] → Permissions
   - Click "Add permissions" → "Attach existing policies directly"
   - Search for and select `AmazonLightsailFullAccess`
   - Click "Next: Review" → "Add permissions"

   **Via AWS CLI:**
   ```bash
   # Attach Lightsail policy
   aws iam attach-user-policy \
     --user-name [your-username] \
     --policy-arn arn:aws:iam::aws:policy/AmazonLightsailFullAccess
   ```

3. **Verify permissions were added:**
   ```bash
   aws iam list-attached-user-policies --user-name [your-username]
   ```

4. **Retry the deployment:**
   ```bash
   # For Terraform
   terraform apply
   
   # For CloudFormation
   ./deploy-cloudformation.sh
   ```

**Prevention:**
- Set up IAM permissions before starting deployment
- Use IAM policy simulator to test permissions: https://policysim.aws.amazon.com/
- Follow the principle of least privilege (only grant necessary permissions)
- Document required permissions in your deployment runbook

---

#### Issue: Lightsail Instance Stuck in "Pending" State

**Symptom:**
Instance creation appears to succeed, but the instance remains in "pending" state for more than 5 minutes.

```bash
aws lightsail get-instance --instance-name ai-website-builder
```

Shows: `"state": {"name": "pending"}`

**Root Cause:**
AWS is taking longer than usual to provision the instance, or there's an issue with the instance initialization.

**Diagnostic Commands:**
```bash
# Check instance state
aws lightsail get-instance --instance-name ai-website-builder \
  --query 'instance.state.name'

# Check instance creation time
aws lightsail get-instance --instance-name ai-website-builder \
  --query 'instance.createdAt'

# View instance details
aws lightsail get-instance --instance-name ai-website-builder
```

**Solution:**

1. **Wait longer:**
   - Instance provisioning typically takes 2-5 minutes
   - In rare cases, it can take up to 10-15 minutes
   - Wait at least 10 minutes before taking action

2. **Check AWS Service Health:**
   - Visit: https://status.aws.amazon.com/
   - Look for issues in your region
   - Check Lightsail service status

3. **If stuck for more than 15 minutes, delete and recreate:**
   ```bash
   # Delete the stuck instance
   aws lightsail delete-instance --instance-name ai-website-builder
   
   # Wait for deletion
   sleep 60
   
   # Verify deletion
   aws lightsail get-instances
   
   # Redeploy
   terraform apply  # or ./deploy-cloudformation.sh
   ```

4. **Try a different availability zone or region:**
   - Follow the solutions in "Insufficient Capacity" section above

**Prevention:**
- Deploy during off-peak hours
- Monitor AWS Service Health before deployment
- Have a rollback plan ready

---

#### Issue: Cannot Retrieve Terraform/CloudFormation Outputs

**Symptom:**
After successful deployment, you cannot retrieve the instance IP address or other outputs.

**For Terraform:**
```bash
terraform output
```

Shows: `No outputs found.`

**For CloudFormation:**
```bash
aws cloudformation describe-stacks --stack-name ai-website-builder
```

Shows no outputs or empty outputs section.

**Root Cause:**
Outputs are not defined in the Terraform/CloudFormation configuration, or the deployment didn't complete successfully.

**Diagnostic Commands:**
```bash
# For Terraform - check if outputs are defined
cat terraform/outputs.tf

# For Terraform - check state file
terraform show

# For CloudFormation - check stack status
aws cloudformation describe-stacks --stack-name ai-website-builder \
  --query 'Stacks[0].StackStatus'
```

**Solution:**

1. **Verify deployment completed successfully:**

   **For Terraform:**
   ```bash
   cd terraform
   terraform show
   ```
   
   Look for the Lightsail instance resource in the output.

   **For CloudFormation:**
   ```bash
   aws cloudformation describe-stacks --stack-name ai-website-builder \
     --query 'Stacks[0].StackStatus'
   ```
   
   Should show: `CREATE_COMPLETE`

2. **If outputs are missing, retrieve instance IP manually:**

   ```bash
   # Get instance IP address
   aws lightsail get-instance --instance-name ai-website-builder \
     --query 'instance.publicIpAddress' \
     --output text
   ```

3. **For Terraform - refresh outputs:**
   ```bash
   cd terraform
   terraform refresh
   terraform output
   ```

4. **For CloudFormation - check template has outputs defined:**
   ```bash
   # View the template
   cat cloudformation/lightsail-stack.yaml
   ```
   
   Ensure the `Outputs:` section is present and correctly formatted.

**Prevention:**
- Always define outputs in your infrastructure templates
- Test output retrieval immediately after deployment
- Document manual commands to retrieve critical information

---

#### Issue: Deployment Succeeds but Cannot SSH to Instance

**Symptom:**
Infrastructure deployment completes successfully, but you cannot connect to the instance via SSH.

```bash
ssh -i ~/.ssh/lightsail-key.pem ubuntu@[instance-ip]
```

Shows:
```
Connection timed out
```

Or:
```
Permission denied (publickey)
```

**Root Cause:**
- SSH key is not configured correctly
- Security group/firewall rules are blocking SSH (port 22)
- Instance is not fully initialized
- Wrong username or IP address

**Diagnostic Commands:**
```bash
# Verify instance is running
aws lightsail get-instance-state --instance-name ai-website-builder

# Get instance IP address
aws lightsail get-instance --instance-name ai-website-builder \
  --query 'instance.publicIpAddress' \
  --output text

# Check if port 22 is open
nc -zv [instance-ip] 22

# Download the SSH key from Lightsail
aws lightsail download-default-key-pair \
  --query 'privateKeyBase64' \
  --output text | base64 --decode > ~/.ssh/lightsail-key.pem
chmod 600 ~/.ssh/lightsail-key.pem
```

**Solution:**

1. **Verify instance is running:**
   ```bash
   aws lightsail get-instance-state --instance-name ai-website-builder
   ```
   
   Should show: `{"state": {"name": "running"}}`
   
   If not running, wait a few minutes for initialization.

2. **Download the correct SSH key:**
   ```bash
   # Download default Lightsail key pair
   aws lightsail download-default-key-pair \
     --query 'privateKeyBase64' \
     --output text | base64 --decode > ~/.ssh/lightsail-key.pem
   
   # Set correct permissions
   chmod 600 ~/.ssh/lightsail-key.pem
   ```

3. **Use the correct username:**
   - For Ubuntu instances: `ubuntu`
   - For Amazon Linux: `ec2-user`
   - For Debian: `admin`
   
   ```bash
   ssh -i ~/.ssh/lightsail-key.pem ubuntu@[instance-ip]
   ```

4. **Check firewall rules:**
   ```bash
   # Verify port 22 is open in Lightsail firewall
   aws lightsail get-instance-port-states --instance-name ai-website-builder
   ```
   
   Ensure port 22 is listed with `fromPort: 22, toPort: 22, protocol: tcp`

5. **Wait for instance initialization:**
   - New instances may take 2-5 minutes to fully initialize SSH
   - Wait and retry every 30 seconds

6. **Use Lightsail browser-based SSH (alternative):**
   - Go to: https://lightsail.aws.amazon.com/
   - Click on your instance
   - Click "Connect using SSH" button
   - This provides a browser-based terminal

**Prevention:**
- Download and test SSH key immediately after instance creation
- Verify firewall rules include port 22
- Document the correct username for your instance OS
- Keep SSH keys secure and backed up

---

### Log Files and Diagnostic Information

When troubleshooting infrastructure issues, the following log locations and commands are helpful:

**Terraform Logs:**
```bash
# Enable detailed Terraform logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log

# Run Terraform with logging
terraform apply

# View logs
cat terraform-debug.log
```

**CloudFormation Logs:**
```bash
# View stack events (most useful for troubleshooting)
aws cloudformation describe-stack-events \
  --stack-name ai-website-builder \
  --max-items 50

# View stack events in table format
aws cloudformation describe-stack-events \
  --stack-name ai-website-builder \
  --query 'StackEvents[*].[Timestamp,ResourceType,ResourceStatus,ResourceStatusReason]' \
  --output table
```

**AWS CLI Debug Mode:**
```bash
# Enable AWS CLI debug output
aws lightsail get-instances --debug 2>&1 | tee aws-debug.log
```

**Lightsail Instance Logs (after SSH access):**
```bash
# System logs
sudo journalctl -xe

# Cloud-init logs (instance initialization)
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log
```

---

### Rollback Procedures for Failed Infrastructure Deployment

If infrastructure deployment fails and you need to start over:

**For Terraform:**

1. **Destroy all resources:**
   ```bash
   cd terraform
   terraform destroy
   ```
   
   Type `yes` when prompted.

2. **Verify all resources are deleted:**
   ```bash
   aws lightsail get-instances
   ```
   
   Should show no instances or empty list.

3. **Clean up Terraform state (if needed):**
   ```bash
   rm -f terraform.tfstate terraform.tfstate.backup
   rm -rf .terraform/
   ```

4. **Start fresh:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

**For CloudFormation:**

1. **Delete the stack:**
   ```bash
   aws cloudformation delete-stack --stack-name ai-website-builder
   ```

2. **Wait for deletion to complete:**
   ```bash
   aws cloudformation wait stack-delete-complete --stack-name ai-website-builder
   ```
   
   Or monitor status:
   ```bash
   aws cloudformation describe-stacks --stack-name ai-website-builder \
     --query 'Stacks[0].StackStatus'
   ```

3. **Verify deletion:**
   ```bash
   aws lightsail get-instances
   ```

4. **Redeploy:**
   ```bash
   cd infrastructure/cloudformation
   ./deploy-cloudformation.sh
   ```

**Manual Cleanup (if automated cleanup fails):**

```bash
# List all Lightsail instances
aws lightsail get-instances

# Delete specific instance
aws lightsail delete-instance --instance-name ai-website-builder

# List all Lightsail static IPs
aws lightsail get-static-ips

# Release static IP (if created)
aws lightsail release-static-ip --static-ip-name [static-ip-name]

# List all key pairs
aws lightsail get-key-pairs

# Delete key pair (if needed)
aws lightsail delete-key-pair --key-pair-name [key-pair-name]
```

**Important Notes:**
- Always verify resources are deleted before redeploying to avoid conflicts
- Deleting infrastructure does not delete your domain name or DNS records
- SSH keys may need to be re-downloaded after recreating instances
- CloudFormation automatically cleans up all resources it created during rollback

---

### Server Configuration Issues

This section covers problems that may occur during Phase 4 (Server Configuration) when running configuration scripts on the Lightsail instance.

---

#### Issue: SSH Connection Refused or Times Out

**Symptom:**
```bash
ssh -i ~/.ssh/lightsail-key.pem ubuntu@[instance-ip]
```

Shows:
```
ssh: connect to host [instance-ip] port 22: Connection refused
```

Or:
```
ssh: connect to host [instance-ip] port 22: Connection timed out
```

**Root Cause:**
- Instance is not fully initialized
- Firewall is blocking SSH access
- Wrong IP address
- SSH service is not running on the instance
- Network connectivity issues

**Diagnostic Commands:**
```bash
# Verify instance is running
aws lightsail get-instance-state --instance-name ai-website-builder

# Get correct IP address
aws lightsail get-instance --instance-name ai-website-builder \
  --query 'instance.publicIpAddress' \
  --output text

# Test network connectivity
ping [instance-ip]

# Test if port 22 is reachable
nc -zv [instance-ip] 22

# Check Lightsail firewall rules
aws lightsail get-instance-port-states --instance-name ai-website-builder
```

**Solution:**

1. **Wait for instance initialization:**
   - New instances take 2-5 minutes to fully boot and start SSH
   - Wait and retry every 30 seconds
   ```bash
   # Wait and retry
   sleep 30
   ssh -i ~/.ssh/lightsail-key.pem ubuntu@[instance-ip]
   ```

2. **Verify correct IP address:**
   ```bash
   # Get the current IP
   aws lightsail get-instance --instance-name ai-website-builder \
     --query 'instance.publicIpAddress' \
     --output text
   ```

3. **Check Lightsail firewall rules:**
   ```bash
   # Verify port 22 is open
   aws lightsail get-instance-port-states --instance-name ai-website-builder
   ```
   
   If port 22 is not open, add it:
   ```bash
   aws lightsail open-instance-public-ports \
     --instance-name ai-website-builder \
     --port-info fromPort=22,toPort=22,protocol=tcp
   ```

4. **Use Lightsail browser-based SSH:**
   - Go to: https://lightsail.aws.amazon.com/
   - Click on your instance
   - Click "Connect using SSH"
   - This bypasses local SSH issues

5. **Reboot the instance if SSH service is stuck:**
   ```bash
   aws lightsail reboot-instance --instance-name ai-website-builder
   
   # Wait for reboot
   sleep 60
   
   # Retry SSH
   ssh -i ~/.ssh/lightsail-key.pem ubuntu@[instance-ip]
   ```

**Prevention:**
- Always wait for instance to fully initialize before attempting SSH
- Verify firewall rules immediately after instance creation
- Keep SSH keys secure and accessible
- Document the correct IP address after deployment

---

#### Issue: SSH "Permission Denied (publickey)" Error

**Symptom:**
```bash
ssh -i ~/.ssh/lightsail-key.pem ubuntu@[instance-ip]
```

Shows:
```
Permission denied (publickey).
```

**Root Cause:**
- Wrong SSH key file
- Incorrect SSH key permissions
- Wrong username
- SSH key not properly configured on instance

**Diagnostic Commands:**
```bash
# Check SSH key file permissions
ls -la ~/.ssh/lightsail-key.pem

# Verify SSH key format
head -n 1 ~/.ssh/lightsail-key.pem

# Test SSH with verbose output
ssh -v -i ~/.ssh/lightsail-key.pem ubuntu@[instance-ip]
```

**Solution:**

1. **Download the correct SSH key:**
   ```bash
   # Download default Lightsail key pair
   aws lightsail download-default-key-pair \
     --query 'privateKeyBase64' \
     --output text | base64 --decode > ~/.ssh/lightsail-key.pem
   ```

2. **Set correct permissions:**
   ```bash
   # SSH requires strict permissions on key files
   chmod 600 ~/.ssh/lightsail-key.pem
   
   # Verify permissions
   ls -la ~/.ssh/lightsail-key.pem
   ```
   
   Should show: `-rw-------` (600 permissions)

3. **Use the correct username:**
   - For Ubuntu instances: `ubuntu`
   - For Amazon Linux: `ec2-user`
   - For Debian: `admin`
   
   ```bash
   # Try with ubuntu user
   ssh -i ~/.ssh/lightsail-key.pem ubuntu@[instance-ip]
   ```

4. **Verify SSH key format:**
   ```bash
   # Key should start with:
   head -n 1 ~/.ssh/lightsail-key.pem
   ```
   
   Should show: `-----BEGIN RSA PRIVATE KEY-----` or similar

5. **Use SSH agent (alternative):**
   ```bash
   # Add key to SSH agent
   eval $(ssh-agent)
   ssh-add ~/.ssh/lightsail-key.pem
   
   # Connect without -i flag
   ssh ubuntu@[instance-ip]
   ```

**Prevention:**
- Download and test SSH key immediately after instance creation
- Store SSH keys securely with correct permissions
- Document the correct username for your instance OS
- Keep backup copies of SSH keys in secure storage

---

#### Issue: UFW Firewall Blocks SSH After Configuration

**Symptom:**
After running `configure-ufw.sh`, you lose SSH connection and cannot reconnect.

```bash
ssh -i ~/.ssh/lightsail-key.pem ubuntu@[instance-ip]
```

Shows:
```
ssh: connect to host [instance-ip] port 22: Connection timed out
```

**Root Cause:**
The UFW firewall was enabled without allowing SSH (port 22), blocking all SSH connections including your current session.

**Diagnostic Commands:**
```bash
# If you still have an active SSH session:
sudo ufw status

# Check if SSH is allowed
sudo ufw status | grep 22
```

**Solution:**

1. **If you still have an active SSH session:**
   ```bash
   # Allow SSH immediately
   sudo ufw allow 22/tcp
   
   # Verify rule was added
   sudo ufw status
   ```

2. **If you lost SSH access, use Lightsail browser-based SSH:**
   - Go to: https://lightsail.aws.amazon.com/
   - Click on your instance
   - Click "Connect using SSH"
   - This uses a different connection method that bypasses UFW
   
   Then fix the firewall:
   ```bash
   # Allow SSH
   sudo ufw allow 22/tcp
   
   # Verify
   sudo ufw status
   ```

3. **If browser SSH doesn't work, disable UFW via Lightsail console:**
   ```bash
   # Use Lightsail browser SSH to run:
   sudo ufw disable
   
   # Then reconfigure properly:
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw allow 41641/udp
   sudo ufw --force enable
   ```

4. **Verify the configure-ufw.sh script includes SSH:**
   ```bash
   # The script should include:
   cat infrastructure/scripts/configure-ufw.sh
   ```
   
   Should contain:
   ```bash
   sudo ufw allow 22/tcp    # SSH
   ```

**Prevention:**
- Always allow SSH (port 22) before enabling UFW
- Test firewall rules before disconnecting from SSH
- Keep Lightsail browser-based SSH as a backup access method
- Review firewall configuration scripts before running them

---

#### Issue: DNS Not Resolving to Lightsail Instance

**Symptom:**
```bash
dig yourdomain.com
```

Shows wrong IP address or no A record, or:
```
;; ANSWER SECTION:
yourdomain.com.  300  IN  A  [wrong-ip-address]
```

**Root Cause:**
- DNS records not configured correctly
- DNS changes not yet propagated
- Wrong IP address in DNS records
- DNS cached by local resolver

**Diagnostic Commands:**
```bash
# Check DNS resolution
dig yourdomain.com

# Check with specific DNS server (Google DNS)
dig @8.8.8.8 yourdomain.com

# Check with specific DNS server (Cloudflare DNS)
dig @1.1.1.1 yourdomain.com

# Check www subdomain
dig www.yourdomain.com

# Get Lightsail instance IP
aws lightsail get-instance --instance-name ai-website-builder \
  --query 'instance.publicIpAddress' \
  --output text

# Check DNS propagation status
# Visit: https://www.whatsmydns.net/#A/yourdomain.com
```

**Solution:**

1. **Verify correct IP address:**
   ```bash
   # Get your Lightsail instance IP
   INSTANCE_IP=$(aws lightsail get-instance --instance-name ai-website-builder \
     --query 'instance.publicIpAddress' \
     --output text)
   
   echo "Instance IP: $INSTANCE_IP"
   
   # Check what DNS returns
   dig +short yourdomain.com
   ```
   
   These should match.

2. **Update DNS records at your registrar:**
   - Log in to your domain registrar (Namecheap, GoDaddy, Route53, etc.)
   - Navigate to DNS settings for your domain
   - Update or create A records:
     - **Host:** `@` (root domain) → **Value:** `[instance-ip]`
     - **Host:** `www` → **Value:** `[instance-ip]`
   - Save changes

3. **Wait for DNS propagation:**
   - DNS changes typically propagate in 5-30 minutes
   - Can take up to 48 hours in rare cases
   - Check propagation status: https://www.whatsmydns.net/
   
   ```bash
   # Check every 2 minutes
   watch -n 120 "dig +short yourdomain.com"
   ```

4. **Clear local DNS cache:**
   
   **macOS:**
   ```bash
   sudo dscacheutil -flushcache
   sudo killall -HUP mDNSResponder
   ```
   
   **Linux:**
   ```bash
   sudo systemd-resolve --flush-caches
   ```
   
   **Windows:**
   ```powershell
   ipconfig /flushdns
   ```

5. **Use alternative DNS servers for testing:**
   ```bash
   # Test with Google DNS
   dig @8.8.8.8 yourdomain.com
   
   # Test with Cloudflare DNS
   dig @1.1.1.1 yourdomain.com
   ```

6. **Verify DNS records are correct format:**
   - A records should point to IP addresses (not domain names)
   - TTL (Time To Live) should be reasonable (300-3600 seconds)
   - No CNAME records on root domain (use A record instead)

**Prevention:**
- Set low TTL (300 seconds) before making DNS changes
- Verify IP address before updating DNS
- Test DNS resolution before proceeding to SSL configuration
- Document DNS configuration for future reference

---

#### Issue: SSL Certificate Acquisition Fails with "DNS Validation Failed"

**Symptom:**
```bash
sudo DOMAIN=yourdomain.com SSL_EMAIL=admin@yourdomain.com ./configure-ssl.sh
```

Shows:
```
Certbot failed to authenticate some domains (authenticator: webroot)
Challenge failed for domain yourdomain.com
```

Or:
```
Detail: DNS problem: NXDOMAIN looking up A for yourdomain.com
```

**Root Cause:**
- DNS records not configured or not propagated
- Domain not pointing to the correct IP address
- NGINX not serving the ACME challenge files
- Firewall blocking HTTP (port 80)

**Diagnostic Commands:**
```bash
# Verify DNS resolution
dig +short yourdomain.com

# Check if domain resolves to instance IP
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
DOMAIN_IP=$(dig +short yourdomain.com)
echo "Instance IP: $INSTANCE_IP"
echo "Domain IP: $DOMAIN_IP"

# Test HTTP access
curl -I http://yourdomain.com

# Check NGINX status
sudo systemctl status nginx

# Check if port 80 is open
sudo ufw status | grep 80

# Test ACME challenge directory
sudo ls -la /var/www/html/.well-known/acme-challenge/
```

**Solution:**

1. **Verify DNS is configured and propagated:**
   ```bash
   # Check DNS resolution
   dig yourdomain.com
   
   # Should return your instance IP
   # If not, wait for DNS propagation or fix DNS records
   ```
   
   **If DNS is not resolving correctly:**
   - Go back to [DNS Not Resolving](#issue-dns-not-resolving-to-lightsail-instance)
   - Wait for DNS propagation (5-30 minutes typically)
   - Do not proceed with SSL until DNS is working

2. **Verify NGINX is running and accessible:**
   ```bash
   # Check NGINX status
   sudo systemctl status nginx
   
   # If not running, start it
   sudo systemctl start nginx
   
   # Test HTTP access
   curl -I http://yourdomain.com
   ```
   
   Should return: `HTTP/1.1 200 OK` or similar

3. **Verify port 80 is open in firewall:**
   ```bash
   # Check UFW status
   sudo ufw status | grep 80
   
   # If not open, allow it
   sudo ufw allow 80/tcp
   ```

4. **Create ACME challenge directory:**
   ```bash
   # Ensure directory exists with correct permissions
   sudo mkdir -p /var/www/html/.well-known/acme-challenge
   sudo chown -R www-data:www-data /var/www/html/.well-known
   sudo chmod -R 755 /var/www/html/.well-known
   ```

5. **Test ACME challenge manually:**
   ```bash
   # Create test file
   echo "test" | sudo tee /var/www/html/.well-known/acme-challenge/test.txt
   
   # Test access from outside
   curl http://yourdomain.com/.well-known/acme-challenge/test.txt
   ```
   
   Should return: `test`

6. **Retry SSL certificate acquisition:**
   ```bash
   sudo DOMAIN=yourdomain.com SSL_EMAIL=admin@yourdomain.com \
     ./configure-ssl.sh
   ```

7. **Use DNS challenge instead of HTTP challenge (alternative):**
   ```bash
   # If HTTP challenge continues to fail, use DNS challenge
   sudo certbot certonly --manual --preferred-challenges dns \
     -d yourdomain.com -d www.yourdomain.com \
     --email admin@yourdomain.com \
     --agree-tos
   ```
   
   Follow the prompts to add TXT records to your DNS.

**Prevention:**
- Always verify DNS is working before attempting SSL configuration
- Ensure NGINX is running and accessible via HTTP
- Verify firewall allows port 80
- Test ACME challenge directory accessibility
- Wait at least 5-10 minutes after DNS changes before requesting SSL

---

#### Issue: SSL Certificate Fails with "Rate Limit Exceeded"

**Symptom:**
```bash
sudo DOMAIN=yourdomain.com SSL_EMAIL=admin@yourdomain.com ./configure-ssl.sh
```

Shows:
```
Error: too many certificates already issued for exact set of domains
```

Or:
```
Error: too many failed authorizations recently
```

**Root Cause:**
Let's Encrypt has rate limits to prevent abuse:
- 50 certificates per registered domain per week
- 5 failed validation attempts per hour
- Multiple retry attempts exceeded the limit

**Diagnostic Commands:**
```bash
# Check existing certificates
sudo certbot certificates

# Check Let's Encrypt rate limit status
# Visit: https://crt.sh/?q=yourdomain.com
```

**Solution:**

1. **Wait for rate limit to reset:**
   - Failed validation limit: Wait 1 hour
   - Certificate issuance limit: Wait 1 week
   - Check rate limits: https://letsencrypt.org/docs/rate-limits/

2. **Use Let's Encrypt staging environment for testing:**
   ```bash
   # Test with staging (doesn't count against rate limits)
   sudo certbot certonly --webroot -w /var/www/html \
     -d yourdomain.com -d www.yourdomain.com \
     --email admin@yourdomain.com \
     --agree-tos \
     --staging
   ```
   
   **Note:** Staging certificates are not trusted by browsers (for testing only)

3. **Once staging works, get production certificate:**
   ```bash
   # Delete staging certificate
   sudo certbot delete --cert-name yourdomain.com
   
   # Get production certificate
   sudo DOMAIN=yourdomain.com SSL_EMAIL=admin@yourdomain.com \
     ./configure-ssl.sh
   ```

4. **Use a subdomain to bypass rate limits (temporary workaround):**
   ```bash
   # If you hit rate limits on yourdomain.com, try:
   # - subdomain.yourdomain.com
   # - www.yourdomain.com only
   # Each subdomain has separate rate limits
   ```

5. **Check for existing certificates:**
   ```bash
   # List all certificates
   sudo certbot certificates
   
   # If you have an existing valid certificate, use it
   # No need to request a new one
   ```

**Prevention:**
- Always test SSL configuration with staging environment first
- Fix DNS and NGINX issues before attempting SSL
- Don't retry SSL acquisition repeatedly if it fails
- Diagnose and fix the root cause before retrying
- Use `--dry-run` flag to test without requesting certificates:
  ```bash
  sudo certbot certonly --webroot -w /var/www/html \
    -d yourdomain.com -d www.yourdomain.com \
    --email admin@yourdomain.com \
    --agree-tos \
    --dry-run
  ```

---

#### Issue: SSL Certificate Acquired but HTTPS Not Working

**Symptom:**
SSL certificate was successfully acquired, but accessing `https://yourdomain.com` fails.

```bash
curl https://yourdomain.com
```

Shows:
```
curl: (7) Failed to connect to yourdomain.com port 443: Connection refused
```

Or browser shows: "This site can't be reached" or "Connection refused"

**Root Cause:**
- NGINX not configured to use SSL certificates
- Port 443 not open in firewall
- NGINX not restarted after SSL configuration
- SSL configuration syntax errors

**Diagnostic Commands:**
```bash
# Check if port 443 is open
sudo ufw status | grep 443

# Check NGINX status
sudo systemctl status nginx

# Test NGINX configuration
sudo nginx -t

# Check if NGINX is listening on port 443
sudo netstat -tlnp | grep :443

# Check SSL certificate files exist
sudo ls -la /etc/letsencrypt/live/yourdomain.com/

# Check NGINX SSL configuration
sudo cat /etc/nginx/sites-available/default | grep ssl
```

**Solution:**

1. **Verify port 443 is open in firewall:**
   ```bash
   # Check UFW status
   sudo ufw status | grep 443
   
   # If not open, allow it
   sudo ufw allow 443/tcp
   
   # Verify
   sudo ufw status
   ```

2. **Verify NGINX SSL configuration:**
   ```bash
   # Check NGINX configuration syntax
   sudo nginx -t
   ```
   
   Should show: `syntax is ok` and `test is successful`
   
   **If syntax errors:**
   ```bash
   # View the error details
   sudo nginx -t
   
   # Edit the configuration
   sudo nano /etc/nginx/sites-available/default
   
   # Fix syntax errors and test again
   sudo nginx -t
   ```

3. **Verify SSL certificate files exist:**
   ```bash
   # Check certificate files
   sudo ls -la /etc/letsencrypt/live/yourdomain.com/
   ```
   
   Should show:
   - `fullchain.pem` (certificate)
   - `privkey.pem` (private key)
   - `chain.pem` (certificate chain)
   - `cert.pem` (certificate only)

4. **Verify NGINX SSL configuration includes certificates:**
   ```bash
   # Check SSL configuration
   sudo grep -A 10 "listen 443" /etc/nginx/sites-available/default
   ```
   
   Should include:
   ```nginx
   listen 443 ssl;
   ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
   ```

5. **Restart NGINX:**
   ```bash
   # Restart NGINX to apply SSL configuration
   sudo systemctl restart nginx
   
   # Verify it's running
   sudo systemctl status nginx
   
   # Check if listening on port 443
   sudo netstat -tlnp | grep :443
   ```

6. **Test HTTPS access:**
   ```bash
   # Test from server
   curl -I https://yourdomain.com
   
   # Should return: HTTP/2 200 or HTTP/1.1 200
   ```

7. **If NGINX fails to start, check error logs:**
   ```bash
   # View NGINX error log
   sudo tail -n 50 /var/log/nginx/error.log
   
   # View systemd logs
   sudo journalctl -u nginx -n 50
   ```

**Prevention:**
- Always run `sudo nginx -t` before restarting NGINX
- Verify firewall rules include port 443
- Test HTTPS access immediately after SSL configuration
- Keep NGINX configuration backed up

---

#### Issue: Tailscale VPN Not Connecting

**Symptom:**
After running `configure-tailscale.sh`, the server doesn't appear in your Tailscale admin console, or shows as "offline".

**Root Cause:**
- Invalid Tailscale auth key
- Tailscale service not running
- Network connectivity issues
- Firewall blocking Tailscale (port 41641/udp)

**Diagnostic Commands:**
```bash
# Check Tailscale status
sudo tailscale status

# Check Tailscale service
sudo systemctl status tailscaled

# Check Tailscale IP address
sudo tailscale ip

# Check Tailscale logs
sudo journalctl -u tailscaled -n 50

# Check if port 41641 is open
sudo ufw status | grep 41641

# Test Tailscale connectivity
sudo tailscale ping [another-device-name]
```

**Solution:**

1. **Verify Tailscale service is running:**
   ```bash
   # Check status
   sudo systemctl status tailscaled
   
   # If not running, start it
   sudo systemctl start tailscaled
   
   # Enable auto-start
   sudo systemctl enable tailscaled
   ```

2. **Verify Tailscale is authenticated:**
   ```bash
   # Check Tailscale status
   sudo tailscale status
   ```
   
   Should show your device and other devices in your network.
   
   **If not authenticated:**
   ```bash
   # Re-authenticate with auth key
   sudo tailscale up --authkey=tskey-auth-xxxxx
   ```

3. **Verify auth key is valid:**
   - Log in to Tailscale admin console: https://login.tailscale.com/admin/settings/keys
   - Check if your auth key is expired or revoked
   - Generate a new auth key if needed
   - Re-run configure-tailscale.sh with new key:
   ```bash
   sudo TAILSCALE_AUTH_KEY=tskey-auth-xxxxx ./configure-tailscale.sh
   ```

4. **Verify firewall allows Tailscale:**
   ```bash
   # Check if port 41641/udp is open
   sudo ufw status | grep 41641
   
   # If not open, allow it
   sudo ufw allow 41641/udp
   ```

5. **Check Tailscale logs for errors:**
   ```bash
   # View recent logs
   sudo journalctl -u tailscaled -n 100
   
   # Look for error messages or authentication failures
   ```

6. **Restart Tailscale service:**
   ```bash
   # Restart service
   sudo systemctl restart tailscaled
   
   # Wait a few seconds
   sleep 5
   
   # Check status
   sudo tailscale status
   ```

7. **Verify device appears in admin console:**
   - Visit: https://login.tailscale.com/admin/machines
   - Look for your server in the device list
   - Should show as "Connected" with a green indicator
   - Note the Tailscale IP address (100.x.x.x)

8. **Test connectivity from another device:**
   ```bash
   # From your local machine (with Tailscale installed)
   tailscale status
   
   # Ping the server
   ping [server-tailscale-ip]
   
   # Test HTTP access to Builder Interface
   curl http://[server-tailscale-ip]:3000
   ```

**Prevention:**
- Verify auth key is valid before running configuration script
- Ensure firewall allows Tailscale port (41641/udp)
- Test Tailscale connectivity immediately after configuration
- Keep auth keys secure and document their expiration dates

---

#### Issue: Firewall Configuration Locks Out All Access

**Symptom:**
After running `configure-ufw.sh`, you cannot access the server via SSH, HTTP, or any other method.

**Root Cause:**
UFW was enabled without proper rules, blocking all incoming connections.

**Diagnostic Commands:**
```bash
# If you have any active connection:
sudo ufw status verbose

# Check which ports are allowed
sudo ufw status numbered
```

**Solution:**

1. **Use Lightsail browser-based SSH (bypasses UFW):**
   - Go to: https://lightsail.aws.amazon.com/
   - Click on your instance
   - Click "Connect using SSH"
   - This provides console access that bypasses the firewall

2. **Once connected, check UFW status:**
   ```bash
   sudo ufw status verbose
   ```

3. **Add required firewall rules:**
   ```bash
   # Allow SSH (critical!)
   sudo ufw allow 22/tcp
   
   # Allow HTTP
   sudo ufw allow 80/tcp
   
   # Allow HTTPS
   sudo ufw allow 443/tcp
   
   # Allow Tailscale
   sudo ufw allow 41641/udp
   
   # Verify rules
   sudo ufw status
   ```

4. **If UFW is completely broken, disable and reconfigure:**
   ```bash
   # Disable UFW
   sudo ufw disable
   
   # Reset to defaults
   sudo ufw --force reset
   
   # Add rules in correct order
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw allow 41641/udp
   
   # Enable UFW
   sudo ufw --force enable
   
   # Verify
   sudo ufw status verbose
   ```

5. **Test access from outside:**
   ```bash
   # From your local machine
   ssh -i ~/.ssh/lightsail-key.pem ubuntu@[instance-ip]
   curl -I http://yourdomain.com
   curl -I https://yourdomain.com
   ```

**Prevention:**
- Always allow SSH (port 22) before enabling UFW
- Test firewall rules before disconnecting
- Keep Lightsail browser SSH as backup access
- Document firewall rules for future reference
- Use the provided configure-ufw.sh script which includes all required rules

---

### Rollback Procedures for Failed Server Configuration

If server configuration fails and you need to undo changes:

**Rollback NGINX Configuration:**
```bash
# Stop NGINX
sudo systemctl stop nginx

# Remove custom configuration
sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default

# Restore default configuration
sudo apt-get install --reinstall nginx

# Or restore from backup if you created one
sudo cp /etc/nginx/sites-available/default.backup /etc/nginx/sites-available/default

# Test and restart
sudo nginx -t
sudo systemctl start nginx
```

**Rollback UFW Configuration:**
```bash
# Disable UFW
sudo ufw disable

# Reset to defaults
sudo ufw --force reset

# Reconfigure from scratch
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 41641/udp
sudo ufw --force enable
```

**Rollback Tailscale Configuration:**
```bash
# Disconnect from Tailscale network
sudo tailscale down

# Remove Tailscale
sudo apt-get remove --purge tailscale

# Remove Tailscale repository
sudo rm /etc/apt/sources.list.d/tailscale.list

# Reinstall if needed
curl -fsSL https://tailscale.com/install.sh | sh
```

**Rollback SSL Configuration:**
```bash
# Revoke certificates (optional, if you want to free up rate limits)
sudo certbot revoke --cert-name yourdomain.com

# Delete certificates
sudo certbot delete --cert-name yourdomain.com

# Remove SSL configuration from NGINX
sudo nano /etc/nginx/sites-available/default
# Remove or comment out SSL-related lines

# Restart NGINX
sudo nginx -t
sudo systemctl restart nginx
```

**Rollback Systemd Service Configuration:**
```bash
# Stop and disable service
sudo systemctl stop website-builder
sudo systemctl disable website-builder

# Remove service file
sudo rm /etc/systemd/system/website-builder.service

# Reload systemd
sudo systemctl daemon-reload
```

**Complete Server Reset (Nuclear Option):**

If configuration is completely broken and you want to start fresh:

1. **Destroy and recreate the instance:**
   ```bash
   # From your local machine
   cd terraform
   terraform destroy
   
   # Or for CloudFormation
   aws cloudformation delete-stack --stack-name ai-website-builder
   ```

2. **Wait for deletion:**
   ```bash
   # Verify instance is deleted
   aws lightsail get-instances
   ```

3. **Redeploy infrastructure:**
   ```bash
   # Terraform
   terraform apply
   
   # Or CloudFormation
   ./deploy-cloudformation.sh
   ```

4. **Start server configuration from Phase 4 again**

**Important Notes:**
- Always try targeted rollback before complete reset
- Document what went wrong to avoid repeating mistakes
- Keep backups of working configurations
- Test each configuration step before proceeding to the next

---

### Application Deployment Issues

This section covers problems that may occur during Phase 5 (Application Deployment) when installing dependencies, building the application, and starting the systemd service, as well as runtime errors that may occur after deployment.

---

#### Issue: Node.js Dependency Installation Fails with "EACCES: permission denied"

**Symptom:**
```bash
npm install
```

Shows:
```
npm ERR! code EACCES
npm ERR! syscall mkdir
npm ERR! path /home/ubuntu/.npm/_cacache
npm ERR! errno -13
npm ERR! Error: EACCES: permission denied, mkdir '/home/ubuntu/.npm/_cacache'
```

**Root Cause:**
npm cache directory has incorrect permissions, or you're trying to install packages in a directory you don't have write access to.

**Diagnostic Commands:**
```bash
# Check current directory ownership
ls -la

# Check npm cache directory
ls -la ~/.npm

# Check Node.js and npm versions
node --version
npm --version

# Check current user
whoami
```

**Solution:**

1. **Fix npm cache permissions:**
   ```bash
   # Clear npm cache
   npm cache clean --force
   
   # Fix ownership of npm directories
   sudo chown -R $(whoami) ~/.npm
   sudo chown -R $(whoami) ~/.config
   ```

2. **Ensure you're in the correct directory:**
   ```bash
   # Navigate to application directory
   cd ~/ai-website-builder
   
   # Verify package.json exists
   ls -la package.json
   ```

3. **Retry npm install:**
   ```bash
   npm install
   ```

4. **If still failing, check directory permissions:**
   ```bash
   # Check application directory ownership
   ls -la ~/ai-website-builder
   
   # If owned by root or another user, fix it
   sudo chown -R ubuntu:ubuntu ~/ai-website-builder
   ```

5. **Alternative: Use npm with --unsafe-perm (not recommended for production):**
   ```bash
   # Only if other solutions don't work
   npm install --unsafe-perm
   ```

**Prevention:**
- Always run npm install as the application user (ubuntu), not root
- Avoid using sudo with npm install
- Ensure application directory has correct ownership before installing dependencies
- Keep npm cache clean and with correct permissions

---

#### Issue: npm install Fails with "Cannot find module" or Dependency Resolution Errors

**Symptom:**
```bash
npm install
```

Shows:
```
npm ERR! code ERESOLVE
npm ERR! ERESOLVE unable to resolve dependency tree
```

Or:
```
npm ERR! Cannot find module 'some-package'
```

**Root Cause:**
- Conflicting dependency versions
- Corrupted package-lock.json
- Incompatible Node.js version
- Network issues downloading packages

**Diagnostic Commands:**
```bash
# Check Node.js version
node --version

# Check npm version
npm --version

# Check package.json exists
cat package.json

# Check for package-lock.json
ls -la package-lock.json

# Test npm registry connectivity
npm ping
```

**Solution:**

1. **Verify Node.js version meets requirements:**
   ```bash
   # Check current version
   node --version
   ```
   
   Should be v18.x.x or higher.
   
   **If version is too old:**
   ```bash
   # Install Node.js 18 using nvm
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   source ~/.bashrc
   nvm install 18
   nvm use 18
   
   # Verify
   node --version
   ```

2. **Clear npm cache and node_modules:**
   ```bash
   # Remove existing node_modules and package-lock.json
   rm -rf node_modules package-lock.json
   
   # Clear npm cache
   npm cache clean --force
   ```

3. **Retry installation:**
   ```bash
   npm install
   ```

4. **If dependency conflicts persist, use --legacy-peer-deps:**
   ```bash
   npm install --legacy-peer-deps
   ```

5. **Check network connectivity:**
   ```bash
   # Test npm registry access
   npm ping
   
   # If behind a proxy, configure npm
   npm config set proxy http://proxy.example.com:8080
   npm config set https-proxy http://proxy.example.com:8080
   ```

6. **Verify package.json is valid JSON:**
   ```bash
   # Check for syntax errors
   cat package.json | jq .
   ```
   
   If jq is not installed:
   ```bash
   sudo apt-get install jq
   ```

**Prevention:**
- Use the correct Node.js version (18 or higher)
- Commit package-lock.json to version control for consistent installs
- Test npm install locally before deploying
- Keep dependencies up to date
- Use npm ci instead of npm install for production deployments (faster and more reliable)

---

#### Issue: npm install Succeeds but with Vulnerability Warnings

**Symptom:**
```bash
npm install
```

Shows:
```
added 500 packages, and audited 501 packages in 30s

50 vulnerabilities (10 moderate, 30 high, 10 critical)

To address all issues, run:
  npm audit fix
```

**Root Cause:**
Some installed packages have known security vulnerabilities. This is common in Node.js projects and doesn't necessarily prevent the application from running.

**Diagnostic Commands:**
```bash
# View detailed vulnerability report
npm audit

# View vulnerabilities in JSON format
npm audit --json

# Check which packages have vulnerabilities
npm audit --parseable
```

**Solution:**

1. **Assess the severity:**
   ```bash
   # View detailed audit report
   npm audit
   ```
   
   Read the report to understand:
   - Which packages are vulnerable
   - Severity levels (low, moderate, high, critical)
   - Whether vulnerabilities affect production code or just dev dependencies

2. **Attempt automatic fixes:**
   ```bash
   # Try to fix vulnerabilities automatically
   npm audit fix
   
   # If that doesn't fix everything, try force fix (may introduce breaking changes)
   npm audit fix --force
   ```

3. **Verify application still works after fixes:**
   ```bash
   # Rebuild the application
   npm run build
   
   # Check for build errors
   echo $?  # Should be 0 for success
   ```

4. **For vulnerabilities that can't be auto-fixed:**
   
   **Option A: Accept the risk (if vulnerabilities are in dev dependencies or don't affect your use case)**
   ```bash
   # Document the decision
   echo "Known vulnerabilities accepted: [list reasons]" >> SECURITY.md
   ```
   
   **Option B: Manually update vulnerable packages**
   ```bash
   # Update specific package
   npm update [package-name]
   
   # Or update to specific version
   npm install [package-name]@[version]
   ```
   
   **Option C: Find alternative packages**
   - Research if there are alternative packages without vulnerabilities
   - Update package.json to use alternatives

5. **Re-run audit after fixes:**
   ```bash
   npm audit
   ```

**When to Worry:**
- **Critical vulnerabilities in production dependencies**: Fix immediately
- **High vulnerabilities in production dependencies**: Fix soon
- **Vulnerabilities in dev dependencies**: Lower priority (not used in production)
- **Vulnerabilities in transitive dependencies**: May require waiting for upstream fixes

**Prevention:**
- Run npm audit regularly
- Keep dependencies up to date
- Use npm audit in CI/CD pipeline
- Subscribe to security advisories for critical packages
- Consider using tools like Snyk or Dependabot for automated vulnerability monitoring

---

#### Issue: TypeScript Build Fails with "Cannot find module" or Type Errors

**Symptom:**
```bash
npm run build
```

Shows:
```
error TS2307: Cannot find module './some-file' or its corresponding type declarations.
```

Or:
```
error TS2322: Type 'string' is not assignable to type 'number'.
```

**Root Cause:**
- Missing TypeScript dependencies
- TypeScript configuration errors
- Type errors in the code
- Missing type declaration files

**Diagnostic Commands:**
```bash
# Check if TypeScript is installed
npm list typescript

# Check TypeScript version
npx tsc --version

# Check tsconfig.json exists
cat tsconfig.json

# Check for type declaration files
ls -la src/**/*.d.ts

# Try building with verbose output
npx tsc --noEmit --listFiles
```

**Solution:**

1. **Verify TypeScript is installed:**
   ```bash
   # Check if TypeScript is in dependencies
   npm list typescript
   ```
   
   **If not installed:**
   ```bash
   npm install --save-dev typescript
   ```

2. **Verify tsconfig.json is present and valid:**
   ```bash
   # Check tsconfig.json exists
   cat tsconfig.json
   ```
   
   **If missing or invalid:**
   ```bash
   # Create default tsconfig.json
   npx tsc --init
   ```

3. **Install missing type declarations:**
   ```bash
   # For common packages, install @types packages
   npm install --save-dev @types/node @types/express
   
   # Check what types are needed
   npm run build 2>&1 | grep "Cannot find module"
   ```

4. **Clear build cache and rebuild:**
   ```bash
   # Remove build output directory
   rm -rf dist build
   
   # Clear TypeScript cache
   rm -rf node_modules/.cache
   
   # Rebuild
   npm run build
   ```

5. **Check for code errors:**
   ```bash
   # Run TypeScript compiler with no emit to check for errors
   npx tsc --noEmit
   ```
   
   Fix any type errors reported in the source code.

6. **Verify build script in package.json:**
   ```bash
   # Check build script
   cat package.json | grep -A 2 '"build"'
   ```
   
   Should show something like:
   ```json
   "build": "tsc" or "build": "tsc -p tsconfig.json"
   ```

7. **If errors persist, check Node.js module resolution:**
   ```bash
   # Ensure all imports use correct paths
   # Check for missing file extensions in imports
   grep -r "from '\\./" src/
   ```

**Prevention:**
- Test builds locally before deploying
- Keep TypeScript and type declarations up to date
- Use strict TypeScript configuration for better type safety
- Commit tsconfig.json to version control
- Run type checking in CI/CD pipeline

---

#### Issue: systemd Service Fails to Start with "ExecStart failed"

**Symptom:**
```bash
sudo systemctl start website-builder
```

Shows:
```
Job for website-builder.service failed because the control process exited with error code.
See "systemctl status website-builder.service" and "journalctl -xe" for details.
```

And:
```bash
sudo systemctl status website-builder
```

Shows:
```
● website-builder.service - AI Website Builder
     Loaded: loaded (/etc/systemd/system/website-builder.service; enabled)
     Active: failed (Result: exit-code)
```

**Root Cause:**
- Application failed to start due to runtime error
- Missing or incorrect environment variables
- Port already in use
- Incorrect file paths in service file
- Missing dependencies

**Diagnostic Commands:**
```bash
# Check service status
sudo systemctl status website-builder

# View detailed logs
sudo journalctl -u website-builder -n 50

# View all logs since last boot
sudo journalctl -u website-builder -b

# Check service file configuration
cat /etc/systemd/system/website-builder.service

# Check if port 3000 is already in use
sudo netstat -tlnp | grep :3000

# Try running the application manually
cd ~/ai-website-builder
node dist/index.js
```

**Solution:**

1. **Check application logs for specific error:**
   ```bash
   # View recent logs
   sudo journalctl -u website-builder -n 100 --no-pager
   ```
   
   Look for error messages indicating the root cause.

2. **Verify environment variables are set:**
   ```bash
   # Check .env file exists
   ls -la ~/ai-website-builder/.env
   
   # Verify required variables (without exposing values)
   grep -E "^(ANTHROPIC_API_KEY|DOMAIN|PORT)" ~/ai-website-builder/.env
   ```
   
   **If .env is missing or incomplete:**
   ```bash
   # Create or update .env file
   nano ~/ai-website-builder/.env
   ```
   
   Ensure all required variables are set:
   ```
   ANTHROPIC_API_KEY=sk-ant-xxxxx
   DOMAIN=yourdomain.com
   PORT=3000
   MONTHLY_TOKEN_LIMIT=1000000
   ```

3. **Check if port 3000 is already in use:**
   ```bash
   # Check what's using port 3000
   sudo netstat -tlnp | grep :3000
   ```
   
   **If port is in use:**
   ```bash
   # Kill the process using the port
   sudo kill [PID]
   
   # Or change the port in .env
   echo "PORT=3001" >> ~/ai-website-builder/.env
   ```

4. **Verify application was built successfully:**
   ```bash
   # Check if dist directory exists
   ls -la ~/ai-website-builder/dist
   
   # Check if main entry point exists
   ls -la ~/ai-website-builder/dist/index.js
   ```
   
   **If dist directory is missing:**
   ```bash
   cd ~/ai-website-builder
   npm run build
   ```

5. **Test running the application manually:**
   ```bash
   # Try running directly
   cd ~/ai-website-builder
   node dist/index.js
   ```
   
   This will show any runtime errors directly in the terminal.

6. **Verify service file paths are correct:**
   ```bash
   # Check service file
   cat /etc/systemd/system/website-builder.service
   ```
   
   Verify:
   - `WorkingDirectory=/home/ubuntu/ai-website-builder` (correct path)
   - `ExecStart=/usr/bin/node dist/index.js` (correct node path and entry point)
   - `User=ubuntu` (correct user)

7. **Reload systemd and retry:**
   ```bash
   # Reload systemd configuration
   sudo systemctl daemon-reload
   
   # Restart service
   sudo systemctl restart website-builder
   
   # Check status
   sudo systemctl status website-builder
   ```

**Prevention:**
- Test application manually before creating systemd service
- Verify all environment variables are set correctly
- Ensure application builds successfully before starting service
- Check logs immediately after starting service
- Use systemctl status and journalctl for debugging

---

#### Issue: Application Starts but Crashes Immediately

**Symptom:**
```bash
sudo systemctl start website-builder
sudo systemctl status website-builder
```

Shows:
```
Active: activating (auto-restart) (Result: exit-code)
```

Or service starts but immediately stops.

**Root Cause:**
- Uncaught exception in application code
- Missing or invalid environment variables
- Database or external service connection failure
- Port binding failure

**Diagnostic Commands:**
```bash
# View crash logs
sudo journalctl -u website-builder -n 100

# Check for uncaught exceptions
sudo journalctl -u website-builder | grep -i "error\|exception\|fatal"

# Run application manually to see errors
cd ~/ai-website-builder
node dist/index.js

# Check environment variables
cat ~/ai-website-builder/.env

# Check Node.js version
node --version
```

**Solution:**

1. **View detailed error logs:**
   ```bash
   # View all logs with timestamps
   sudo journalctl -u website-builder -n 200 --no-pager
   ```
   
   Look for:
   - Uncaught exceptions
   - Missing module errors
   - Connection failures
   - Environment variable errors

2. **Run application manually to see full error output:**
   ```bash
   cd ~/ai-website-builder
   
   # Run with environment variables loaded
   node dist/index.js
   ```
   
   This will display the full error stack trace.

3. **Common errors and fixes:**

   **a) "Error: Cannot find module"**
   ```bash
   # Reinstall dependencies
   cd ~/ai-website-builder
   rm -rf node_modules
   npm install
   npm run build
   ```

   **b) "Error: ANTHROPIC_API_KEY is required"**
   ```bash
   # Verify .env file has API key
   grep ANTHROPIC_API_KEY ~/ai-website-builder/.env
   
   # If missing, add it
   echo "ANTHROPIC_API_KEY=sk-ant-xxxxx" >> ~/ai-website-builder/.env
   ```

   **c) "Error: listen EADDRINUSE: address already in use :::3000"**
   ```bash
   # Find and kill process using port 3000
   sudo netstat -tlnp | grep :3000
   sudo kill [PID]
   
   # Or change port
   echo "PORT=3001" >> ~/ai-website-builder/.env
   ```

   **d) "Error: connect ECONNREFUSED" (API connection failure)**
   ```bash
   # Test API connectivity
   curl https://api.anthropic.com/v1/messages \
     -H "x-api-key: YOUR_API_KEY" \
     -H "anthropic-version: 2023-06-01" \
     -H "content-type: application/json" \
     -d '{"model": "claude-3-5-sonnet-20241022", "max_tokens": 10, "messages": [{"role": "user", "content": "test"}]}'
   
   # Verify API key is valid
   ```

4. **Check for missing environment variables:**
   ```bash
   # List all required variables
   cat ~/ai-website-builder/.env
   ```
   
   Ensure all required variables are present:
   - ANTHROPIC_API_KEY
   - DOMAIN
   - PORT
   - MONTHLY_TOKEN_LIMIT

5. **Verify Node.js version compatibility:**
   ```bash
   node --version
   ```
   
   Should be v18.x.x or higher.

6. **After fixing, restart service:**
   ```bash
   sudo systemctl restart website-builder
   sudo systemctl status website-builder
   ```

**Prevention:**
- Add proper error handling in application code
- Validate environment variables on startup
- Use try-catch blocks for async operations
- Log errors with stack traces
- Test application thoroughly before deployment

---

#### Issue: Application Running but Not Accessible on Port 3000

**Symptom:**
```bash
sudo systemctl status website-builder
```

Shows:
```
Active: active (running)
```

But:
```bash
curl http://localhost:3000
```

Shows:
```
curl: (7) Failed to connect to localhost port 3000: Connection refused
```

**Root Cause:**
- Application listening on wrong port
- Application listening on wrong interface (127.0.0.1 instead of 0.0.0.0)
- Firewall blocking local connections
- Application started but not actually listening

**Diagnostic Commands:**
```bash
# Check if application is listening on port 3000
sudo netstat -tlnp | grep :3000

# Check application logs
sudo journalctl -u website-builder -n 50

# Check environment variables
cat ~/ai-website-builder/.env | grep PORT

# Test from server
curl http://localhost:3000
curl http://127.0.0.1:3000

# Test from Tailscale IP
TAILSCALE_IP=$(sudo tailscale ip -4)
curl http://$TAILSCALE_IP:3000
```

**Solution:**

1. **Verify application is actually listening:**
   ```bash
   # Check listening ports
   sudo netstat -tlnp | grep :3000
   ```
   
   Should show:
   ```
   tcp        0      0 0.0.0.0:3000            0.0.0.0:*               LISTEN      [PID]/node
   ```

2. **Check PORT environment variable:**
   ```bash
   # Verify PORT is set correctly
   grep PORT ~/ai-website-builder/.env
   ```
   
   Should show:
   ```
   PORT=3000
   ```

3. **Verify application is binding to correct interface:**
   
   Application should bind to `0.0.0.0` (all interfaces), not `127.0.0.1` (localhost only).
   
   Check application logs:
   ```bash
   sudo journalctl -u website-builder -n 50 | grep -i "listening\|started"
   ```
   
   Should show something like:
   ```
   Server listening on http://0.0.0.0:3000
   ```

4. **Test connectivity from different interfaces:**
   ```bash
   # Test localhost
   curl http://localhost:3000
   
   # Test 127.0.0.1
   curl http://127.0.0.1:3000
   
   # Test Tailscale IP
   TAILSCALE_IP=$(sudo tailscale ip -4)
   curl http://$TAILSCALE_IP:3000
   
   # Test public IP (should fail - not exposed publicly)
   PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
   curl http://$PUBLIC_IP:3000
   ```

5. **Check application logs for startup errors:**
   ```bash
   # View full logs
   sudo journalctl -u website-builder -n 100 --no-pager
   ```
   
   Look for:
   - "Server started" or "Listening on port" messages
   - Any error messages
   - Port binding failures

6. **Restart service and monitor logs:**
   ```bash
   # Restart service
   sudo systemctl restart website-builder
   
   # Watch logs in real-time
   sudo journalctl -u website-builder -f
   ```
   
   Press Ctrl+C to stop watching.

7. **If still not accessible, check firewall:**
   ```bash
   # Check if local firewall is blocking
   sudo iptables -L -n | grep 3000
   
   # UFW shouldn't block local connections, but verify
   sudo ufw status
   ```

**Prevention:**
- Ensure application binds to 0.0.0.0, not 127.0.0.1
- Log startup messages clearly
- Test connectivity immediately after starting service
- Monitor logs during startup

---

#### Issue: Application Logs Show "API Rate Limit Exceeded"

**Symptom:**
Application logs show:
```
Error: 429 Too Many Requests - Rate limit exceeded
```

Or:
```
Error: Monthly token limit exceeded
```

**Root Cause:**
- Anthropic API rate limits exceeded
- Monthly token limit configured in application exceeded
- Too many concurrent requests

**Diagnostic Commands:**
```bash
# Check application logs
sudo journalctl -u website-builder | grep -i "rate limit\|429\|token limit"

# Check environment variables
cat ~/ai-website-builder/.env | grep MONTHLY_TOKEN_LIMIT

# Check Anthropic API usage
# Visit: https://console.anthropic.com/settings/usage
```

**Solution:**

1. **Check Anthropic API usage:**
   - Log in to: https://console.anthropic.com/settings/usage
   - View current usage and limits
   - Check if you've exceeded your plan limits

2. **Check monthly token limit configuration:**
   ```bash
   # View configured limit
   grep MONTHLY_TOKEN_LIMIT ~/ai-website-builder/.env
   ```
   
   **If limit is too low:**
   ```bash
   # Increase limit (in tokens)
   nano ~/ai-website-builder/.env
   
   # Change to higher value, e.g.:
   MONTHLY_TOKEN_LIMIT=5000000
   
   # Restart service
   sudo systemctl restart website-builder
   ```

3. **Wait for rate limit to reset:**
   - Anthropic rate limits reset after a time period
   - Check Anthropic documentation for current rate limits
   - Typically resets every minute or hour depending on limit type

4. **Implement request throttling (if needed):**
   - Reduce concurrent requests
   - Add delays between requests
   - Implement request queuing

5. **Monitor API usage:**
   ```bash
   # Check logs for API calls
   sudo journalctl -u website-builder | grep -i "anthropic\|claude\|api"
   ```

6. **Upgrade Anthropic plan if needed:**
   - Visit: https://console.anthropic.com/settings/billing
   - Consider upgrading to higher tier for increased limits

**Prevention:**
- Set appropriate monthly token limits
- Monitor API usage regularly
- Implement request throttling in application
- Set up usage alerts in Anthropic console
- Plan for expected usage and choose appropriate API plan

---

### How to Access and Interpret Application Logs

Understanding how to access and interpret application logs is critical for troubleshooting runtime issues.

**Viewing Application Logs:**

```bash
# View recent logs (last 50 lines)
sudo journalctl -u website-builder -n 50

# View all logs since last boot
sudo journalctl -u website-builder -b

# View logs in real-time (follow mode)
sudo journalctl -u website-builder -f

# View logs with timestamps
sudo journalctl -u website-builder -n 100 --no-pager

# View logs from specific time period
sudo journalctl -u website-builder --since "2024-01-01 00:00:00"
sudo journalctl -u website-builder --since "1 hour ago"
sudo journalctl -u website-builder --since today

# Search logs for specific terms
sudo journalctl -u website-builder | grep -i "error"
sudo journalctl -u website-builder | grep -i "warning"
sudo journalctl -u website-builder | grep -i "exception"

# Export logs to file
sudo journalctl -u website-builder > ~/website-builder-logs.txt
```

**Log Levels and What They Mean:**

- **INFO**: Normal operation messages (server started, request received, etc.)
- **WARN**: Warning messages (deprecated features, non-critical issues)
- **ERROR**: Error messages (failed requests, exceptions, API errors)
- **DEBUG**: Detailed debugging information (usually disabled in production)

**Common Log Patterns:**

1. **Successful Startup:**
   ```
   Started website-builder.service - AI Website Builder
   Server listening on http://0.0.0.0:3000
   Connected to Anthropic API
   ```

2. **API Request:**
   ```
   Received request: POST /api/generate
   Calling Anthropic API with model: claude-3-5-sonnet-20241022
   API response received: 200 OK
   ```

3. **Error Pattern:**
   ```
   Error: ANTHROPIC_API_KEY is required
       at validateConfig (/home/ubuntu/ai-website-builder/dist/config.js:15:11)
       at Object.<anonymous> (/home/ubuntu/ai-website-builder/dist/index.js:5:1)
   ```

4. **Rate Limit:**
   ```
   Error: 429 Too Many Requests
   Rate limit exceeded, retrying in 60 seconds
   ```

**Interpreting Stack Traces:**

When you see an error with a stack trace:
```
Error: Cannot find module 'express'
    at Function.Module._resolveFilename (node:internal/modules/cjs/loader:1039:15)
    at Function.Module._load (node:internal/modules/cjs/loader:885:27)
    at Module.require (node:internal/modules/cjs/loader:1105:19)
    at require (node:internal/modules/cjs/helpers:103:18)
    at Object.<anonymous> (/home/ubuntu/ai-website-builder/dist/index.js:3:17)
```

Read from top to bottom:
1. **Error message**: "Cannot find module 'express'" - tells you what went wrong
2. **First line of stack**: Where the error originated in your code
3. **Subsequent lines**: Call stack showing how execution reached that point

**Log Rotation:**

systemd automatically rotates journal logs, but you can manage them:

```bash
# Check journal disk usage
sudo journalctl --disk-usage

# Clean old logs (keep last 2 days)
sudo journalctl --vacuum-time=2d

# Clean old logs (keep last 500MB)
sudo journalctl --vacuum-size=500M

# Verify logs after cleaning
sudo journalctl --verify
```

**Exporting Logs for Support:**

If you need to share logs for troubleshooting:

```bash
# Export last 500 lines to file
sudo journalctl -u website-builder -n 500 --no-pager > ~/logs-export.txt

# Sanitize sensitive information before sharing
sed -i 's/sk-ant-[a-zA-Z0-9]*/REDACTED_API_KEY/g' ~/logs-export.txt
sed -i 's/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/REDACTED_IP/g' ~/logs-export.txt

# Download to local machine
scp -i ~/.ssh/lightsail-key.pem ubuntu@[instance-ip]:~/logs-export.txt ./
```

**Prevention:**
- Check logs regularly for warnings and errors
- Set up log monitoring and alerting
- Rotate logs to prevent disk space issues
- Keep logs for at least 7 days for troubleshooting

---

### Application Troubleshooting Summary

**Quick Diagnostic Checklist:**

When the application isn't working, check in this order:

1. **Is the service running?**
   ```bash
   sudo systemctl status website-builder
   ```

2. **Are there errors in the logs?**
   ```bash
   sudo journalctl -u website-builder -n 50
   ```

3. **Are dependencies installed?**
   ```bash
   ls -la ~/ai-website-builder/node_modules
   ```

4. **Was the build successful?**
   ```bash
   ls -la ~/ai-website-builder/dist
   ```

5. **Are environment variables set?**
   ```bash
   cat ~/ai-website-builder/.env
   ```

6. **Is the application listening on port 3000?**
   ```bash
   sudo netstat -tlnp | grep :3000
   ```

7. **Can you access it locally?**
   ```bash
   curl http://localhost:3000
   ```

**Common Solutions:**

- **Service won't start**: Check logs, verify .env file, rebuild application
- **Dependencies fail**: Clear cache, reinstall with correct Node.js version
- **Build fails**: Check TypeScript errors, verify tsconfig.json
- **Port not accessible**: Verify application is listening on 0.0.0.0
- **API errors**: Check API key, verify connectivity, check rate limits

**When to Restart the Service:**

Restart the service after:
- Changing environment variables
- Updating application code
- Rebuilding the application
- Modifying configuration files

```bash
sudo systemctl restart website-builder
sudo systemctl status website-builder
```

---

## Maintenance Procedures

This section documents ongoing maintenance tasks for the deployed AI Website Builder, including application updates, dependency management, and system maintenance procedures.

### Application Update Procedures

As you develop new features or fix bugs in the AI Website Builder, you'll need to deploy updates to your production server. This section provides step-by-step instructions for updating the application code, dependencies, and restarting services.

#### Prerequisites for Updates

Before performing updates, ensure you have:
- SSH access to your Lightsail instance
- Git configured on the server (already set up during initial deployment)
- Sufficient disk space for new dependencies and build artifacts
- A backup of critical data (if applicable)

**Recommended:** Test updates in a staging environment before deploying to production.

---

#### Step 1: Connect to the Server

SSH into your Lightsail instance:

```bash
ssh ubuntu@YOUR_INSTANCE_IP
```

Replace `YOUR_INSTANCE_IP` with your Lightsail instance's public IP address (obtained during infrastructure deployment).

**Alternative:** If you have Tailscale configured, you can also SSH via the Tailscale IP:

```bash
ssh ubuntu@YOUR_TAILSCALE_IP
```

---

#### Step 2: Navigate to the Application Directory

Once connected, navigate to the application directory:

```bash
cd /home/ubuntu/ai-website-builder
```

**Verify you're in the correct directory:**

```bash
pwd
```

**Expected Output:**
```
/home/ubuntu/ai-website-builder
```

---

#### Step 3: Pull Latest Code from Git Repository

Update the application code by pulling the latest changes from your Git repository:

```bash
# Fetch the latest changes from the remote repository
git fetch origin

# Pull the latest code from the main branch
git pull origin main
```

**If you're using a different branch** (e.g., `production`):

```bash
git pull origin production
```

**Expected Output:**
```
From https://github.com/yourusername/ai-website-builder
 * branch            main       -> FETCH_HEAD
Updating abc1234..def5678
Fast-forward
 src/app.ts                    | 10 +++++-----
 src/services/ai-service.ts    | 25 +++++++++++++++++++++++++
 2 files changed, 30 insertions(+), 5 deletions(-)
```

**If there are no updates:**
```
Already up to date.
```

**Troubleshooting Git Pull Issues:**

**Issue:** Merge conflicts or uncommitted local changes

```bash
# View status to see what's changed locally
git status

# If you have local changes you want to discard:
git reset --hard origin/main

# If you have local changes you want to keep:
git stash              # Save local changes
git pull origin main   # Pull updates
git stash pop          # Reapply local changes (may require manual merge)
```

**Issue:** Authentication errors

If you're using HTTPS and encounter authentication issues:

```bash
# Switch to SSH authentication (recommended)
git remote set-url origin git@github.com:yourusername/ai-website-builder.git

# Or configure Git credentials helper
git config --global credential.helper store
```

**Issue:** Detached HEAD state

```bash
# Return to the main branch
git checkout main
git pull origin main
```

---

#### Step 4: Update Node.js Dependencies

After pulling new code, update the Node.js dependencies to ensure all required packages are installed:

```bash
npm install
```

**What this does:**
- Installs any new dependencies added to `package.json`
- Updates existing dependencies to versions specified in `package-lock.json`
- Removes dependencies that are no longer needed
- Rebuilds native modules if necessary

**Expected Output:**
```
added 5 packages, removed 2 packages, changed 8 packages, and audited 523 packages in 12s

89 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

**If there are no dependency changes:**
```
up to date, audited 523 packages in 2s

found 0 vulnerabilities
```

**Troubleshooting Dependency Installation Issues:**

**Issue:** Permission errors

```bash
# Ensure you're running as the correct user (ubuntu)
whoami  # Should output: ubuntu

# If you accidentally ran npm as root, fix permissions:
sudo chown -R ubuntu:ubuntu /home/ubuntu/ai-website-builder
```

**Issue:** Network errors or timeouts

```bash
# Clear npm cache and retry
npm cache clean --force
npm install
```

**Issue:** Dependency conflicts or vulnerabilities

```bash
# View audit report
npm audit

# Attempt to fix vulnerabilities automatically
npm audit fix

# For breaking changes, review and update manually
npm audit fix --force  # Use with caution
```

**Issue:** Out of disk space

```bash
# Check available disk space
df -h

# Clean up old build artifacts and caches
rm -rf node_modules
rm -rf dist
npm cache clean --force
npm install
```

---

#### Step 5: Rebuild the Application

After updating dependencies, rebuild the TypeScript application:

```bash
npm run build
```

**What this does:**
- Compiles TypeScript source files (`.ts`) to JavaScript (`.js`)
- Performs type checking
- Generates the `dist/` directory with compiled code
- Prepares the application for production execution

**Expected Output:**
```
> ai-website-builder@1.0.0 build
> tsc

# If successful, no output or minimal output
# The dist/ directory will be created/updated
```

**Verify the build succeeded:**

```bash
ls -la dist/
```

**Expected Output:**
```
total 48
drwxrwxr-x  3 ubuntu ubuntu  4096 Jan 15 10:30 .
drwxrwxr-x 10 ubuntu ubuntu  4096 Jan 15 10:30 ..
-rw-rw-r--  1 ubuntu ubuntu  1234 Jan 15 10:30 app.js
-rw-rw-r--  1 ubuntu ubuntu   567 Jan 15 10:30 app.js.map
drwxrwxr-x  2 ubuntu ubuntu  4096 Jan 15 10:30 services
...
```

**Troubleshooting Build Issues:**

**Issue:** TypeScript compilation errors

```bash
# View detailed error output
npm run build

# Common issues:
# - Type errors: Fix type annotations in source code
# - Missing dependencies: Run npm install again
# - Syntax errors: Review recent code changes
```

**Example TypeScript Error:**
```
src/app.ts:45:12 - error TS2345: Argument of type 'string' is not assignable to parameter of type 'number'.

45     doSomething("hello");
              ~~~~~~~~

Found 1 error.
```

**Resolution:** Fix the type error in the source code, commit the fix, and pull the corrected code.

**Issue:** Build succeeds but dist/ directory is empty

```bash
# Check tsconfig.json configuration
cat tsconfig.json

# Ensure outDir is set correctly:
# "outDir": "./dist"

# Clean and rebuild
rm -rf dist
npm run build
```

---

#### Step 6: Restart the Application Service

After rebuilding the application, restart the systemd service to load the new code:

```bash
sudo systemctl restart website-builder
```

**What this does:**
- Stops the currently running website-builder service
- Starts the service with the newly built code
- Reloads environment variables from `/home/ubuntu/ai-website-builder/.env`

**Expected Output:**
No output indicates success.

**Verify the service restarted successfully:**

```bash
sudo systemctl status website-builder
```

**Expected Output:**
```
● website-builder.service - AI Website Builder
     Loaded: loaded (/etc/systemd/system/website-builder.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-01-15 10:35:22 UTC; 5s ago
   Main PID: 12345 (node)
      Tasks: 11 (limit: 1234)
     Memory: 45.2M
        CPU: 1.234s
     CGroup: /system.slice/website-builder.service
             └─12345 /usr/bin/node /home/ubuntu/ai-website-builder/dist/app.js

Jan 15 10:35:22 ip-172-26-1-123 systemd[1]: Started AI Website Builder.
Jan 15 10:35:23 ip-172-26-1-123 node[12345]: Server starting on port 3000...
Jan 15 10:35:23 ip-172-26-1-123 node[12345]: Connected to database
Jan 15 10:35:23 ip-172-26-1-123 node[12345]: Application ready
```

**Key indicators of success:**
- `Active: active (running)` - Service is running
- Recent timestamp - Service just started
- No error messages in the log output

**If the service fails to start:**

```bash
# View detailed error logs
sudo journalctl -u website-builder -n 50 --no-pager

# Common issues:
# - Port already in use (another process on port 3000)
# - Missing environment variables in .env file
# - Runtime errors in the application code
# - Missing dependencies
```

**Troubleshooting Service Restart Issues:**

**Issue:** Service fails to start with "port already in use" error

```bash
# Find process using port 3000
sudo lsof -i :3000

# Kill the process if necessary
sudo kill -9 <PID>

# Restart the service
sudo systemctl restart website-builder
```

**Issue:** Service starts but immediately crashes

```bash
# View full logs
sudo journalctl -u website-builder -n 100 --no-pager

# Check for:
# - Missing environment variables
# - Database connection errors
# - API key issues
# - File permission problems
```

**Issue:** Environment variables not loading

```bash
# Verify .env file exists and has correct permissions
ls -la /home/ubuntu/ai-website-builder/.env

# Should show:
# -rw------- 1 ubuntu ubuntu 234 Jan 15 10:00 .env

# If permissions are wrong:
chmod 600 /home/ubuntu/ai-website-builder/.env
sudo systemctl restart website-builder
```

---

#### Step 7: Verify the Update

After restarting the service, verify that the application is running correctly with the new code.

**1. Check Service Status:**

```bash
sudo systemctl status website-builder
```

**Expected:** `Active: active (running)` with no error messages.

---

**2. Verify Application Logs:**

View recent application logs to ensure no runtime errors:

```bash
sudo journalctl -u website-builder -n 20 --no-pager
```

**Expected Output:**
```
Jan 15 10:35:23 ip-172-26-1-123 node[12345]: Server starting on port 3000...
Jan 15 10:35:23 ip-172-26-1-123 node[12345]: Connected to database
Jan 15 10:35:23 ip-172-26-1-123 node[12345]: Application ready
```

**Look for:**
- Successful startup messages
- No error or warning messages
- Database connections established (if applicable)
- API integrations initialized

---

**3. Test Builder Interface Access:**

From your local machine (connected to Tailscale VPN), access the Builder Interface:

```bash
# Get the Tailscale IP of your server
# On the server:
tailscale ip -4
```

**Expected Output:**
```
100.x.x.x
```

**From your local machine:**

Open a web browser and navigate to:
```
http://100.x.x.x:3000
```

Replace `100.x.x.x` with your server's Tailscale IP.

**Expected:** The Builder Interface loads successfully, and you can interact with the application.

**Test basic functionality:**
- Create a new page
- Generate content using AI
- Save changes
- Verify no JavaScript errors in browser console (F12)

---

**4. Test Public Website Access:**

Verify the public-facing static website is still accessible:

```bash
# From your local machine or any device
curl -I https://yourdomain.com
```

**Expected Output:**
```
HTTP/2 200
server: nginx/1.18.0
date: Mon, 15 Jan 2024 10:40:00 GMT
content-type: text/html
...
```

**Or open in a browser:**
```
https://yourdomain.com
```

**Expected:** The website loads correctly with HTTPS.

---

**5. Verify SSL Certificate Status:**

Ensure SSL certificates are still valid:

```bash
# On the server
sudo certbot certificates
```

**Expected Output:**
```
Found the following certs:
  Certificate Name: yourdomain.com
    Domains: yourdomain.com www.yourdomain.com
    Expiry Date: 2024-04-15 10:00:00+00:00 (VALID: 89 days)
    Certificate Path: /etc/letsencrypt/live/yourdomain.com/fullchain.pem
    Private Key Path: /etc/letsencrypt/live/yourdomain.com/privkey.pem
```

---

**6. Check System Resources:**

Verify the update hasn't caused resource issues:

```bash
# Check memory usage
free -h

# Check disk usage
df -h

# Check CPU usage
top -bn1 | head -20
```

**Expected:**
- Memory usage is reasonable (not near 100%)
- Disk space is available (at least 10% free)
- CPU usage is normal (not constantly at 100%)

---

#### Update Procedure Summary

**Quick Reference - Complete Update Workflow:**

```bash
# 1. SSH into server
ssh ubuntu@YOUR_INSTANCE_IP

# 2. Navigate to application directory
cd /home/ubuntu/ai-website-builder

# 3. Pull latest code
git pull origin main

# 4. Update dependencies
npm install

# 5. Rebuild application
npm run build

# 6. Restart service
sudo systemctl restart website-builder

# 7. Verify service is running
sudo systemctl status website-builder

# 8. Check logs for errors
sudo journalctl -u website-builder -n 20 --no-pager
```

**Estimated Time:** 5-10 minutes (depending on the size of updates and network speed)

**Frequency:** As needed when new code is pushed to the repository

---

#### Rollback Procedure

If an update causes issues, you can rollback to the previous version:

**1. Identify the previous Git commit:**

```bash
# View recent commits
git log --oneline -n 10
```

**Expected Output:**
```
def5678 (HEAD -> main, origin/main) Fix: Resolve API timeout issue
abc1234 Feature: Add new content template
xyz9876 Update: Improve error handling
...
```

**2. Rollback to the previous commit:**

```bash
# Rollback to the commit before the current one
git reset --hard abc1234

# Or rollback to the previous commit (shorthand)
git reset --hard HEAD~1
```

**3. Reinstall dependencies (if package.json changed):**

```bash
npm install
```

**4. Rebuild the application:**

```bash
npm run build
```

**5. Restart the service:**

```bash
sudo systemctl restart website-builder
```

**6. Verify the rollback:**

```bash
sudo systemctl status website-builder
sudo journalctl -u website-builder -n 20 --no-pager
```

**Important Notes:**
- Rolling back discards any local changes
- After fixing the issue, you'll need to pull the corrected code again
- Consider using Git tags or branches for production releases to make rollbacks easier

---

#### Best Practices for Application Updates

**1. Test Before Deploying:**
- Test updates in a local development environment first
- Use a staging server that mirrors production
- Run automated tests before deploying

**2. Backup Before Updates:**
- Backup the `.env` file (contains sensitive configuration)
- Backup any user-generated data or databases
- Document the current Git commit hash for easy rollback

**3. Schedule Updates During Low-Traffic Periods:**
- Plan updates during off-peak hours
- Notify users of scheduled maintenance if applicable
- Monitor the application closely after updates

**4. Monitor After Updates:**
- Watch application logs for errors: `sudo journalctl -u website-builder -f`
- Monitor system resources: `htop` or `top`
- Check error rates and performance metrics
- Test critical user workflows

**5. Use Git Tags for Releases:**
```bash
# Tag a release before deploying
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin v1.2.0

# Deploy a specific tagged version
git fetch --tags
git checkout v1.2.0
npm install
npm run build
sudo systemctl restart website-builder
```

**6. Automate Updates (Advanced):**
Consider setting up automated deployment pipelines using:
- GitHub Actions
- GitLab CI/CD
- Jenkins
- Custom deployment scripts

**7. Keep Dependencies Updated:**
```bash
# Check for outdated dependencies
npm outdated

# Update dependencies (carefully)
npm update

# Or update specific packages
npm update package-name
```

**8. Document Changes:**
- Maintain a CHANGELOG.md file
- Document breaking changes
- Include migration instructions if needed

---

#### Troubleshooting Common Update Issues

**Issue:** Git pull fails with "Permission denied"

**Solution:**
```bash
# Ensure you're the correct user
whoami  # Should be: ubuntu

# Fix repository permissions
sudo chown -R ubuntu:ubuntu /home/ubuntu/ai-website-builder

# Try pulling again
git pull origin main
```

---

**Issue:** npm install fails with EACCES errors

**Solution:**
```bash
# Fix npm permissions
sudo chown -R ubuntu:ubuntu ~/.npm
sudo chown -R ubuntu:ubuntu /home/ubuntu/ai-website-builder

# Clear cache and retry
npm cache clean --force
npm install
```

---

**Issue:** Build succeeds but application doesn't reflect changes

**Solution:**
```bash
# Ensure you restarted the service
sudo systemctl restart website-builder

# Clear browser cache (for frontend changes)
# Hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)

# Verify the correct code is running
git log -1  # Check current commit
ls -la dist/  # Verify build timestamp
```

---

**Issue:** Service won't start after update

**Solution:**
```bash
# Check detailed error logs
sudo journalctl -u website-builder -n 50 --no-pager

# Common fixes:
# 1. Verify .env file exists and is readable
ls -la /home/ubuntu/ai-website-builder/.env

# 2. Check for syntax errors in code
npm run build  # Should show TypeScript errors

# 3. Verify all dependencies are installed
npm install

# 4. Check for port conflicts
sudo lsof -i :3000

# 5. Rollback if necessary (see Rollback Procedure above)
```

---

**Issue:** Application runs but features are broken

**Solution:**
```bash
# Check application logs for runtime errors
sudo journalctl -u website-builder -f

# Verify environment variables are correct
cat /home/ubuntu/ai-website-builder/.env

# Test API connectivity
curl -I https://api.anthropic.com/v1/messages \
  -H "x-api-key: YOUR_API_KEY"

# Check database connections (if applicable)
# Review recent code changes for bugs
```

---

#### Next Steps

After successfully updating the application, consider:
- Monitoring application performance and error rates
- Reviewing application logs regularly
- Setting up automated monitoring and alerting
- Planning the next update cycle
- Documenting any issues encountered for future reference

For system-level maintenance (security updates, SSL certificate renewal, backups), see the next section: [System Maintenance Procedures](#system-maintenance-procedures).

---

## Cost Management

Understanding and monitoring the costs associated with running the AI Website Builder is essential for budget planning and cost optimization. This section provides a detailed breakdown of expected costs, monitoring procedures, and optimization strategies to help you manage your deployment expenses effectively.

---

### Cost Breakdown

The AI Website Builder deployment incurs costs from three primary sources: AWS Lightsail infrastructure, domain registration, and Claude API usage. Below is a comprehensive breakdown of each cost component.

---

#### 1. AWS Lightsail Instance Costs (Fixed Monthly)

AWS Lightsail provides predictable, fixed monthly pricing for virtual private servers. The cost depends on the instance size you choose during infrastructure deployment.

**Recommended Instance: $10/month Plan**

For most use cases, the $10/month Lightsail instance provides sufficient resources:

- **Instance Size:** 2 GB RAM, 1 vCPU, 60 GB SSD
- **Monthly Cost:** $10.00 USD
- **Data Transfer:** 2 TB outbound data transfer included
- **Cost Type:** Fixed (billed monthly regardless of usage)
- **Billing:** Prorated for partial months

**Alternative Instance Options:**

| Instance Size | RAM | vCPU | Storage | Transfer | Monthly Cost |
|--------------|-----|------|---------|----------|--------------|
| Nano | 512 MB | 1 | 20 GB | 1 TB | $3.50 |
| Micro | 1 GB | 1 | 40 GB | 2 TB | $5.00 |
| Small | 2 GB | 1 | 60 GB | 2 TB | **$10.00** ⭐ |
| Medium | 4 GB | 2 | 80 GB | 3 TB | $20.00 |
| Large | 8 GB | 2 | 160 GB | 4 TB | $40.00 |

⭐ **Recommended for production use**

**Choosing the Right Instance Size:**

- **$3.50-$5.00 plans:** Suitable for testing/development or very low-traffic sites
  - May experience performance issues with concurrent AI generation requests
  - Limited resources for Node.js application and NGINX
  
- **$10.00 plan (Recommended):** Best balance of performance and cost
  - Handles moderate traffic and concurrent AI requests
  - Sufficient resources for production use
  - 2 GB RAM allows comfortable operation of Node.js + NGINX + system services
  
- **$20.00+ plans:** Consider if you experience:
  - High concurrent user load
  - Frequent AI generation requests
  - Need for additional storage or data transfer

**Additional AWS Lightsail Costs:**

- **Static IP Address:** Free (included with instance)
- **Snapshots (Backups):** $0.05 per GB per month (optional)
  - Example: 20 GB snapshot = $1.00/month
- **Data Transfer Overage:** $0.09 per GB beyond included amount (rare for typical usage)
- **DNS Zone:** Free (if using Lightsail DNS)

**Total Estimated AWS Infrastructure Cost:** $10.00 - $11.00/month

---

#### 2. Domain Registration Costs (Annual)

A domain name is required for the AI Website Builder to serve content over HTTPS. Domain costs are paid annually to your domain registrar.

**Typical Domain Registration Costs:**

| TLD (Top-Level Domain) | Annual Cost | Notes |
|------------------------|-------------|-------|
| .com | $8 - $15 | Most popular, recommended for general use |
| .net | $10 - $15 | Alternative to .com |
| .org | $10 - $15 | Typically for organizations |
| .io | $30 - $40 | Popular for tech startups |
| .dev | $12 - $20 | Developer-focused domains |
| .app | $15 - $20 | Application-focused domains |
| .ai | $60 - $100 | Premium pricing for AI-related domains |

**Registrar Pricing Examples:**

- **Namecheap:** .com domains typically $8-13/year (first year often discounted)
- **Google Domains:** .com domains $12/year (flat pricing)
- **AWS Route 53:** .com domains $12/year (integrated with AWS)
- **Cloudflare Registrar:** .com domains $8-10/year (at-cost pricing)

**Additional Domain Costs:**

- **WHOIS Privacy Protection:** $0 - $10/year
  - Hides your personal information from public WHOIS database
  - Often included free with many registrars (Namecheap, Google Domains, Cloudflare)
  
- **Domain Renewal:** Same as registration cost (typically increases after first year)
  - Set up auto-renewal to avoid losing your domain
  - Some registrars offer multi-year discounts

**Total Estimated Domain Cost:** $10 - $15/year ($0.83 - $1.25/month)

**Cost Optimization Tips:**
- Choose a .com domain for best value and recognition
- Look for first-year registration discounts
- Enable auto-renewal to lock in pricing
- Consider registrars that include free WHOIS privacy
- Avoid premium or vanity domains unless necessary for branding

---

#### 3. Claude API Costs (Variable, Per Token)

The Claude API powers the AI content generation features of the Website Builder. Costs are variable and depend on your usage patterns.

**Claude API Pricing (as of 2024):**

The AI Website Builder uses **Claude 3.5 Sonnet**, which offers the best balance of performance and cost.

| Model | Input Tokens | Output Tokens | Use Case |
|-------|--------------|---------------|----------|
| Claude 3.5 Sonnet | $3.00 / 1M tokens | $15.00 / 1M tokens | **Recommended** - Best balance |
| Claude 3 Opus | $15.00 / 1M tokens | $75.00 / 1M tokens | Highest quality (expensive) |
| Claude 3 Haiku | $0.25 / 1M tokens | $1.25 / 1M tokens | Fastest, lower quality |

**Understanding Token Costs:**

- **Input Tokens:** Text you send to Claude (prompts, context, instructions)
- **Output Tokens:** Text Claude generates (website content, responses)
- **1 Token ≈ 4 characters** (approximately 750 words = 1,000 tokens)
- Output tokens cost more than input tokens (5x for Sonnet)

**Typical Usage Patterns:**

**Low Usage (Personal/Small Site):**
- 10-20 AI generation requests per month
- Average 2,000 input tokens + 1,500 output tokens per request
- **Monthly Cost:** $0.50 - $1.50

**Moderate Usage (Small Business):**
- 50-100 AI generation requests per month
- Average 2,000 input tokens + 1,500 output tokens per request
- **Monthly Cost:** $2.50 - $5.00

**High Usage (Active Content Creation):**
- 200-500 AI generation requests per month
- Average 2,000 input tokens + 1,500 output tokens per request
- **Monthly Cost:** $10.00 - $25.00

**Example Calculation:**

Let's calculate the cost for 100 AI generation requests per month:

```
Assumptions:
- 100 requests/month
- Average 2,000 input tokens per request = 200,000 input tokens/month
- Average 1,500 output tokens per request = 150,000 output tokens/month

Input Cost:
200,000 tokens × ($3.00 / 1,000,000 tokens) = $0.60

Output Cost:
150,000 tokens × ($15.00 / 1,000,000 tokens) = $2.25

Total Monthly API Cost: $0.60 + $2.25 = $2.85
```

**Cost Protection Features:**

The AI Website Builder includes a **monthly token threshold** configuration to prevent unexpected costs:

- Default limit: 1,000,000 tokens per month (configurable in `.env`)
- When threshold is reached, the application stops making API calls
- Prevents runaway costs from bugs or abuse
- Threshold resets automatically at the start of each month

**To configure the token limit:**

```bash
# Edit .env file on the server
MONTHLY_TOKEN_THRESHOLD=1000000  # Adjust as needed
```

**Total Estimated Claude API Cost:** $1 - $25/month (highly variable based on usage)

---

#### 4. Total Monthly Cost Summary

Here's a comprehensive summary of all costs associated with running the AI Website Builder:

**Fixed Costs (Predictable):**

| Cost Component | Monthly Cost | Annual Cost | Notes |
|----------------|--------------|-------------|-------|
| AWS Lightsail Instance | $10.00 | $120.00 | Fixed, billed monthly |
| Domain Name | $0.83 - $1.25 | $10 - $15 | Billed annually |
| **Fixed Subtotal** | **$10.83 - $11.25** | **$130 - $135** | Predictable baseline |

**Variable Costs (Usage-Based):**

| Cost Component | Low Usage | Moderate Usage | High Usage |
|----------------|-----------|----------------|------------|
| Claude API | $0.50 - $1.50 | $2.50 - $5.00 | $10 - $25 |

**Total Estimated Monthly Cost:**

| Usage Level | Monthly Cost | Annual Cost |
|-------------|--------------|-------------|
| **Low Usage** | **$11.33 - $12.75** | **$136 - $153** |
| **Moderate Usage** | **$13.33 - $16.25** | **$160 - $195** |
| **High Usage** | **$20.83 - $36.25** | **$250 - $435** |

**Cost Range Summary:**
- **Minimum:** ~$11/month (~$132/year) - Fixed costs only, minimal API usage
- **Typical:** ~$15/month (~$180/year) - Moderate usage for small business or personal site
- **Maximum:** ~$36/month (~$432/year) - High usage with frequent AI content generation

**Cost Comparison:**

For context, here's how the AI Website Builder compares to alternatives:

- **Traditional Web Hosting:** $5-20/month (no AI features)
- **WordPress Hosting:** $10-50/month (no AI features)
- **Wix/Squarespace:** $15-50/month (limited AI features)
- **AI Website Builder (This Solution):** $11-36/month (full AI capabilities, self-hosted)

**Key Advantages:**
- No per-user fees (unlimited users via Tailscale)
- No transaction fees or revenue sharing
- Full control over infrastructure and data
- Predictable baseline costs with usage-based AI scaling

---

### Cost Monitoring Procedures

Monitoring your deployment costs is essential for staying within budget and identifying unexpected usage patterns. This section provides detailed instructions for monitoring AWS Lightsail infrastructure costs, Claude API usage, and configuring application-level cost controls.

---

#### Monitoring AWS Lightsail Costs

AWS Lightsail provides predictable, fixed monthly pricing, but it's important to monitor your actual costs to ensure there are no unexpected charges from data transfer overages, snapshots, or other resources.

**Why This Matters:**
- Detect unexpected charges early (e.g., data transfer overages)
- Track costs across multiple resources if you expand your deployment
- Verify billing matches expected costs
- Set up alerts for budget overruns

---

##### Access AWS Billing Dashboard

**1. Log in to AWS Console:**

Visit: https://console.aws.amazon.com/

**2. Navigate to Billing Dashboard:**

- Click on your account name in the top-right corner
- Select "Billing and Cost Management" from the dropdown
- Or go directly to: https://console.aws.amazon.com/billing/

**3. View Current Month Costs:**

On the Billing Dashboard, you'll see:
- **Month-to-Date Costs:** Current charges for the month
- **Forecasted Costs:** Estimated total for the month based on current usage
- **Cost by Service:** Breakdown showing Lightsail and other AWS services

**Expected Lightsail Costs:**
- **Instance:** $10.00/month (or your chosen plan)
- **Data Transfer:** $0.00 (included up to 2 TB for $10 plan)
- **Static IP:** $0.00 (free when attached to running instance)
- **Total:** ~$10.00/month

**Red Flags to Watch For:**
- Data transfer charges (indicates you exceeded included bandwidth)
- Multiple instance charges (indicates you have more than one instance running)
- Snapshot charges (if you created backups via Lightsail snapshots)
- Static IP charges (if you have unattached static IPs)

---

##### View Detailed Lightsail Costs

**1. Access Cost Explorer:**

- In the Billing Dashboard, click "Cost Explorer" in the left sidebar
- Or go directly to: https://console.aws.amazon.com/cost-management/home#/cost-explorer

**Note:** Cost Explorer may require enabling (one-time setup, free to use)

**2. Filter by Lightsail Service:**

- In Cost Explorer, set the date range (e.g., "Last 3 months")
- Under "Filters," select "Service"
- Check "Amazon Lightsail"
- Click "Apply filters"

**3. View Cost Breakdown:**

You can view costs by:
- **Daily costs:** Identify specific days with unusual charges
- **Monthly costs:** Track trends over time
- **By usage type:** See breakdown of instance, data transfer, snapshots, etc.

**Example Cost Analysis:**

```
January 2024 Lightsail Costs:
├─ Instance (us-east-1): $10.00
├─ Data Transfer Out: $0.00 (1.2 TB used of 2 TB included)
├─ Snapshots: $0.00 (no snapshots created)
└─ Total: $10.00
```

---

##### Set Up AWS Budget Alerts

Receive email notifications when costs exceed expected thresholds.

**1. Navigate to AWS Budgets:**

- In the Billing Dashboard, click "Budgets" in the left sidebar
- Or go directly to: https://console.aws.amazon.com/billing/home#/budgets

**2. Create a New Budget:**

- Click "Create budget"
- Select "Cost budget" (recommended)
- Click "Next"

**3. Configure Budget Details:**

**Budget Name:** `AI-Website-Builder-Monthly-Budget`

**Period:** Monthly

**Budget Amount:** 
- **Fixed:** $15.00 (allows for $10 Lightsail + $5 buffer for API costs)
- Or **Planned:** Set different amounts for different months

**Budget Scope:**
- **All AWS services** (recommended to catch all costs)
- Or filter to "Amazon Lightsail" only

**4. Configure Alerts:**

Add multiple alert thresholds:

**Alert 1 - 80% Threshold:**
- **Alert threshold:** 80% of budgeted amount ($12.00)
- **Email recipients:** your-email@example.com
- **Notification:** "Your AWS costs have reached 80% of your monthly budget"

**Alert 2 - 100% Threshold:**
- **Alert threshold:** 100% of budgeted amount ($15.00)
- **Email recipients:** your-email@example.com
- **Notification:** "Your AWS costs have exceeded your monthly budget"

**Alert 3 - Forecasted (Optional):**
- **Alert threshold:** Forecasted to exceed 100%
- **Email recipients:** your-email@example.com
- **Notification:** "Your AWS costs are forecasted to exceed your monthly budget"

**5. Review and Create:**

- Review your budget configuration
- Click "Create budget"
- You'll receive a confirmation email

**Expected Notifications:**
- You should NOT receive alerts if costs stay within expected range ($10-11/month)
- Alerts indicate unexpected usage or additional resources

---

##### Monitor Lightsail Data Transfer

Data transfer overages are the most common source of unexpected Lightsail costs.

**1. Access Lightsail Console:**

Visit: https://lightsail.aws.amazon.com/

**2. View Instance Metrics:**

- Click on your instance name
- Click the "Metrics" tab
- Select "Network out" metric

**3. Check Data Transfer Usage:**

The graph shows:
- **Network out:** Data sent from your server to the internet
- **Time period:** Last hour, day, week, or month

**Included Data Transfer:**
- **$10/month plan:** 2 TB (2,000 GB) included
- **Overage cost:** $0.09 per GB beyond included amount

**Example Usage Scenarios:**

**Low Traffic (Personal Site):**
- 10,000 page views/month
- Average page size: 500 KB
- Total transfer: ~5 GB/month
- Cost: $0 (well within 2 TB limit)

**Moderate Traffic (Small Business):**
- 100,000 page views/month
- Average page size: 500 KB
- Total transfer: ~50 GB/month
- Cost: $0 (well within 2 TB limit)

**High Traffic (Popular Site):**
- 1,000,000 page views/month
- Average page size: 500 KB
- Total transfer: ~500 GB/month
- Cost: $0 (still within 2 TB limit)

**Overage Example:**
- 2,500 GB transferred in a month
- Included: 2,000 GB
- Overage: 500 GB × $0.09 = $45.00 additional cost

**How to Reduce Data Transfer Costs:**
- Optimize images (compress, use appropriate formats)
- Enable browser caching
- Use a CDN for static assets (CloudFlare, etc.)
- Minimize page sizes

---

##### Check for Unused Resources

Ensure you're not paying for resources you're not using.

**1. Review Lightsail Instances:**

- In Lightsail Console: https://lightsail.aws.amazon.com/
- Check "Instances" tab
- Verify you only have ONE instance running (the AI Website Builder)
- **Action:** Delete any unused instances

**2. Review Static IPs:**

- In Lightsail Console, click "Networking" tab
- Check "Static IPs"
- Verify each static IP is attached to a running instance
- **Cost:** $0.005/hour (~$3.60/month) for unattached static IPs
- **Action:** Delete unattached static IPs or attach them to instances

**3. Review Snapshots:**

- In Lightsail Console, click "Snapshots" tab
- Check for instance or disk snapshots
- **Cost:** $0.05 per GB per month
- **Action:** Delete old snapshots you no longer need (keep recent backups)

**4. Review Load Balancers and Databases:**

- Check "Networking" and "Databases" tabs
- Verify you don't have unused load balancers or databases
- **Cost:** Varies by resource type
- **Action:** Delete unused resources

---

#### Monitoring Claude API Usage

Claude API costs are variable and depend on your usage patterns. Monitoring API usage helps you understand costs, optimize usage, and prevent unexpected bills.

**Why This Matters:**
- Claude API costs can vary significantly based on usage
- Detect unusual usage patterns (bugs, abuse, or unexpected traffic)
- Optimize prompts and reduce token usage
- Stay within budget and avoid surprises

---

##### Access Anthropic Console

**1. Log in to Anthropic Console:**

Visit: https://console.anthropic.com/

**2. Navigate to Usage Dashboard:**

- Click "Usage" in the left sidebar
- Or go directly to: https://console.anthropic.com/settings/usage

**3. View Current Usage:**

The Usage dashboard shows:
- **Current billing period:** Month-to-date usage
- **Total tokens used:** Input + output tokens
- **Estimated cost:** Based on current usage
- **Usage by day:** Daily breakdown of API calls and tokens

---

##### Understand Token Usage Metrics

**Key Metrics:**

**1. Input Tokens:**
- Text sent TO Claude (prompts, context, instructions)
- Cost: $3.00 per 1 million tokens (Claude 3.5 Sonnet)
- Typically lower volume than output tokens

**2. Output Tokens:**
- Text generated BY Claude (website content, responses)
- Cost: $15.00 per 1 million tokens (Claude 3.5 Sonnet)
- Typically higher volume and more expensive

**3. Total Cost:**
- (Input tokens × $3.00 / 1M) + (Output tokens × $15.00 / 1M)

**Example Usage Calculation:**

```
Monthly Usage:
├─ API Requests: 100
├─ Input Tokens: 200,000 (2,000 per request)
├─ Output Tokens: 150,000 (1,500 per request)
└─ Total Cost: $2.85

Breakdown:
├─ Input Cost: 200,000 × ($3.00 / 1,000,000) = $0.60
└─ Output Cost: 150,000 × ($15.00 / 1,000,000) = $2.25
```

---

##### Monitor Daily Usage Trends

**1. View Usage Graph:**

In the Anthropic Console Usage page:
- View the daily usage graph
- Hover over bars to see exact token counts
- Identify days with unusually high usage

**2. Analyze Usage Patterns:**

**Normal Usage Pattern:**
- Consistent daily usage
- Spikes on days when you create new content
- Low usage on days with no content generation

**Concerning Usage Pattern:**
- Sudden unexplained spikes
- Continuous high usage without corresponding activity
- Usage during hours when you're not using the system

**Red Flags:**
- **Sudden 10x increase:** May indicate a bug or unauthorized access
- **Continuous usage 24/7:** May indicate a loop or automated abuse
- **Usage when you're not creating content:** May indicate unauthorized access

**3. Investigate Unusual Usage:**

If you see unexpected usage:

```bash
# SSH into your server
ssh ubuntu@YOUR_INSTANCE_IP

# Check application logs for API calls
sudo journalctl -u website-builder --since "24 hours ago" | grep -i "anthropic\|claude\|api"

# Check for unusual access patterns
sudo journalctl -u website-builder --since "24 hours ago" | grep -i "error\|warning"

# Review NGINX access logs
sudo tail -100 /var/log/nginx/access.log
```

---

##### Set Up Usage Alerts (Anthropic Console)

**Note:** As of 2024, Anthropic Console may have limited built-in alerting. Check the console for current features.

**Alternative: Manual Monitoring Schedule**

Set a reminder to check usage weekly:
- Every Monday morning, review the past week's usage
- Compare to expected usage patterns
- Investigate any anomalies

**Create a monitoring checklist:**

```
Weekly API Usage Check:
- [ ] Log in to Anthropic Console
- [ ] Check total tokens used this month
- [ ] Compare to expected usage (~200K-300K tokens for moderate use)
- [ ] Review daily usage graph for spikes
- [ ] Calculate estimated monthly cost
- [ ] Verify cost is within budget ($1-5 for typical usage)
- [ ] Investigate any unusual patterns
```

---

##### View Detailed API Request Logs

**In Anthropic Console:**

Some Anthropic Console plans may provide detailed request logs showing:
- Timestamp of each API call
- Model used (Claude 3.5 Sonnet, etc.)
- Input and output token counts
- Request duration
- Response status

**Check your plan features:**
- Visit: https://console.anthropic.com/settings/plans
- Review available logging and monitoring features
- Consider upgrading if you need more detailed logs

**In Your Application Logs:**

The AI Website Builder logs API requests. View them on your server:

```bash
# View recent API requests
sudo journalctl -u website-builder --since "24 hours ago" | grep "API request"

# Count API requests today
sudo journalctl -u website-builder --since "today" | grep -c "API request"

# View API errors
sudo journalctl -u website-builder --since "7 days ago" | grep -i "api.*error"
```

---

#### Application-Level Cost Controls

The AI Website Builder includes built-in cost protection features to prevent unexpected API usage and costs.

---

##### Monthly Token Threshold Configuration

The application includes a configurable monthly token limit that automatically stops API calls when the threshold is reached.

**Why This Matters:**
- Prevents runaway costs from bugs or abuse
- Provides a hard limit on monthly API spending
- Automatically resets at the start of each month
- Gives you control over maximum API costs

---

**1. Understand the Token Threshold:**

**Default Configuration:**
```bash
MONTHLY_TOKEN_THRESHOLD=1000000  # 1 million tokens per month
```

**What This Means:**
- The application tracks total tokens used (input + output)
- When the threshold is reached, API calls are blocked
- Users see an error message: "Monthly token limit reached"
- The counter resets automatically on the 1st of each month

**Cost Implications:**

With a 1 million token threshold:
- **Worst case (all output tokens):** 1M × $15/1M = $15.00
- **Typical mix (60% output, 40% input):** ~$10.80
- **Best case (all input tokens):** 1M × $3/1M = $3.00

**Recommended Thresholds by Budget:**

| Monthly Budget | Recommended Threshold | Expected Cost Range |
|----------------|----------------------|---------------------|
| $5 | 300,000 tokens | $1.80 - $4.50 |
| $10 | 600,000 tokens | $3.60 - $9.00 |
| $15 | 1,000,000 tokens | $6.00 - $15.00 |
| $25 | 1,500,000 tokens | $9.00 - $22.50 |
| $50 | 3,000,000 tokens | $18.00 - $45.00 |

---

**2. Configure the Token Threshold:**

**On your server:**

```bash
# SSH into your server
ssh ubuntu@YOUR_INSTANCE_IP

# Edit the .env file
nano /home/ubuntu/ai-website-builder/.env
```

**Find and modify the threshold:**

```bash
# Rate Limiting and Cost Controls
MAX_REQUESTS_PER_MINUTE=10
MONTHLY_TOKEN_THRESHOLD=1000000  # ← Change this value
```

**Example Configurations:**

**Conservative (Low Budget):**
```bash
MONTHLY_TOKEN_THRESHOLD=300000  # ~$1.80-$4.50/month
```

**Moderate (Typical Usage):**
```bash
MONTHLY_TOKEN_THRESHOLD=1000000  # ~$6-$15/month (default)
```

**High Usage (Active Content Creation):**
```bash
MONTHLY_TOKEN_THRESHOLD=3000000  # ~$18-$45/month
```

**Unlimited (No Limit):**
```bash
MONTHLY_TOKEN_THRESHOLD=999999999  # Effectively unlimited (not recommended)
```

**Save and exit:** Press `Ctrl+X`, then `Y`, then `Enter`

---

**3. Restart the Application:**

After changing the threshold, restart the application to apply the new configuration:

```bash
sudo systemctl restart website-builder
sudo systemctl status website-builder
```

**Verify the change:**

```bash
# Check the .env file
grep MONTHLY_TOKEN_THRESHOLD /home/ubuntu/ai-website-builder/.env

# Check application logs for the new threshold
sudo journalctl -u website-builder -n 20 --no-pager | grep -i threshold
```

---

**4. Monitor Token Usage Against Threshold:**

**Check current usage:**

The application tracks token usage internally. To view current usage:

```bash
# View application logs for token usage
sudo journalctl -u website-builder --since "1 month ago" | grep -i "tokens used"

# Or check application metrics (if implemented)
# This depends on your application's logging configuration
```

**What happens when threshold is reached:**

1. **User attempts to generate content**
2. **Application checks current month's token usage**
3. **If threshold exceeded:**
   - API call is blocked
   - User sees error: "Monthly token limit reached. Please try again next month."
   - Request is logged with reason
4. **If under threshold:**
   - API call proceeds normally
   - Token count is updated

**Reset behavior:**

- The token counter automatically resets on the 1st of each month at 00:00 UTC
- No manual intervention required
- Previous month's usage is logged for historical tracking

---

**5. Adjust Threshold Based on Usage:**

**Monthly Review Process:**

At the end of each month:

1. **Check actual usage in Anthropic Console**
2. **Compare to your threshold setting**
3. **Adjust threshold if needed:**

**If you hit the threshold:**
- **Option A:** Increase threshold if usage was legitimate
- **Option B:** Optimize usage patterns to reduce token consumption
- **Option C:** Keep threshold and accept the limit

**If you're well under the threshold:**
- **Option A:** Lower threshold to provide tighter cost control
- **Option B:** Keep current threshold for headroom

**Example Adjustment:**

```
Month 1: Threshold = 1,000,000 tokens
Actual usage: 750,000 tokens (75% of threshold)
Cost: ~$11.25

Decision: Keep threshold at 1,000,000 (good headroom)

Month 2: Threshold = 1,000,000 tokens
Actual usage: 1,000,000 tokens (hit limit)
Cost: ~$15.00

Decision: Increase threshold to 1,500,000 tokens
```

---

##### Rate Limiting Configuration

In addition to monthly token limits, the application includes per-minute rate limiting to prevent abuse and control costs.

**Default Configuration:**

```bash
MAX_REQUESTS_PER_MINUTE=10  # Maximum 10 API requests per minute
```

**What This Means:**
- Users can make up to 10 AI generation requests per minute
- Requests beyond this limit are rejected with "Rate limit exceeded"
- Prevents rapid-fire requests that could quickly consume tokens
- Protects against bugs that might cause request loops

**When to Adjust:**

**Increase the limit if:**
- You have multiple users accessing the Builder Interface simultaneously
- You're doing bulk content generation
- Legitimate usage is being blocked

**Decrease the limit if:**
- You want tighter cost control
- You're concerned about abuse
- You have a single user and don't need high throughput

**Example Configurations:**

```bash
# Very restrictive (single user, low budget)
MAX_REQUESTS_PER_MINUTE=5

# Default (moderate usage)
MAX_REQUESTS_PER_MINUTE=10

# Permissive (multiple users, high usage)
MAX_REQUESTS_PER_MINUTE=30

# No limit (not recommended)
MAX_REQUESTS_PER_MINUTE=999999
```

**To change the rate limit:**

1. Edit `.env` file: `nano /home/ubuntu/ai-website-builder/.env`
2. Modify `MAX_REQUESTS_PER_MINUTE` value
3. Save and restart: `sudo systemctl restart website-builder`

---

#### Cost Monitoring Dashboard Links

Quick reference links for monitoring costs:

**AWS Lightsail:**
- **Lightsail Console:** https://lightsail.aws.amazon.com/
- **Billing Dashboard:** https://console.aws.amazon.com/billing/
- **Cost Explorer:** https://console.aws.amazon.com/cost-management/home#/cost-explorer
- **Budgets:** https://console.aws.amazon.com/billing/home#/budgets

**Anthropic Claude API:**
- **Anthropic Console:** https://console.anthropic.com/
- **Usage Dashboard:** https://console.anthropic.com/settings/usage
- **API Keys:** https://console.anthropic.com/settings/keys
- **Billing:** https://console.anthropic.com/settings/billing

**Application Configuration:**
- **Token Threshold:** Edit `/home/ubuntu/ai-website-builder/.env` on server
- **Application Logs:** `sudo journalctl -u website-builder -f`

---

#### Cost Monitoring Best Practices

**1. Set Up Alerts Early**
- Configure AWS Budget alerts during initial deployment
- Set conservative thresholds (80% and 100% of expected costs)
- Use multiple alert levels for early warning

**2. Review Costs Weekly**
- Check AWS Billing Dashboard every Monday
- Review Anthropic Console usage weekly
- Compare actual costs to expected costs
- Investigate any anomalies immediately

**3. Track Usage Trends**
- Keep a simple spreadsheet of monthly costs
- Track: AWS Lightsail, Claude API, total cost
- Identify trends (increasing, stable, decreasing)
- Adjust budgets and thresholds based on trends

**4. Optimize Token Usage**
- Review prompts to minimize unnecessary tokens
- Use shorter system prompts where possible
- Cache frequently used context
- Avoid redundant API calls

**5. Document Cost Baselines**
- Record typical monthly costs after 2-3 months
- Use this as your baseline for comparison
- Alert on deviations >20% from baseline

**6. Test Cost Controls**
- Verify monthly token threshold works as expected
- Test rate limiting behavior
- Ensure alerts are delivered to correct email addresses

**7. Plan for Growth**
- If usage increases, adjust thresholds proactively
- Consider upgrading Lightsail instance if needed
- Budget for increased API costs as traffic grows

---

#### Cost Monitoring Checklist

Use this checklist for regular cost monitoring:

**Weekly (5 minutes):**
- [ ] Check AWS Billing Dashboard for current month costs
- [ ] Verify Lightsail costs are ~$10 (expected amount)
- [ ] Check Anthropic Console for API usage
- [ ] Verify API costs are within expected range ($1-5 typical)
- [ ] Review any budget alert emails received
- [ ] Investigate any unusual cost patterns

**Monthly (15 minutes):**
- [ ] Review complete month's AWS costs in Cost Explorer
- [ ] Review complete month's Anthropic API usage
- [ ] Calculate total monthly cost (AWS + API)
- [ ] Compare to budget and previous months
- [ ] Adjust token threshold if needed
- [ ] Update cost tracking spreadsheet
- [ ] Verify no unused AWS resources (snapshots, unattached IPs)

**Quarterly (30 minutes):**
- [ ] Analyze 3-month cost trends
- [ ] Review and adjust AWS Budget thresholds
- [ ] Optimize token usage based on patterns
- [ ] Consider Lightsail instance sizing (upgrade/downgrade)
- [ ] Review and update cost documentation
- [ ] Plan budget for next quarter

---

### Cost Optimization Recommendations

This section provides actionable strategies for optimizing costs across all components of the AI Website Builder deployment. By implementing these recommendations, you can reduce expenses while maintaining performance and functionality.

---

#### Optimizing Claude API Usage

Claude API costs are variable and represent the most significant opportunity for cost optimization. The following strategies can help reduce token consumption and API costs.

---

##### 1. Optimize Prompt Engineering

**Strategy:** Reduce token usage by crafting efficient prompts that minimize input tokens while maintaining output quality.

**Implementation:**

**Use Concise System Prompts:**
- Remove unnecessary explanations and examples from system prompts
- Focus on essential instructions only
- Avoid redundant context that doesn't improve output quality

**Example - Before (Verbose):**
```
You are an AI assistant that helps create website content. Please generate 
high-quality, engaging content for a website. Make sure the content is 
professional, well-written, and appropriate for the target audience. Use 
proper grammar and formatting. Be creative and engaging.
```
**Tokens:** ~50 input tokens

**Example - After (Concise):**
```
Generate professional website content with proper grammar and formatting.
```
**Tokens:** ~12 input tokens
**Savings:** ~76% reduction in system prompt tokens

**Provide Only Necessary Context:**
- Include only the context Claude needs to generate accurate content
- Avoid sending entire page histories or irrelevant information
- Use targeted context for each request

**Reuse Prompts:**
- Cache frequently used prompt templates
- Avoid regenerating the same instructions for each request
- Store common prompt patterns in the application

**Expected Savings:** 20-40% reduction in input token usage

---

##### 2. Implement Response Caching

**Strategy:** Cache AI-generated content to avoid regenerating the same or similar content multiple times.

**Implementation:**

**Cache Generated Content:**
- Store generated content in the application database
- Reuse cached content for similar requests
- Implement a cache expiration policy (e.g., 30 days)

**Example Caching Logic:**
```typescript
// Before making API call, check cache
const cachedContent = await checkCache(prompt);
if (cachedContent) {
  return cachedContent; // No API call needed
}

// If not cached, make API call
const newContent = await callClaudeAPI(prompt);
await saveToCache(prompt, newContent);
return newContent;
```

**Cache Similar Requests:**
- Use fuzzy matching to identify similar prompts
- Return cached results for near-duplicate requests
- Implement a similarity threshold (e.g., 90% match)

**Expected Savings:** 30-50% reduction in API calls for sites with repetitive content

---

##### 3. Reduce Output Token Generation

**Strategy:** Limit the length of generated content to reduce output token costs (which are 5x more expensive than input tokens).

**Implementation:**

**Set Appropriate max_tokens Limits:**
```typescript
// Configure max_tokens based on content type
const maxTokens = {
  headline: 50,        // Short headlines
  paragraph: 200,      // Single paragraph
  section: 500,        // Full section
  page: 1500,          // Complete page
};
```

**Use Structured Output Formats:**
- Request specific formats (bullet points, short paragraphs)
- Avoid asking for lengthy explanations
- Use clear length constraints in prompts

**Example:**
```
Generate a 2-3 sentence product description (max 50 words).
```

**Implement Content Length Validation:**
- Validate generated content length
- Reject and regenerate if output is unnecessarily long
- Provide feedback to improve future generations

**Expected Savings:** 20-30% reduction in output token costs

---

##### 4. Batch Similar Requests

**Strategy:** Combine multiple related content generation requests into a single API call to reduce overhead.

**Implementation:**

**Batch Multiple Sections:**
```typescript
// Instead of 3 separate API calls:
// Call 1: Generate headline
// Call 2: Generate description
// Call 3: Generate call-to-action

// Use 1 combined API call:
const prompt = `
Generate the following for a product page:
1. Headline (10 words max)
2. Description (50 words)
3. Call-to-action button text (3-5 words)
`;
```

**Benefits:**
- Reduces total API calls
- Shares context across generations
- Maintains consistency across related content
- Reduces input token overhead from repeated system prompts

**Expected Savings:** 15-25% reduction in total API costs for batch operations

---

##### 5. Implement Smart Regeneration

**Strategy:** Only regenerate content when necessary, avoiding unnecessary API calls.

**Implementation:**

**Confirm Before Regeneration:**
- Ask users to confirm before regenerating existing content
- Show preview of current content
- Provide "Edit" option instead of full regeneration

**Implement Incremental Updates:**
- Allow users to edit specific sections without regenerating entire pages
- Use targeted prompts for small changes
- Preserve unchanged content

**Track Regeneration Patterns:**
- Log how often users regenerate content
- Identify patterns of unnecessary regenerations
- Provide guidance to users on efficient content creation

**Expected Savings:** 10-20% reduction in unnecessary API calls

---

##### 6. Use Appropriate Model Selection

**Strategy:** Use the most cost-effective Claude model for each use case.

**Current Model:** Claude 3.5 Sonnet ($3/$15 per 1M tokens)

**Alternative Models:**

| Model | Input Cost | Output Cost | Best For |
|-------|------------|-------------|----------|
| Claude 3.5 Sonnet | $3/1M | $15/1M | **Current** - Best balance |
| Claude 3 Haiku | $0.25/1M | $1.25/1M | Simple content, high volume |
| Claude 3 Opus | $15/1M | $75/1M | Complex content, high quality |

**When to Consider Haiku:**
- Simple, repetitive content (product descriptions, meta tags)
- High-volume content generation
- Budget constraints with acceptable quality trade-offs
- **Potential Savings:** Up to 92% cost reduction for suitable use cases

**When to Use Sonnet (Current):**
- General-purpose content generation
- Balance of quality and cost
- Most use cases for the AI Website Builder

**When to Consider Opus:**
- Highly complex content requiring nuanced understanding
- Premium content where quality is paramount
- Low-volume, high-value content generation

**Implementation:**
- Configure model selection in application settings
- Allow per-request model selection for advanced users
- Default to Sonnet for best balance

---

##### 7. Monitor and Optimize High-Usage Patterns

**Strategy:** Identify and optimize the most expensive usage patterns.

**Implementation:**

**Analyze Token Usage by Feature:**
```bash
# Review application logs to identify high-token features
sudo journalctl -u website-builder --since "30 days ago" | grep "tokens" | sort | uniq -c
```

**Identify Optimization Opportunities:**
- Which features consume the most tokens?
- Are there patterns of inefficient usage?
- Can high-cost features be optimized or cached?

**Example Findings:**
```
Feature: Homepage generation
Average tokens: 5,000 per request
Frequency: 50 requests/month
Monthly cost: $3.75

Optimization: Implement caching for homepage templates
New frequency: 10 requests/month (80% cache hit rate)
New monthly cost: $0.75
Savings: $3.00/month (80% reduction)
```

**Expected Savings:** 25-50% reduction in total API costs through targeted optimizations

---

#### Optimizing AWS Lightsail Instance Costs

While Lightsail costs are fixed monthly, there are strategies to ensure you're using the most cost-effective instance size and avoiding unnecessary charges.

---

##### 1. Right-Size Your Instance

**Strategy:** Choose the smallest instance size that meets your performance requirements.

**Current Recommendation:** $10/month (2 GB RAM, 1 vCPU)

**When to Consider Downsizing to $5/month (1 GB RAM):**

**Indicators:**
- Very low traffic (< 1,000 page views/month)
- Infrequent AI content generation (< 10 requests/month)
- Single user access
- Testing or development environment

**How to Check Resource Usage:**

```bash
# SSH into your server
ssh ubuntu@YOUR_INSTANCE_IP

# Check memory usage
free -h

# Check CPU usage
top -bn1 | grep "Cpu(s)"

# Check disk usage
df -h
```

**Interpretation:**

**Memory Usage:**
```
              total        used        free
Mem:           2.0Gi       1.2Gi       800Mi
```
- **Used < 60% consistently:** Consider downsizing
- **Used > 80% consistently:** Current size appropriate or consider upgrading
- **Used > 90% frequently:** Upgrade to $20/month plan

**CPU Usage:**
```
Cpu(s):  15.2%us,  2.3%sy,  0.0%ni, 82.1%id
```
- **Idle (id) > 80% consistently:** CPU not a bottleneck
- **Idle (id) < 20% frequently:** Consider upgrading

**Downgrade Process:**

**Warning:** Downgrading requires creating a snapshot and launching a new instance. This involves downtime.

1. **Create a snapshot of your current instance:**
   ```bash
   aws lightsail create-instance-snapshot \
     --instance-name ai-website-builder \
     --instance-snapshot-name pre-downgrade-snapshot
   ```

2. **Create a new instance from snapshot with smaller size:**
   ```bash
   aws lightsail create-instances-from-snapshot \
     --instance-names ai-website-builder-small \
     --instance-snapshot-name pre-downgrade-snapshot \
     --bundle-id micro_2_0  # $5/month plan
   ```

3. **Update DNS to point to new instance**
4. **Test thoroughly**
5. **Delete old instance**

**Expected Savings:** $5/month ($60/year) if downgrading from $10 to $5 plan

---

##### 2. Avoid Data Transfer Overages

**Strategy:** Stay within the included data transfer allowance to avoid overage charges.

**Included Transfer:**
- $10/month plan: 2 TB (2,000 GB) outbound data transfer
- Overage cost: $0.09 per GB

**Optimization Techniques:**

**Optimize Images:**
```bash
# Install image optimization tools
sudo apt-get install jpegoptim optipng

# Optimize JPEG images (on server)
find /var/www/html -name "*.jpg" -exec jpegoptim --max=85 {} \;

# Optimize PNG images
find /var/www/html -name "*.png" -exec optipng -o2 {} \;
```

**Expected Savings:** 40-60% reduction in image file sizes

**Enable NGINX Compression:**

NGINX compression is already configured by the `configure-nginx.sh` script, but verify it's enabled:

```bash
# Check NGINX compression configuration
sudo nginx -T | grep gzip
```

**Expected Output:**
```
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml;
```

**Expected Savings:** 60-80% reduction in text-based content transfer

**Implement Browser Caching:**

Configure NGINX to set appropriate cache headers:

```bash
# Edit NGINX configuration
sudo nano /etc/nginx/sites-available/default
```

**Add caching headers:**
```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

**Reload NGINX:**
```bash
sudo nginx -t
sudo systemctl reload nginx
```

**Expected Savings:** 50-70% reduction in repeat visitor bandwidth

**Use a CDN for High-Traffic Sites:**

For sites exceeding 1 TB/month transfer:
- Consider Cloudflare (free tier available)
- Offload static assets to CDN
- Reduce Lightsail data transfer costs

**Expected Savings:** Can eliminate data transfer overages entirely

---

##### 3. Eliminate Unused Resources

**Strategy:** Regularly audit and remove unused AWS resources to avoid unnecessary charges.

**Monthly Audit Checklist:**

**Check for Unused Instances:**
```bash
aws lightsail get-instances --query 'instances[*].[name,state.name]' --output table
```
- Verify you only have ONE instance running
- Delete any stopped or unused instances

**Check for Unattached Static IPs:**
```bash
aws lightsail get-static-ips --query 'staticIps[*].[name,isAttached]' --output table
```
- **Cost:** $0.005/hour (~$3.60/month) per unattached IP
- Delete unattached static IPs or attach them to instances

**Check for Old Snapshots:**
```bash
aws lightsail get-instance-snapshots --query 'instanceSnapshots[*].[name,createdAt,sizeInGb]' --output table
```
- **Cost:** $0.05 per GB per month
- Keep only recent snapshots (last 2-3 backups)
- Delete snapshots older than 90 days

**Example Cleanup:**
```bash
# Delete old snapshot
aws lightsail delete-instance-snapshot --instance-snapshot-name old-snapshot-2023-01-01

# Delete unattached static IP
aws lightsail release-static-ip --static-ip-name unused-ip
```

**Expected Savings:** $3-10/month from eliminating unused resources

---

##### 4. Optimize Backup Strategy

**Strategy:** Balance data protection with storage costs for snapshots.

**Snapshot Costs:**
- $0.05 per GB per month
- Example: 20 GB snapshot = $1.00/month

**Recommended Backup Strategy:**

**Keep 3 Snapshots:**
- Most recent snapshot (current state)
- Weekly snapshot (7 days old)
- Monthly snapshot (30 days old)

**Automate Snapshot Rotation:**
```bash
# Create a snapshot rotation script
cat > /home/ubuntu/rotate-snapshots.sh << 'EOF'
#!/bin/bash
# Create new snapshot
aws lightsail create-instance-snapshot \
  --instance-name ai-website-builder \
  --instance-snapshot-name "backup-$(date +%Y-%m-%d)"

# Delete snapshots older than 30 days
aws lightsail get-instance-snapshots \
  --query "instanceSnapshots[?createdAt<='$(date -d '30 days ago' --iso-8601)'].name" \
  --output text | xargs -n1 aws lightsail delete-instance-snapshot --instance-snapshot-name
EOF

chmod +x /home/ubuntu/rotate-snapshots.sh
```

**Schedule with Cron:**
```bash
# Run weekly on Sundays at 2 AM
crontab -e
# Add: 0 2 * * 0 /home/ubuntu/rotate-snapshots.sh
```

**Expected Savings:** Maintain 3 snapshots (~$3/month) vs. unlimited accumulation

---

#### Staying Within Budget

Implementing cost controls and budget management strategies ensures your deployment costs remain predictable and manageable.

---

##### 1. Set Conservative Token Thresholds

**Strategy:** Configure monthly token limits that align with your budget.

**Budget-Based Threshold Recommendations:**

| Monthly Budget | Recommended Threshold | Expected API Cost |
|----------------|----------------------|-------------------|
| $5 total | 150,000 tokens | $1-2 API cost |
| $10 total | 300,000 tokens | $2-4 API cost |
| $15 total | 600,000 tokens | $4-9 API cost |
| $25 total | 1,200,000 tokens | $8-18 API cost |

**Implementation:**
```bash
# Edit .env file on server
nano /home/ubuntu/ai-website-builder/.env

# Set threshold based on budget
MONTHLY_TOKEN_THRESHOLD=300000  # For $10/month total budget
```

**Expected Outcome:** Hard limit prevents API costs from exceeding budget

---

##### 2. Implement Multi-Level Budget Alerts

**Strategy:** Set up multiple alert thresholds to provide early warning of budget overruns.

**Recommended Alert Structure:**

**Alert Level 1 - 50% of Budget:**
- **Purpose:** Early awareness of usage trends
- **Action:** Review usage patterns, no immediate action needed
- **Example:** $7.50 spent of $15 budget

**Alert Level 2 - 80% of Budget:**
- **Purpose:** Warning that budget limit is approaching
- **Action:** Review and optimize high-cost activities
- **Example:** $12.00 spent of $15 budget

**Alert Level 3 - 100% of Budget:**
- **Purpose:** Budget limit reached
- **Action:** Immediate investigation and cost reduction measures
- **Example:** $15.00 spent of $15 budget

**Alert Level 4 - 120% of Budget:**
- **Purpose:** Budget exceeded
- **Action:** Emergency cost controls, consider reducing token threshold
- **Example:** $18.00 spent of $15 budget

**Setup in AWS Budgets:**
```
Budget Name: AI-Website-Builder-Budget
Amount: $15.00/month
Alerts:
  - 50% threshold → Email notification
  - 80% threshold → Email notification
  - 100% threshold → Email notification + SMS (optional)
  - 120% threshold → Email notification + SMS
```

**Expected Outcome:** Early detection of cost overruns with time to respond

---

##### 3. Conduct Monthly Cost Reviews

**Strategy:** Regular cost reviews help identify trends and optimization opportunities.

**Monthly Review Process (15 minutes):**

**1. Gather Cost Data:**
```bash
# AWS Lightsail costs
# Visit: https://console.aws.amazon.com/billing/

# Claude API costs
# Visit: https://console.anthropic.com/settings/usage
```

**2. Calculate Total Costs:**
```
AWS Lightsail: $______
Claude API:    $______
Domain (÷12):  $______
Total:         $______
```

**3. Compare to Budget:**
```
Budget:        $______
Actual:        $______
Variance:      $______ (over/under)
Percentage:    ____%
```

**4. Analyze Trends:**
- Is usage increasing, stable, or decreasing?
- Are there unexpected spikes?
- Is the trend sustainable within budget?

**5. Take Action:**
- **Under budget:** No action needed, maintain current usage
- **At budget:** Monitor closely, consider optimizations
- **Over budget:** Implement cost reduction measures immediately

**6. Document Findings:**
Keep a simple cost tracking spreadsheet:
```
Month    | AWS  | API  | Total | Budget | Variance | Notes
---------|------|------|-------|--------|----------|------------------
Jan 2024 | $10  | $3   | $13   | $15    | -$2      | Normal usage
Feb 2024 | $10  | $8   | $18   | $15    | +$3      | High content gen
Mar 2024 | $10  | $4   | $14   | $15    | -$1      | Optimized prompts
```

**Expected Outcome:** Proactive cost management and early problem detection

---

##### 4. Educate Users on Cost-Effective Usage

**Strategy:** If multiple users access the Builder Interface, educate them on cost-effective content generation practices.

**User Guidelines:**

**Best Practices for Cost-Effective Content Generation:**

1. **Plan Before Generating:**
   - Outline content requirements before using AI
   - Avoid trial-and-error generation
   - Use AI for final content, not brainstorming

2. **Use Regeneration Sparingly:**
   - Review generated content carefully
   - Edit manually instead of regenerating
   - Only regenerate if content is significantly off-target

3. **Provide Clear, Specific Prompts:**
   - Specific prompts generate better results on first try
   - Reduces need for regeneration
   - Saves tokens and costs

4. **Reuse and Adapt Existing Content:**
   - Copy and modify existing content when appropriate
   - Use AI for new content only
   - Maintain a content library for reuse

**Expected Outcome:** 20-40% reduction in API costs through user education

---

##### 5. Implement Usage Quotas for Multi-User Environments

**Strategy:** If multiple users share the Builder Interface, implement per-user quotas to distribute costs fairly.

**Implementation Considerations:**

**Per-User Token Limits:**
```typescript
// Example configuration
const userQuotas = {
  admin: 500000,      // 500K tokens/month
  editor: 200000,     // 200K tokens/month
  contributor: 100000 // 100K tokens/month
};
```

**Benefits:**
- Prevents single user from consuming entire budget
- Encourages efficient usage
- Provides fair access to AI features

**Note:** This requires application-level changes and is an advanced optimization.

**Expected Outcome:** Balanced usage across multiple users

---

### Cost Optimization Summary

**Quick Reference: Top 5 Cost Optimization Actions**

1. **Set Token Threshold:** Configure `MONTHLY_TOKEN_THRESHOLD` in `.env` to match your budget
2. **Enable Caching:** Implement content caching to reduce duplicate API calls
3. **Optimize Prompts:** Use concise prompts and limit output token generation
4. **Right-Size Instance:** Use $5/month Lightsail plan if traffic is low
5. **Set Up Alerts:** Configure AWS Budget alerts at 50%, 80%, and 100% thresholds

**Expected Total Savings:**
- **API Costs:** 30-60% reduction through optimization
- **Infrastructure Costs:** $5/month ($60/year) if downsizing instance
- **Total Potential Savings:** $10-20/month ($120-240/year)

**Cost Optimization Checklist:**

- [ ] Configure monthly token threshold based on budget
- [ ] Set up AWS Budget alerts (50%, 80%, 100%)
- [ ] Implement prompt optimization for high-usage features
- [ ] Enable content caching for frequently generated content
- [ ] Optimize images and enable NGINX compression
- [ ] Audit and remove unused AWS resources monthly
- [ ] Conduct monthly cost reviews and trend analysis
- [ ] Right-size Lightsail instance based on actual usage
- [ ] Educate users on cost-effective content generation
- [ ] Monitor and optimize high-token usage patterns

---

**End of Cost Management Section**

For ongoing system maintenance (security updates, SSL certificates, backups), see the next section: [System Maintenance Procedures](#system-maintenance-procedures).

---

**End of Deployment Guide**
For system-level maintenance (security updates, SSL certificate renewal, backups), see the next section: [System Maintenance Procedures](#system-maintenance-procedures).

---

### System Maintenance Procedures

In addition to application updates, your deployed AI Website Builder requires ongoing system-level maintenance to ensure security, reliability, and data protection. This section covers automatic security updates, SSL certificate renewal monitoring, and backup/restore procedures.

---

#### Automatic Security Updates Configuration

Keeping your Ubuntu server up-to-date with security patches is critical for maintaining a secure deployment. Ubuntu provides the `unattended-upgrades` package to automatically install security updates without manual intervention.

**Why This Matters:**
- Security vulnerabilities are discovered regularly in system packages
- Automatic updates ensure critical patches are applied promptly
- Reduces the risk of exploitation from known vulnerabilities
- Minimizes manual maintenance overhead

---

##### Verify Unattended Upgrades is Installed

The `unattended-upgrades` package is typically pre-installed on Ubuntu systems, but let's verify:

```bash
# SSH into your server
ssh ubuntu@YOUR_INSTANCE_IP

# Check if unattended-upgrades is installed
dpkg -l | grep unattended-upgrades
```

**Expected Output:**
```
ii  unattended-upgrades  2.8ubuntu1  all  automatic installation of security upgrades
```

**If not installed:**
```bash
sudo apt-get update
sudo apt-get install unattended-upgrades
```

---

##### Configure Automatic Security Updates

Configure `unattended-upgrades` to automatically install security updates:

```bash
# Enable automatic updates
sudo dpkg-reconfigure -plow unattended-upgrades
```

**When prompted:**
- Select "Yes" to enable automatic updates
- Press Enter to confirm

**Verify the configuration:**

```bash
cat /etc/apt/apt.conf.d/20auto-upgrades
```

**Expected Output:**
```
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

**What these settings mean:**
- `Update-Package-Lists "1"`: Update package lists daily
- `Unattended-Upgrade "1"`: Install security updates automatically daily

---

##### Customize Unattended Upgrades Configuration (Optional)

For more control over automatic updates, edit the main configuration file:

```bash
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

**Key configuration options:**

```
// Automatically upgrade packages from these origins
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    // Uncomment to also install stable updates automatically:
    // "${distro_id}:${distro_codename}-updates";
};

// Automatically reboot if required (use with caution)
// Unattended-Upgrade::Automatic-Reboot "false";

// If automatic reboot is enabled, reboot at a specific time
// Unattended-Upgrade::Automatic-Reboot-Time "02:00";

// Email notifications (requires mail server configuration)
// Unattended-Upgrade::Mail "admin@yourdomain.com";
// Unattended-Upgrade::MailReport "on-change";

// Remove unused dependencies automatically
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Automatically remove old kernel packages
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
```

**Recommended Settings for Production:**
- Keep automatic reboots disabled (`"false"`) to avoid unexpected downtime
- Enable email notifications if you have a mail server configured
- Enable removal of unused dependencies to save disk space
- Only install security updates automatically (not all updates)

**Save and exit:** Press `Ctrl+X`, then `Y`, then `Enter`

---

##### Monitor Automatic Updates

View the log of automatic updates to see what has been installed:

```bash
# View recent automatic update activity
sudo cat /var/log/unattended-upgrades/unattended-upgrades.log
```

**Example Output:**
```
2024-01-15 06:00:01,234 INFO Starting unattended upgrades script
2024-01-15 06:00:05,123 INFO Allowed origins are: ['o=Ubuntu,a=jammy-security']
2024-01-15 06:00:10,456 INFO Packages that will be upgraded: libssl3 openssl
2024-01-15 06:00:45,789 INFO Package libssl3 upgraded
2024-01-15 06:00:50,123 INFO Package openssl upgraded
2024-01-15 06:01:00,456 INFO All upgrades installed
```

**Check if a reboot is required after updates:**

```bash
# Check if system needs reboot
ls /var/run/reboot-required
```

**If the file exists:**
```
/var/run/reboot-required
```

**View which packages require a reboot:**
```bash
cat /var/run/reboot-required.pkgs
```

**Schedule a reboot during a maintenance window:**
```bash
# Reboot immediately (use with caution)
sudo reboot

# Or schedule a reboot at a specific time
sudo shutdown -r 02:00  # Reboot at 2:00 AM
```

---

##### Manual Security Updates

While automatic updates handle most security patches, you may occasionally need to perform manual updates:

```bash
# Update package lists
sudo apt-get update

# View available upgrades
apt list --upgradable

# Install all available updates
sudo apt-get upgrade -y

# For major version upgrades (use with caution)
sudo apt-get dist-upgrade -y

# Clean up old packages
sudo apt-get autoremove -y
sudo apt-get autoclean
```

**When to perform manual updates:**
- Before deploying major application changes
- When investigating security vulnerabilities
- During scheduled maintenance windows
- After system configuration changes

**Best Practices:**
- Review the list of packages to be upgraded before proceeding
- Test updates in a staging environment first (if available)
- Backup critical data before major updates
- Monitor application logs after updates to catch any issues
- Schedule updates during low-traffic periods

---

#### SSL Certificate Renewal Monitoring

Let's Encrypt SSL certificates are valid for 90 days and must be renewed before expiration. Certbot (the Let's Encrypt client) automatically handles renewal, but you should monitor the process to ensure certificates remain valid.

**Why This Matters:**
- Expired SSL certificates cause browser warnings and prevent HTTPS access
- Automatic renewal can fail due to DNS issues, firewall problems, or rate limits
- Monitoring ensures you can intervene before certificates expire
- Maintains user trust and SEO rankings

---

##### Verify Certbot Automatic Renewal is Configured

During the initial deployment (configure-ssl.sh script), Certbot was configured to automatically renew certificates. Let's verify this configuration:

```bash
# Check if the Certbot renewal timer is active
sudo systemctl status certbot.timer
```

**Expected Output:**
```
● certbot.timer - Run certbot twice daily
     Loaded: loaded (/lib/systemd/system/certbot.timer; enabled; vendor preset: enabled)
     Active: active (waiting) since Mon 2024-01-15 10:00:00 UTC; 5 days ago
    Trigger: Tue 2024-01-16 12:00:00 UTC; 1h 30min left
   Triggers: ● certbot.service

Jan 15 10:00:00 ip-172-26-1-123 systemd[1]: Started Run certbot twice daily.
```

**Key indicators:**
- `Active: active (waiting)` - Timer is running
- `Trigger:` shows the next scheduled renewal check
- `enabled` - Timer will start automatically on boot

**If the timer is not active:**
```bash
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---

##### Check Current Certificate Status

View the status of your SSL certificates:

```bash
sudo certbot certificates
```

**Expected Output:**
```
Found the following certs:
  Certificate Name: yourdomain.com
    Serial Number: 1234567890abcdef1234567890abcdef12345678
    Key Type: RSA
    Domains: yourdomain.com www.yourdomain.com
    Expiry Date: 2024-04-15 10:00:00+00:00 (VALID: 89 days)
    Certificate Path: /etc/letsencrypt/live/yourdomain.com/fullchain.pem
    Private Key Path: /etc/letsencrypt/live/yourdomain.com/privkey.pem
```

**Key information:**
- **Expiry Date:** When the certificate expires
- **VALID: X days:** Days remaining until expiration
- **Domains:** Which domains are covered by the certificate

**Certificate Renewal Timeline:**
- Certbot attempts renewal when certificates have 30 days or less remaining
- Certificates are valid for 90 days from issuance
- Renewal checks run twice daily (via certbot.timer)

---

##### Test Certificate Renewal

Test the renewal process without actually renewing the certificate:

```bash
sudo certbot renew --dry-run
```

**Expected Output:**
```
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/yourdomain.com.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Account registered.
Simulating renewal of an existing certificate for yourdomain.com and www.yourdomain.com

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Congratulations, all simulated renewals succeeded:
  /etc/letsencrypt/live/yourdomain.com/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

**What this test does:**
- Verifies DNS records are correctly configured
- Checks that port 80 is accessible (required for HTTP-01 challenge)
- Confirms Certbot can communicate with Let's Encrypt servers
- Validates the renewal configuration without issuing a new certificate

**If the dry-run succeeds:** Automatic renewal will work when certificates approach expiration.

**If the dry-run fails:** See the troubleshooting section below.

---

##### Manual Certificate Renewal

If you need to renew certificates manually (e.g., after fixing an issue):

```bash
# Renew all certificates that are due for renewal
sudo certbot renew

# Force renewal of all certificates (even if not due)
sudo certbot renew --force-renewal
```

**Expected Output:**
```
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/yourdomain.com.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Certificate not yet due for renewal

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The following certificates are not due for renewal yet:
  /etc/letsencrypt/live/yourdomain.com/fullchain.pem expires on 2024-04-15 (skipped)
No renewals were attempted.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

**After successful renewal, reload NGINX:**

```bash
sudo systemctl reload nginx
```

---

##### Monitor Certificate Renewal Logs

View Certbot renewal logs to check for issues:

```bash
# View recent Certbot activity
sudo cat /var/log/letsencrypt/letsencrypt.log | tail -50

# Or view the full log
sudo less /var/log/letsencrypt/letsencrypt.log
```

**Look for:**
- Successful renewal messages
- Error messages indicating renewal failures
- Rate limit warnings from Let's Encrypt

**Set up a monitoring script (optional):**

Create a simple script to check certificate expiration and send alerts:

```bash
# Create a monitoring script
sudo nano /usr/local/bin/check-ssl-expiry.sh
```

**Script content:**
```bash
#!/bin/bash
# Check SSL certificate expiration and alert if < 30 days

DOMAIN="yourdomain.com"
EXPIRY_DATE=$(sudo certbot certificates | grep "Expiry Date" | awk '{print $3}')
DAYS_LEFT=$(sudo certbot certificates | grep "VALID:" | awk '{print $2}')

if [ "$DAYS_LEFT" -lt 30 ]; then
    echo "WARNING: SSL certificate for $DOMAIN expires in $DAYS_LEFT days!"
    echo "Expiry Date: $EXPIRY_DATE"
    # Add email notification here if configured
fi
```

**Make the script executable:**
```bash
sudo chmod +x /usr/local/bin/check-ssl-expiry.sh
```

**Test the script:**
```bash
sudo /usr/local/bin/check-ssl-expiry.sh
```

**Schedule the script to run daily (optional):**
```bash
# Add to crontab
sudo crontab -e

# Add this line to run daily at 9 AM
0 9 * * * /usr/local/bin/check-ssl-expiry.sh
```

---

##### Troubleshooting Certificate Renewal Issues

**Issue:** Renewal fails with "Connection refused" or "Timeout"

**Cause:** Port 80 is not accessible or firewall is blocking HTTP traffic.

**Solution:**
```bash
# Verify UFW allows port 80
sudo ufw status

# Should show:
# 80/tcp                     ALLOW       Anywhere

# If not, add the rule:
sudo ufw allow 80/tcp

# Verify NGINX is running
sudo systemctl status nginx

# Test port 80 accessibility from outside
curl -I http://yourdomain.com
```

---

**Issue:** Renewal fails with "DNS problem: NXDOMAIN"

**Cause:** DNS records are not correctly configured or have changed.

**Solution:**
```bash
# Verify DNS resolution
dig yourdomain.com +short
dig www.yourdomain.com +short

# Should return your server's IP address
# If not, update DNS records at your registrar

# Wait for DNS propagation (5-30 minutes)
# Then retry renewal:
sudo certbot renew --dry-run
```

---

**Issue:** Renewal fails with "Rate limit exceeded"

**Cause:** Let's Encrypt has rate limits (5 certificates per domain per week).

**Solution:**
- Wait for the rate limit to reset (typically 7 days)
- Avoid using `--force-renewal` unnecessarily
- Use `--dry-run` for testing to avoid hitting rate limits
- If you need more certificates, consider using wildcard certificates

---

**Issue:** Certificate renewed but NGINX still serves old certificate

**Cause:** NGINX hasn't reloaded the new certificate files.

**Solution:**
```bash
# Reload NGINX to pick up new certificates
sudo systemctl reload nginx

# Or restart NGINX
sudo systemctl restart nginx

# Verify the new certificate is being served
echo | openssl s_client -servername yourdomain.com -connect yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates
```

---

#### Backup Procedures

Regular backups are essential for disaster recovery and protecting against data loss. This section covers what to backup, how to create backups, and where to store them.

**What to Backup:**

1. **Application Code** (if not in Git)
   - Location: `/home/ubuntu/ai-website-builder/`
   - Note: If your code is in a Git repository, you don't need to backup the code itself

2. **Environment Configuration**
   - Location: `/home/ubuntu/ai-website-builder/.env`
   - Contains: API keys, domain configuration, sensitive settings
   - **CRITICAL:** This file contains secrets and must be backed up securely

3. **Generated Website Content**
   - Location: `/var/www/html/` (or wherever NGINX serves static files)
   - Contains: User-generated HTML pages, images, assets

4. **Application Data** (if applicable)
   - Database files (if using SQLite or similar)
   - User uploads or media files
   - Application state or cache files

5. **System Configuration** (optional but recommended)
   - NGINX configuration: `/etc/nginx/sites-available/`
   - Systemd service files: `/etc/systemd/system/website-builder.service`
   - UFW rules: `sudo ufw status numbered > ufw-rules-backup.txt`
   - Tailscale configuration: `/var/lib/tailscale/`

**What NOT to Backup:**
- `node_modules/` directory (can be reinstalled with `npm install`)
- `dist/` directory (can be rebuilt with `npm run build`)
- System packages (can be reinstalled)
- SSL certificates (can be re-issued by Let's Encrypt)

---

##### Create a Manual Backup

**1. Create a backup directory:**

```bash
# On your server
mkdir -p ~/backups
cd ~/backups
```

**2. Backup the environment file:**

```bash
# Backup .env file (contains sensitive data)
cp /home/ubuntu/ai-website-builder/.env ~/backups/env-backup-$(date +%Y%m%d).txt

# Set restrictive permissions
chmod 600 ~/backups/env-backup-*.txt
```

**3. Backup generated website content:**

```bash
# Backup static website files
sudo tar -czf ~/backups/website-content-$(date +%Y%m%d).tar.gz /var/www/html/

# Verify the backup was created
ls -lh ~/backups/
```

**4. Backup application data (if applicable):**

```bash
# If using a database file (e.g., SQLite)
cp /home/ubuntu/ai-website-builder/database.db ~/backups/database-$(date +%Y%m%d).db

# If using other data directories
tar -czf ~/backups/app-data-$(date +%Y%m%d).tar.gz /home/ubuntu/ai-website-builder/data/
```

**5. Backup system configuration (optional):**

```bash
# Backup NGINX configuration
sudo tar -czf ~/backups/nginx-config-$(date +%Y%m%d).tar.gz /etc/nginx/sites-available/ /etc/nginx/sites-enabled/

# Backup systemd service file
sudo cp /etc/systemd/system/website-builder.service ~/backups/website-builder-service-$(date +%Y%m%d).service

# Backup UFW rules
sudo ufw status numbered > ~/backups/ufw-rules-$(date +%Y%m%d).txt
```

**6. Verify backup contents:**

```bash
# List all backups
ls -lh ~/backups/

# Verify tar archive contents (without extracting)
tar -tzf ~/backups/website-content-$(date +%Y%m%d).tar.gz | head -20
```

---

##### Download Backups to Local Machine

**Important:** Store backups off-server to protect against server failure or data loss.

**From your local machine:**

```bash
# Download all backups using scp
scp -r ubuntu@YOUR_INSTANCE_IP:~/backups/ ./local-backups/

# Or download specific backup files
scp ubuntu@YOUR_INSTANCE_IP:~/backups/env-backup-20240115.txt ./local-backups/
scp ubuntu@YOUR_INSTANCE_IP:~/backups/website-content-20240115.tar.gz ./local-backups/
```

**Alternative: Use rsync for incremental backups:**

```bash
# Sync backups to local machine (more efficient for repeated backups)
rsync -avz ubuntu@YOUR_INSTANCE_IP:~/backups/ ./local-backups/
```

**Verify downloaded backups:**

```bash
# On your local machine
ls -lh ./local-backups/

# Verify tar archive integrity
tar -tzf ./local-backups/website-content-20240115.tar.gz > /dev/null && echo "Backup is valid"
```

---

##### Automated Backup Script

Create a script to automate the backup process:

```bash
# On your server
sudo nano /usr/local/bin/backup-website.sh
```

**Script content:**

```bash
#!/bin/bash
# Automated backup script for AI Website Builder

# Configuration
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d-%H%M%S)
RETENTION_DAYS=30  # Keep backups for 30 days

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Starting backup at $(date)"

# Backup environment file
echo "Backing up .env file..."
cp /home/ubuntu/ai-website-builder/.env "$BACKUP_DIR/env-backup-$DATE.txt"
chmod 600 "$BACKUP_DIR/env-backup-$DATE.txt"

# Backup website content
echo "Backing up website content..."
sudo tar -czf "$BACKUP_DIR/website-content-$DATE.tar.gz" /var/www/html/ 2>/dev/null

# Backup application data (if applicable)
if [ -f /home/ubuntu/ai-website-builder/database.db ]; then
    echo "Backing up database..."
    cp /home/ubuntu/ai-website-builder/database.db "$BACKUP_DIR/database-$DATE.db"
fi

# Backup system configuration
echo "Backing up system configuration..."
sudo tar -czf "$BACKUP_DIR/nginx-config-$DATE.tar.gz" /etc/nginx/sites-available/ /etc/nginx/sites-enabled/ 2>/dev/null
sudo cp /etc/systemd/system/website-builder.service "$BACKUP_DIR/website-builder-service-$DATE.service" 2>/dev/null

# Remove old backups (older than RETENTION_DAYS)
echo "Cleaning up old backups..."
find "$BACKUP_DIR" -name "*-backup-*" -type f -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "website-content-*" -type f -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "database-*" -type f -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "nginx-config-*" -type f -mtime +$RETENTION_DAYS -delete

echo "Backup completed at $(date)"
echo "Backup location: $BACKUP_DIR"
ls -lh "$BACKUP_DIR" | tail -10
```

**Make the script executable:**

```bash
sudo chmod +x /usr/local/bin/backup-website.sh
```

**Test the script:**

```bash
sudo /usr/local/bin/backup-website.sh
```

**Expected Output:**
```
Starting backup at Mon Jan 15 10:00:00 UTC 2024
Backing up .env file...
Backing up website content...
Backing up database...
Backing up system configuration...
Cleaning up old backups...
Backup completed at Mon Jan 15 10:00:15 UTC 2024
Backup location: /home/ubuntu/backups
```

---

##### Schedule Automated Backups

Schedule the backup script to run automatically using cron:

```bash
# Edit the crontab
crontab -e
```

**Add one of the following lines:**

```bash
# Run daily at 2:00 AM
0 2 * * * /usr/local/bin/backup-website.sh >> /var/log/backup-website.log 2>&1

# Run weekly on Sunday at 3:00 AM
0 3 * * 0 /usr/local/bin/backup-website.sh >> /var/log/backup-website.log 2>&1

# Run twice daily at 2:00 AM and 2:00 PM
0 2,14 * * * /usr/local/bin/backup-website.sh >> /var/log/backup-website.log 2>&1
```

**Save and exit:** Press `Ctrl+X`, then `Y`, then `Enter`

**Verify the cron job is scheduled:**

```bash
crontab -l
```

**View backup logs:**

```bash
cat /var/log/backup-website.log
```

---

##### Backup to Cloud Storage (Advanced)

For additional protection, consider backing up to cloud storage:

**Option 1: AWS S3**

```bash
# Install AWS CLI (if not already installed)
sudo apt-get install awscli

# Configure AWS credentials
aws configure

# Sync backups to S3
aws s3 sync ~/backups/ s3://your-backup-bucket/ai-website-builder/
```

**Option 2: Rsync to Remote Server**

```bash
# Sync backups to a remote backup server
rsync -avz ~/backups/ user@backup-server:/path/to/backups/
```

**Option 3: Automated Cloud Backup Services**

Consider using services like:
- AWS Backup
- Backblaze B2
- Wasabi
- DigitalOcean Spaces

---

#### Restore Procedures

In case of data loss, server failure, or the need to migrate to a new server, follow these procedures to restore from backups.

**Restore Scenarios:**
1. Restore environment configuration after accidental deletion
2. Restore website content after data loss
3. Restore application data (database, user files)
4. Full server restore after catastrophic failure

---

##### Restore Environment Configuration

If the `.env` file is lost or corrupted:

**1. Locate the backup:**

```bash
# On your server
ls -lh ~/backups/env-backup-*

# Or download from local machine
scp ./local-backups/env-backup-20240115.txt ubuntu@YOUR_INSTANCE_IP:~/
```

**2. Restore the file:**

```bash
# Copy backup to application directory
cp ~/backups/env-backup-20240115.txt /home/ubuntu/ai-website-builder/.env

# Or if uploaded from local machine
cp ~/env-backup-20240115.txt /home/ubuntu/ai-website-builder/.env

# Set correct permissions
chmod 600 /home/ubuntu/ai-website-builder/.env
chown ubuntu:ubuntu /home/ubuntu/ai-website-builder/.env
```

**3. Verify the restoration:**

```bash
# Check file exists and has correct permissions
ls -la /home/ubuntu/ai-website-builder/.env

# Should show:
# -rw------- 1 ubuntu ubuntu 234 Jan 15 10:00 .env

# Verify contents (be careful not to expose secrets)
head -3 /home/ubuntu/ai-website-builder/.env
```

**4. Restart the application:**

```bash
sudo systemctl restart website-builder
sudo systemctl status website-builder
```

---

##### Restore Website Content

If generated website content is lost or corrupted:

**1. Locate the backup:**

```bash
# On your server
ls -lh ~/backups/website-content-*

# Or upload from local machine
scp ./local-backups/website-content-20240115.tar.gz ubuntu@YOUR_INSTANCE_IP:~/
```

**2. Stop NGINX (optional, to prevent serving incomplete content):**

```bash
sudo systemctl stop nginx
```

**3. Backup current content (if any exists):**

```bash
sudo mv /var/www/html /var/www/html.old-$(date +%Y%m%d)
```

**4. Restore from backup:**

```bash
# Extract the backup
sudo tar -xzf ~/backups/website-content-20240115.tar.gz -C /

# Or if the backup was created with a different structure
sudo mkdir -p /var/www/html
sudo tar -xzf ~/backups/website-content-20240115.tar.gz -C /var/www/html --strip-components=3
```

**5. Set correct permissions:**

```bash
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

**6. Restart NGINX:**

```bash
sudo systemctl start nginx
sudo systemctl status nginx
```

**7. Verify the restoration:**

```bash
# Check files were restored
ls -la /var/www/html/

# Test website access
curl -I https://yourdomain.com

# Or open in browser
# https://yourdomain.com
```

---

##### Restore Application Data

If application data (database, user files) is lost:

**1. Locate the backup:**

```bash
ls -lh ~/backups/database-*
```

**2. Stop the application:**

```bash
sudo systemctl stop website-builder
```

**3. Restore the database:**

```bash
# For SQLite database
cp ~/backups/database-20240115.db /home/ubuntu/ai-website-builder/database.db

# Set correct permissions
chown ubuntu:ubuntu /home/ubuntu/ai-website-builder/database.db
chmod 644 /home/ubuntu/ai-website-builder/database.db
```

**4. Restart the application:**

```bash
sudo systemctl start website-builder
sudo systemctl status website-builder
```

**5. Verify the restoration:**

```bash
# Check application logs
sudo journalctl -u website-builder -n 20 --no-pager

# Test application functionality
# Access Builder Interface and verify data is present
```

---

##### Full Server Restore

If you need to restore to a new server after catastrophic failure:

**1. Deploy a new Lightsail instance:**
- Follow the [Infrastructure Deployment Phase](#infrastructure-deployment-phase)
- Configure DNS to point to the new instance IP
- Wait for DNS propagation

**2. Run server configuration scripts:**
- Follow the [Server Configuration Phase](#server-configuration-phase)
- Run all five configuration scripts (NGINX, UFW, Tailscale, SSL, systemd)

**3. Deploy application code:**
- Follow the [Application Deployment Phase](#application-deployment-phase)
- Clone the repository or transfer code

**4. Restore environment configuration:**

```bash
# Upload .env backup from local machine
scp ./local-backups/env-backup-20240115.txt ubuntu@NEW_INSTANCE_IP:~/

# Copy to application directory
ssh ubuntu@NEW_INSTANCE_IP
cp ~/env-backup-20240115.txt /home/ubuntu/ai-website-builder/.env
chmod 600 /home/ubuntu/ai-website-builder/.env
```

**5. Restore website content:**

```bash
# Upload website content backup
scp ./local-backups/website-content-20240115.tar.gz ubuntu@NEW_INSTANCE_IP:~/

# Extract on new server
ssh ubuntu@NEW_INSTANCE_IP
sudo tar -xzf ~/website-content-20240115.tar.gz -C /
sudo chown -R www-data:www-data /var/www/html
```

**6. Restore application data:**

```bash
# Upload database backup
scp ./local-backups/database-20240115.db ubuntu@NEW_INSTANCE_IP:~/

# Copy to application directory
ssh ubuntu@NEW_INSTANCE_IP
cp ~/database-20240115.db /home/ubuntu/ai-website-builder/database.db
chown ubuntu:ubuntu /home/ubuntu/ai-website-builder/database.db
```

**7. Start the application:**

```bash
sudo systemctl start website-builder
sudo systemctl status website-builder
```

**8. Verify full restoration:**
- Follow the [Post-Deployment Verification Phase](#post-deployment-verification-phase)
- Test all functionality
- Verify SSL certificates are working
- Confirm VPN access to Builder Interface
- Test public website access

---

#### Recommended Maintenance Schedule

Establish a regular maintenance schedule to keep your AI Website Builder deployment secure, reliable, and performant.

---

##### Daily Tasks (Automated)

**Automatic Security Updates**
- **What:** System security patches installed automatically
- **How:** Configured via `unattended-upgrades` (see above)
- **Action Required:** None (monitor logs weekly)

**Automatic Backups**
- **What:** Daily backup of application data and configuration
- **How:** Automated via cron job (see backup script above)
- **Action Required:** None (verify backups weekly)

**SSL Certificate Renewal Checks**
- **What:** Certbot checks for certificates needing renewal
- **How:** Automated via `certbot.timer` (runs twice daily)
- **Action Required:** None (monitor monthly)

---

##### Weekly Tasks (5-10 minutes)

**Review Application Logs**
- **What:** Check for errors, warnings, or unusual activity
- **How:**
  ```bash
  ssh ubuntu@YOUR_INSTANCE_IP
  sudo journalctl -u website-builder --since "7 days ago" | grep -i error
  ```
- **Action Required:** Investigate and resolve any errors

**Verify Backup Success**
- **What:** Confirm backups are being created successfully
- **How:**
  ```bash
  ls -lh ~/backups/ | tail -10
  cat /var/log/backup-website.log | tail -20
  ```
- **Action Required:** Ensure recent backups exist and are complete

**Monitor Disk Space**
- **What:** Check available disk space
- **How:**
  ```bash
  df -h
  ```
- **Action Required:** Clean up old logs or backups if space is low (<20% free)

**Review System Updates**
- **What:** Check if system updates were applied
- **How:**
  ```bash
  cat /var/log/unattended-upgrades/unattended-upgrades.log | tail -30
  ```
- **Action Required:** Note any updates that require a reboot

---

##### Monthly Tasks (15-30 minutes)

**Verify SSL Certificate Status**
- **What:** Confirm SSL certificates are valid and will auto-renew
- **How:**
  ```bash
  sudo certbot certificates
  sudo certbot renew --dry-run
  ```
- **Action Required:** Ensure certificates have >30 days validity

**Review Security Updates**
- **What:** Check for pending security updates
- **How:**
  ```bash
  sudo apt-get update
  apt list --upgradable | grep -i security
  ```
- **Action Required:** Apply critical security updates if needed

**Test Backup Restoration**
- **What:** Verify backups can be restored successfully
- **How:** Restore a backup to a test directory and verify contents
- **Action Required:** Ensure backup/restore procedures work

**Monitor API Usage and Costs**
- **What:** Review Anthropic API usage and AWS costs
- **How:** Check Anthropic Console and AWS billing dashboard
- **Action Required:** Ensure usage is within expected limits (see [Cost Management](#cost-management))

**Review Application Performance**
- **What:** Check application response times and resource usage
- **How:**
  ```bash
  # Check memory usage
  free -h
  
  # Check CPU usage
  top -bn1 | head -20
  
  # Check application uptime
  sudo systemctl status website-builder
  ```
- **Action Required:** Investigate performance issues if detected

**Update Application Dependencies**
- **What:** Check for outdated Node.js packages
- **How:**
  ```bash
  cd /home/ubuntu/ai-website-builder
  npm outdated
  ```
- **Action Required:** Update dependencies if security vulnerabilities exist

---

##### Quarterly Tasks (30-60 minutes)

**Full System Update**
- **What:** Apply all available system updates
- **How:**
  ```bash
  sudo apt-get update
  sudo apt-get upgrade -y
  sudo apt-get dist-upgrade -y
  sudo apt-get autoremove -y
  ```
- **Action Required:** Reboot if required, test application after updates

**Review and Rotate Credentials**
- **What:** Rotate API keys and access credentials
- **How:**
  - Generate new Anthropic API key
  - Update `.env` file with new key
  - Delete old API key from Anthropic Console
  - Rotate AWS IAM access keys
- **Action Required:** Update credentials and test application

**Audit User Access**
- **What:** Review who has access to the system
- **How:**
  - Check Tailscale connected devices
  - Review AWS IAM users
  - Check SSH authorized keys
- **Action Required:** Remove access for users who no longer need it

**Test Disaster Recovery**
- **What:** Perform a full backup and restore test
- **How:** Restore backups to a test server and verify functionality
- **Action Required:** Document any issues with restore procedures

**Review and Update Documentation**
- **What:** Update deployment documentation with any changes
- **How:** Review this guide and update with lessons learned
- **Action Required:** Keep documentation current

---

##### Annual Tasks (1-2 hours)

**Renew Domain Name**
- **What:** Renew domain registration before expiration
- **How:** Check domain registrar for renewal options
- **Action Required:** Renew domain to avoid expiration

**Review Infrastructure Costs**
- **What:** Analyze annual costs and optimization opportunities
- **How:** Review AWS and Anthropic billing for the past year
- **Action Required:** Implement cost optimizations if needed

**Security Audit**
- **What:** Comprehensive security review
- **How:**
  - Review firewall rules
  - Check for unused services
  - Audit access logs
  - Update security policies
- **Action Required:** Address any security concerns

**Upgrade Major Dependencies**
- **What:** Upgrade Node.js, system packages, and major dependencies
- **How:** Plan and test major version upgrades
- **Action Required:** Schedule and execute upgrades during maintenance window

---

##### Maintenance Schedule Summary

| Task | Frequency | Time Required | Automated |
|------|-----------|---------------|-----------|
| Security updates | Daily | 0 min | ✓ Yes |
| Backups | Daily | 0 min | ✓ Yes |
| SSL renewal checks | Daily | 0 min | ✓ Yes |
| Review logs | Weekly | 5-10 min | ☐ No |
| Verify backups | Weekly | 5 min | ☐ No |
| Monitor disk space | Weekly | 2 min | ☐ No |
| SSL certificate status | Monthly | 5 min | ☐ No |
| Test backup restoration | Monthly | 15 min | ☐ No |
| Monitor costs | Monthly | 10 min | ☐ No |
| Update dependencies | Monthly | 10 min | ☐ No |
| Full system update | Quarterly | 30-60 min | ☐ No |
| Rotate credentials | Quarterly | 30 min | ☐ No |
| Disaster recovery test | Quarterly | 60 min | ☐ No |
| Domain renewal | Annual | 15 min | ☐ No |
| Security audit | Annual | 1-2 hours | ☐ No |

**Total Time Investment:**
- **Automated tasks:** ~0 minutes/week (monitoring only)
- **Weekly tasks:** ~15-20 minutes/week
- **Monthly tasks:** ~1 hour/month
- **Quarterly tasks:** ~2-3 hours/quarter
- **Annual tasks:** ~3-4 hours/year

**Estimated Annual Maintenance Time:** ~20-25 hours/year

---

#### Maintenance Best Practices

**1. Document Everything**
- Keep a maintenance log of all activities
- Document any issues encountered and how they were resolved
- Update this guide with lessons learned

**2. Test in Staging First**
- If possible, maintain a staging environment
- Test updates and changes before applying to production
- Validate backup/restore procedures in staging

**3. Schedule Maintenance Windows**
- Plan maintenance during low-traffic periods
- Notify users of scheduled maintenance if applicable
- Have a rollback plan ready

**4. Monitor Proactively**
- Set up alerts for critical issues (disk space, SSL expiration, service failures)
- Review logs regularly to catch issues early
- Monitor resource usage trends

**5. Keep Backups Secure and Accessible**
- Store backups in multiple locations (on-server, local, cloud)
- Encrypt backups containing sensitive data
- Test restore procedures regularly
- Document backup locations and access procedures

**6. Stay Informed**
- Subscribe to security mailing lists for Ubuntu and Node.js
- Monitor Anthropic API announcements for changes
- Keep up with AWS Lightsail updates and best practices

**7. Automate Where Possible**
- Use scripts for repetitive tasks
- Set up cron jobs for scheduled maintenance
- Consider configuration management tools for complex setups

---

**End of Deployment Guide**
