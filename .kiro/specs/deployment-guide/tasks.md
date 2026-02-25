# Implementation Plan: Deployment Guide

## Overview

This plan breaks down the creation of the comprehensive DEPLOYMENT.md file into discrete documentation tasks. Each task focuses on writing a specific section of the guide, ensuring all requirements are covered with clear, actionable content. The guide will be structured as a single markdown file that operators can follow sequentially to deploy the AI Website Builder to AWS Lightsail.

## Tasks

- [x] 1. Create DEPLOYMENT.md structure and introduction
  - Create the main DEPLOYMENT.md file in the project root
  - Write the document header with title and metadata
  - Write the introduction section explaining purpose, scope, and target audience
  - Add the high-level workflow overview with deployment phases
  - Include time estimates for complete deployment (60-90 minutes)
  - Add table of contents with links to all major sections
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [ ] 2. Write prerequisites section
  - [x] 2.1 Document required tools and versions
    - List AWS CLI (>=2.0), Terraform (>=1.0) or AWS CLI for CloudFormation
    - List Node.js (>=18), Git, SSH client
    - Provide installation commands for macOS, Linux, and Windows
    - Include verification commands for each tool
    - _Requirements: 1.1, 1.6_
  
  - [x] 2.2 Document credential acquisition procedures
    - Document how to obtain Anthropic API key with links to console
    - Document how to obtain Tailscale auth key with step-by-step instructions
    - Document AWS account setup and credential configuration
    - Document domain name registration or preparation
    - Include security best practices for credential storage
    - _Requirements: 1.2, 1.3, 1.4, 1.5, 10.1, 10.2, 10.3_
  
  - [x] 2.3 Create prerequisites checklist
    - Create interactive markdown checklist for all prerequisites
    - Add estimated time for completing prerequisites
    - Include verification section to confirm readiness
    - _Requirements: 1.7_

- [ ] 3. Write infrastructure deployment section
  - [x] 3.1 Document deployment method selection
    - Create decision matrix for Terraform vs CloudFormation
    - List advantages and disadvantages of each approach
    - Provide recommendation based on operator experience
    - _Requirements: 2.1_
  
  - [x] 3.2 Document Terraform deployment path
    - Document terraform.tfvars configuration with all required variables
    - Provide example configuration with placeholders
    - Document terraform init, plan, and apply command sequence
    - Document how to retrieve and interpret outputs (instance IP, etc.)
    - Include verification commands for created resources
    - _Requirements: 2.2, 2.3, 2.4, 2.6, 2.7_
  
  - [x] 3.3 Document CloudFormation deployment path
    - Document parameter configuration for CloudFormation template
    - Provide example parameters file with placeholders
    - Document AWS CLI commands for stack creation
    - Document how to retrieve stack outputs
    - Include verification commands for created resources
    - _Requirements: 2.2, 2.3, 2.4, 2.6, 2.7_

- [ ] 4. Write DNS configuration section
  - [x] 4.1 Document domain registration process
    - Document how to register domain through common registrars (Namecheap, GoDaddy, Route53)
    - Document how to use existing domain with AWS Lightsail
    - Include cost estimates for domain registration
    - _Requirements: 3.1, 3.2_
  
  - [x] 4.2 Document DNS record configuration
    - Document how to create A records for root domain and www subdomain
    - Provide specific instructions for pointing to Lightsail instance IP
    - Document DNS configuration for Builder Interface hostname
    - Document DNS configuration for Static Server hostname
    - Include examples from multiple DNS providers
    - _Requirements: 3.3, 3.4, 3.7, 3.8_
  
  - [x] 4.3 Document DNS verification procedures
    - Document DNS propagation timeframes (typically 5-30 minutes)
    - Provide dig/nslookup commands for verification
    - Document expected output for successful DNS configuration
    - Include pre-SSL verification checks
    - _Requirements: 3.5, 3.6_

