# Quick Start Guide - OpenTofu Provisioners Lab

## 🚀 5-Minute Setup

### Prerequisites
```bash
# Verify prerequisites
tofu --version  # Should be >= 1.6.0
aws --version   # AWS CLI configured
aws sts get-caller-identity  # Verify AWS credentials
```

### Option 1: Auto-Generate SSH Key (Recommended for Lab)

```bash
# Navigate to lab directory
cd lesson13_provisioners_connections

# Initialize OpenTofu
tofu init

# Review the plan
tofu plan

# Deploy infrastructure
tofu apply -auto-approve

# Wait for completion (~3-5 minutes)
# The provisioners will:
# - Generate SSH key pair
# - Create EC2 instance
# - Configure web server
# - Upload custom content
```

### Access Your Instance

```bash
# Get the SSH command
tofu output ssh_command

# Copy and execute it
ssh -i ./ssh-key-XXXXXX.pem ec2-user@<PUBLIC_IP>

# Or use the helper output
eval $(tofu output -raw ssh_command)
```

### Test the Web Server

```bash
# Get the web URL
WEB_URL=$(tofu output -raw web_url)

# Open in browser or curl
curl $WEB_URL

# Should show a beautiful web page!
```

### View Provisioner Artifacts

```bash
# Check local files created by provisioners
cat inventory.txt
cat ssh-config-entry.txt
cat provisioner-log.txt
cat deployment-notifications.txt
```

---

## Option 2: Use Existing SSH Key

```bash
# Set environment variables
export TF_VAR_use_existing_key=true
export TF_VAR_existing_key_name="your-aws-key-name"
export TF_VAR_existing_key_path="~/.ssh/your-key.pem"

# Deploy
tofu init
tofu apply -auto-approve

# Connect using your existing key
ssh -i ~/.ssh/your-key.pem ec2-user@$(tofu output -raw instance_public_ip)
```

---

## What to Explore

### 1. Check the Web Server
```bash
# View the custom page
curl http://$(tofu output -raw instance_public_ip)

# Check health endpoint
curl http://$(tofu output -raw instance_public_ip)/health.html

# View server info
curl http://$(tofu output -raw instance_public_ip)/server-info.txt
```

### 2. SSH and Explore
```bash
# Connect to instance
eval $(tofu output -raw ssh_command)

# Run the health check
health

# View web logs
logs

# Check Apache status
sudo systemctl status httpd

# View MOTD
cat /etc/motd

# Check provisioner artifacts
cat /opt/app/config/deployment-status.json
```

### 3. Examine Provisioner Logs
```bash
# Local files created by local-exec
ls -la *.txt

# On the instance (after SSH)
sudo cat /var/log/provisioner-lab/setup.log
cat /opt/app/config/deployment-status.json
```

---

## Common Commands

### Infrastructure Management
```bash
# Show all outputs
tofu output

# Get specific output
tofu output instance_public_ip

# Refresh state
tofu refresh

# Show current state
tofu show
```

### Debugging
```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log
tofu apply

# Test SSH connectivity manually
ssh -vvv -i ./ssh-key-*.pem ec2-user@<PUBLIC_IP>

# Check security group
aws ec2 describe-security-groups \
  --group-ids $(tofu output -raw security_group_id)
```

### Testing Provisioners
```bash
# Taint the instance to force reprovisioning
tofu taint aws_instance.web_server

# Re-apply to see provisioners run again
tofu apply

# Taint null_resource to re-run post-deploy
tofu taint null_resource.post_deployment_config
tofu apply
```

---

## Cleanup

```bash
# Destroy all resources
# Note: destroy-time provisioners will run!
tofu destroy -auto-approve

# Verify local files are cleaned
ls -la *.txt *.pem

# Remove generated files manually if needed
rm -f inventory.txt ssh-config-entry.txt *.pem
```

---

## Troubleshooting

### SSH Connection Timeout
```bash
# Check security group allows your IP
curl ifconfig.me  # Get your public IP

# Update allowed_ssh_cidr if needed
tofu apply -var="allowed_ssh_cidr=$(curl -s ifconfig.me)/32"
```

### Provisioner Failed
```bash
# Check the logs
cat terraform-debug.log

# SSH manually and debug
ssh -i ./ssh-key-*.pem ec2-user@<PUBLIC_IP>
sudo journalctl -xe
```

### Instance Not Ready
```bash
# Wait for cloud-init to complete
ssh -i ./ssh-key-*.pem ec2-user@<PUBLIC_IP>
cloud-init status --wait

# Check cloud-init logs
sudo cat /var/log/cloud-init-output.log
```

---

## Next Steps

1. **Review the code**: Open `main.tf` and study each provisioner
2. **Modify provisioners**: Try adding your own custom provisioners
3. **Test error handling**: Intentionally break a provisioner to see `on_failure`
4. **Explore alternatives**: Compare with `user_data` approach
5. **Read the full README**: Deep dive into provisioner concepts

---

## Learning Objectives Checklist

- [ ] Understand when to use (and avoid) provisioners
- [ ] Configure SSH connections with key-based auth
- [ ] Use local-exec for local operations
- [ ] Use remote-exec for remote commands
- [ ] Use file provisioner to upload content
- [ ] Implement error handling with on_failure
- [ ] Use destroy-time provisioners with when
- [ ] Create re-runnable provisioners with null_resource
- [ ] Debug provisioner failures
- [ ] Compare provisioners vs user_data vs custom AMIs

---

## Quick Reference

| Task | Command |
|------|---------|
| Deploy | `tofu apply` |
| Destroy | `tofu destroy` |
| SSH Connect | `eval $(tofu output -raw ssh_command)` |
| View Web | `curl $(tofu output -raw web_url)` |
| Get Outputs | `tofu output` |
| Re-provision | `tofu taint <resource>` then `tofu apply` |
| Debug | `export TF_LOG=DEBUG && tofu apply` |

---

**Happy Learning! 🎓**
