#!/bin/bash
################################################################################
# Quick Start Deployment Script for AI Website Builder
# 
# This script automates the complete installation and configuration of the
# AI website builder on fresh Ubuntu VMs. It handles dependency installation,
# service configuration, authentication flows, and QR code generation.
#
# Version: 1.0.0
# Requirements: Ubuntu 22.04 LTS, root access, network connectivity
################################################################################

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

################################################################################
# Script Configuration
################################################################################

SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/ai-website-builder-deploy.log"
CONFIG_DIR="/etc/ai-website-builder"
CONFIG_FILE="$CONFIG_DIR/config.env"
STATE_FILE="$CONFIG_DIR/.install-state"
REPOSITORY_PATH="/opt/ai-website-builder"
QR_CODE_DIR="$CONFIG_DIR/qr-codes"

################################################################################
# Color Codes for Output
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Utility Functions
################################################################################

# Mask sensitive value for display (show only last 4 characters)
mask_value() {
    local value="$1"
    local visible_chars=4
    
    # If value is too short, mask everything except last char
    if [ ${#value} -le $visible_chars ]; then
        visible_chars=1
    fi
    
    local masked_length=$((${#value} - visible_chars))
    
    # Create masked string
    printf '%*s' "$masked_length" | tr ' ' '*'
    echo "${value: -visible_chars}"
}

################################################################################
# Logging and Output Functions
################################################################################

# Initialize logging
init_logging() {
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Start logging session
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
    echo "Deployment started at $(date -Iseconds)" | tee -a "$LOG_FILE"
    echo "Script version: $SCRIPT_VERSION" | tee -a "$LOG_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
}

# Log operation to file (with credential masking)
log_operation() {
    local message="$1"
    
    # Mask any potential credentials in the log message
    # Look for patterns like API keys and mask them
    local masked_message="$message"
    
    # Mask Claude API keys (sk-ant-...)
    if [[ "$masked_message" =~ sk-ant-[a-zA-Z0-9_-]+ ]]; then
        # Extract the API key
        local api_key=$(echo "$masked_message" | grep -oP 'sk-ant-[a-zA-Z0-9_-]+')
        local masked_key=$(mask_value "$api_key")
        masked_message="${masked_message//$api_key/$masked_key}"
    fi
    
    # Mask email addresses in sensitive contexts (but not in general logging)
    # We'll be conservative and only mask when explicitly needed
    
    echo "[$(date -Iseconds)] $masked_message" >> "$LOG_FILE"
}

# Display progress message
display_progress() {
    local message="$1"
    echo -e "${BLUE}▶${NC} $message"
    log_operation "PROGRESS: $message"
}

# Display success message
display_success() {
    local message="$1"
    echo -e "${GREEN}✓${NC} $message"
    log_operation "SUCCESS: $message"
}

# Display warning message
display_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠${NC} $message"
    log_operation "WARNING: $message"
}

# Display info message
display_info() {
    local message="$1"
    echo -e "${BLUE}ℹ${NC} $message"
    log_operation "INFO: $message"
}

# Display error message
display_error() {
    local message="$1"
    echo -e "${RED}✗${NC} $message"
    log_operation "ERROR: $message"
}

################################################################################
# Error Handling
################################################################################

# Handle errors with formatted output and remediation guidance
handle_error() {
    local exit_code=$?
    local line_number=$1
    local command="$2"
    
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo -e "${RED}❌ ERROR: Deployment failed${NC}" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "Details:" >&2
    echo "  Exit code: $exit_code" >&2
    echo "  Line number: $line_number" >&2
    echo "  Failed command: $command" >&2
    echo "" >&2
    echo "Remediation:" >&2
    echo "  1. Check the log file for detailed error information:" >&2
    echo "     $LOG_FILE" >&2
    echo "  2. Verify all prerequisites are met (Ubuntu 22.04, root access, network)" >&2
    echo "  3. If you created a VM snapshot, you can restore it and try again" >&2
    echo "  4. Re-run this script to resume from a safe checkpoint" >&2
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    
    log_operation "ERROR: Deployment failed at line $line_number with exit code $exit_code"
    log_operation "ERROR: Failed command: $command"
    
    exit "$exit_code"
}

# Set up error trap
trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR

# Handle script interruption (Ctrl+C)
handle_interrupt() {
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo -e "${YELLOW}⚠ Deployment interrupted by user${NC}" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "The deployment was interrupted. You can safely re-run this script" >&2
    echo "to resume from a safe checkpoint." >&2
    echo "" >&2
    log_operation "WARNING: Deployment interrupted by user"
    exit 130
}

trap 'handle_interrupt' INT TERM

################################################################################
# Placeholder Functions (to be implemented in subsequent tasks)
################################################################################

# Prompt user to create VM snapshot before deployment
prompt_vm_snapshot() {
    log_operation "FUNCTION: prompt_vm_snapshot called"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${YELLOW}⚠ VM Snapshot Recommendation${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Before proceeding with the deployment, we strongly recommend"
    echo "creating a snapshot of your VM. This allows you to easily"
    echo "restore your system if something goes wrong during deployment."
    echo ""
    echo "How to create a snapshot on common cloud providers:"
    echo ""
    echo -e "${BLUE}AWS EC2:${NC}"
    echo "  1. Go to EC2 Dashboard → Instances"
    echo "  2. Select your instance → Actions → Image and templates → Create image"
    echo "  3. Or use CLI: aws ec2 create-image --instance-id <instance-id> --name \"Pre-deployment-snapshot\""
    echo ""
    echo -e "${BLUE}Google Cloud Platform (GCP):${NC}"
    echo "  1. Go to Compute Engine → VM instances"
    echo "  2. Click on your instance → Create snapshot"
    echo "  3. Or use CLI: gcloud compute disks snapshot <disk-name> --snapshot-names=pre-deployment-snapshot"
    echo ""
    echo -e "${BLUE}Microsoft Azure:${NC}"
    echo "  1. Go to Virtual machines → Select your VM"
    echo "  2. Click Disks → Select OS disk → Create snapshot"
    echo "  3. Or use CLI: az snapshot create --resource-group <rg> --source <disk-id> --name pre-deployment-snapshot"
    echo ""
    echo -e "${BLUE}DigitalOcean:${NC}"
    echo "  1. Go to Droplets → Select your droplet"
    echo "  2. Click Snapshots → Take snapshot"
    echo "  3. Or use CLI: doctl compute droplet-action snapshot <droplet-id> --snapshot-name pre-deployment-snapshot"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_operation "Displayed VM snapshot instructions for cloud providers"
    
    # Prompt user for confirmation
    while true; do
        echo -n "Have you created a VM snapshot? (yes/no): "
        read -r response
        
        log_operation "User response to snapshot prompt: $response"
        
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                display_success "Snapshot confirmed - proceeding with deployment"
                log_operation "User confirmed VM snapshot creation"
                break
                ;;
            [Nn]|[Nn][Oo])
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo -e "${RED}⚠ WARNING: Proceeding without VM snapshot${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "You have chosen to proceed without creating a VM snapshot."
                echo ""
                echo "Recovery limitations:"
                echo "  • If deployment fails, manual recovery may be required"
                echo "  • System changes cannot be easily rolled back"
                echo "  • You may need to restore from backups or rebuild the VM"
                echo ""
                echo "We strongly recommend creating a snapshot before continuing."
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                
                display_warning "Proceeding without VM snapshot - recovery options limited"
                log_operation "WARNING: User chose to proceed without VM snapshot"
                
                # Ask for final confirmation
                echo -n "Are you sure you want to continue without a snapshot? (yes/no): "
                read -r final_response
                
                log_operation "User final confirmation: $final_response"
                
                case "$final_response" in
                    [Yy]|[Yy][Ee][Ss])
                        display_info "Continuing deployment without snapshot"
                        log_operation "User confirmed proceeding without snapshot"
                        break
                        ;;
                    [Nn]|[Nn][Oo])
                        echo ""
                        display_info "Deployment cancelled - please create a snapshot and re-run this script"
                        log_operation "User cancelled deployment to create snapshot"
                        exit 0
                        ;;
                    *)
                        echo "Please answer 'yes' or 'no'"
                        ;;
                esac
                ;;
            *)
                echo "Please answer 'yes' or 'no'"
                ;;
        esac
    done
    
    echo ""
}

# Pre-flight system checks
run_preflight_checks() {
    display_progress "Running pre-flight system checks..."
    log_operation "FUNCTION: run_preflight_checks called"
    
    local checks_passed=true
    
    # Check 1: Verify running as root (already checked at entry point, but log it)
    if [ "$EUID" -eq 0 ]; then
        display_success "Root user check: PASSED"
        log_operation "Pre-flight check: Running as root - PASSED"
    else
        display_error "Root user check: FAILED"
        log_operation "Pre-flight check: Not running as root - FAILED"
        checks_passed=false
    fi
    
    # Check 2: Verify Ubuntu OS
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            display_success "Ubuntu OS check: PASSED (Version: $VERSION)"
            log_operation "Pre-flight check: Ubuntu OS detected - PASSED (ID=$ID, VERSION=$VERSION)"
        else
            display_warning "Ubuntu OS check: FAILED (Detected: $ID)"
            display_warning "This script is designed for Ubuntu. Proceeding may cause issues."
            log_operation "Pre-flight check: Non-Ubuntu OS detected - WARNING (ID=$ID)"
            # Don't fail, just warn
        fi
    else
        display_warning "Ubuntu OS check: Cannot determine OS (/etc/os-release not found)"
        log_operation "Pre-flight check: Cannot determine OS - WARNING"
    fi
    
    # Check 3: Check disk space (minimum 10GB free)
    local available_space_kb=$(df / | tail -1 | awk '{print $4}')
    local available_space_gb=$((available_space_kb / 1024 / 1024))
    local min_space_gb=10
    
    if [ "$available_space_gb" -ge "$min_space_gb" ]; then
        display_success "Disk space check: PASSED (${available_space_gb}GB available)"
        log_operation "Pre-flight check: Sufficient disk space - PASSED (${available_space_gb}GB available)"
    else
        display_error "Disk space check: FAILED (${available_space_gb}GB available, ${min_space_gb}GB required)"
        log_operation "Pre-flight check: Insufficient disk space - FAILED (${available_space_gb}GB available, ${min_space_gb}GB required)"
        checks_passed=false
    fi
    
    # Check 4: Verify network connectivity
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        display_success "Network connectivity check: PASSED"
        log_operation "Pre-flight check: Network connectivity - PASSED"
    else
        display_error "Network connectivity check: FAILED"
        log_operation "Pre-flight check: Network connectivity - FAILED"
        checks_passed=false
    fi
    
    # If any critical checks failed, exit
    if [ "$checks_passed" = false ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Pre-flight checks failed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "One or more critical pre-flight checks failed."
        echo ""
        echo "Remediation:"
        echo "  1. Ensure you are running as root user"
        echo "  2. Verify you have at least 10GB of free disk space"
        echo "  3. Check your network connectivity"
        echo "  4. Review the log file for details: $LOG_FILE"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_operation "ERROR: Pre-flight checks failed - exiting"
        exit 1
    fi
    
    echo ""
}

# Detect if this is a fresh installation or update mode
detect_existing_installation() {
    display_progress "Detecting existing installation..."
    log_operation "FUNCTION: detect_existing_installation called"
    
    if [ -f "$STATE_FILE" ]; then
        MODE="update"
        display_info "Existing installation detected - entering update mode"
        log_operation "Installation mode: update (state file found at $STATE_FILE)"
    else
        MODE="fresh"
        display_info "No existing installation found - entering fresh installation mode"
        log_operation "Installation mode: fresh (no state file at $STATE_FILE)"
    fi
}

# Validate Claude API key format
validate_claude_api_key() {
    local api_key="$1"
    
    # Check if empty
    if [ -z "$api_key" ]; then
        echo "ERROR: Claude API key cannot be empty"
        return 1
    fi
    
    # Check if it starts with expected prefix (sk-ant-)
    if [[ ! "$api_key" =~ ^sk-ant- ]]; then
        echo "ERROR: Claude API key must start with 'sk-ant-'"
        return 1
    fi
    
    # Check minimum length (sk-ant- is 7 chars, plus at least some key material)
    if [ ${#api_key} -lt 20 ]; then
        echo "ERROR: Claude API key appears too short"
        return 1
    fi
    
    return 0
}

# Validate domain name format
validate_domain_name() {
    local domain="$1"
    
    # Check if empty
    if [ -z "$domain" ]; then
        echo "ERROR: Domain name cannot be empty"
        return 1
    fi
    
    # Check FQDN format (basic regex)
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        echo "ERROR: Invalid domain name format. Must be a valid FQDN (e.g., example.com)"
        return 1
    fi
    
    # Check if domain has at least one dot (TLD required)
    if [[ ! "$domain" =~ \. ]]; then
        echo "ERROR: Domain name must include a top-level domain (e.g., .com, .org)"
        return 1
    fi
    
    # Try DNS resolution (optional check - may fail if DNS not yet configured)
    if command -v dig >/dev/null 2>&1; then
        if dig +short "$domain" A >/dev/null 2>&1 || dig +short "$domain" AAAA >/dev/null 2>&1; then
            log_operation "Domain $domain resolves in DNS"
        else
            display_warning "Domain $domain does not currently resolve in DNS (this is OK if you haven't configured DNS yet)"
            log_operation "WARNING: Domain $domain does not resolve in DNS"
        fi
    fi
    
    return 0
}

# Validate email format
validate_email() {
    local email="$1"
    
    # Check if empty
    if [ -z "$email" ]; then
        echo "ERROR: Email address cannot be empty"
        return 1
    fi
    
    # Check email format with regex
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "ERROR: Invalid email format. Must be a valid email address (e.g., user@example.com)"
        return 1
    fi
    
    return 0
}

# Validate all configuration inputs
validate_configuration() {
    local field="$1"
    local value="$2"
    
    log_operation "Validating configuration field: $field"
    
    case "$field" in
        "claude_api_key")
            validate_claude_api_key "$value"
            ;;
        "domain_name")
            validate_domain_name "$value"
            ;;
        "tailscale_email")
            validate_email "$value"
            ;;
        *)
            echo "ERROR: Unknown configuration field: $field"
            return 1
            ;;
    esac
}

