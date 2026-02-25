# Requirements Document

## Introduction

The Quick Start Deployment System provides a streamlined deployment experience for the AI website builder on fresh Ubuntu VMs. The system assumes users have already provisioned a VM, registered a domain, obtained a Claude API key, and created a Tailscale account. The deployment process is designed to minimize steps and user interaction while handling all necessary configuration, authentication, and setup automatically.

## Glossary

- **Deployment_Script**: The automated script that handles the complete installation and configuration of the AI website builder
- **Quick_Start_Guide**: The single-page documentation that guides users through the deployment process
- **Target_VM**: A fresh Ubuntu virtual machine on any cloud provider where the user is logged in as root via SSH
- **Configuration_Input**: User-provided values including Claude API key, domain name, and Tailscale account information
- **QR_Code_System**: The mechanism for end users to access the Tailscale app and connect to the deployed AI website builder
- **Update_Mode**: The ability to re-run the Deployment_Script to modify existing configuration values
- **Browser_Authentication**: Authentication flows that require opening a web browser to complete OAuth or similar processes
- **VM_Snapshot**: A point-in-time backup of the Target_VM state that allows restoration in case of deployment failures

## Requirements

### Requirement 1: Single-Page Quick Start Guide

**User Story:** As a developer, I want a concise single-page guide, so that I can quickly understand and complete the deployment process without navigating multiple pages.

#### Acceptance Criteria

1. THE Quick_Start_Guide SHALL begin from the point where the user is logged into the Target_VM as root via SSH
2. THE Quick_Start_Guide SHALL document all prerequisites (Ubuntu VM, domain name, Claude API key, Tailscale account)
3. THE Quick_Start_Guide SHALL provide the exact command to download and execute the Deployment_Script
4. THE Quick_Start_Guide SHALL explain how to use the QR_Code_System for end user access
5. THE Quick_Start_Guide SHALL fit on a single page without requiring scrolling through multiple sections

### Requirement 2: Automated Deployment Script

**User Story:** As a developer, I want a single script that handles the entire deployment, so that I can deploy the AI website builder without manual configuration steps.

#### Acceptance Criteria

1. WHEN executed, THE Deployment_Script SHALL prompt for all required Configuration_Input values
2. THE Deployment_Script SHALL clone the AI website builder repository from git
3. THE Deployment_Script SHALL install all necessary dependencies on the Target_VM
4. THE Deployment_Script SHALL configure the AI website builder with the provided Configuration_Input
5. WHEN deployment completes successfully, THE Deployment_Script SHALL display a success message with access instructions

### Requirement 3: Interactive Configuration Input

**User Story:** As a developer, I want to provide configuration values interactively, so that I don't need to prepare a configuration file before running the script.

#### Acceptance Criteria

1. WHEN the Deployment_Script starts, THE Deployment_Script SHALL prompt for the Claude API key
2. WHEN the Deployment_Script starts, THE Deployment_Script SHALL prompt for the domain name
3. WHEN the Deployment_Script starts, THE Deployment_Script SHALL prompt for Tailscale account information
4. THE Deployment_Script SHALL validate each Configuration_Input before proceeding
5. WHEN invalid Configuration_Input is provided, THE Deployment_Script SHALL display a descriptive error message and re-prompt

### Requirement 4: Browser-Based Authentication Support

**User Story:** As a developer, I want the script to handle authentication flows that require a browser, so that I can complete OAuth and similar processes during deployment.

#### Acceptance Criteria

1. WHEN Browser_Authentication is required, THE Deployment_Script SHALL display a clickable URL
2. WHEN Browser_Authentication is required, THE Deployment_Script SHALL wait for the authentication to complete
3. WHEN Browser_Authentication completes successfully, THE Deployment_Script SHALL continue with the deployment process
4. WHEN Browser_Authentication fails, THE Deployment_Script SHALL display an error message and provide retry instructions

### Requirement 5: Configuration Update Capability

**User Story:** As a developer, I want to re-run the deployment script to update configuration values, so that I can change my Claude API key, domain, or Tailscale settings without redeploying from scratch.

#### Acceptance Criteria

1. WHEN the Deployment_Script is executed on a system with an existing installation, THE Deployment_Script SHALL detect the existing installation
2. WHEN running in Update_Mode, THE Deployment_Script SHALL display current configuration values
3. WHEN running in Update_Mode, THE Deployment_Script SHALL allow the user to modify any Configuration_Input
4. WHEN running in Update_Mode, THE Deployment_Script SHALL preserve existing data and settings not being updated
5. WHEN running in Update_Mode, THE Deployment_Script SHALL assume previously supplied Configuration_Input values unless the user provides new values
6. WHEN configuration updates complete, THE Deployment_Script SHALL restart affected services

### Requirement 6: QR Code Generation for End User Access

**User Story:** As a developer, I want to generate QR codes for end users, so that they can easily install Tailscale and connect to the AI website builder.

#### Acceptance Criteria

