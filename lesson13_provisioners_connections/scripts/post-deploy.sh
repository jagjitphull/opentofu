#!/bin/bash
# =============================================================================
# Post-Deployment Configuration Script
# =============================================================================
# This script runs via null_resource provisioner
# Demonstrates advanced provisioner patterns and re-runnable configurations
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[POST-DEPLOY]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log "Starting post-deployment configuration..."

# -----------------------------------------------------------------------------
# Create application directory structure
# -----------------------------------------------------------------------------
log "Setting up application directory structure..."
mkdir -p /opt/app/{bin,config,logs,data}
chown -R ec2-user:ec2-user /opt/app

# -----------------------------------------------------------------------------
# Install additional useful packages
# -----------------------------------------------------------------------------
log "Installing additional packages..."
yum install -y \
    htop \
    tree \
    jq \
    vim \
    net-tools \
    telnet \
    bind-utils \
    || true  # Don't fail if some packages are unavailable

# -----------------------------------------------------------------------------
# Configure system monitoring
# -----------------------------------------------------------------------------
log "Setting up basic monitoring..."
cat > /opt/app/bin/health-check.sh <<'EOF'
#!/bin/bash
# Simple health check script

echo "=== System Health Check ==="
echo "Time: $(date)"
echo "Uptime: $(uptime)"
echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"
echo "Apache: $(systemctl is-active httpd)"
echo "=========================="
EOF

chmod +x /opt/app/bin/health-check.sh
log "Health check script created"

# -----------------------------------------------------------------------------
# Create custom aliases for ec2-user
# -----------------------------------------------------------------------------
log "Setting up user aliases..."
cat >> /home/ec2-user/.bashrc <<'EOF'

# Custom aliases for OpenTofu lab
alias ll='ls -lah'
alias logs='sudo tail -f /var/log/httpd/access_log'
alias errors='sudo tail -f /var/log/httpd/error_log'
alias restart-web='sudo systemctl restart httpd'
alias health='bash /opt/app/bin/health-check.sh'
alias webroot='cd /var/www/html'

# Prompt customization
export PS1='\[\033[01;32m\]\u@provisioner-lab\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF

log "User aliases configured"

# -----------------------------------------------------------------------------
# Create MOTD (Message of the Day)
# -----------------------------------------------------------------------------
log "Configuring MOTD..."
cat > /etc/motd <<'EOF'
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║    🚀 OpenTofu Provisioners Lab                         ║
║    📚 Lesson 13: Provisioners & Connections             ║
║                                                          ║
║    This instance was configured using:                   ║
║    • local-exec provisioner                              ║
║    • remote-exec provisioner                             ║
║    • file provisioner                                    ║
║    • SSH connection blocks                               ║
║                                                          ║
║    Quick Commands:                                       ║
║    • health       - System health check                  ║
║    • logs         - View access logs                     ║
║    • errors       - View error logs                      ║
║    • restart-web  - Restart Apache                       ║
║    • webroot      - Go to web root                       ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF

log "MOTD configured"

# -----------------------------------------------------------------------------
# Create sample API endpoint
# -----------------------------------------------------------------------------
log "Creating sample API endpoint..."
cat > /var/www/html/api.php <<'EOF'
<?php
header('Content-Type: application/json');

$data = [
    'status' => 'healthy',
    'timestamp' => date('c'),
    'hostname' => gethostname(),
    'server_ip' => $_SERVER['SERVER_ADDR'],
    'client_ip' => $_SERVER['REMOTE_ADDR'],
    'method' => $_SERVER['REQUEST_METHOD'],
    'uri' => $_SERVER['REQUEST_URI'],
    'uptime' => shell_exec('uptime'),
    'provisioner' => 'OpenTofu',
    'lab' => 'lesson13'
];

echo json_encode($data, JSON_PRETTY_PRINT);
?>
EOF

# Only if PHP is installed
if command -v php &> /dev/null; then
    chmod 644 /var/www/html/api.php
    log "API endpoint created (PHP detected)"
else
    rm -f /var/www/html/api.php
    info "PHP not installed, skipping API endpoint"
fi

# -----------------------------------------------------------------------------
# Create health endpoint
# -----------------------------------------------------------------------------
log "Creating health endpoint..."
cat > /var/www/html/health.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Health Check</title>
    <meta http-equiv="refresh" content="5">
    <style>
        body { font-family: monospace; background: #1e1e1e; color: #00ff00; padding: 20px; }
        .healthy { color: #00ff00; }
        .timestamp { color: #888; }
    </style>
</head>
<body>
    <h1 class="healthy">✓ System Healthy</h1>
    <p class="timestamp">Last Check: <span id="time"></span></p>
    <script>
        document.getElementById('time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOF

chmod 644 /var/www/html/health.html
log "Health endpoint created"

# -----------------------------------------------------------------------------
# Set up log rotation
# -----------------------------------------------------------------------------
log "Configuring log rotation..."
cat > /etc/logrotate.d/provisioner-lab <<'EOF'
/opt/app/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 ec2-user ec2-user
}
EOF

log "Log rotation configured"

# -----------------------------------------------------------------------------
# Create status file
# -----------------------------------------------------------------------------
log "Creating status file..."
cat > /opt/app/config/deployment-status.json <<EOF
{
  "deployment_status": "completed",
  "last_configured": "$(date -Iseconds)",
  "configured_by": "OpenTofu null_resource provisioner",
  "script": "post-deploy.sh",
  "version": "1.0.0",
  "components": {
    "web_server": "configured",
    "monitoring": "configured",
    "logging": "configured",
    "aliases": "configured"
  }
}
EOF

chown ec2-user:ec2-user /opt/app/config/deployment-status.json
log "Status file created"

# -----------------------------------------------------------------------------
# Final verification
# -----------------------------------------------------------------------------
log "Running final verification..."

# Test web server
if curl -s http://localhost/ > /dev/null; then
    log "Web server responding correctly"
else
    log "Warning: Web server not responding on localhost"
fi

# Check directory permissions
if [ -w /opt/app ]; then
    log "Application directory permissions correct"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
log "============================================"
log "Post-Deployment Configuration Complete!"
log "============================================"
info "Application dir: /opt/app"
info "Health check: http://$(hostname -I | awk '{print $1}')/health.html"
info "Logs: /opt/app/logs"
info "Config: /opt/app/config"
log "============================================"

exit 0
