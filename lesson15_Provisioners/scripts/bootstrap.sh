#!/bin/bash
set -e

echo "=== Starting Bootstrap Script ==="
echo "Hostname: $(hostname)"
echo "Time: $(date)"

# Wait for cloud-init to complete
echo "Waiting for cloud-init to finish..."
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
  sleep 1
done
echo "Cloud-init completed."

# Update system (with error handling for package conflicts)
echo "Updating system packages..."
sudo dnf update -y --allowerasing || {
  echo "Warning: dnf update had issues, continuing anyway..."
}

# Install nginx
echo "Installing nginx..."
sudo dnf install -y nginx

# Install additional tools (curl may already be installed)
echo "Installing additional tools..."
sudo dnf install -y git wget || true

echo "=== Bootstrap Complete ==="