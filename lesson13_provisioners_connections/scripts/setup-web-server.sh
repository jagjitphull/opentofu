#!/bin/bash
# =============================================================================
# Web Server Setup Script
# =============================================================================
# This script is uploaded and executed by OpenTofu provisioners
# Demonstrates remote-exec and file provisioners working together
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log "Starting web server setup..."

# -----------------------------------------------------------------------------
# Update system packages
# -----------------------------------------------------------------------------
log "Updating system packages..."
yum update -y || warn "Some packages failed to update"

# -----------------------------------------------------------------------------
# Install Apache HTTPD
# -----------------------------------------------------------------------------
log "Installing Apache HTTPD..."
if ! yum list installed httpd &>/dev/null; then
    yum install -y httpd
    log "Apache HTTPD installed successfully"
else
    log "Apache HTTPD already installed"
fi

# -----------------------------------------------------------------------------
# Configure Apache
# -----------------------------------------------------------------------------
log "Configuring Apache..."

# Create custom Apache configuration
cat > /etc/httpd/conf.d/provisioner-lab.conf <<'EOF'
# Custom configuration for Provisioner Lab
ServerTokens Prod
ServerSignature Off
TraceEnable Off

# Performance tuning
Timeout 60
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5

# Security headers
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
EOF

log "Apache configuration created"

# -----------------------------------------------------------------------------
# Set up web directory
# -----------------------------------------------------------------------------
log "Setting up web directory..."
mkdir -p /var/www/html
chown -R apache:apache /var/www/html
chmod 755 /var/www/html

# Create a backup of default index if it exists
if [ -f /var/www/html/index.html ]; then
    mv /var/www/html/index.html /var/www/html/index.html.bak
    log "Backed up existing index.html"
fi

# -----------------------------------------------------------------------------
# Configure firewall (if firewalld is running)
# -----------------------------------------------------------------------------
if systemctl is-active --quiet firewalld; then
    log "Configuring firewall..."
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
    log "Firewall configured"
else
    log "Firewalld not running, skipping firewall configuration"
fi

# -----------------------------------------------------------------------------
# Enable and start Apache
# -----------------------------------------------------------------------------
log "Enabling Apache to start on boot..."
systemctl enable httpd

log "Starting Apache..."
systemctl start httpd

# Verify Apache is running
if systemctl is-active --quiet httpd; then
    log "Apache is running successfully"
else
    error "Apache failed to start"
    systemctl status httpd
    exit 1
fi

# -----------------------------------------------------------------------------
# Create info page
# -----------------------------------------------------------------------------
log "Creating server info page..."
cat > /var/www/html/server-info.txt <<EOF
Server Information
==================
Hostname: $(hostname)
IP Address: $(hostname -I | awk '{print $1}')
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Apache Version: $(httpd -v | head -n1)
PHP Installed: $(which php &>/dev/null && echo "Yes" || echo "No")
Configured By: OpenTofu Provisioners
Setup Time: $(date)
EOF

chmod 644 /var/www/html/server-info.txt
log "Server info page created"

# -----------------------------------------------------------------------------
# Set up logging
# -----------------------------------------------------------------------------
log "Configuring logging..."
mkdir -p /var/log/provisioner-lab
cat > /var/log/provisioner-lab/setup.log <<EOF
Web Server Setup Log
====================
Setup completed at: $(date)
Script executed by: $(whoami)
Working directory: $(pwd)
Apache status: $(systemctl is-active httpd)
EOF

log "Logging configured"

# -----------------------------------------------------------------------------
# Final verification
# -----------------------------------------------------------------------------
log "Performing final verification..."

# Check if port 80 is listening
if netstat -tuln | grep -q ':80 '; then
    log "Port 80 is listening"
else
    warn "Port 80 is not listening"
fi

# Test Apache configuration
if httpd -t &>/dev/null; then
    log "Apache configuration is valid"
else
    error "Apache configuration has errors"
    httpd -t
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
log "============================================"
log "Web Server Setup Complete!"
log "============================================"
log "Apache Status: $(systemctl is-active httpd)"
log "Apache Enabled: $(systemctl is-enabled httpd)"
log "Document Root: /var/www/html"
log "Configuration: /etc/httpd/conf.d/provisioner-lab.conf"
log "Logs: /var/log/httpd/"
log "============================================"

exit 0
