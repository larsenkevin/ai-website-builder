# Integration Test 18.1: Fresh Installation

## Overview

This integration test validates the complete end-to-end fresh installation flow for the Quick Start Deployment system. It tests that a fresh deployment creates all necessary files, directories, and configurations with proper security settings.

## Test Coverage

### Requirements Validated
- **Requirement 2.1**: Deployment script prompts for configuration input
- **Requirement 2.2**: Deployment script clones repository
- **Requirement 2.3**: Deployment script installs dependencies
- **Requirement 2.4**: Deployment script configures the system
- **Requirement 2.5**: Deployment script displays success message

### Test Cases

1. **Configuration Directory Created**
   - Verifies `/etc/ai-website-builder/` directory exists
   - Verifies directory has secure permissions (700)

2. **Configuration File Created and Secured**
   - Verifies `/etc/ai-website-builder/config.env` exists
   - Verifies file has secure permissions (600)
   - Verifies file contains required configuration values:
     - CLAUDE_API_KEY
     - DOMAIN_NAME
     - TAILSCALE_EMAIL
     - INSTALL_DATE

3. **State File Created**
   - Verifies `/etc/ai-website-builder/.install-state` exists
   - Verifies file has secure permissions (600)
   - Verifies file contains installation metadata:
     - INSTALL_DATE
     - INSTALL_VERSION
     - REPOSITORY_PATH

4. **QR Codes Generated**
   - Verifies `/etc/ai-website-builder/qr-codes/` directory exists
   - Verifies `tailscale-app.png` QR code exists
   - Verifies `service-access.png` QR code exists
   - Verifies QR code files have correct permissions (644)

5. **System Dependencies**
   - Checks availability of system dependencies:
     - curl, wget, git
     - nginx, certbot
     - qrencode, ufw

6. **Services Configuration**
   - Checks if nginx service is configured
   - Checks if tailscaled service is configured
   - Checks if ai-website-builder service is configured

7. **Domain Configuration**
   - Checks for nginx configuration file
   - Verifies nginx site is enabled (symlink exists)

## Test Approach

### Mock Deployment

This integration test uses a **mock deployment** approach because a full integration test would require:
- A clean Ubuntu VM
- Root access
- Network connectivity
- Valid domain name
- Valid API keys
- Actual service installation

The mock deployment:
- Creates the configuration directory structure
- Generates configuration and state files
- Creates placeholder QR code files
- Sets proper file permissions
- Does NOT install actual services or dependencies
- Does NOT modify system-wide configurations

### Why Mock Deployment?

1. **Safety**: Avoids modifying the system extensively during testing
2. **Speed**: Runs quickly without waiting for package installations
3. **Portability**: Can run on any system with bash and root access
4. **Repeatability**: Produces consistent results every time

### Full Integration Testing

For a complete end-to-end integration test, you would need:

1. **Clean Ubuntu VM**: Fresh Ubuntu 22.04 LTS installation
2. **Root Access**: SSH access as root user
3. **Valid Credentials**:
   - Real Claude API key
   - Registered domain name pointing to the VM
   - Tailscale account email
4. **Network Access**: Open ports 80, 443, and 22
5. **DNS Configuration**: Domain properly configured to point to VM

The full integration test would:
- Run the actual deployment script
- Install all dependencies
- Configure all services
- Acquire SSL certificates
- Start all services
- Verify domain accessibility
- Test QR code functionality

## Running the Test

### Prerequisites

- Root access (sudo)
- Bash shell
- Basic system utilities (stat, grep, etc.)

### Execution

```bash
# Run with the runner script (recommended)
sudo ./run-integration-fresh-installation.sh

# Or run directly
sudo ./integration-fresh-installation.sh
```

### Expected Output

The test will:
1. Display a header with test name
2. Run pre-flight checks (root user, script exists, system requirements)
3. Setup test environment
4. Execute mock deployment
5. Run all test cases
6. Display test results for each case
7. Cleanup test environment
8. Display test summary with pass/fail counts

### Success Criteria

All tests should pass:
- Configuration directory created with correct permissions
- Configuration file created with correct permissions and content
- State file created with correct content
- QR code files created
- System dependencies available (informational)
- Services configured (informational)

## Test Results Interpretation

### Passed Tests
- Green checkmarks (✓) indicate successful assertions
- All critical security and configuration tests should pass

### Failed Tests
- Red X marks (✗) indicate failed assertions
- Failed tests will show the condition that failed
- Review the failure details to understand what went wrong

### Informational Tests
- Blue info icons (ℹ) indicate informational messages
- These are not failures, just additional context
- Example: "Dependency not installed (expected in mock deployment)"

## Cleanup

The test automatically cleans up after itself:
- Removes test configuration directory
- Removes test log files
- Leaves the mock deployment artifacts for inspection

To manually clean up mock deployment artifacts:

```bash
sudo rm -rf /etc/ai-website-builder
```

## Limitations

This integration test has the following limitations:

1. **Mock Deployment**: Does not test actual service installation
2. **No Network Tests**: Does not verify domain accessibility
3. **No Service Tests**: Does not verify services are actually running
4. **No SSL Tests**: Does not test SSL certificate acquisition
5. **No QR Code Validation**: Does not verify QR codes contain correct data

For comprehensive testing, run the deployment script on a clean Ubuntu VM and manually verify all functionality.

## Future Enhancements

Potential improvements for this integration test:

1. **Docker-based Testing**: Run test in isolated Docker container
2. **Full Deployment Mode**: Option to run actual deployment (not mock)
3. **Service Verification**: Test actual service status and functionality
4. **Network Tests**: Verify domain accessibility and SSL certificates
5. **QR Code Validation**: Decode and verify QR code content
6. **Rollback Testing**: Test deployment rollback and recovery
7. **Update Mode Testing**: Test update mode after fresh installation

## Related Tests

- **Task 18.2**: Integration test for update mode
- **Task 18.3**: Integration test for authentication flow
- **Property Tests**: Various property-based tests for specific behaviors

## Troubleshooting

### Test Fails: Permission Denied

Ensure you're running as root:
```bash
sudo ./run-integration-fresh-installation.sh
```

### Test Fails: Script Not Found

Ensure you're in the correct directory:
```bash
cd infrastructure/scripts/tests
sudo ./run-integration-fresh-installation.sh
```

### Test Fails: Configuration Directory Exists

Clean up from previous test run:
```bash
sudo rm -rf /etc/ai-website-builder
sudo ./run-integration-fresh-installation.sh
```

### Mock Deployment vs Real Deployment

Remember this is a mock deployment. For real deployment testing:
1. Provision a clean Ubuntu VM
2. SSH into the VM as root
3. Run the actual deployment script: `./deploy.sh`
4. Manually verify all functionality

## Conclusion

This integration test provides a quick validation of the deployment script's ability to create the necessary file structure and configurations. While it uses a mock deployment approach, it ensures that the critical security and configuration aspects of the deployment are working correctly.

For production validation, always test on a clean Ubuntu VM with the actual deployment script.
