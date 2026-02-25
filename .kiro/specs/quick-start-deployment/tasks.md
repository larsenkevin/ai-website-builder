# Implementation Plan: Quick Start Deployment

## Overview

This implementation plan breaks down the Quick Start Deployment System into discrete, actionable tasks. The system consists of a single-page quick start guide and a bash deployment script that automates the complete installation and configuration of the AI website builder on fresh Ubuntu VMs. The implementation follows a linear progression from documentation through core script functionality, configuration management, service setup, and testing.

## Tasks

- [x] 1. Create quick start guide documentation
  - Create `QUICKSTART.md` in repository root with single-page format
  - Document prerequisites (Ubuntu VM, domain, Claude API key, Tailscale account)
  - Provide script download and execution command
  - Explain QR code usage for end users
  - Add troubleshooting section for common issues
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 2. Implement core deployment script structure
  - [x] 2.1 Create deploy.sh with main entry point and execution flow
    - Create `deploy.sh` bash script with proper shebang and error handling
    - Implement main() function with linear execution flow
    - Add script version tracking and logging initialization
    - Set up error trap handlers for graceful failures
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [x] 2.2 Write property test for deployment idempotency
    - **Property 7: Deployment Idempotency**
    - **Validates: Requirements 8.1, 8.2, 8.3, 8.5**

  - [x] 2.3 Implement logging and progress display utilities
    - Create log_operation() function writing to `/var/log/ai-website-builder-deploy.log`
    - Create display_progress() function for long-running operations
    - Create handle_error() function with formatted error messages
    - _Requirements: 7.3, 7.4, 7.5_

  - [x] 2.4 Write property test for operation logging
    - **Property 5: Operation Logging**
    - **Validates: Requirements 7.4**

- [ ] 3. Implement VM snapshot prompting and pre-flight checks
  - [x] 3.1 Create VM snapshot prompt with cloud provider instructions
    - Implement prompt_vm_snapshot() function
    - Display instructions for common cloud providers (AWS, GCP, Azure, DigitalOcean)
    - Allow user to confirm snapshot creation or proceed without
    - Display warning when proceeding without snapshot
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

  - [x] 3.2 Implement pre-flight system checks
    - Check if running as root user
    - Verify Ubuntu OS (check /etc/os-release)
    - Check disk space availability (minimum 10GB free)
    - Verify network connectivity
    - _Requirements: 2.1_

- [ ] 4. Implement configuration input collection and validation
  - [x] 4.1 Create interactive configuration input prompts
    - Implement collect_configuration_input() function
    - Prompt for Claude API key with input masking
    - Prompt for domain name
    - Prompt for Tailscale email
    - _Requirements: 3.1, 3.2, 3.3_

  - [x] 4.2 Implement configuration validation functions
    - Create validate_configuration() function
    - Validate Claude API key format (non-empty, expected prefix)
    - Validate domain name (FQDN format, DNS resolution)
    - Validate email format (standard email regex)
    - Display descriptive error messages on validation failure
    - Re-prompt for invalid inputs
    - _Requirements: 3.4, 3.5_

  - [x] 4.3 Write property test for configuration input validation
    - **Property 1: Configuration Input Validation**
    - **Validates: Requirements 3.4, 3.5**

  - [x] 4.4 Write unit tests for configuration validation
    - Test valid Claude API key accepted
    - Test valid domain name accepted
    - Test valid email accepted
    - Test empty inputs rejected
    - Test malformed inputs rejected
    - _Requirements: 3.4, 3.5_