1. WHEN deployment completes, THE Deployment_Script SHALL generate a QR code for the Tailscale app store link
2. WHEN deployment completes, THE Deployment_Script SHALL generate a QR code for connecting to the AI website builder interface
3. THE QR_Code_System SHALL display QR codes in the terminal output
4. THE QR_Code_System SHALL save QR codes as image files for later distribution
5. WHEN an end user scans the app store QR code, THE QR_Code_System SHALL direct them to install Tailscale on their device

### Requirement 7: Minimal User Interaction

**User Story:** As a developer, I want the deployment to require minimal interaction, so that I can complete the setup quickly without constant monitoring.

#### Acceptance Criteria

1. THE Deployment_Script SHALL collect all Configuration_Input at the beginning of execution
2. WHEN all Configuration_Input is collected, THE Deployment_Script SHALL complete the deployment without additional prompts
3. THE Deployment_Script SHALL display progress indicators during long-running operations
4. THE Deployment_Script SHALL log all operations to a file for troubleshooting
5. WHEN errors occur, THE Deployment_Script SHALL provide clear remediation steps

### Requirement 8: Idempotent Deployment

**User Story:** As a developer, I want to safely re-run the deployment script, so that I can recover from failures or update the system without causing conflicts.

#### Acceptance Criteria

1. WHEN the Deployment_Script is executed multiple times, THE Deployment_Script SHALL produce the same end state
2. THE Deployment_Script SHALL detect existing installations and avoid duplicate resource creation
3. THE Deployment_Script SHALL safely update existing configurations without data loss
4. WHEN a previous deployment failed partially, THE Deployment_Script SHALL resume from a safe point
5. THE Deployment_Script SHALL verify the system state before making changes

### Requirement 9: Dependency Installation

**User Story:** As a developer, I want all dependencies installed automatically, so that I don't need to manually install packages or tools.

#### Acceptance Criteria

1. THE Deployment_Script SHALL install all required system packages on the Target_VM
2. THE Deployment_Script SHALL install the correct version of runtime dependencies (Node.js, Python, etc.)
3. THE Deployment_Script SHALL install and configure Tailscale on the Target_VM
4. THE Deployment_Script SHALL configure firewall rules as needed
5. WHEN running in Update_Mode, THE Deployment_Script SHALL apply security updates to system packages
6. WHEN running in Update_Mode, THE Deployment_Script SHALL update dependencies to compatible versions
7. WHEN dependency installation fails, THE Deployment_Script SHALL display the specific dependency that failed and exit gracefully

### Requirement 10: Domain Configuration

**User Story:** As a developer, I want the script to configure my domain automatically, so that the AI website builder is accessible via my registered domain name.

#### Acceptance Criteria

1. WHEN a domain name is provided, THE Deployment_Script SHALL configure DNS settings or provide DNS configuration instructions
2. THE Deployment_Script SHALL configure SSL/TLS certificates for the domain
3. THE Deployment_Script SHALL configure the web server to serve the AI website builder on the specified domain
4. WHEN domain configuration fails, THE Deployment_Script SHALL provide troubleshooting guidance
5. THE Deployment_Script SHALL verify domain accessibility before completing deployment

### Requirement 11: Secure Credential Storage

**User Story:** As a developer, I want my API keys and credentials stored securely, so that they are not exposed to unauthorized access.

#### Acceptance Criteria

1. THE Deployment_Script SHALL store the Claude API key in a secure configuration file with restricted permissions
2. THE Deployment_Script SHALL store Tailscale credentials securely
3. THE Deployment_Script SHALL set file permissions to prevent unauthorized access to credential files
4. THE Deployment_Script SHALL not log sensitive credentials in plain text
5. WHEN displaying configuration values in Update_Mode, THE Deployment_Script SHALL mask sensitive credentials

### Requirement 12: VM Snapshot Recommendation

**User Story:** As a developer, I want to be prompted to snapshot my VM before deployment, so that I can easily recover if something goes wrong during the deployment process.

#### Acceptance Criteria

1. WHEN the Deployment_Script starts, THE Deployment_Script SHALL prompt the user to create a VM_Snapshot before proceeding
2. THE Deployment_Script SHALL provide instructions on how to create a VM_Snapshot for common cloud providers
3. THE Deployment_Script SHALL allow the user to confirm they have created a VM_Snapshot or choose to proceed without one
4. WHEN the user chooses to proceed without a VM_Snapshot, THE Deployment_Script SHALL display a warning about recovery limitations
5. THE Deployment_Script SHALL continue execution after the user confirms their snapshot choice

### Requirement 13: Service Management

**User Story:** As a developer, I want the AI website builder to start automatically, so that it remains available after system reboots.

#### Acceptance Criteria

1. THE Deployment_Script SHALL configure the AI website builder as a system service
2. THE Deployment_Script SHALL enable automatic startup on system boot
3. THE Deployment_Script SHALL start the AI website builder service after deployment
4. THE Deployment_Script SHALL verify the service is running before completing deployment
5. WHEN the service fails to start, THE Deployment_Script SHALL display service logs and error information
