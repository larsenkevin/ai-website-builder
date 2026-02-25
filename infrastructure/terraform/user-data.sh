#!/bin/bash
# User data script for AWS Lightsail instance
# Configures Ubuntu LTS with automatic security updates

set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting AI Website Builder deployment..."
echo "Timestamp: $(date)"

# Update package lists
echo "Updating package lists..."
apt-get update

# Configure automatic security updates
echo "Configuring automatic security updates..."
apt-get install -y unattended-upgrades apt-listchanges

# Configure unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF

# Enable automatic updates
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Install essential packages
echo "Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    ufw \
    fail2ban

# Create application directory structure
echo "Creating application directories..."
mkdir -p /opt/website-builder/{app,config,assets,versions,logs}
mkdir -p /opt/website-builder/config/pages
mkdir -p /opt/website-builder/assets/{uploads,processed/{320,768,1920}}
mkdir -p /var/www/html

# Set proper permissions
chown -R ubuntu:ubuntu /opt/website-builder
chmod 750 /opt/website-builder
chmod 755 /var/www/html

echo "User data script completed successfully!"
echo "Timestamp: $(date)"