- [ ] 5. Implement installation mode detection and state management
  - [x] 5.1 Create installation mode detector
    - Implement detect_existing_installation() function
    - Check for `/etc/ai-website-builder/.install-state` file
    - Set MODE variable to "fresh" or "update"
    - _Requirements: 5.1_

  - [x] 5.2 Write property test for installation mode detection
    - **Property 2: Installation Mode Detection**
    - **Validates: Requirements 5.1**

  - [x] 5.3 Implement existing configuration loader for update mode
    - Create load_existing_configuration() function
    - Parse `/etc/ai-website-builder/config.env` file
    - Load existing values into variables
    - Display current configuration values (masked for sensitive data)
    - _Requirements: 5.2_

  - [x] 5.4 Implement configuration preservation in update mode
    - Allow user to press Enter to keep existing values
    - Only update values when user provides new input
    - Preserve all non-updated configuration values
    - _Requirements: 5.3, 5.4, 5.5_

  - [x] 5.5 Write property test for configuration preservation
    - **Property 3: Configuration Preservation in Update Mode**
    - **Validates: Requirements 5.3, 5.4, 5.5**

- [x] 6. Checkpoint - Ensure configuration and mode detection work correctly
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Implement secure configuration storage
  - [x] 7.1 Create secure configuration file writer
    - Implement save_configuration() function
    - Create `/etc/ai-website-builder/` directory with 700 permissions
    - Write configuration to `/etc/ai-website-builder/config.env`
    - Set file permissions to 600 (owner read/write only)
    - Set ownership to root:root
    - _Requirements: 11.1, 11.2, 11.3_

  - [x] 7.2 Implement credential masking for display
    - Create mask_value() function
    - Mask all but last 4 characters of sensitive values
    - Use masking when displaying configuration in update mode
    - _Requirements: 11.5_

  - [x] 7.3 Implement credential logging protection
    - Ensure no plain-text credentials in log files
    - Mask credentials before logging
    - _Requirements: 11.4_

  - [x] 7.4 Write property test for credential file security
    - **Property 9: Credential File Security**
    - **Validates: Requirements 11.3**

  - [x] 7.5 Write property test for credential logging protection
    - **Property 10: Credential Logging Protection**
    - **Validates: Requirements 11.4**

  - [x] 7.6 Write property test for credential display masking
    - **Property 11: Credential Display Masking**
    - **Validates: Requirements 11.5**

  - [x] 7.7 Write unit tests for security measures
    - Test configuration file has 600 permissions
    - Test configuration directory has 700 permissions
    - Test credentials not in log file
    - Test credentials masked in update mode display
    - _Requirements: 11.3, 11.4, 11.5_