# Collect configuration input from user
collect_configuration_input() {
    display_progress "Collecting configuration input..."
    log_operation "FUNCTION: collect_configuration_input called"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Configuration Input${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Please provide the following configuration values:"
    echo ""
    
    # Collect Claude API key
    while true; do
        echo -n "Claude API key (starts with sk-ant-): "
        read -s CLAUDE_API_KEY  # -s flag masks input
        echo ""  # New line after masked input
        
        log_operation "User provided Claude API key (masked)"
        
        # Temporarily disable exit on error for validation
        set +e
        validation_error=$(validate_configuration "claude_api_key" "$CLAUDE_API_KEY")
        validation_result=$?
        set -e
        
        if [ $validation_result -eq 0 ]; then
            display_success "Claude API key validated"
            log_operation "Claude API key validation: PASSED"
            break
        else
            display_error "$validation_error"
            log_operation "Claude API key validation: FAILED - $validation_error"
            echo "Please try again."
            echo ""
        fi
    done
    
    echo ""
    
    # Collect domain name
    while true; do
        echo -n "Domain name (e.g., example.com): "
        read -r DOMAIN_NAME
        
        log_operation "User provided domain name: $DOMAIN_NAME"
        
        # Temporarily disable exit on error for validation
        set +e
        validation_error=$(validate_configuration "domain_name" "$DOMAIN_NAME")
        validation_result=$?
        set -e
        
        if [ $validation_result -eq 0 ]; then
            display_success "Domain name validated"
            log_operation "Domain name validation: PASSED"
            break
        else
            display_error "$validation_error"
            log_operation "Domain name validation: FAILED - $validation_error"
            echo "Please try again."
            echo ""
        fi
    done
    
    echo ""
    
    # Collect Tailscale email
    while true; do
        echo -n "Tailscale account email: "
        read -r TAILSCALE_EMAIL
        
        log_operation "User provided Tailscale email: $TAILSCALE_EMAIL"
        
        # Temporarily disable exit on error for validation
        set +e
        validation_error=$(validate_configuration "tailscale_email" "$TAILSCALE_EMAIL")
        validation_result=$?
        set -e
        
        if [ $validation_result -eq 0 ]; then
            display_success "Tailscale email validated"
            log_operation "Tailscale email validation: PASSED"
            break
        else
            display_error "$validation_error"
            log_operation "Tailscale email validation: FAILED - $validation_error"
            echo "Please try again."
            echo ""
        fi
    done
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    display_success "Configuration input collected successfully"
    log_operation "All configuration inputs collected and validated"
    echo ""
}

# Load existing configuration in update mode
load_existing_configuration() {
    display_progress "Loading existing configuration..."
    log_operation "FUNCTION: load_existing_configuration called"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        display_error "Configuration file not found: $CONFIG_FILE"
        log_operation "ERROR: Configuration file not found at $CONFIG_FILE"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Cannot load existing configuration${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: Configuration file not found at $CONFIG_FILE"
        echo ""
        echo "Remediation:"
        echo "  1. Verify this is an existing installation"
        echo "  2. Check if the configuration file was deleted"
        echo "  3. Run the script in fresh installation mode instead"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Source the configuration file to load variables
    source "$CONFIG_FILE"
    log_operation "Loaded configuration from $CONFIG_FILE"
    
    # Display current configuration with masked sensitive values
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Current Configuration${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Claude API key: $(mask_value "$CLAUDE_API_KEY")"
    echo "Domain name: $DOMAIN_NAME"
    echo "Tailscale email: $TAILSCALE_EMAIL"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_operation "Displayed current configuration (credentials masked)"
    
    # Now prompt for updates, allowing user to press Enter to keep existing values
    echo "Press Enter to keep the current value, or enter a new value to update."
    echo ""
    
    # Update Claude API key
    while true; do
        echo -n "Claude API key [$(mask_value "$CLAUDE_API_KEY")]: "
        read -s new_api_key
        echo ""  # New line after masked input
        
        # If user pressed Enter (empty input), keep existing value
        if [ -z "$new_api_key" ]; then
            display_info "Keeping existing Claude API key"
            log_operation "User kept existing Claude API key"
            break
        fi
        
        log_operation "User provided new Claude API key (masked)"
        
        # Temporarily disable exit on error for validation
        set +e
        validation_error=$(validate_configuration "claude_api_key" "$new_api_key")
        validation_result=$?
        set -e
        
        if [ $validation_result -eq 0 ]; then
            CLAUDE_API_KEY="$new_api_key"
            display_success "Claude API key updated"
            log_operation "Claude API key updated and validated"
            break
        else
            display_error "$validation_error"
            log_operation "Claude API key validation: FAILED - $validation_error"
            echo "Please try again, or press Enter to keep the existing value."
            echo ""
        fi
    done
    
    echo ""
    
    # Update domain name
    while true; do
        echo -n "Domain name [$DOMAIN_NAME]: "
        read -r new_domain
        
        # If user pressed Enter (empty input), keep existing value
        if [ -z "$new_domain" ]; then
            display_info "Keeping existing domain name"
            log_operation "User kept existing domain name: $DOMAIN_NAME"
            break
        fi
        
        log_operation "User provided new domain name: $new_domain"
        
        # Temporarily disable exit on error for validation
        set +e
        validation_error=$(validate_configuration "domain_name" "$new_domain")
        validation_result=$?
        set -e
        
        if [ $validation_result -eq 0 ]; then
            DOMAIN_NAME="$new_domain"
            display_success "Domain name updated"
            log_operation "Domain name updated and validated: $DOMAIN_NAME"
            break
        else
            display_error "$validation_error"
            log_operation "Domain name validation: FAILED - $validation_error"
            echo "Please try again, or press Enter to keep the existing value."
            echo ""
        fi
    done
    
    echo ""
    
    # Update Tailscale email
    while true; do
        echo -n "Tailscale account email [$TAILSCALE_EMAIL]: "
        read -r new_email
        
        # If user pressed Enter (empty input), keep existing value
        if [ -z "$new_email" ]; then
            display_info "Keeping existing Tailscale email"
            log_operation "User kept existing Tailscale email: $TAILSCALE_EMAIL"
            break
        fi
        
        log_operation "User provided new Tailscale email: $new_email"
        
        # Temporarily disable exit on error for validation
        set +e
        validation_error=$(validate_configuration "tailscale_email" "$new_email")
        validation_result=$?
        set -e
        
        if [ $validation_result -eq 0 ]; then
            TAILSCALE_EMAIL="$new_email"
            display_success "Tailscale email updated"
            log_operation "Tailscale email updated and validated: $TAILSCALE_EMAIL"
            break
        else
            display_error "$validation_error"
            log_operation "Tailscale email validation: FAILED - $validation_error"
            echo "Please try again, or press Enter to keep the existing value."
            echo ""
        fi
    done
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    display_success "Configuration update completed"
    log_operation "Configuration update completed in update mode"
    echo ""
}

# Save configuration to secure file
save_configuration() {
    display_progress "Saving configuration..."
    log_operation "FUNCTION: save_configuration called"
    
    # Create configuration directory with secure permissions (700 = rwx------)
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        chmod 700 "$CONFIG_DIR"
        display_success "Created configuration directory: $CONFIG_DIR"
        log_operation "Created configuration directory with 700 permissions: $CONFIG_DIR"
    fi
    
    # Verify directory permissions
    chmod 700 "$CONFIG_DIR"
    chown root:root "$CONFIG_DIR"
    log_operation "Set configuration directory permissions to 700 and ownership to root:root"
    
    # Write configuration to file
    cat > "$CONFIG_FILE" << EOF
# AI Website Builder Configuration
# Generated: $(date -Iseconds)
# DO NOT SHARE THIS FILE - Contains sensitive credentials

CLAUDE_API_KEY=$CLAUDE_API_KEY
DOMAIN_NAME=$DOMAIN_NAME
TAILSCALE_EMAIL=$TAILSCALE_EMAIL
INSTALL_DATE=${INSTALL_DATE:-$(date -Iseconds)}
REPOSITORY_PATH=$REPOSITORY_PATH
EOF
    
    # Set secure file permissions (600 = rw-------)
    chmod 600 "$CONFIG_FILE"
    chown root:root "$CONFIG_FILE"
    
    display_success "Configuration saved to $CONFIG_FILE"
    log_operation "Configuration saved with 600 permissions and root:root ownership"
    
    # Verify permissions were set correctly
    local file_perms=$(stat -c "%a" "$CONFIG_FILE")
    local file_owner=$(stat -c "%U:%G" "$CONFIG_FILE")
    
    if [ "$file_perms" = "600" ] && [ "$file_owner" = "root:root" ]; then
        display_success "Configuration file security verified (600, root:root)"
        log_operation "Configuration file security verified: permissions=$file_perms, owner=$file_owner"
    else
        display_warning "Configuration file permissions may not be secure: $file_perms, $file_owner"
        log_operation "WARNING: Configuration file security check: permissions=$file_perms, owner=$file_owner"
    fi
}

# Install system dependencies
install_system_dependencies() {
    display_progress "Installing system dependencies..."
    log_operation "FUNCTION: install_system_dependencies called"
    
    # Update package lists
    display_progress "Updating package lists..."
    log_operation "Running apt update"
    
    if apt update >> "$LOG_FILE" 2>&1; then
        display_success "Package lists updated"
        log_operation "apt update completed successfully"
    else
        display_error "Failed to update package lists"
        log_operation "ERROR: apt update failed"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Package list update failed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: Failed to update apt package lists"
        echo ""
        echo "Remediation:"
        echo "  1. Check your network connectivity"
        echo "  2. Verify your apt sources are configured correctly in /etc/apt/sources.list"
        echo "  3. Check the log file for details: $LOG_FILE"
        echo "  4. Try running 'apt update' manually to see the error"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # List of system packages to install
    local packages=(
        "curl"
        "wget"
        "git"
        "nginx"
        "certbot"
        "qrencode"
        "ufw"
    )
    
    # Install each package with progress indication
    for package in "${packages[@]}"; do
        display_progress "Installing $package..."
        log_operation "Installing package: $package"
        
        # Check if package is already installed
        if dpkg -l | grep -q "^ii  $package "; then
            display_info "$package is already installed"
            log_operation "Package $package is already installed - skipping"
            continue
        fi
        
        # Install the package
        if DEBIAN_FRONTEND=noninteractive apt install -y "$package" >> "$LOG_FILE" 2>&1; then
            display_success "$package installed successfully"
            log_operation "Package $package installed successfully"
        else
            display_error "Failed to install $package"
            log_operation "ERROR: Failed to install package $package"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: Package installation failed${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: Failed to install package: $package"
            echo ""
            echo "Remediation:"
            echo "  1. Check your network connectivity"
            echo "  2. Verify the package name is correct and available in your Ubuntu version"
            echo "  3. Check the log file for detailed error information: $LOG_FILE"
            echo "  4. Try running 'apt install $package' manually to see the error"
            echo "  5. Ensure you have sufficient disk space"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
    done
    
    display_success "All system dependencies installed successfully"
    log_operation "All system dependencies installed successfully"
}

# Install runtime dependencies (Node.js, npm packages)
install_runtime_dependencies() {
    display_progress "Installing runtime dependencies..."
    log_operation "FUNCTION: install_runtime_dependencies called"
    
    # Check if Node.js is already installed
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version)
        display_info "Node.js is already installed: $node_version"
        log_operation "Node.js already installed: $node_version"
    else
        # Add NodeSource repository for Node.js LTS
        display_progress "Adding NodeSource repository for Node.js LTS..."
        log_operation "Adding NodeSource repository"
        
        # Download and run NodeSource setup script for Node.js 20.x (LTS)
        if curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >> "$LOG_FILE" 2>&1; then
            display_success "NodeSource repository added"
            log_operation "NodeSource repository added successfully"
        else
            display_error "Failed to add NodeSource repository"
            log_operation "ERROR: Failed to add NodeSource repository"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: NodeSource repository setup failed${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: Failed to add NodeSource repository for Node.js"
            echo ""
            echo "Remediation:"
            echo "  1. Check your network connectivity"
            echo "  2. Verify you can access https://deb.nodesource.com"
            echo "  3. Check the log file for details: $LOG_FILE"
            echo "  4. Try running the setup script manually:"
            echo "     curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
        
        # Install Node.js and npm
        display_progress "Installing Node.js and npm..."
        log_operation "Installing Node.js and npm"
        
        if DEBIAN_FRONTEND=noninteractive apt install -y nodejs >> "$LOG_FILE" 2>&1; then
            local node_version=$(node --version)
            local npm_version=$(npm --version)
            display_success "Node.js $node_version and npm $npm_version installed"
            log_operation "Node.js $node_version and npm $npm_version installed successfully"
        else
            display_error "Failed to install Node.js"
            log_operation "ERROR: Failed to install Node.js"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: Node.js installation failed${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: Failed to install Node.js package"
            echo ""
            echo "Remediation:"
            echo "  1. Verify the NodeSource repository was added correctly"
            echo "  2. Check the log file for details: $LOG_FILE"
            echo "  3. Try running 'apt install nodejs' manually to see the error"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
    fi
    
    # Clone repository if it doesn't exist
    if [ -d "$REPOSITORY_PATH" ]; then
        display_info "Repository already exists at $REPOSITORY_PATH"
        log_operation "Repository already exists at $REPOSITORY_PATH - skipping clone"
    else
        display_progress "Cloning AI website builder repository..."
        log_operation "Cloning repository to $REPOSITORY_PATH"
        
        local repo_url="https://github.com/larsenkevin/ai-website-builder.git"
        
        if git clone "$repo_url" "$REPOSITORY_PATH" >> "$LOG_FILE" 2>&1; then
            display_success "Repository cloned to $REPOSITORY_PATH"
            log_operation "Repository cloned successfully"
        else
            display_error "Failed to clone repository"
            log_operation "ERROR: Failed to clone repository from $repo_url"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: Repository clone failed${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: Failed to clone repository from $repo_url"
            echo ""
            echo "Remediation:"
            echo "  1. Check your network connectivity"
            echo "  2. Verify the repository URL is correct"
            echo "  3. Ensure you have access to the repository"
            echo "  4. Check the log file for details: $LOG_FILE"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
    fi
    
    # Install npm dependencies
    display_progress "Installing npm dependencies (this may take a few minutes)..."
    log_operation "Running npm install in $REPOSITORY_PATH"
    
    if [ -f "$REPOSITORY_PATH/package.json" ]; then
        cd "$REPOSITORY_PATH"
        
        if npm install >> "$LOG_FILE" 2>&1; then
            display_success "npm dependencies installed successfully"
            log_operation "npm install completed successfully"
        else
            display_error "Failed to install npm dependencies"
            log_operation "ERROR: npm install failed"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: npm dependency installation failed${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: Failed to install npm dependencies"
            echo ""
            echo "Remediation:"
            echo "  1. Check the log file for detailed error information: $LOG_FILE"
            echo "  2. Verify package.json exists and is valid"
            echo "  3. Try running 'npm install' manually in $REPOSITORY_PATH"
            echo "  4. Check for disk space issues"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
        
        cd - > /dev/null
    else
        display_warning "No package.json found in $REPOSITORY_PATH - skipping npm install"
        log_operation "WARNING: No package.json found - skipping npm install"
    fi
    
    # Build the application
    display_progress "Building application (compiling TypeScript)..."
    log_operation "Running npm run build in $REPOSITORY_PATH"
    
    if [ -f "$REPOSITORY_PATH/package.json" ]; then
        cd "$REPOSITORY_PATH"
        
        if npm run build >> "$LOG_FILE" 2>&1; then
            display_success "Application built successfully"
            log_operation "npm run build completed successfully"
            
            # Verify dist directory was created
            if [ -d "$REPOSITORY_PATH/dist" ] && [ -f "$REPOSITORY_PATH/dist/server.js" ]; then
                display_success "Build output verified (dist/server.js exists)"
                log_operation "Build verification: dist/server.js exists"
            else
                display_error "Build completed but dist/server.js not found"
                log_operation "ERROR: Build completed but dist/server.js not found"
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo -e "${RED}❌ ERROR: Application build verification failed${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "Details: Build completed but expected output file not found"
                echo ""
                echo "Remediation:"
                echo "  1. Check the log file for build errors: $LOG_FILE"
                echo "  2. Verify tsconfig.json is configured correctly"
                echo "  3. Check that app/server.ts exists"
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                exit 1
            fi
        else
            display_error "Failed to build application"
            log_operation "ERROR: npm run build failed"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: Application build failed${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: Failed to compile TypeScript code"
            echo ""
            echo "Remediation:"
            echo "  1. Check the log file for detailed error information: $LOG_FILE"
            echo "  2. Verify TypeScript is installed correctly"
            echo "  3. Try running 'npm run build' manually in $REPOSITORY_PATH"
            echo "  4. Check for TypeScript compilation errors"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
        
        cd - > /dev/null
    fi
    
    display_success "All runtime dependencies installed successfully"
    log_operation "All runtime dependencies installed successfully"
}

# Install and configure Tailscale
install_tailscale() {
    display_progress "Installing Tailscale..."
    log_operation "FUNCTION: install_tailscale called"
    
    # Check if Tailscale is already installed
    if command -v tailscale >/dev/null 2>&1; then
        local tailscale_version=$(tailscale version | head -n1)
        display_info "Tailscale is already installed: $tailscale_version"
        log_operation "Tailscale already installed: $tailscale_version"
    else
        # Add Tailscale package repository
        display_progress "Adding Tailscale package repository..."
        log_operation "Adding Tailscale repository"
        
        # Download and add Tailscale GPG key
        if curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$(lsb_release -cs).noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null; then
            display_success "Tailscale GPG key added"
            log_operation "Tailscale GPG key added successfully"
        else
            display_error "Failed to add Tailscale GPG key"
            log_operation "ERROR: Failed to add Tailscale GPG key"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: Tailscale repository setup failed${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: Failed to add Tailscale GPG key"
            echo ""
            echo "Remediation:"
            echo "  1. Check your network connectivity"
            echo "  2. Verify you can access https://pkgs.tailscale.com"
            echo "  3. Check the log file for details: $LOG_FILE"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
        
        # Add Tailscale repository to sources list
        echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/tailscale.list > /dev/null
        
        display_success "Tailscale repository added"
        log_operation "Tailscale repository added to sources list"
        
        # Update package lists
        display_progress "Updating package lists..."
        log_operation "Running apt update after adding Tailscale repository"
        
        if apt update >> "$LOG_FILE" 2>&1; then
            display_success "Package lists updated"
            log_operation "apt update completed successfully"
        else
            display_error "Failed to update package lists"
            log_operation "ERROR: apt update failed after adding Tailscale repository"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: Package list update failed${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: Failed to update apt package lists after adding Tailscale repository"
            echo ""
            echo "Remediation:"
            echo "  1. Check the Tailscale repository configuration in /etc/apt/sources.list.d/tailscale.list"
            echo "  2. Check the log file for details: $LOG_FILE"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
        
        # Install Tailscale package
        display_progress "Installing Tailscale package..."
        log_operation "Installing Tailscale package"
        
        if DEBIAN_FRONTEND=noninteractive apt install -y tailscale >> "$LOG_FILE" 2>&1; then
            local tailscale_version=$(tailscale version | head -n1)
            display_success "Tailscale $tailscale_version installed"
            log_operation "Tailscale installed successfully: $tailscale_version"
        else
            display_error "Failed to install Tailscale"
            log_operation "ERROR: Failed to install Tailscale package"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: Tailscale installation failed${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: Failed to install Tailscale package"
            echo ""
            echo "Remediation:"
            echo "  1. Verify the Tailscale repository was added correctly"
            echo "  2. Check the log file for details: $LOG_FILE"
            echo "  3. Try running 'apt install tailscale' manually to see the error"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
    fi
    
    # Enable and start tailscaled service
    display_progress "Enabling and starting tailscaled service..."
    log_operation "Enabling tailscaled service"
    
    if systemctl enable tailscaled >> "$LOG_FILE" 2>&1; then
        display_success "tailscaled service enabled"
        log_operation "tailscaled service enabled successfully"
    else
        display_warning "Failed to enable tailscaled service (may already be enabled)"
        log_operation "WARNING: Failed to enable tailscaled service"
    fi
    
    log_operation "Starting tailscaled service"
    
    if systemctl start tailscaled >> "$LOG_FILE" 2>&1; then
        display_success "tailscaled service started"
        log_operation "tailscaled service started successfully"
    else
        # Check if already running
        if systemctl is-active --quiet tailscaled; then
            display_info "tailscaled service is already running"
            log_operation "tailscaled service is already running"
        else
            display_error "Failed to start tailscaled service"
            log_operation "ERROR: Failed to start tailscaled service"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: Tailscale service start failed${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: Failed to start tailscaled service"
            echo ""
            echo "Remediation:"
            echo "  1. Check the service status: systemctl status tailscaled"
            echo "  2. Check the log file for details: $LOG_FILE"
            echo "  3. Check system logs: journalctl -u tailscaled"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
    fi
    
    # Verify service is running
    if systemctl is-active --quiet tailscaled; then
        display_success "Tailscale installed and running successfully"
        log_operation "Tailscale installation completed - service is active"
    else
        display_warning "Tailscale installed but service status unclear"
        log_operation "WARNING: Tailscale installed but service status unclear"
    fi
}

# Configure firewall rules
configure_firewall() {
    display_progress "Configuring firewall..."
    log_operation "FUNCTION: configure_firewall called"
    
    # Check if ufw is installed (should be from system dependencies)
    if ! command -v ufw >/dev/null 2>&1; then
        display_error "ufw is not installed"
        log_operation "ERROR: ufw command not found"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Firewall configuration failed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: ufw (Uncomplicated Firewall) is not installed"
        echo ""
        echo "Remediation:"
        echo "  1. Install ufw: apt install ufw"
        echo "  2. Re-run this script"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Allow SSH (port 22) - critical to do this before enabling firewall
    display_progress "Allowing SSH (port 22)..."
    log_operation "Configuring ufw to allow SSH"
    
    if ufw allow 22/tcp >> "$LOG_FILE" 2>&1; then
        display_success "SSH (port 22) allowed"
        log_operation "ufw rule added: allow 22/tcp"
    else
        display_warning "Failed to add SSH rule (may already exist)"
        log_operation "WARNING: Failed to add SSH rule"
    fi
    
    # Allow HTTP (port 80)
    display_progress "Allowing HTTP (port 80)..."
    log_operation "Configuring ufw to allow HTTP"
    
    if ufw allow 80/tcp >> "$LOG_FILE" 2>&1; then
        display_success "HTTP (port 80) allowed"
        log_operation "ufw rule added: allow 80/tcp"
    else
        display_warning "Failed to add HTTP rule (may already exist)"
        log_operation "WARNING: Failed to add HTTP rule"
    fi
    
    # Allow HTTPS (port 443)
    display_progress "Allowing HTTPS (port 443)..."
    log_operation "Configuring ufw to allow HTTPS"
    
    if ufw allow 443/tcp >> "$LOG_FILE" 2>&1; then
        display_success "HTTPS (port 443) allowed"
        log_operation "ufw rule added: allow 443/tcp"
    else
        display_warning "Failed to add HTTPS rule (may already exist)"
        log_operation "WARNING: Failed to add HTTPS rule"
    fi
    
    # Enable ufw firewall
    display_progress "Enabling firewall..."
    log_operation "Enabling ufw firewall"
    
    # Check if already enabled
    if ufw status | grep -q "Status: active"; then
        display_info "Firewall is already enabled"
        log_operation "ufw is already enabled"
    else
        # Enable ufw with --force to avoid interactive prompt
        if echo "y" | ufw enable >> "$LOG_FILE" 2>&1; then
            display_success "Firewall enabled"
            log_operation "ufw enabled successfully"
        else
            display_error "Failed to enable firewall"
            log_operation "ERROR: Failed to enable ufw"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: Firewall enable failed${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: Failed to enable ufw firewall"
            echo ""
            echo "Remediation:"
            echo "  1. Check the log file for details: $LOG_FILE"
            echo "  2. Try enabling manually: ufw enable"
            echo "  3. Check for conflicting firewall configurations"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
    fi
    
    # Display firewall status
    display_progress "Verifying firewall configuration..."
    log_operation "Checking ufw status"
    
    local ufw_status=$(ufw status)
    log_operation "ufw status output: $ufw_status"
    
    if echo "$ufw_status" | grep -q "Status: active"; then
        display_success "Firewall configured and active"
        log_operation "Firewall configuration completed successfully"
        
        # Log the active rules
        display_info "Active firewall rules:"
        ufw status numbered | grep -E "^\[" | while read -r line; do
            display_info "  $line"
        done
    else
        display_warning "Firewall configuration unclear"
        log_operation "WARNING: Firewall status unclear"
    fi
}

# Configure web server (nginx)
configure_web_server() {
    display_progress "Configuring nginx web server..."
    log_operation "FUNCTION: configure_web_server called"
    
    # Verify nginx is installed
    if ! command -v nginx >/dev/null 2>&1; then
        display_error "nginx is not installed"
        log_operation "ERROR: nginx command not found"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Web server configuration failed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: nginx is not installed"
        echo ""
        echo "Remediation:"
        echo "  1. Install nginx: apt install nginx"
        echo "  2. Re-run this script"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Create directory for ACME challenge if it doesn't exist
    display_progress "Creating ACME challenge directory..."
    log_operation "Creating /var/www/certbot directory for ACME challenges"
    
    if mkdir -p /var/www/certbot; then
        display_success "ACME challenge directory created"
        log_operation "ACME challenge directory created at /var/www/certbot"
    else
        display_error "Failed to create ACME challenge directory"
        log_operation "ERROR: Failed to create /var/www/certbot"
        exit 1
    fi
    
    # Generate nginx configuration file
    display_progress "Generating nginx configuration..."
    log_operation "Generating nginx configuration for domain: $DOMAIN_NAME"
    
    local nginx_config="/etc/nginx/sites-available/ai-website-builder"
    
    # Create initial HTTP-only configuration (SSL will be added after certificate acquisition)
    cat > "$nginx_config" << EOF
# AI Website Builder - Nginx Configuration
# Generated: $(date -Iseconds)
# Domain: $DOMAIN_NAME

# HTTP Server Block - Handles ACME challenges and serves application
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME;
    
    # ACME challenge location for Let's Encrypt certificate acquisition
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri =404;
    }
    
    # Proxy to AI Website Builder application on localhost:3000
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        
        # Proxy headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support (if needed)
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Logging
    access_log /var/log/nginx/ai-website-builder-access.log;
    error_log /var/log/nginx/ai-website-builder-error.log;
}
EOF
    
    if [ $? -eq 0 ]; then
        display_success "Nginx configuration generated at $nginx_config"
        log_operation "Nginx configuration file created successfully"
    else
        display_error "Failed to generate nginx configuration"
        log_operation "ERROR: Failed to create nginx configuration file"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Nginx configuration generation failed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: Failed to write nginx configuration file"
        echo ""
        echo "Remediation:"
        echo "  1. Check disk space availability"
        echo "  2. Verify write permissions to /etc/nginx/sites-available/"
        echo "  3. Check the log file for details: $LOG_FILE"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Test nginx configuration syntax
    display_progress "Testing nginx configuration syntax..."
    log_operation "Running nginx -t to test configuration"
    
    if nginx -t >> "$LOG_FILE" 2>&1; then
        display_success "Nginx configuration syntax is valid"
        log_operation "Nginx configuration syntax test passed"
    else
        display_error "Nginx configuration syntax test failed"
        log_operation "ERROR: Nginx configuration syntax test failed"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Nginx configuration syntax error${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: The generated nginx configuration has syntax errors"
        echo ""
        echo "Remediation:"
        echo "  1. Check the log file for detailed error information: $LOG_FILE"
        echo "  2. Review the configuration file: $nginx_config"
        echo "  3. Run 'nginx -t' manually to see the specific error"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Enable site by creating symlink to sites-enabled
    display_progress "Enabling nginx site..."
    log_operation "Creating symlink to enable site"
    
    local sites_enabled="/etc/nginx/sites-enabled/ai-website-builder"
    
    # Remove existing symlink if it exists
    if [ -L "$sites_enabled" ]; then
        display_info "Removing existing site symlink"
        log_operation "Removing existing symlink at $sites_enabled"
        rm -f "$sites_enabled"
    fi
    
    # Create symlink
    if ln -s "$nginx_config" "$sites_enabled"; then
        display_success "Site enabled in nginx"
        log_operation "Symlink created: $sites_enabled -> $nginx_config"
    else
        display_error "Failed to enable site"
        log_operation "ERROR: Failed to create symlink to enable site"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Failed to enable nginx site${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: Failed to create symlink to enable site"
        echo ""
        echo "Remediation:"
        echo "  1. Check write permissions to /etc/nginx/sites-enabled/"
        echo "  2. Manually create symlink: ln -s $nginx_config $sites_enabled"
        echo "  3. Check the log file for details: $LOG_FILE"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Reload nginx configuration
    display_progress "Reloading nginx configuration..."
    log_operation "Reloading nginx service"
    
    if systemctl reload nginx >> "$LOG_FILE" 2>&1; then
        display_success "Nginx configuration reloaded"
        log_operation "Nginx service reloaded successfully"
    else
        # If reload fails, try restart
        display_warning "Nginx reload failed, attempting restart..."
        log_operation "WARNING: Nginx reload failed, attempting restart"
        
        if systemctl restart nginx >> "$LOG_FILE" 2>&1; then
            display_success "Nginx service restarted"
            log_operation "Nginx service restarted successfully"
        else
            display_error "Failed to reload/restart nginx"
            log_operation "ERROR: Failed to reload or restart nginx service"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: Nginx reload/restart failed${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: Failed to reload or restart nginx service"
            echo ""
            echo "Remediation:"
            echo "  1. Check nginx service status: systemctl status nginx"
            echo "  2. Check nginx error logs: tail -n 50 /var/log/nginx/error.log"
            echo "  3. Verify configuration syntax: nginx -t"
            echo "  4. Check the log file for details: $LOG_FILE"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
    fi
    
    # Verify nginx is running
    if systemctl is-active --quiet nginx; then
        display_success "Nginx web server configured and running"
        log_operation "Nginx configuration completed successfully - service is active"
    else
        display_warning "Nginx configuration completed but service status unclear"
        log_operation "WARNING: Nginx configured but service status unclear"
    fi
}

# Set up SSL/TLS certificates
setup_ssl_certificates() {
    display_progress "Acquiring SSL certificates with Let's Encrypt..."
    log_operation "FUNCTION: setup_ssl_certificates called"
    
    # Verify certbot is installed
    if ! command -v certbot >/dev/null 2>&1; then
        display_error "certbot is not installed"
        log_operation "ERROR: certbot command not found"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: SSL certificate acquisition failed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: certbot is not installed"
        echo ""
        echo "Remediation:"
        echo "  1. Install certbot: apt install certbot"
        echo "  2. Re-run this script"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Check if certificates already exist
    if [ -d "/etc/letsencrypt/live/$DOMAIN_NAME" ]; then
        display_info "SSL certificates already exist for $DOMAIN_NAME"
        log_operation "SSL certificates already exist at /etc/letsencrypt/live/$DOMAIN_NAME"
        
        # Check certificate expiry
        local cert_file="/etc/letsencrypt/live/$DOMAIN_NAME/cert.pem"
        if [ -f "$cert_file" ]; then
            local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
            if [ -n "$expiry_date" ]; then
                display_info "Certificate expires: $expiry_date"
                log_operation "Existing certificate expires: $expiry_date"
            fi
        fi
        
        display_success "Using existing SSL certificates"
        log_operation "Skipping certificate acquisition - using existing certificates"
        return 0
    fi
    
    # Validate DNS configuration before attempting certificate acquisition
    display_progress "Validating DNS configuration for $DOMAIN_NAME..."
    log_operation "Checking if $DOMAIN_NAME resolves to this server's IP"
    
    # Get server's public IP address
    local server_ip=""
    
    # Try multiple methods to get public IP
    if command -v curl >/dev/null 2>&1; then
        server_ip=$(curl -s -4 https://ifconfig.me 2>/dev/null || curl -s -4 https://icanhazip.com 2>/dev/null || curl -s -4 https://api.ipify.org 2>/dev/null)
    elif command -v wget >/dev/null 2>&1; then
        server_ip=$(wget -qO- -4 https://ifconfig.me 2>/dev/null || wget -qO- -4 https://icanhazip.com 2>/dev/null)
    fi
    
    if [ -z "$server_ip" ]; then
        display_warning "Could not determine server's public IP address"
        log_operation "WARNING: Unable to determine server public IP for DNS validation"
    else
        display_info "Server public IP: $server_ip"
        log_operation "Server public IP detected: $server_ip"
    fi
    
    # Check DNS resolution
    local domain_ip=""
    if command -v dig >/dev/null 2>&1; then
        domain_ip=$(dig +short "$DOMAIN_NAME" A | head -n 1)
    elif command -v nslookup >/dev/null 2>&1; then
        domain_ip=$(nslookup "$DOMAIN_NAME" 2>/dev/null | grep -A1 "Name:" | tail -n1 | awk '{print $2}')
    elif command -v host >/dev/null 2>&1; then
        domain_ip=$(host "$DOMAIN_NAME" 2>/dev/null | grep "has address" | head -n1 | awk '{print $4}')
    fi
    
    if [ -z "$domain_ip" ]; then
        display_warning "DNS validation: $DOMAIN_NAME does not resolve to any IP address"
        log_operation "DNS validation failed: Domain does not resolve"
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${YELLOW}⚠ DNS Configuration Required${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Your domain $DOMAIN_NAME is not yet configured in DNS."
        echo ""
        echo "SSL certificate acquisition requires that your domain points to this server."
        echo ""
        if [ -n "$server_ip" ]; then
            echo "To configure DNS:"
            echo "  1. Log in to your domain registrar or DNS provider"
            echo "  2. Create an A record for $DOMAIN_NAME"
            echo "  3. Point it to this server's IP address: $server_ip"
            echo "  4. Wait for DNS propagation (can take 5 minutes to 48 hours)"
            echo ""
            echo "You can check DNS propagation with:"
            echo "  dig +short $DOMAIN_NAME"
            echo "  (should return: $server_ip)"
        else
            echo "To configure DNS:"
            echo "  1. Determine this server's public IP address"
            echo "  2. Log in to your domain registrar or DNS provider"
            echo "  3. Create an A record for $DOMAIN_NAME pointing to the server IP"
            echo "  4. Wait for DNS propagation (can take 5 minutes to 48 hours)"
        fi
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        display_info "Skipping SSL certificate acquisition for now"
        display_info "The application will be accessible via HTTP only"
        log_operation "Skipping SSL certificate acquisition - DNS not configured"
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${BLUE}ℹ After DNS Configuration${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Once your DNS is configured and propagated, run this command"
        echo "to acquire SSL certificates and enable HTTPS:"
        echo ""
        echo "  sudo DOMAIN=$DOMAIN_NAME SSL_EMAIL=$TAILSCALE_EMAIL $SCRIPT_DIR/configure-ssl.sh"
        echo ""
        echo "Or manually run:"
        echo "  sudo certbot certonly --nginx -d $DOMAIN_NAME --email $TAILSCALE_EMAIL --agree-tos --non-interactive"
        echo "  # Then update nginx config to add HTTPS block and reload"
        echo ""
        echo "Or re-run the deployment script - it will detect existing installation"
        echo "and only attempt SSL certificate acquisition:"
        echo ""
        echo "  sudo $SCRIPT_DIR/deploy.sh"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        return 0
    fi
    
    # Check if domain resolves to this server
    if [ -n "$server_ip" ] && [ "$domain_ip" != "$server_ip" ]; then
        display_warning "DNS validation: $DOMAIN_NAME resolves to $domain_ip (expected: $server_ip)"
        log_operation "DNS validation warning: Domain resolves to $domain_ip but server IP is $server_ip"
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${YELLOW}⚠ DNS Configuration Mismatch${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Your domain $DOMAIN_NAME is configured in DNS, but it points"
        echo "to a different IP address than this server."
        echo ""
        echo "Current DNS configuration:"
        echo "  Domain: $DOMAIN_NAME"
        echo "  Resolves to: $domain_ip"
        echo ""
        echo "This server's IP:"
        echo "  Server IP: $server_ip"
        echo ""
        echo "SSL certificate acquisition will likely fail because Let's Encrypt"
        echo "will try to validate the domain at $domain_ip instead of this server."
        echo ""
        echo "To fix this:"
        echo "  1. Log in to your domain registrar or DNS provider"
        echo "  2. Update the A record for $DOMAIN_NAME"
        echo "  3. Change it to point to: $server_ip"
        echo "  4. Wait for DNS propagation (can take 5 minutes to 48 hours)"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Ask user if they want to proceed anyway
        while true; do
            echo -n "Do you want to attempt SSL certificate acquisition anyway? (yes/no): "
            read -r response
            
            case "$response" in
                [Yy]|[Yy][Ee][Ss])
                    display_info "Proceeding with SSL certificate acquisition despite DNS mismatch"
                    log_operation "User chose to proceed with SSL acquisition despite DNS mismatch"
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    display_info "Skipping SSL certificate acquisition"
                    log_operation "User chose to skip SSL acquisition due to DNS mismatch"
                    
                    echo ""
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo -e "${BLUE}ℹ After DNS Configuration${NC}"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo ""
                    echo "Once your DNS is updated and propagated, run this command"
                    echo "to acquire SSL certificates and enable HTTPS:"
                    echo ""
                    echo "  sudo DOMAIN=$DOMAIN_NAME SSL_EMAIL=$TAILSCALE_EMAIL $SCRIPT_DIR/configure-ssl.sh"
                    echo ""
                    echo "Or manually run:"
                    echo "  sudo certbot certonly --nginx -d $DOMAIN_NAME --email $TAILSCALE_EMAIL --agree-tos --non-interactive"
                    echo "  # Then update nginx config to add HTTPS block and reload"
                    echo ""
                    echo "Or re-run the deployment script - it will detect existing installation"
                    echo "and only attempt SSL certificate acquisition:"
                    echo ""
                    echo "  sudo $SCRIPT_DIR/deploy.sh"
                    echo ""
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo ""
                    
                    return 0
                    ;;
                *)
                    echo "Please answer 'yes' or 'no'"
                    ;;
            esac
        done
    else
        display_success "DNS validation: $DOMAIN_NAME resolves to $domain_ip"
        log_operation "DNS validation passed: Domain resolves to correct IP"
    fi
    
    # Verify nginx is running (required for certbot nginx plugin)
    if ! systemctl is-active --quiet nginx; then
        display_warning "Nginx is not running, attempting to start..."
        log_operation "WARNING: Nginx not running, attempting to start"
        
        if systemctl start nginx >> "$LOG_FILE" 2>&1; then
            display_success "Nginx started"
            log_operation "Nginx started successfully"
        else
            display_error "Failed to start nginx"
            log_operation "ERROR: Failed to start nginx for certificate acquisition"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: SSL certificate acquisition failed${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: Nginx must be running for certificate acquisition"
            echo ""
            echo "Remediation:"
            echo "  1. Check nginx service status: systemctl status nginx"
            echo "  2. Check nginx error logs: tail -n 50 /var/log/nginx/error.log"
            echo "  3. Verify nginx configuration: nginx -t"
            echo "  4. Check the log file for details: $LOG_FILE"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
    fi
    
    # Run certbot to acquire certificates
    display_progress "Running certbot to acquire SSL certificate for $DOMAIN_NAME..."
    display_info "This may take a minute or two..."
    log_operation "Running certbot for domain: $DOMAIN_NAME, email: $TAILSCALE_EMAIL"
    
    # Use certbot with nginx plugin in non-interactive mode
    if certbot certonly \
        --nginx \
        --non-interactive \
        --agree-tos \
        --email "$TAILSCALE_EMAIL" \
        -d "$DOMAIN_NAME" \
        >> "$LOG_FILE" 2>&1; then
        
        display_success "SSL certificate acquired successfully for $DOMAIN_NAME"
        log_operation "SSL certificate acquired successfully"
        
        # Verify certificate files exist
        if [ -f "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" ] && \
           [ -f "/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem" ]; then
            display_success "Certificate files verified"
            log_operation "Certificate files verified at /etc/letsencrypt/live/$DOMAIN_NAME/"
            
            # Display certificate expiry information
            local cert_file="/etc/letsencrypt/live/$DOMAIN_NAME/cert.pem"
            if [ -f "$cert_file" ]; then
                local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
                if [ -n "$expiry_date" ]; then
                    display_info "Certificate expires: $expiry_date"
                    log_operation "Certificate expires: $expiry_date"
                fi
            fi
        else
            display_warning "Certificate files not found at expected location"
            log_operation "WARNING: Certificate files not found at /etc/letsencrypt/live/$DOMAIN_NAME/"
        fi
        
    else
        display_error "Failed to acquire SSL certificate"
        log_operation "ERROR: certbot failed to acquire SSL certificate"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: SSL certificate acquisition failed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: certbot failed to acquire SSL certificate for $DOMAIN_NAME"
        echo ""
        echo "Troubleshooting guidance:"
        echo ""
        echo "  1. Verify DNS configuration:"
        echo "     • Ensure $DOMAIN_NAME points to this server's public IP address"
        echo "     • Check DNS propagation: dig +short $DOMAIN_NAME"
        echo "     • DNS changes can take up to 48 hours to propagate"
        echo ""
        echo "  2. Verify domain accessibility:"
        echo "     • Ensure port 80 is open and accessible from the internet"
        echo "     • Check firewall rules: ufw status"
        echo "     • Verify nginx is serving on port 80: curl -I http://$DOMAIN_NAME"
        echo ""
        echo "  3. Check Let's Encrypt rate limits:"
        echo "     • Let's Encrypt has rate limits (50 certificates per domain per week)"
        echo "     • Check if you've hit rate limits: https://crt.sh/?q=$DOMAIN_NAME"
        echo "     • Consider using staging environment for testing"
        echo ""
        echo "  4. Review detailed error logs:"
        echo "     • Deployment log: $LOG_FILE"
        echo "     • Certbot logs: /var/log/letsencrypt/letsencrypt.log"
        echo "     • Nginx error log: /var/log/nginx/error.log"
        echo ""
        echo "  5. Common issues and solutions:"
        echo "     • Domain not pointing to server: Update DNS A record"
        echo "     • Port 80 blocked: Check cloud provider security groups/firewall"
        echo "     • Nginx misconfiguration: Verify nginx -t passes"
        echo "     • ACME challenge directory missing: Ensure /var/www/certbot exists"
        echo ""
        echo "  6. Manual certificate acquisition:"
        echo "     • Try running certbot manually to see detailed errors:"
        echo "       certbot certonly --nginx -d $DOMAIN_NAME"
        echo ""
        echo "  7. Alternative approaches:"
        echo "     • Use certbot standalone mode (requires stopping nginx temporarily):"
        echo "       systemctl stop nginx"
        echo "       certbot certonly --standalone -d $DOMAIN_NAME"
        echo "       systemctl start nginx"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Update nginx configuration to add HTTPS block with SSL certificates
    display_progress "Updating nginx configuration to enable HTTPS..."
    log_operation "Adding HTTPS configuration block to nginx"
    
    local nginx_config="/etc/nginx/sites-available/ai-website-builder"
    
    # Create updated configuration with both HTTP and HTTPS blocks
    cat > "$nginx_config" << EOF
# AI Website Builder - Nginx Configuration
# Generated: $(date -Iseconds)
# Domain: $DOMAIN_NAME
# SSL Certificates: Enabled

# HTTP Server Block - Handles ACME challenges and redirects to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME;
    
    # ACME challenge location for Let's Encrypt certificate acquisition
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri =404;
    }
    
    # Redirect all other HTTP traffic to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS Server Block - Proxies to AI Website Builder application
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN_NAME;
    
    # SSL certificate paths
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    
    # SSL configuration for security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    
    # Proxy to AI Website Builder application on localhost:3000
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        
        # Proxy headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support (if needed)
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Logging
    access_log /var/log/nginx/ai-website-builder-access.log;
    error_log /var/log/nginx/ai-website-builder-error.log;
}
EOF
    
    if [ $? -eq 0 ]; then
        display_success "Nginx configuration updated with HTTPS support"
        log_operation "Nginx configuration updated successfully"
    else
        display_error "Failed to update nginx configuration"
        log_operation "ERROR: Failed to update nginx configuration with HTTPS"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Nginx configuration update failed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: Failed to write updated nginx configuration"
        echo ""
        echo "Remediation:"
        echo "  1. Check write permissions to /etc/nginx/sites-available/"
        echo "  2. Manually update the configuration file: $nginx_config"
        echo "  3. Check the log file for details: $LOG_FILE"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Test nginx configuration syntax
    display_progress "Testing updated nginx configuration..."
    log_operation "Running nginx -t to test updated configuration"
    
    if nginx -t >> "$LOG_FILE" 2>&1; then
        display_success "Nginx configuration syntax is valid"
        log_operation "Nginx configuration syntax test passed"
    else
        display_error "Nginx configuration syntax test failed"
        log_operation "ERROR: Nginx configuration syntax test failed after HTTPS update"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Nginx configuration syntax error${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: The updated nginx configuration has syntax errors"
        echo ""
        echo "Remediation:"
        echo "  1. Check the log file for detailed error information: $LOG_FILE"
        echo "  2. Review the configuration file: $nginx_config"
        echo "  3. Run 'nginx -t' manually to see the specific error"
        echo "  4. Verify SSL certificate paths exist:"
        echo "     ls -la /etc/letsencrypt/live/$DOMAIN_NAME/"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Reload nginx to use the new certificates
    display_progress "Reloading nginx to use new SSL certificates..."
    log_operation "Reloading nginx to apply SSL certificates"
    
    if systemctl reload nginx >> "$LOG_FILE" 2>&1; then
        display_success "Nginx reloaded with SSL certificates"
        log_operation "Nginx reloaded successfully with SSL certificates"
    else
        display_warning "Failed to reload nginx (certificates may still work)"
        log_operation "WARNING: Failed to reload nginx after certificate acquisition"
        
        # Try restart as fallback
        if systemctl restart nginx >> "$LOG_FILE" 2>&1; then
            display_success "Nginx restarted with SSL certificates"
            log_operation "Nginx restarted successfully with SSL certificates"
        else
            display_error "Failed to reload/restart nginx"
            log_operation "ERROR: Failed to reload/restart nginx after certificate acquisition"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: Nginx reload failed after certificate acquisition${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Details: SSL certificates were acquired but nginx failed to reload"
            echo ""
            echo "Remediation:"
            echo "  1. Check nginx configuration: nginx -t"
            echo "  2. Verify certificate paths in nginx config match acquired certificates"
            echo "  3. Check nginx error logs: tail -n 50 /var/log/nginx/error.log"
            echo "  4. Try restarting nginx manually: systemctl restart nginx"
            echo "  5. Check the log file for details: $LOG_FILE"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            exit 1
        fi
    fi
    
    display_success "SSL certificates configured successfully"
    log_operation "SSL certificate setup completed successfully"
}

# Wait for authentication completion with timeout
wait_for_auth_completion() {
    local timeout_seconds="${1:-300}"  # Default 5 minutes (300 seconds)
    local poll_interval=5  # Check every 5 seconds
    local elapsed=0
    
    log_operation "FUNCTION: wait_for_auth_completion called with timeout=${timeout_seconds}s"
    
    display_progress "Waiting for authentication to complete (timeout: ${timeout_seconds}s)..."
    
    while [ $elapsed -lt $timeout_seconds ]; do
        # Check Tailscale status to see if authenticated
        if tailscale status >/dev/null 2>&1; then
            # Check if we have a valid connection (not just running)
            local status_output=$(tailscale status 2>&1)
            
            # If status shows we're connected (has IP addresses or peers), authentication succeeded
            if echo "$status_output" | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"; then
                display_success "Authentication completed successfully!"
                log_operation "Authentication completed - Tailscale status shows active connection"
                return 0
            fi
        fi
        
        # Display progress indicator
        local remaining=$((timeout_seconds - elapsed))
        echo -ne "\r${BLUE}▶${NC} Waiting for authentication... (${remaining}s remaining)  "
        
        # Wait for poll interval
        sleep $poll_interval
        elapsed=$((elapsed + poll_interval))
    done
    
    # Timeout reached
    echo ""  # New line after progress indicator
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${YELLOW}⚠ Authentication Timeout${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "The authentication process did not complete within ${timeout_seconds} seconds."
    echo ""
    echo "This could mean:"
    echo "  • You haven't completed the authentication in your browser yet"
    echo "  • The authentication completed but Tailscale hasn't connected yet"
    echo "  • There was a network issue preventing connection"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_operation "WARNING: Authentication timeout reached after ${timeout_seconds}s"
    
    # Offer retry or manual continuation options
    while true; do
        echo "What would you like to do?"
        echo "  1) Retry - Wait another ${timeout_seconds} seconds for authentication"
        echo "  2) Continue - I completed authentication, continue deployment"
        echo "  3) Abort - Exit deployment"
        echo ""
        echo -n "Enter your choice (1/2/3): "
        read -r choice
        
        log_operation "User timeout choice: $choice"
        
        case "$choice" in
            1)
                display_info "Retrying authentication check..."
                log_operation "User chose to retry authentication wait"
                # Recursive call to retry
                wait_for_auth_completion "$timeout_seconds"
                return $?
                ;;
            2)
                display_info "Continuing with deployment..."
                log_operation "User confirmed authentication completed manually"
                
                # Verify authentication actually completed
                if tailscale status >/dev/null 2>&1; then
                    local status_output=$(tailscale status 2>&1)
                    if echo "$status_output" | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"; then
                        display_success "Authentication verified - continuing deployment"
                        log_operation "Manual continuation verified - Tailscale is connected"
                        return 0
                    else
                        display_warning "Tailscale status unclear, but continuing as requested"
                        log_operation "WARNING: Manual continuation but Tailscale status unclear"
                        return 0
                    fi
                else
                    display_warning "Cannot verify Tailscale status, but continuing as requested"
                    log_operation "WARNING: Manual continuation but cannot verify Tailscale status"
                    return 0
                fi
                ;;
            3)
                display_info "Deployment aborted by user"
                log_operation "User chose to abort deployment due to authentication timeout"
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo -e "${YELLOW}Deployment Aborted${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "You can re-run this script later to complete the deployment."
                echo "The script will resume from where it left off."
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, or 3."
                ;;
        esac
    done
}

# Handle browser-based authentication flows
handle_browser_authentication() {
    local auth_url="$1"
    
    log_operation "FUNCTION: handle_browser_authentication called"
    
    # If no URL provided, this is a placeholder call
    if [ -z "$auth_url" ]; then
        display_info "Browser authentication will be required during Tailscale setup"
        log_operation "Browser authentication placeholder - no URL provided yet"
        return 0
    fi
    
    # Display authentication URL with clear formatting
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${YELLOW}🔐 Browser Authentication Required${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "To complete the authentication process, please open this URL"
    echo "in your web browser:"
    echo ""
    echo -e "${BLUE}${auth_url}${NC}"
    echo ""
    echo "Instructions:"
    echo "  1. Copy the URL above"
    echo "  2. Open it in your web browser"
    echo "  3. Complete the authentication process"
    echo "  4. Return to this terminal once authentication is complete"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_operation "Displayed browser authentication URL (masked in log)"
    log_operation "Waiting for user to complete browser authentication"
    
    # Wait for authentication to complete with 5-minute timeout
    wait_for_auth_completion 300
}

# Generate QR codes for end user access
generate_qr_codes() {
    display_progress "Generating QR codes for end user access..."
    log_operation "FUNCTION: generate_qr_codes called"
    
    # Create QR code directory if it doesn't exist
    if [ ! -d "$QR_CODE_DIR" ]; then
        mkdir -p "$QR_CODE_DIR"
        chmod 700 "$QR_CODE_DIR"
        chown root:root "$QR_CODE_DIR"
        display_success "Created QR code directory: $QR_CODE_DIR"
        log_operation "Created QR code directory with 700 permissions: $QR_CODE_DIR"
    fi
    
    # Create web-accessible directory for QR codes
    local web_qr_dir="/var/www/html/qr-codes"
    if [ ! -d "$web_qr_dir" ]; then
        mkdir -p "$web_qr_dir"
        chmod 755 "$web_qr_dir"
        chown www-data:www-data "$web_qr_dir"
        display_success "Created web-accessible QR code directory: $web_qr_dir"
        log_operation "Created web-accessible QR code directory: $web_qr_dir"
    fi
    
    # Determine base URL for QR code access
    local base_url=""
    local protocol="http"
    
    # Check if SSL certificates exist
    if [ -d "/etc/letsencrypt/live/$DOMAIN_NAME" ] && \
       [ -f "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" ]; then
        protocol="https"
        base_url="${protocol}://${DOMAIN_NAME}"
        display_info "Using HTTPS URL for QR codes: $base_url"
        log_operation "SSL certificates found - using HTTPS URL: $base_url"
    else
        # No SSL, determine if we should use domain or IP
        # Try to get server's public IP
        local server_ip=""
        if command -v curl >/dev/null 2>&1; then
            server_ip=$(curl -s -4 --max-time 5 https://ifconfig.me 2>/dev/null || curl -s -4 --max-time 5 https://icanhazip.com 2>/dev/null)
        fi
        
        # Check if domain resolves to this server
        local domain_ip=""
        if command -v dig >/dev/null 2>&1; then
            domain_ip=$(dig +short "$DOMAIN_NAME" A | head -n 1)
        fi
        
        # Use domain if it resolves to this server, otherwise use IP
        if [ -n "$domain_ip" ] && [ "$domain_ip" = "$server_ip" ]; then
            base_url="${protocol}://${DOMAIN_NAME}"
            display_info "Using HTTP domain URL for QR codes: $base_url"
            log_operation "Domain resolves correctly - using HTTP domain URL: $base_url"
        elif [ -n "$server_ip" ]; then
            base_url="${protocol}://${server_ip}"
            display_info "Using HTTP IP URL for QR codes: $base_url"
            log_operation "Using server IP for QR codes: $base_url"
        else
            # Fallback to domain name
            base_url="${protocol}://${DOMAIN_NAME}"
            display_warning "Could not determine server IP, using domain name"
            log_operation "WARNING: Could not determine server IP, using domain name: $base_url"
        fi
    fi
    
    # Tailscale app store link (universal link that works for both iOS and Android)
    local tailscale_app_url="https://tailscale.com/download"
    local tailscale_qr_png="$QR_CODE_DIR/tailscale-app.png"
    local tailscale_qr_web="$web_qr_dir/tailscale-app.png"
    local tailscale_qr_ascii="$QR_CODE_DIR/tailscale-app.txt"
    
    display_progress "Generating QR code for Tailscale app store..."
    log_operation "Generating QR code for Tailscale app store: $tailscale_app_url"
    
    # Generate PNG QR code
    if qrencode -o "$tailscale_qr_png" -s 10 -m 2 "$tailscale_app_url" 2>> "$LOG_FILE"; then
        chmod 644 "$tailscale_qr_png"
        
        # Copy to web directory
        cp "$tailscale_qr_png" "$tailscale_qr_web"
        chmod 644 "$tailscale_qr_web"
        chown www-data:www-data "$tailscale_qr_web"
        
        local tailscale_qr_url="${base_url}/qr-codes/tailscale-app.png"
        display_success "Tailscale app QR code: $tailscale_qr_url"
        log_operation "Tailscale app QR code PNG generated and published: $tailscale_qr_url"
    else
        display_error "Failed to generate Tailscale app QR code PNG"
        log_operation "ERROR: Failed to generate Tailscale app QR code PNG"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: QR code generation failed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: Failed to generate QR code for Tailscale app store"
        echo ""
        echo "Remediation:"
        echo "  1. Verify qrencode is installed: apt install qrencode"
        echo "  2. Check the log file for details: $LOG_FILE"
        echo "  3. Ensure the QR code directory is writable: $QR_CODE_DIR"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        return 1
    fi
    
    # Generate ASCII art QR code for terminal display
    if qrencode -t ANSI256 -o "$tailscale_qr_ascii" "$tailscale_app_url" 2>> "$LOG_FILE"; then
        chmod 644 "$tailscale_qr_ascii"
        display_success "Tailscale app QR code ASCII art saved to: $tailscale_qr_ascii"
        log_operation "Tailscale app QR code ASCII art generated: $tailscale_qr_ascii"
    else
        display_warning "Failed to generate ASCII art QR code (non-critical)"
        log_operation "WARNING: Failed to generate Tailscale app QR code ASCII art"
    fi
    
    # Service access URL QR code
    display_progress "Generating QR code for service access URL..."
    log_operation "Generating QR code for service access URL"
    
    # Use the same base URL we determined earlier
    local service_access_url="$base_url"
    local service_qr_png="$QR_CODE_DIR/service-access.png"
    local service_qr_web="$web_qr_dir/service-access.png"
    local service_qr_ascii="$QR_CODE_DIR/service-access.txt"
    
    log_operation "Service access URL: $service_access_url"
    
    # Generate PNG QR code for service access
    if qrencode -o "$service_qr_png" -s 10 -m 2 "$service_access_url" 2>> "$LOG_FILE"; then
        chmod 644 "$service_qr_png"
        
        # Copy to web directory
        cp "$service_qr_png" "$service_qr_web"
        chmod 644 "$service_qr_web"
        chown www-data:www-data "$service_qr_web"
        
        local service_qr_url="${base_url}/qr-codes/service-access.png"
        display_success "Service access QR code: $service_qr_url"
        log_operation "Service access QR code PNG generated and published: $service_qr_url"
    else
        display_error "Failed to generate service access QR code PNG"
        log_operation "ERROR: Failed to generate service access QR code PNG"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Service access QR code generation failed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: Failed to generate QR code for service access URL"
        echo ""
        echo "Remediation:"
        echo "  1. Verify qrencode is installed: apt install qrencode"
        echo "  2. Check the log file for details: $LOG_FILE"
        echo "  3. Ensure the QR code directory is writable: $QR_CODE_DIR"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        return 1
    fi
    
    # Generate ASCII art QR code for service access
    if qrencode -t ANSI256 -o "$service_qr_ascii" "$service_access_url" 2>> "$LOG_FILE"; then
        chmod 644 "$service_qr_ascii"
        display_success "Service access QR code ASCII art saved to: $service_qr_ascii"
        log_operation "Service access QR code ASCII art generated: $service_qr_ascii"
    else
        display_warning "Failed to generate service access ASCII art QR code (non-critical)"
        log_operation "WARNING: Failed to generate service access QR code ASCII art"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}QR Codes Available${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Tailscale App Download:"
    echo "  ${base_url}/qr-codes/tailscale-app.png"
    echo ""
    echo "Service Access:"
    echo "  ${base_url}/qr-codes/service-access.png"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    display_success "QR code generation completed"
    log_operation "QR code generation completed successfully"
}

# Display QR codes in terminal with formatted borders
display_qr_codes_terminal() {
    display_progress "Displaying QR codes..."
    log_operation "FUNCTION: display_qr_codes_terminal called"
    
    local tailscale_qr_ascii="$QR_CODE_DIR/tailscale-app.txt"
    local service_qr_ascii="$QR_CODE_DIR/service-access.txt"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}QR Codes for End User Access${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Display Tailscale app QR code
    if [ -f "$tailscale_qr_ascii" ]; then
        echo "┌─────────────────────────────────────────────────┐"
        echo "│  📱 Scan to Install Tailscale App              │"
        echo "│                                                 │"
        
        # Read and display the ASCII art QR code with proper indentation
        while IFS= read -r line; do
            echo "│  $line"
        done < "$tailscale_qr_ascii"
        
        echo "│                                                 │"
        echo "│  URL: https://tailscale.com/download           │"
        echo "└─────────────────────────────────────────────────┘"
        echo ""
        
        log_operation "Displayed Tailscale app QR code in terminal"
    else
        display_warning "Tailscale app QR code ASCII art not found: $tailscale_qr_ascii"
        log_operation "WARNING: Tailscale app QR code ASCII art file not found"
    fi
    
    # Display service access QR code
    if [ -f "$service_qr_ascii" ]; then
        echo "┌─────────────────────────────────────────────────┐"
        echo "│  🌐 Scan to Access AI Website Builder          │"
        echo "│                                                 │"
        
        # Read and display the ASCII art QR code with proper indentation
        while IFS= read -r line; do
            echo "│  $line"
        done < "$service_qr_ascii"
        
        echo "│                                                 │"
        
        # Get the service URL for display
        local service_url=""
        if [ -f "$CONFIG_FILE" ]; then
            source "$CONFIG_FILE"
            
            # Try to get Tailscale hostname
            if command -v tailscale >/dev/null 2>&1; then
                local tailscale_hostname=$(tailscale status --json 2>/dev/null | grep -o '"HostName":"[^"]*"' | cut -d'"' -f4 | head -n1)
                
                if [ -z "$tailscale_hostname" ]; then
                    tailscale_hostname=$(tailscale status 2>/dev/null | head -n1 | awk '{print $2}')
                fi
                
                if [ -z "$tailscale_hostname" ]; then
                    tailscale_hostname="$DOMAIN_NAME"
                fi
            else
                tailscale_hostname="$DOMAIN_NAME"
            fi
            
            service_url="https://${tailscale_hostname}"
        fi
        
        if [ -n "$service_url" ]; then
            echo "│  URL: $service_url"
        fi
        
        echo "└─────────────────────────────────────────────────┘"
        echo ""
        
        log_operation "Displayed service access QR code in terminal"
    else
        display_warning "Service access QR code ASCII art not found: $service_qr_ascii"
        log_operation "WARNING: Service access QR code ASCII art file not found"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "QR code images saved to: $QR_CODE_DIR"
    echo "  • tailscale-app.png - For installing Tailscale"
    echo "  • service-access.png - For accessing the AI website builder"
    echo ""
    
    log_operation "QR code display completed"
}

# Configure systemd service
configure_systemd_service() {
    display_progress "Configuring systemd service..."
    log_operation "FUNCTION: configure_systemd_service called"
    
    local service_file="/etc/systemd/system/ai-website-builder.service"
    
    # Create systemd service file
    display_progress "Creating systemd service file..."
    log_operation "Creating systemd service file at $service_file"
    
    cat > "$service_file" << EOF
[Unit]
Description=AI Website Builder Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$REPOSITORY_PATH
EnvironmentFile=$CONFIG_FILE
ExecStart=/usr/bin/node $REPOSITORY_PATH/dist/server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ai-website-builder

[Install]
WantedBy=multi-user.target
EOF
    
    if [ $? -eq 0 ]; then
        display_success "Systemd service file created"
        log_operation "Systemd service file created successfully"
    else
        display_error "Failed to create systemd service file"
        log_operation "ERROR: Failed to create systemd service file"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Systemd service file creation failed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: Failed to write systemd service file"
        echo ""
        echo "Remediation:"
        echo "  1. Check write permissions to /etc/systemd/system/"
        echo "  2. Verify you're running as root"
        echo "  3. Check the log file for details: $LOG_FILE"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Set proper permissions
    chmod 644 "$service_file"
    chown root:root "$service_file"
    log_operation "Set service file permissions to 644 and ownership to root:root"
    
    # Reload systemd daemon
    display_progress "Reloading systemd daemon..."
    log_operation "Running systemctl daemon-reload"
    
    if systemctl daemon-reload >> "$LOG_FILE" 2>&1; then
        display_success "Systemd daemon reloaded"
        log_operation "Systemd daemon reloaded successfully"
    else
        display_error "Failed to reload systemd daemon"
        log_operation "ERROR: Failed to reload systemd daemon"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Systemd daemon reload failed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: systemctl daemon-reload command failed"
        echo ""
        echo "Remediation:"
        echo "  1. Check the log file for details: $LOG_FILE"
        echo "  2. Verify the service file exists: ls -l /etc/systemd/system/ai-website-builder.service"
        echo "  3. Check service file syntax: systemd-analyze verify ai-website-builder.service"
        echo "  4. View systemd errors: journalctl -xe"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Enable service to start on boot
    display_progress "Enabling ai-website-builder service..."
    log_operation "Running systemctl enable ai-website-builder"
    
    if systemctl enable ai-website-builder >> "$LOG_FILE" 2>&1; then
        display_success "Service enabled to start on boot"
        log_operation "Service enabled successfully"
    else
        display_warning "Failed to enable service (non-critical)"
        log_operation "WARNING: Failed to enable service"
    fi
    
    display_success "Systemd service configuration completed"
    log_operation "Systemd service configuration completed successfully"
}

# Start services
start_services() {
    display_progress "Starting services..."
    log_operation "FUNCTION: start_services called"
    
    # Reload systemd daemon to pick up new service file
    display_progress "Reloading systemd daemon..."
    log_operation "Running systemctl daemon-reload"
    
    if systemctl daemon-reload >> "$LOG_FILE" 2>&1; then
        display_success "Systemd daemon reloaded"
        log_operation "systemctl daemon-reload completed successfully"
    else
        display_error "Failed to reload systemd daemon"
        log_operation "ERROR: systemctl daemon-reload failed"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Failed to reload systemd daemon${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: systemctl daemon-reload command failed"
        echo ""
        echo "Remediation:"
        echo "  1. Check the log file for details: $LOG_FILE"
        echo "  2. Verify systemd is running: systemctl status"
        echo "  3. Check for systemd errors: journalctl -xe"
        echo "  4. Ensure you are running as root"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Enable ai-website-builder service for auto-start on boot
    display_progress "Enabling ai-website-builder service for auto-start..."
    log_operation "Running systemctl enable ai-website-builder"
    
    if systemctl enable ai-website-builder >> "$LOG_FILE" 2>&1; then
        display_success "Service enabled for auto-start on boot"
        log_operation "systemctl enable ai-website-builder completed successfully"
    else
        display_error "Failed to enable ai-website-builder service"
        log_operation "ERROR: systemctl enable ai-website-builder failed"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Failed to enable ai-website-builder service${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: systemctl enable command failed"
        echo ""
        echo "Remediation:"
        echo "  1. Check the log file for details: $LOG_FILE"
        echo "  2. Verify the service file exists: ls -l /etc/systemd/system/ai-website-builder.service"
        echo "  3. Check service file syntax: systemd-analyze verify ai-website-builder.service"
        echo "  4. View systemd errors: journalctl -xe"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    # Start ai-website-builder service
    display_progress "Starting ai-website-builder service..."
    log_operation "Running systemctl start ai-website-builder"
    
    if systemctl start ai-website-builder >> "$LOG_FILE" 2>&1; then
        display_success "Service started successfully"
        log_operation "systemctl start ai-website-builder completed successfully"
    else
        display_error "Failed to start ai-website-builder service"
        log_operation "ERROR: systemctl start ai-website-builder failed"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Failed to start ai-website-builder service${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: systemctl start command failed"
        echo ""
        echo "Service logs (last 20 lines):"
        journalctl -u ai-website-builder -n 20 --no-pager
        echo ""
        echo "Remediation:"
        echo "  1. Check the log file for details: $LOG_FILE"
        echo "  2. View full service logs: journalctl -u ai-website-builder -n 100"
        echo "  3. Check service status: systemctl status ai-website-builder"
        echo "  4. Verify configuration file exists: ls -l $CONFIG_FILE"
        echo "  5. Check application logs in the repository directory"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    echo ""
    display_success "All services started successfully"
    log_operation "start_services completed successfully"
}

# Restart services (update mode)
restart_services() {
    display_progress "Restarting services after configuration update..."
    log_operation "FUNCTION: restart_services called"
    
    # Verify we're in update mode
    if [ "$MODE" != "update" ]; then
        display_warning "restart_services called but not in update mode (MODE=$MODE)"
        log_operation "WARNING: restart_services called in $MODE mode, expected update mode"
        return 0
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Restarting Services${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    display_info "Applying configuration changes by restarting ai-website-builder service"
    log_operation "Restarting ai-website-builder service in update mode"
    
    # Restart ai-website-builder service
    display_progress "Restarting ai-website-builder service..."
    log_operation "Running systemctl restart ai-website-builder"
    
    if systemctl restart ai-website-builder >> "$LOG_FILE" 2>&1; then
        display_success "Service restarted successfully"
        log_operation "systemctl restart ai-website-builder completed successfully"
    else
        display_error "Failed to restart ai-website-builder service"
        log_operation "ERROR: systemctl restart ai-website-builder failed"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Failed to restart ai-website-builder service${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Details: systemctl restart command failed"
        echo ""
        echo "Service logs (last 20 lines):"
        journalctl -u ai-website-builder -n 20 --no-pager
        echo ""
        echo "Remediation:"
        echo "  1. Check the log file for details: $LOG_FILE"
        echo "  2. View full service logs: journalctl -u ai-website-builder -n 100"
        echo "  3. Check service status: systemctl status ai-website-builder"
        echo "  4. Verify configuration file is valid: cat $CONFIG_FILE"
        echo "  5. Try restarting manually: systemctl restart ai-website-builder"
        echo "  6. Check application logs in the repository directory"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
    
    echo ""
    display_success "Service restart completed successfully"
    log_operation "restart_services completed successfully"
}

# Verify service status
verify_service_status() {
    display_progress "Verifying service status..."
    log_operation "FUNCTION: verify_service_status called"
    
    local verification_passed=true
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Service Status Verification${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check 1: Verify service is active with systemctl
    display_progress "Checking service status with systemctl..."
    log_operation "Checking ai-website-builder service status"
    
    if systemctl is-active --quiet ai-website-builder; then
        display_success "Service is active"
        log_operation "Service status check: ai-website-builder is active"
    else
        display_error "Service is not active"
        log_operation "ERROR: Service status check: ai-website-builder is not active"
        verification_passed=false
    fi
    
    # Check 2: Verify process is running
    display_progress "Verifying process is running..."
    log_operation "Checking if ai-website-builder process is running"
    
    local service_pid=$(systemctl show -p MainPID --value ai-website-builder)
    
    if [ -n "$service_pid" ] && [ "$service_pid" != "0" ]; then
        if ps -p "$service_pid" > /dev/null 2>&1; then
            display_success "Process is running (PID: $service_pid)"
            log_operation "Process check: ai-website-builder process running with PID $service_pid"
        else
            display_error "Process not found (PID: $service_pid)"
            log_operation "ERROR: Process check: PID $service_pid not found"
            verification_passed=false
        fi
    else
        display_error "No process ID found for service"
        log_operation "ERROR: Process check: No valid PID for ai-website-builder"
        verification_passed=false
    fi
    
    # Check 3: Check service logs for errors
    display_progress "Checking service logs for errors..."
    log_operation "Checking ai-website-builder service logs for errors"
    
    # Get last 50 lines of service logs and check for error patterns
    local error_count=$(journalctl -u ai-website-builder -n 50 --no-pager | grep -iE "error|failed|fatal|exception" | wc -l)
    
    if [ "$error_count" -eq 0 ]; then
        display_success "No errors found in recent service logs"
        log_operation "Service logs check: No errors found in last 50 lines"
    else
        display_warning "Found $error_count error-like entries in recent service logs"
        log_operation "WARNING: Service logs check: Found $error_count error-like entries"
        # Don't fail verification for warnings in logs, but note them
    fi
    
    # Check 4: Test HTTP endpoint accessibility on localhost:3000
    display_progress "Testing HTTP endpoint accessibility on localhost:3000..."
    log_operation "Testing HTTP endpoint at http://localhost:3000"
    
    # Give the service a moment to fully start if it just started
    sleep 2
    
    if curl -f -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3000 > /dev/null 2>&1; then
        local http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3000)
        display_success "HTTP endpoint is accessible (HTTP $http_code)"
        log_operation "HTTP endpoint check: localhost:3000 returned HTTP $http_code"
    else
        local http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3000 2>&1 || echo "000")
        display_error "HTTP endpoint is not accessible (HTTP $http_code)"
        log_operation "ERROR: HTTP endpoint check: localhost:3000 failed with HTTP $http_code"
        verification_passed=false
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # If verification failed, display comprehensive error information
    if [ "$verification_passed" = false ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${RED}❌ ERROR: Service verification failed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "The ai-website-builder service failed one or more verification checks."
        echo ""
        echo "Service Status:"
        systemctl status ai-website-builder --no-pager -l || true
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Recent Service Logs (last 30 lines):"
        journalctl -u ai-website-builder -n 30 --no-pager || true
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Remediation:"
        echo "  1. Check the service logs above for specific error messages"
        echo "  2. Verify the application code is correct in $REPOSITORY_PATH"
        echo "  3. Check that all dependencies are installed correctly"
        echo "  4. Verify the configuration file at $CONFIG_FILE"
        echo "  5. Try restarting the service: systemctl restart ai-website-builder"
        echo "  6. Check the full deployment log: $LOG_FILE"
        echo ""
        echo "To view live service logs, run:"
        echo "  journalctl -u ai-website-builder -f"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        log_operation "ERROR: Service verification failed - displaying service logs and error information"
        exit 1
    else
        display_success "Service verification completed successfully"
        log_operation "Service verification: All checks passed"
    fi
    
    echo ""
}

# Verify domain accessibility
verify_domain_accessibility() {
    display_progress "Verifying domain accessibility..."
    log_operation "FUNCTION: verify_domain_accessibility called"
    
    local verification_passed=true
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Domain Verification: $DOMAIN_NAME${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check 1: DNS Resolution
    display_progress "Checking DNS resolution..."
    log_operation "Checking DNS resolution for $DOMAIN_NAME"
    
    if command -v dig >/dev/null 2>&1; then
        local dns_result=$(dig +short "$DOMAIN_NAME" A 2>&1)
        
        if [ -n "$dns_result" ]; then
            display_success "DNS resolution: PASSED"
            display_info "  Resolved to: $dns_result"
            log_operation "DNS resolution successful: $DOMAIN_NAME -> $dns_result"
        else
            display_error "DNS resolution: FAILED"
            display_error "  Domain $DOMAIN_NAME does not resolve to an IP address"
            log_operation "ERROR: DNS resolution failed for $DOMAIN_NAME"
            verification_passed=false
        fi
    else
        display_warning "DNS resolution: SKIPPED (dig command not available)"
        log_operation "WARNING: dig command not available - skipping DNS check"
    fi
    
    echo ""
    
    # Check 2: HTTP Accessibility
    display_progress "Checking HTTP accessibility..."
    log_operation "Checking HTTP accessibility for $DOMAIN_NAME"
    
    if command -v curl >/dev/null 2>&1; then
        # Use curl with timeout and follow redirects
        local http_response=$(curl -I -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 30 "http://$DOMAIN_NAME" 2>&1)
        
        # Check if we got a valid HTTP response (2xx, 3xx are acceptable)
        if [[ "$http_response" =~ ^[23][0-9][0-9]$ ]]; then
            display_success "HTTP accessibility: PASSED"
            display_info "  HTTP response code: $http_response"
            log_operation "HTTP accessibility successful: $DOMAIN_NAME returned $http_response"
        else
            display_error "HTTP accessibility: FAILED"
            display_error "  HTTP response code: $http_response"
            log_operation "ERROR: HTTP accessibility failed for $DOMAIN_NAME (response: $http_response)"
            verification_passed=false
        fi
    else
        display_warning "HTTP accessibility: SKIPPED (curl command not available)"
        log_operation "WARNING: curl command not available - skipping HTTP check"
    fi
    
    echo ""
    
    # Check 3: HTTPS Accessibility
    display_progress "Checking HTTPS accessibility..."
    log_operation "Checking HTTPS accessibility for $DOMAIN_NAME"
    
    if command -v curl >/dev/null 2>&1; then
        # Use curl with timeout and follow redirects
        local https_response=$(curl -I -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 30 "https://$DOMAIN_NAME" 2>&1)
        
        # Check if we got a valid HTTPS response (2xx, 3xx are acceptable)
        if [[ "$https_response" =~ ^[23][0-9][0-9]$ ]]; then
            display_success "HTTPS accessibility: PASSED"
            display_info "  HTTPS response code: $https_response"
            log_operation "HTTPS accessibility successful: $DOMAIN_NAME returned $https_response"
            
            # Check SSL certificate validity
            local cert_info=$(curl -vI "https://$DOMAIN_NAME" 2>&1 | grep -E "SSL certificate verify|subject:|issuer:")
            if [ -n "$cert_info" ]; then
                display_info "  SSL certificate is valid"
                log_operation "SSL certificate verification passed for $DOMAIN_NAME"
            fi
        else
            display_error "HTTPS accessibility: FAILED"
            display_error "  HTTPS response code: $https_response"
            log_operation "ERROR: HTTPS accessibility failed for $DOMAIN_NAME (response: $https_response)"
            verification_passed=false
        fi
    else
        display_warning "HTTPS accessibility: SKIPPED (curl command not available)"
        log_operation "WARNING: curl command not available - skipping HTTPS check"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Display final verification result
    if [ "$verification_passed" = true ]; then
        echo -e "${GREEN}✓ Domain verification: ALL CHECKS PASSED${NC}"
        log_operation "Domain verification completed successfully - all checks passed"
    else
        echo -e "${YELLOW}⚠ Domain verification: SOME CHECKS FAILED${NC}"
        echo ""
        echo "Some verification checks failed. This may indicate:"
        echo "  • DNS is not yet propagated (can take up to 48 hours)"
        echo "  • Firewall rules are blocking HTTP/HTTPS traffic"
        echo "  • Nginx is not properly configured or running"
        echo "  • SSL certificates are not properly installed"
        echo ""
        echo "The deployment has completed, but you may need to:"
        echo "  1. Wait for DNS propagation to complete"
        echo "  2. Verify firewall rules allow ports 80 and 443"
        echo "  3. Check nginx status: systemctl status nginx"
        echo "  4. Review nginx logs: tail -n 50 /var/log/nginx/error.log"
        echo ""
        log_operation "WARNING: Domain verification completed with failures"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Save installation state
save_installation_state() {
    display_progress "Saving installation state..."
    log_operation "FUNCTION: save_installation_state called"
    
    # Ensure config directory exists with secure permissions
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        chmod 700 "$CONFIG_DIR"
        chown root:root "$CONFIG_DIR"
        log_operation "Created configuration directory: $CONFIG_DIR"
    fi
    
    # Determine if this is a fresh install or update
    local current_timestamp=$(date -Iseconds)
    
    if [ "$MODE" = "update" ] && [ -f "$STATE_FILE" ]; then
        # Update mode: preserve INSTALL_DATE, update LAST_UPDATE
        display_progress "Updating installation state (update mode)..."
        log_operation "Updating installation state in update mode"
        
        # Load existing INSTALL_DATE if it exists
        local existing_install_date=""
        if grep -q "^INSTALL_DATE=" "$STATE_FILE"; then
            existing_install_date=$(grep "^INSTALL_DATE=" "$STATE_FILE" | cut -d'=' -f2)
            log_operation "Preserving existing INSTALL_DATE: $existing_install_date"
        else
            # Fallback if INSTALL_DATE is missing
            existing_install_date="$current_timestamp"
            log_operation "WARNING: INSTALL_DATE not found in existing state file, using current timestamp"
        fi
        
        # Write updated state file
        cat > "$STATE_FILE" << EOF
INSTALL_DATE=$existing_install_date
INSTALL_VERSION=$SCRIPT_VERSION
REPOSITORY_PATH=$REPOSITORY_PATH
LAST_UPDATE=$current_timestamp
EOF
        
        display_success "Installation state updated (LAST_UPDATE: $current_timestamp)"
        log_operation "Installation state updated with LAST_UPDATE: $current_timestamp"
        
    else
        # Fresh installation mode: create new state file
        display_progress "Creating installation state (fresh install)..."
        log_operation "Creating installation state in fresh install mode"
        
        # Write new state file
        cat > "$STATE_FILE" << EOF
INSTALL_DATE=$current_timestamp
INSTALL_VERSION=$SCRIPT_VERSION
REPOSITORY_PATH=$REPOSITORY_PATH
LAST_UPDATE=$current_timestamp
EOF
        
        display_success "Installation state created (INSTALL_DATE: $current_timestamp)"
        log_operation "Installation state created with INSTALL_DATE: $current_timestamp"
    fi
    
    # Set secure file permissions (600 = rw-------)
    chmod 600 "$STATE_FILE"
    chown root:root "$STATE_FILE"
    log_operation "Set state file permissions to 600 and ownership to root:root"
    
    # Verify permissions were set correctly
    local file_perms=$(stat -c "%a" "$STATE_FILE")
    local file_owner=$(stat -c "%U:%G" "$STATE_FILE")
    
    if [ "$file_perms" = "600" ] && [ "$file_owner" = "root:root" ]; then
        display_success "Installation state file security verified (600, root:root)"
        log_operation "State file security verified: permissions=$file_perms, owner=$file_owner"
    else
        display_warning "Installation state file permissions may not be secure: $file_perms, $file_owner"
        log_operation "WARNING: State file security check: permissions=$file_perms, owner=$file_owner"
    fi
    
    # Log the state file contents (for debugging)
    log_operation "State file contents:"
    while IFS= read -r line; do
        log_operation "  $line"
    done < "$STATE_FILE"
    
    display_success "Installation state saved to $STATE_FILE"
    log_operation "Installation state saved successfully"
}

# Update dependencies in update mode
update_dependencies() {
    display_progress "Updating system and runtime dependencies..."
    log_operation "FUNCTION: update_dependencies called (update mode)"
    
    # Update system packages (security updates)
    display_progress "Applying system security updates..."
    log_operation "Running apt update && apt upgrade"
    
    if apt update >> "$LOG_FILE" 2>&1; then
        display_success "Package lists updated"
        log_operation "apt update completed successfully"
    else
        display_warning "Failed to update package lists"
        log_operation "WARNING: apt update failed in update mode"
    fi
    
    # Upgrade packages
    if DEBIAN_FRONTEND=noninteractive apt upgrade -y >> "$LOG_FILE" 2>&1; then
        display_success "System packages upgraded"
        log_operation "apt upgrade completed successfully"
    else
        display_warning "Failed to upgrade system packages"
        log_operation "WARNING: apt upgrade failed in update mode"
    fi
    
    # Update npm dependencies if repository exists
    if [ -d "$REPOSITORY_PATH" ] && [ -f "$REPOSITORY_PATH/package.json" ]; then
        display_progress "Updating npm dependencies..."
        log_operation "Running npm update in $REPOSITORY_PATH"
        
        cd "$REPOSITORY_PATH"
        
        if npm update >> "$LOG_FILE" 2>&1; then
            display_success "npm dependencies updated"
            log_operation "npm update completed successfully"
        else
            display_warning "Failed to update npm dependencies"
            log_operation "WARNING: npm update failed"
        fi
        
        cd - > /dev/null
    else
        display_info "No repository found - skipping npm update"
        log_operation "Repository not found at $REPOSITORY_PATH - skipping npm update"
    fi
    
    # Rebuild the application after dependency updates
    if [ -d "$REPOSITORY_PATH" ] && [ -f "$REPOSITORY_PATH/package.json" ]; then
        display_progress "Rebuilding application..."
        log_operation "Running npm run build in $REPOSITORY_PATH"
        
        cd "$REPOSITORY_PATH"
        
        if npm run build >> "$LOG_FILE" 2>&1; then
            display_success "Application rebuilt successfully"
            log_operation "npm run build completed successfully"
            
            # Verify dist directory was created
            if [ -d "$REPOSITORY_PATH/dist" ] && [ -f "$REPOSITORY_PATH/dist/server.js" ]; then
                display_success "Build output verified (dist/server.js exists)"
                log_operation "Build verification: dist/server.js exists"
            else
                display_warning "Build completed but dist/server.js not found"
                log_operation "WARNING: Build completed but dist/server.js not found"
            fi
        else
            display_warning "Failed to rebuild application"
            log_operation "WARNING: npm run build failed in update mode"
        fi
        
        cd - > /dev/null
    fi
    
    # Check for Tailscale updates
    if command -v tailscale >/dev/null 2>&1; then
        display_progress "Checking for Tailscale updates..."
        log_operation "Checking for Tailscale updates"
        
        # Update Tailscale if available
        if DEBIAN_FRONTEND=noninteractive apt install --only-upgrade -y tailscale >> "$LOG_FILE" 2>&1; then
            local tailscale_version=$(tailscale version | head -n1)
            display_success "Tailscale is up to date: $tailscale_version"
            log_operation "Tailscale updated/verified: $tailscale_version"
        else
            display_warning "Failed to check Tailscale updates"
            log_operation "WARNING: Failed to update Tailscale"
        fi
    else
        display_info "Tailscale not installed - skipping update"
        log_operation "Tailscale not found - skipping update"
    fi
    
    display_success "Dependency updates completed"
    log_operation "All dependency updates completed in update mode"
}

# Display final success message
display_final_success() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Display QR codes for end user access
    display_qr_codes_terminal
    
    echo "Next steps:"
    echo "  1. Access the AI website builder at your configured domain"
    echo "  2. Share the QR codes with end users for easy access"
    echo "  3. Check the log file for detailed deployment information:"
    echo "     $LOG_FILE"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    log_operation "Deployment completed successfully"
}

# Display deployment result with comprehensive information
display_deployment_success() {
    display_progress "Preparing deployment success message..."
    log_operation "FUNCTION: display_deployment_success called"
    
    # Get deployment completion timestamp
    local completion_timestamp=$(date -Iseconds)
    local completion_display=$(date "+%Y-%m-%d %H:%M:%S %Z")
    
    # Get Tailscale hostname for access URL
    local access_url="https://$DOMAIN_NAME"
    local tailscale_hostname=""
    
    if command -v tailscale >/dev/null 2>&1; then
        tailscale_hostname=$(tailscale status --json 2>/dev/null | grep -o '"HostName":"[^"]*"' | cut -d'"' -f4 | head -n1)
        
        if [ -z "$tailscale_hostname" ]; then
            tailscale_hostname=$(tailscale status 2>/dev/null | head -n1 | awk '{print $2}')
        fi
        
        if [ -n "$tailscale_hostname" ]; then
            access_url="https://$tailscale_hostname"
        fi
    fi
    
    log_operation "Deployment completion timestamp: $completion_timestamp"
    log_operation "Deployment mode: $MODE"
    log_operation "Access URL: $access_url"
    
    # Display formatted success message
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    echo "║           ✓ DEPLOYMENT COMPLETED SUCCESSFULLY!                   ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Display deployment information
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Deployment Information${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Display deployment mode
    if [ "$MODE" = "fresh" ]; then
        echo -e "${GREEN}Deployment Mode:${NC} Fresh Installation"
        log_operation "Displayed deployment mode: fresh installation"
    else
        echo -e "${GREEN}Deployment Mode:${NC} Configuration Update"
        log_operation "Displayed deployment mode: configuration update"
    fi
    
    # Display completion timestamp
    echo -e "${GREEN}Completed At:${NC} $completion_display"
    log_operation "Displayed completion timestamp: $completion_display"
    
    # Display access URL
    echo -e "${GREEN}Access URL:${NC} $access_url"
    log_operation "Displayed access URL: $access_url"
    
    # Display domain name
    echo -e "${GREEN}Domain Name:${NC} $DOMAIN_NAME"
    log_operation "Displayed domain name: $DOMAIN_NAME"
    
    echo ""
    
    # Display QR codes for end user access
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}QR Codes for End User Access${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Call the existing display_qr_codes_terminal function
    display_qr_codes_terminal
    
    # Display log file location
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Troubleshooting Information${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}Log File Location:${NC}"
    echo "  $LOG_FILE"
    echo ""
    echo "To view the deployment log:"
    echo "  cat $LOG_FILE"
    echo ""
    echo "To view service logs:"
    echo "  journalctl -u ai-website-builder -f"
    echo ""
    
    log_operation "Displayed log file location: $LOG_FILE"
    
    # Display next steps for end users
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Next Steps for End Users${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. ${GREEN}Install Tailscale on End User Devices:${NC}"
    echo "   • Have end users scan the 'Install Tailscale App' QR code above"
    echo "   • Or direct them to: https://tailscale.com/download"
    echo "   • Install the Tailscale app on their mobile device or computer"
    echo ""
    echo "2. ${GREEN}Connect to Your Tailscale Network:${NC}"
    echo "   • End users should log in to Tailscale using your organization's account"
    echo "   • They will need to authenticate with the same Tailscale account"
    echo "   • Email used for this deployment: $TAILSCALE_EMAIL"
    echo ""
    echo "3. ${GREEN}Access the AI Website Builder:${NC}"
    echo "   • Once connected to Tailscale, scan the 'Access AI Website Builder' QR code"
    echo "   • Or navigate to: $access_url"
    echo "   • The service is now accessible only through your private Tailscale network"
    echo ""
    echo "4. ${GREEN}Share QR Codes with End Users:${NC}"
    echo "   • QR code images are saved in: $QR_CODE_DIR"
    echo "   • Share these images via email, messaging, or print them"
    echo "   • Files:"
    echo "     - tailscale-app.png (for installing Tailscale)"
    echo "     - service-access.png (for accessing the AI website builder)"
    echo ""
    echo "5. ${GREEN}Verify Service is Running:${NC}"
    echo "   • Check service status: systemctl status ai-website-builder"
    echo "   • View service logs: journalctl -u ai-website-builder -f"
    echo "   • Test access from a Tailscale-connected device"
    echo ""
    
    if [ "$MODE" = "update" ]; then
        echo "6. ${GREEN}Configuration Update Notes:${NC}"
        echo "   • Your configuration has been updated successfully"
        echo "   • The service has been restarted with the new configuration"
        echo "   • End users may need to refresh their browser to see changes"
        echo ""
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    echo "║     Thank you for using the AI Website Builder Quick Start!      ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
    
    log_operation "Deployment success message displayed successfully"
    log_operation "Deployment completed at: $completion_timestamp"
}

################################################################################
# Main Execution Flow
################################################################################

main() {
    # Initialize logging
    init_logging
    
    display_info "AI Website Builder - Quick Start Deployment"
    display_info "Version: $SCRIPT_VERSION"
    echo ""
    
    # Phase 1: Pre-flight checks and VM snapshot prompt
    display_progress "Phase 1: Pre-flight checks"
    run_preflight_checks
    prompt_vm_snapshot
    detect_existing_installation
    echo ""
    
    # Phase 2: Configuration input
    display_progress "Phase 2: Configuration"
    if [ "$MODE" = "update" ]; then
        load_existing_configuration
    else
        collect_configuration_input
    fi
    
    # Save configuration to secure file
    save_configuration
    echo ""
    
    # Phase 3: Dependency installation
    if [ "$MODE" = "fresh" ]; then
        display_progress "Phase 3: Installing dependencies"
        install_system_dependencies
        install_runtime_dependencies
        install_tailscale
        configure_firewall
        echo ""
    else
        display_progress "Phase 3: Updating dependencies"
        update_dependencies
        echo ""
    fi
    
    # Phase 4: Service configuration
    display_progress "Phase 4: Configuring services"
    configure_web_server
    setup_ssl_certificates
    echo ""
    
    # Phase 5: Tailscale authentication
    display_progress "Phase 5: Tailscale authentication"
    
    # First, verify Tailscale is installed
    if ! command -v tailscale >/dev/null 2>&1; then
        display_warning "Tailscale is not installed"
        log_operation "WARNING: Tailscale command not found"
        
        # Offer to install it now
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${YELLOW}⚠ Tailscale Not Installed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Tailscale provides secure remote access to your server."
        echo ""
        
        while true; do
            echo -n "Would you like to install Tailscale now? (yes/no): "
            read -r response
            
            case "$response" in
                [Yy]|[Yy][Ee][Ss])
                    display_info "Installing Tailscale..."
                    log_operation "User chose to install Tailscale"
                    install_tailscale
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    display_info "Skipping Tailscale installation"
                    log_operation "User chose to skip Tailscale installation"
                    echo ""
                    echo "You can install Tailscale later by running:"
                    echo "  curl -fsSL https://tailscale.com/install.sh | sh"
                    echo "  sudo tailscale up"
                    echo ""
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo ""
                    # Skip to next phase
                    echo ""
                    display_progress "Phase 6: Finalization"
                    generate_qr_codes
                    configure_systemd_service
                    save_installation_state
                    if [ "$MODE" = "update" ]; then
                        restart_services
                    else
                        start_services
                    fi
                    verify_service_status
                    verify_domain_accessibility
                    echo ""
                    display_deployment_success
                    return 0
                    ;;
                *)
                    echo "Please answer 'yes' or 'no'"
                    ;;
            esac
        done
    fi
    
    # Verify tailscaled service is running
    if ! systemctl is-active --quiet tailscaled; then
        display_warning "tailscaled service is not running"
        log_operation "WARNING: tailscaled service not active"
        
        display_progress "Starting tailscaled service..."
        if systemctl start tailscaled >> "$LOG_FILE" 2>&1; then
            display_success "tailscaled service started"
            log_operation "tailscaled service started successfully"
            # Give it a moment to initialize
            sleep 2
        else
            display_error "Failed to start tailscaled service"
            log_operation "ERROR: Failed to start tailscaled service"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}❌ ERROR: Tailscale service failed to start${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Remediation:"
            echo "  1. Check service status: systemctl status tailscaled"
            echo "  2. Check logs: journalctl -u tailscaled -n 50"
            echo "  3. Check the deployment log: $LOG_FILE"
            echo ""
            echo "You can continue without Tailscale, but remote access will be limited."
            echo ""
            
            while true; do
                echo -n "Continue without Tailscale? (yes/no): "
                read -r response
                
                case "$response" in
                    [Yy]|[Yy][Ee][Ss])
                        display_info "Continuing without Tailscale"
                        log_operation "User chose to continue without Tailscale"
                        echo ""
                        display_progress "Phase 6: Finalization"
                        generate_qr_codes
                        configure_systemd_service
                        save_installation_state
                        if [ "$MODE" = "update" ]; then
                            restart_services
                        else
                            start_services
                        fi
                        verify_service_status
                        verify_domain_accessibility
                        echo ""
                        display_deployment_success
                        return 0
                        ;;
                    [Nn]|[Nn][Oo])
                        display_error "Deployment cancelled"
                        log_operation "User cancelled deployment due to Tailscale service failure"
                        exit 1
                        ;;
                    *)
                        echo "Please answer 'yes' or 'no'"
                        ;;
                esac
            done
        fi
    fi
    
    # Tailscale authentication with retry logic
    local max_auth_attempts=3
    local auth_attempt=1
    local auth_successful=false
    
    while [ $auth_attempt -le $max_auth_attempts ] && [ "$auth_successful" = false ]; do
        if [ $auth_attempt -gt 1 ]; then
            echo ""
            display_progress "Tailscale authentication attempt $auth_attempt of $max_auth_attempts"
            log_operation "Tailscale authentication retry attempt $auth_attempt"
        fi
        
        # Check Tailscale status
        local status_output=$(tailscale status 2>&1)
        local status_exit_code=$?
        
        log_operation "Tailscale status exit code: $status_exit_code"
        log_operation "Tailscale status output: $status_output"
        
        # Check if already authenticated and connected
        if echo "$status_output" | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"; then
            display_info "Tailscale is already authenticated and connected"
            log_operation "Tailscale already authenticated - skipping authentication"
            auth_successful=true
            break
        fi
        
        # Check if logged out (needs authentication)
        if echo "$status_output" | grep -qi "logged out\|not logged in"; then
            display_info "Tailscale is installed but not authenticated"
            log_operation "Tailscale status shows logged out - proceeding with authentication"
            
            # Need to authenticate
            display_progress "Starting Tailscale authentication..."
            log_operation "Running tailscale up to initiate authentication"
            
            # Run tailscale up with explicit flags to ensure we get the auth URL
            echo ""
            echo "Running: tailscale up --accept-routes"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            # Run tailscale up directly (not captured) so user can see output in real-time
            tailscale up --accept-routes
            local tailscale_exit_code=$?
            
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            
            log_operation "Tailscale up exit code: $tailscale_exit_code"
            
            if [ $tailscale_exit_code -eq 0 ]; then
                display_success "Tailscale up command completed"
                log_operation "Tailscale up completed successfully"
                
                # Check if authentication succeeded
                local status_check=$(tailscale status 2>&1)
                if echo "$status_check" | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"; then
                    display_success "Tailscale authentication successful"
                    log_operation "Tailscale authentication completed successfully"
                    auth_successful=true
                    break
                else
                    display_info "Tailscale up completed, checking status..."
                    echo "Current status:"
                    echo "$status_check"
                    echo ""
                    
                    # Ask user if they completed authentication
                    while true; do
                        echo -n "Did you complete the authentication in your browser? (yes/no/retry): "
                        read -r response
                        
                        case "$response" in
                            [Yy]|[Yy][Ee][Ss])
                                # Check again
                                local status_check=$(tailscale status 2>&1)
                                if echo "$status_check" | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"; then
                                    display_success "Tailscale authentication verified!"
                                    log_operation "Manual authentication verified"
                                    auth_successful=true
                                    break 2
                                else
                                    display_warning "Tailscale status doesn't show connection yet"
                                    echo "Status: $status_check"
                                    echo ""
                                fi
                                ;;
                            [Nn]|[Nn][Oo])
                                if [ $auth_attempt -lt $max_auth_attempts ]; then
                                    display_info "Will retry authentication..."
                                    break
                                else
                                    display_warning "Max attempts reached"
                                    break
                                fi
                                ;;
                            [Rr]|[Rr][Ee][Tt][Rr][Yy])
                                display_info "Retrying..."
                                break
                                ;;
                            *)
                                echo "Please answer 'yes', 'no', or 'retry'"
                                ;;
                        esac
                    done
                fi
            else
                display_error "Tailscale up command failed with exit code $tailscale_exit_code"
                log_operation "ERROR: Tailscale up failed with exit code $tailscale_exit_code"
                
                if [ $auth_attempt -lt $max_auth_attempts ]; then
                    display_info "Will retry..."
                fi
            fi
        else
            # Tailscale status command failed or returned unexpected output
            display_error "Tailscale status check failed on attempt $auth_attempt"
            log_operation "ERROR: Tailscale status unexpected output on attempt $auth_attempt"
            
            # Show what the error is
            echo ""
            echo "Tailscale status output:"
            echo "$status_output"
            echo ""
            
            if [ $auth_attempt -lt $max_auth_attempts ]; then
                display_info "Waiting 5 seconds before retry..."
                sleep 5
            fi
        fi
        
        auth_attempt=$((auth_attempt + 1))
    done
    
    # If authentication still not successful after all attempts
    if [ "$auth_successful" = false ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${YELLOW}⚠ Tailscale Authentication Not Completed${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "After $max_auth_attempts attempts, Tailscale authentication could not be completed."
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check if tailscaled is running: systemctl status tailscaled"
        echo "  2. Try restarting the service: systemctl restart tailscaled"
        echo "  3. Check logs: journalctl -u tailscaled -n 50"
        echo "  4. Verify installation: tailscale version"
        echo "  5. Try manual authentication: sudo tailscale up"
        echo "  6. Check Tailscale status: sudo tailscale status"
        echo ""
        echo "Note: If you use GitHub to sign in to Tailscale, make sure to"
        echo "      select GitHub as your authentication method in the browser."
        echo ""
        echo "You can continue without Tailscale authentication and set it up later."
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        while true; do
            echo -n "Continue without Tailscale authentication? (yes/no): "
            read -r response
            
            case "$response" in
                [Yy]|[Yy][Ee][Ss])
                    display_info "Continuing without Tailscale authentication"
                    log_operation "User chose to continue without Tailscale authentication after $max_auth_attempts attempts"
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    display_error "Deployment cancelled"
                    log_operation "User cancelled deployment due to Tailscale authentication failure"
                    exit 1
                    ;;
                *)
                    echo "Please answer 'yes' or 'no'"
                    ;;
            esac
        done
    fi
    echo ""
    
    # Phase 6: Finalization
    display_progress "Phase 6: Finalization"
    generate_qr_codes
    configure_systemd_service
    
    # Save installation state before starting/restarting services
    save_installation_state
    
    if [ "$MODE" = "update" ]; then
        restart_services
    else
        start_services
    fi
    
    verify_service_status
    verify_domain_accessibility
    echo ""
    
    # Display success message
    display_deployment_success
}

################################################################################
# Script Entry Point
################################################################################

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}" >&2
    echo "Please run with: sudo $0" >&2
    exit 1
fi

# Execute main function
main "$@"