- [ ] 5. Write server configuration section
  - [x] 5.1 Document SSH access setup
    - Document how to SSH into Lightsail instance
    - Document SSH key management and best practices
    - Include troubleshooting for common SSH connection issues
    - _Requirements: 4.1, 8.2, 10.3_
  
  - [x] 5.2 Document NGINX configuration script
    - Document purpose of configure-nginx.sh
    - Provide execution command with any required parameters
    - Document expected output and what NGINX configuration is created
    - Include verification commands (nginx -t, systemctl status nginx)
    - _Requirements: 4.2, 4.7_
  
  - [x] 5.3 Document UFW firewall configuration script
    - Document purpose of configure-ufw.sh
    - Provide execution command
    - Document firewall rules created (ports 22, 80, 443, 41641)
    - Include verification commands (ufw status)
    - Document which ports remain closed to public access
    - _Requirements: 4.3, 4.7, 10.5_
  
  - [x] 5.4 Document Tailscale VPN configuration script
    - Document purpose of configure-tailscale.sh
    - Provide execution command with TAILSCALE_AUTH_KEY parameter
    - Document expected output and VPN connection verification
    - Include troubleshooting for VPN connection issues
    - _Requirements: 4.4, 4.7_
  
  - [x] 5.5 Document SSL certificate configuration script
    - Document purpose of configure-ssl.sh
    - Provide execution command with required environment variables (DOMAIN, SSL_EMAIL)
    - Document Let's Encrypt certificate acquisition process
    - Include verification commands for SSL certificates
    - Document automatic renewal configuration
    - _Requirements: 4.5, 4.7, 11.6_
  
  - [x] 5.6 Document systemd service configuration script
    - Document purpose of configure-systemd.sh
    - Provide execution command
    - Document systemd service file creation for website-builder
    - Include verification commands (systemctl status website-builder)
    - _Requirements: 4.6, 4.7_

- [x] 6. Checkpoint - Review server configuration documentation
  - Ensure all five configuration scripts are documented in correct order
  - Verify each script section includes purpose, command, output, and verification
  - Confirm troubleshooting guidance is included for each step

- [ ] 7. Write application deployment section
  - [x] 7.1 Document code transfer methods
    - Document git clone method for transferring code
    - Document scp method as alternative
    - Provide specific commands with placeholders
    - _Requirements: 5.1_
  
  - [x] 7.2 Document dependency installation
    - Document npm install command for Node.js dependencies
    - Include expected output and duration
    - Document troubleshooting for dependency installation failures
    - _Requirements: 5.2_
  
  - [x] 7.3 Document environment configuration
    - Document .env file creation and required variables
    - Provide template with all required variables (ANTHROPIC_API_KEY, DOMAIN, etc.)
    - Document security considerations for .env file
    - Include validation commands to check configuration
    - _Requirements: 5.3, 10.4_
  
  - [x] 7.4 Document build and startup process
    - Document npm run build command for TypeScript compilation
    - Document systemctl start website-builder command
    - Document systemctl enable website-builder for auto-start
    - Include verification that service is running
    - Document how to view application logs (journalctl)
    - _Requirements: 5.4, 5.5, 5.6, 5.7_

- [ ] 8. Write post-deployment verification section
  - [x] 8.1 Document component health checks
    - Provide command to verify NGINX is serving static content
    - Provide command to verify UFW firewall rules are active
    - Provide command to verify Tailscale VPN is connected
    - Provide command to verify SSL certificates are installed and valid
    - Include expected output for each verification command
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.7_
  
  - [x] 8.2 Document application verification
    - Provide command to verify Builder Interface is accessible via VPN
    - Provide command to verify Static Server is publicly accessible
    - Document how to test end-to-end workflow (create page, verify public access)
    - Include curl commands with expected responses
    - _Requirements: 6.5, 6.6, 6.7_
  
  - [x] 8.3 Document security verification
    - Provide command to verify Builder Interface is NOT publicly accessible
    - Document how to verify only correct ports are open
    - Include security checklist for post-deployment review
    - _Requirements: 10.6_