- [ ] 8. Implement dependency installation
  - [x] 8.1 Create system package installer
    - Implement install_system_dependencies() function
    - Run apt update
    - Install curl, wget, git, nginx, certbot, qrencode, ufw
    - Display progress for each package installation
    - Handle installation failures with specific error messages
    - _Requirements: 9.1, 9.7_

  - [x] 8.2 Create runtime dependency installer
    - Implement install_runtime_dependencies() function
    - Add NodeSource repository for Node.js LTS
    - Install Node.js and npm
    - Clone repository to `/opt/ai-website-builder`
    - Run npm install in repository directory
    - _Requirements: 9.2, 2.2_

  - [x] 8.3 Create Tailscale installer
    - Implement install_tailscale() function
    - Add Tailscale package repository
    - Install tailscale package
    - Enable and start tailscaled service
    - _Requirements: 9.3_

  - [x] 8.4 Implement firewall configuration
    - Implement configure_firewall() function
    - Enable ufw firewall
    - Allow SSH (port 22)
    - Allow HTTP (port 80) and HTTPS (port 443)
    - _Requirements: 9.4_

  - [x] 8.5 Implement update mode dependency updates
    - Check if running in update mode
    - Run apt update && apt upgrade -y for security updates
    - Run npm update in repository directory
    - Check for Tailscale updates
    - _Requirements: 9.5, 9.6_

  - [x] 8.6 Write property test for progress indication
    - **Property 6: Progress Indication for Long Operations**
    - **Validates: Requirements 7.3**

  - [x] 8.7 Write unit tests for dependency installation
    - Test system packages installed correctly
    - Test Node.js installed correctly
    - Test Tailscale installed correctly
    - Test firewall configured correctly
    - Test update mode updates dependencies
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [x] 9. Checkpoint - Ensure dependency installation works correctly
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Implement browser authentication support
  - [x] 10.1 Create browser authentication handler
    - Implement handle_browser_authentication() function
    - Display clickable authentication URL with clear formatting
    - Display instructions for user to open URL in browser
    - _Requirements: 4.1, 4.2_

  - [x] 10.2 Create authentication completion waiter
    - Implement wait_for_auth_completion() function
    - Poll Tailscale status to check authentication completion
    - Implement 5-minute timeout
    - Display timeout message and retry option on timeout
    - Allow manual continuation if authentication completed out-of-band
    - _Requirements: 4.2, 4.3, 4.4_

  - [x] 10.3 Write unit tests for authentication flow
    - Test URL displayed correctly
    - Test timeout handled gracefully
    - Test successful authentication continues deployment
    - Test failed authentication shows error and retry
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 11. Implement domain and SSL configuration
  - [x] 11.1 Create nginx configuration generator
    - Implement configure_web_server() function
    - Generate nginx configuration file at `/etc/nginx/sites-available/ai-website-builder`
    - Configure HTTP server block with ACME challenge support
    - Configure HTTPS server block with proxy to localhost:3000
    - Enable site by symlinking to sites-enabled
    - Reload nginx configuration
    - _Requirements: 10.3_

  - [x] 11.2 Create SSL certificate acquisition function
    - Implement setup_ssl_certificates() function
    - Run certbot with nginx plugin
    - Use non-interactive mode with provided email and domain
    - Handle certificate acquisition failures with troubleshooting guidance
    - _Requirements: 10.2, 10.4_

  - [x] 11.3 Create domain verification function
    - Implement verify_domain_accessibility() function
    - Check DNS resolution with dig command
    - Verify HTTP accessibility with curl
    - Verify HTTPS accessibility with curl
    - Display verification results
    - _Requirements: 10.5_

  - [x] 11.4 Write unit tests for domain configuration
    - Test nginx configuration generated correctly
    - Test SSL certificates acquired
    - Test domain verification checks DNS and HTTP/HTTPS
    - Test configuration failure shows troubleshooting guidance
    - _Requirements: 10.2, 10.3, 10.4, 10.5_

- [ ] 12. Implement QR code generation
  - [x] 12.1 Create QR code generator for Tailscale app store
    - Implement generate_qr_codes() function
    - Generate QR code for Tailscale app store link (iOS/Android)
    - Save as PNG to `/etc/ai-website-builder/qr-codes/tailscale-app.png`
    - Generate ASCII art version for terminal display
    - _Requirements: 6.1, 6.5_

  - [x] 12.2 Create QR code generator for service access URL
    - Generate QR code for AI website builder access URL (Tailscale hostname)
    - Save as PNG to `/etc/ai-website-builder/qr-codes/service-access.png`
    - Generate ASCII art version for terminal display
    - _Requirements: 6.2_

  - [x] 12.3 Create QR code display function
    - Implement display_qr_codes_terminal() function
    - Display both QR codes in terminal with formatted borders
    - Include descriptive labels for each QR code
    - _Requirements: 6.3_

  - [x] 12.4 Write property test for QR code file persistence
    - **Property 4: QR Code File Persistence**
    - **Validates: Requirements 6.4**

  - [x] 12.5 Write unit tests for QR code generation
    - Test app store QR code generated
    - Test service access QR code generated
    - Test QR codes saved as PNG files
    - Test QR codes displayed in terminal
    - Test QR codes contain correct URLs
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 13. Implement service management
  - [x] 13.1 Create systemd service file generator
    - Implement configure_systemd_service() function
    - Generate systemd unit file at `/etc/systemd/system/ai-website-builder.service`
    - Configure service to run as www-data user
    - Set working directory to repository path
    - Load environment from config.env
    - Configure automatic restart on failure
    - Set dependency on tailscaled.service
    - _Requirements: 13.1_

  - [x] 13.2 Create service starter and enabler
    - Implement start_services() function
    - Run systemctl daemon-reload
    - Enable ai-website-builder service for auto-start
    - Start ai-website-builder service
    - _Requirements: 13.2, 13.3_

  - [x] 13.3 Create service status verifier
    - Implement verify_service_status() function
    - Check service status with systemctl
    - Verify process is running
    - Check service logs for errors
    - Test HTTP endpoint accessibility on localhost:3000
    - Display service logs and error information on failure
    - _Requirements: 13.4, 13.5_

  - [x] 13.4 Implement service restart for update mode
    - Check if running in update mode
    - Restart ai-website-builder service after configuration updates
    - Verify service restarted successfully
    - _Requirements: 5.6_

  - [x] 13.5 Write unit tests for service management
    - Test systemd service file created correctly
    - Test service enabled for auto-start
    - Test service started successfully
    - Test service status verified
    - Test service logs accessible
    - Test service restarted in update mode
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 5.6_

