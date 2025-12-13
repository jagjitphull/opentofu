## 1 Deploy Development Environment
# Navigate to dev environment
cd environments/dev

# Initialize
tofu init

# Validate configuration
tofu validate

# Review plan
tofu plan

# Apply
tofu apply

# Save outputs
tofu output

## 2 Deploy Production Environment
# Navigate to prod environment
cd environments/prod

# Initialize
tofu init

# Validate configuration
tofu validate

# Review plan
tofu plan

# Apply
tofu apply

# Save outputs
tofu output

## 3 Verification and Testing
#Verify Resources Created
#Check VPC and Subnets:
# Dev environment
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=myapp-dev-vpc"
aws ec2 describe-subnets --filters "Name=tag:Project,Values=myapp" "Name=tag:Environment,Values=dev"

# Production environment
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=myapp-prod-vpc"
aws ec2 describe-subnets --filters "Name=tag:Project,Values=myapp" "Name=tag:Environment,Values=prod"

## Check NAT Gateways
# Dev (should be 1)
aws ec2 describe-nat-gateways --filter "Name=tag:Project,Values=myapp" "Name=tag:Environment,Values=dev"

# Prod (should be 3)
aws ec2 describe-nat-gateways --filter "Name=tag:Project,Values=myapp" "Name=tag:Environment,Values=prod"

## Check Security Groups
# Dev environment
# List security groups
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=myapp"

# Check specific security group rules
aws ec2 describe-security-group-rules --filters "Name=group-name,Values=myapp-dev-web-sg"

Test Subnet CIDR Calculations
Create a test script to verify CIDR calculations:

#!/bin/bash

echo "=== Development Environment ==="
cd environments/dev
tofu console <<EOF
local.public_subnets
local.private_subnets
EOF

echo ""
echo "=== Production Environment ==="
cd ../prod
tofu console <<EOF
local.public_subnets
local.private_subnets
local.database_subnets
EOF