- [ ] 9. Write user access instructions section
  - [x] 9.1 Document Tailscale client installation
    - Provide installation instructions for macOS, Linux, Windows, iOS, Android
    - Include links to official Tailscale downloads
    - Document client configuration steps
    - _Requirements: 7.1_
  
  - [x] 9.2 Document system access procedures
    - Document how to connect to Tailscale network
    - Provide Builder Interface URL format (http://[tailscale-ip]:3000)
    - Provide public website URL format (https://yourdomain.com)
    - Explain difference between VPN-protected and public access
    - Include screenshots or examples of successful access
    - _Requirements: 7.2, 7.3, 7.4, 7.6_
  
  - [x] 9.3 Document connection troubleshooting
    - Document common Tailscale connection issues and solutions
    - Document browser compatibility considerations
    - Include diagnostic commands for connectivity issues
    - _Requirements: 7.5_

- [ ] 10. Write troubleshooting guide section
  - [x] 10.1 Document infrastructure troubleshooting
    - Document common Terraform/CloudFormation deployment failures
    - Document AWS credential and permission issues
    - Document Lightsail instance creation failures
    - Include diagnostic commands and log locations
    - Provide solutions for each common issue
    - _Requirements: 8.1, 8.6_
  
  - [x] 10.2 Document configuration troubleshooting
    - Document SSH connection failures and solutions
    - Document firewall configuration issues and solutions
    - Document SSL certificate acquisition failures and solutions
    - Document DNS propagation issues and solutions
    - Include rollback procedures for failed configurations
    - _Requirements: 8.2, 8.3, 8.4, 8.7_
  
  - [x] 10.3 Document application troubleshooting
    - Document Node.js dependency installation failures
    - Document TypeScript build failures
    - Document systemd service startup failures
    - Document application runtime errors
    - Include how to access and interpret application logs
    - Provide solutions for each common issue
    - _Requirements: 8.5, 8.6_

- [ ] 11. Write maintenance and updates section
  - [x] 11.1 Document application update procedures
    - Document git pull workflow for code updates
    - Document npm install for dependency updates
    - Document npm run build for rebuilding after updates
    - Document systemctl restart website-builder command
    - Include verification steps after updates
    - _Requirements: 11.1, 11.2, 11.3, 11.4_
  
  - [x] 11.2 Document system maintenance procedures
    - Document automatic security update configuration (unattended-upgrades)
    - Document SSL certificate renewal monitoring (certbot renew)
    - Document backup procedures for application data and configuration
    - Document restore procedures from backups
    - Include recommended maintenance schedule
    - _Requirements: 11.5, 11.6, 11.7_

- [ ] 12. Write cost management section
  - [x] 12.1 Document cost breakdown
    - Document AWS Lightsail instance costs (fixed monthly)
    - Document domain registration costs (annual)
    - Document Claude API costs (variable, per token)
    - Provide total estimated monthly cost range
    - _Requirements: 12.1, 12.2_
  
  - [x] 12.2 Document cost monitoring procedures
    - Document how to monitor AWS Lightsail costs in AWS console
    - Document how to monitor Claude API usage in Anthropic console
    - Document monthly token threshold configuration in application
    - Include links to cost monitoring dashboards
    - _Requirements: 12.3, 12.4, 12.6_
  
  - [x] 12.3 Document cost optimization recommendations
    - Document how to optimize Claude API usage
    - Document Lightsail instance sizing considerations
    - Document strategies for staying within budget
    - Include cost alert setup instructions
    - _Requirements: 12.5_

- [x] 13. Final review and polish
  - Review entire DEPLOYMENT.md for consistency and completeness
  - Verify all 12 requirements are fully addressed
  - Check all code blocks have proper syntax highlighting
  - Verify all commands are copy-paste ready
  - Ensure consistent formatting throughout document
  - Add any missing cross-references between sections
  - Verify table of contents links work correctly

## Notes

- All tasks involve writing markdown documentation, not executable code
- Each section should include clear headings, code blocks with syntax highlighting, and verification procedures
- Commands should be formatted for direct copy-paste execution with minimal modification
- Placeholders should be clearly marked (e.g., "yourdomain.com", "[your-api-key]")
- The guide should be usable by operators with varying levels of experience
- Security considerations should be integrated throughout, not just in a separate section
- Troubleshooting guidance should be provided inline where relevant, with a comprehensive troubleshooting section for reference