- [x] 14. Checkpoint - Ensure service management and QR codes work correctly
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 15. Implement installation state tracking
  - [x] 15.1 Create installation state file writer
    - Create `/etc/ai-website-builder/.install-state` file
    - Write installation metadata (date, version, repository path)
    - Update last_update timestamp in update mode
    - _Requirements: 5.1_

  - [x] 15.2 Write property test for safe resumption after failure
    - **Property 8: Safe Resumption After Partial Failure**
    - **Validates: Requirements 8.4**

- [ ] 16. Implement final success message and completion
  - [x] 16.1 Create deployment result display function
    - Display success message with formatted output
    - Show access URL for AI website builder
    - Display QR codes for end user access
    - Show log file location for troubleshooting
    - Include next steps for end users
    - _Requirements: 2.5, 6.3, 6.4_

  - [x] 16.2 Wire all components together in main() function
    - Call prompt_vm_snapshot()
    - Call detect_existing_installation()
    - Call collect_configuration_input() or load_existing_configuration()
    - Call install_system_dependencies() (skip in update mode if already installed)
    - Call install_runtime_dependencies() (or update in update mode)
    - Call install_tailscale() (skip in update mode if already installed)
    - Call configure_firewall() (skip in update mode if already configured)
    - Call configure_web_server()
    - Call setup_ssl_certificates()
    - Call handle_browser_authentication() for Tailscale
    - Call generate_qr_codes()
    - Call configure_systemd_service()
    - Call start_services() or restart_services()
    - Call verify_service_status()
    - Call verify_domain_accessibility()
    - Display final success message
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 7.1, 7.2_

- [x] 17. Write property test for error remediation guidance
  - **Property 12: Error Remediation Guidance**
  - **Validates: Requirements 7.5, 9.7, 10.4, 13.5**

- [ ] 18. Write integration tests for end-to-end flows
  - [x] 18.1 Write integration test for fresh installation
    - Test complete deployment on clean Ubuntu VM
    - Verify all services running
    - Verify domain accessible
    - Verify QR codes generated
    - Verify configuration stored securely
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [x] 18.2 Write integration test for update mode
    - Test deployment on existing installation
    - Verify configuration updated
    - Verify services restarted
    - Verify no data loss
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

  - [x] 18.3 Write integration test for authentication flow
    - Test deployment with browser authentication
    - Verify URL displayed
    - Simulate authentication completion
    - Verify deployment continues
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 19. Final checkpoint - Ensure complete system works end-to-end
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- The deployment script is implemented in Bash as specified in the design
- Property tests validate universal correctness properties across all inputs
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end deployment scenarios
- Checkpoints ensure incremental validation at key milestones
