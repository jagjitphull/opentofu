# OpenTofu Drift Detection and Resolution

## HANDS-ON LAB

**Detect → Analyze → Resolve → Prevent**

---

| Property | Value |
|----------|-------|
| **Duration** | 60 - 90 minutes |
| **Difficulty** | Beginner to Intermediate |
| **Cloud Provider** | AWS |

> ⚠️ **Protected Training Document** - This document is for reference only during training sessions.

---

## Table of Contents

1. [Lab Overview and Prerequisites](#section-1-lab-overview-and-prerequisites)
2. [Understanding Infrastructure Drift](#section-2-understanding-infrastructure-drift)
3. [Set Up the Lab Environment](#section-3-set-up-the-lab-environment)
4. [Create and Introduce Drift](#section-4-create-and-introduce-drift)
5. [Detect Drift with OpenTofu](#section-5-detect-drift-with-opentofu)
6. [Detect Drift with Spacelift](#section-6-detect-drift-with-spacelift)
7. [Resolve Drift - Multiple Strategies](#section-7-resolve-drift---multiple-strategies)
8. [Prevent Future Drift](#section-8-prevent-future-drift)
9. [Troubleshooting Guide](#section-9-troubleshooting-guide)
10. [Best Practices and Next Steps](#section-10-best-practices-and-next-steps)
11. [Quick Reference Card](#quick-reference-card)

---

## Section 1: Lab Overview and Prerequisites

### 1.1 Learning Objectives

By the end of this lab, you will be able to:

- [ ] Understand what infrastructure drift is and why it occurs
- [ ] Detect drift using OpenTofu plan command
- [ ] Configure automated drift detection in Spacelift
- [ ] Analyze drift reports and identify root causes
- [ ] Resolve drift using multiple strategies (reconcile, import, refresh)
- [ ] Implement preventive measures to minimize future drift

### 1.2 Prerequisites

#### Required Access

1. Spacelift account with stack management permissions
2. AWS account with EC2 and S3 permissions
3. GitHub repository for infrastructure code

#### Required Tools

1. OpenTofu CLI (version 1.6.0 or later)
2. AWS CLI configured with valid credentials
3. Git CLI installed and configured
4. Text editor or IDE (VS Code recommended)

#### Verify Your Environment

Run these commands to verify your setup:

```bash
# Verify OpenTofu
tofu version
# Expected: OpenTofu v1.6.0 or higher

# Verify AWS CLI
aws sts get-caller-identity

# Verify AWS permissions for EC2
aws ec2 describe-instances --max-results 1

# Verify AWS permissions for S3
aws s3 ls
```

> 💡 **Environment Check**: If any command fails, resolve the issue before proceeding. All prerequisites must be met for successful lab completion.

---

## Section 2: Understanding Infrastructure Drift

### 2.1 What is Infrastructure Drift?

Infrastructure drift occurs when the actual state of your infrastructure differs from the desired state defined in your OpenTofu configuration. This mismatch can lead to:

1. Security vulnerabilities from unauthorized changes
2. Compliance violations when configurations deviate from standards
3. Unexpected behavior during future deployments
4. Difficulty reproducing environments

### 2.2 Common Causes of Drift

| Cause | Description | Example |
|-------|-------------|---------|
| Manual Changes | Direct modifications via console or CLI | Editing security group rules in AWS Console |
| Emergency Fixes | Hotfixes applied during incidents | Scaling up instances during outage |
| Automated Processes | Scripts or tools modifying resources | Auto-scaling changing instance count |
| External Dependencies | Third-party integrations | CDN provider updating configurations |
| State File Issues | Corrupted or outdated state | State not updated after failed apply |

### 2.3 The Drift Detection Workflow

This lab follows the complete drift management lifecycle:

| Phase | Action | Description |
|-------|--------|-------------|
| **1** | **Detect** | Identify differences between state and reality |
| **2** | **Analyze** | Understand what changed and why |
| **3** | **Resolve** | Reconcile infrastructure with desired state |
| **4** | **Prevent** | Implement controls to minimize future drift |

---

## Section 3: Set Up the Lab Environment

### STEP 1: CREATE THE INFRASTRUCTURE CODE

#### 3.1 Create Repository Structure

Create a new directory for this lab:

```bash
# Create lab directory
mkdir -p drift-detection-lab
cd drift-detection-lab

# Initialize git repository
git init

# Create file structure
mkdir -p stacks/drift-lab
```

#### 3.2 Directory Structure

```
drift-detection-lab/
├── README.md
└── stacks/
    └── drift-lab/
        ├── versions.tf
        ├── providers.tf
        ├── variables.tf
        ├── main.tf
        └── outputs.tf
```

### STEP 2: CREATE THE OPENTOFU FILES

#### 3.3 versions.tf

```hcl
# versions.tf
# Defines version constraints for OpenTofu and providers

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

#### 3.4 providers.tf

```hcl
# providers.tf
# AWS provider configuration

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "drift-detection-lab"
      Environment = var.environment
      ManagedBy   = "OpenTofu"
    }
  }
}
```

#### 3.5 variables.tf

```hcl
# variables.tf
# Input variables for the drift detection lab

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "lab"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "bucket_prefix" {
  description = "Prefix for S3 bucket name"
  type        = string
  default     = "drift-lab"
}
```

#### 3.6 main.tf

```hcl
# main.tf
# Resources for drift detection demonstration

# Random suffix for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 Bucket - Simple resource for drift demo
resource "aws_s3_bucket" "demo" {
  bucket = "${var.bucket_prefix}-${random_id.suffix.hex}"
  
  tags = {
    Name        = "Drift Detection Demo Bucket"
    Purpose     = "Training"
    CostCenter  = "Training-001"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Security Group - Common drift target
resource "aws_security_group" "demo" {
  name        = "drift-demo-sg-${random_id.suffix.hex}"
  description = "Security group for drift detection demo"
  
  # SSH access - restricted to specific CIDR
  ingress {
    description = "SSH from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  
  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "drift-demo-sg"
  }
}

# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

#### 3.7 outputs.tf

```hcl
# outputs.tf
# Output values for reference and verification

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.demo.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.demo.arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.demo.id
}

output "security_group_name" {
  description = "Name of the security group"
  value       = aws_security_group.demo.name
}
```

### STEP 3: DEPLOY THE INITIAL INFRASTRUCTURE

#### 3.8 Initialize and Apply

```bash
# Navigate to stack directory
cd stacks/drift-lab

# Initialize OpenTofu
tofu init

# Validate configuration
tofu validate
# Expected: Success! The configuration is valid.

# Preview changes
tofu plan

# Apply the configuration
tofu apply -auto-approve

# Save the outputs for later reference
tofu output > ../../initial-outputs.txt
```

> 💡 **Save Your Outputs**: Note the bucket_name and security_group_id from the outputs. You will need these values to introduce drift in the next section.

#### 3.9 Verify Deployment

```bash
# Verify S3 bucket exists
aws s3 ls | grep drift-lab

# Verify security group exists
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=drift-demo-sg-*" \
  --query "SecurityGroups[*].[GroupId,GroupName]" \
  --output table
```

---

## Section 4: Create and Introduce Drift

In this section, we will intentionally introduce drift by making manual changes to resources outside of OpenTofu. This simulates real-world scenarios where drift commonly occurs.

### STEP 4: INTRODUCE DRIFT VIA AWS CONSOLE/CLI

#### 4.1 Drift Scenario 1: S3 Bucket Tags

Add an unauthorized tag to the S3 bucket:

```bash
# Get your bucket name from outputs
BUCKET_NAME=$(tofu output -raw bucket_name)

# Add a manual tag (simulating emergency change)
aws s3api put-bucket-tagging \
  --bucket $BUCKET_NAME \
  --tagging 'TagSet=[{Key=Name,Value=Drift Detection Demo Bucket},{Key=Purpose,Value=Training},{Key=CostCenter,Value=Training-001},{Key=ManualChange,Value=EmergencyFix}]'

# Verify the tag was added
aws s3api get-bucket-tagging --bucket $BUCKET_NAME
```

#### 4.2 Drift Scenario 2: Security Group Rules

Add an unauthorized ingress rule to the security group (common during incident response):

```bash
# Get your security group ID from outputs
SG_ID=$(tofu output -raw security_group_id)

# Add a manual rule (simulating emergency SSH access)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --tag-specifications 'ResourceType=security-group-rule,Tags=[{Key=Purpose,Value=EmergencyAccess}]'

# Verify the rule was added
aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --query "SecurityGroups[0].IpPermissions"
```

> ⚠️ **Security Alert**: We just added a rule allowing SSH from anywhere (0.0.0.0/0). In production, this would be a serious security vulnerability. This is exactly the type of drift that needs to be detected and remediated quickly.

#### 4.3 Drift Scenario 3: Bucket Versioning

Disable bucket versioning (simulating cost-cutting measure):

```bash
# Suspend versioning on the bucket
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Suspended

# Verify versioning is suspended
aws s3api get-bucket-versioning --bucket $BUCKET_NAME
```

#### 4.4 Summary of Introduced Drift

| Resource | Drift Type | Impact |
|----------|-----------|--------|
| S3 Bucket | Added tag: ManualChange=EmergencyFix | Minor - Cosmetic |
| Security Group | Added 0.0.0.0/0 SSH rule | **Critical - Security Risk** |
| S3 Versioning | Changed from Enabled to Suspended | Medium - Data Protection |

---

## Section 5: Detect Drift with OpenTofu

### STEP 5: USE TOFU PLAN FOR DRIFT DETECTION

#### 5.1 Understanding tofu plan for Drift

The `tofu plan` command compares three things:

1. Your configuration files (desired state)
2. The state file (last known state)
3. The actual infrastructure (real state)

When drift exists, `tofu plan` will show changes needed to bring infrastructure back to the desired state.

#### 5.2 Run Drift Detection

```bash
# Navigate to stack directory
cd stacks/drift-lab

# Run plan to detect drift
tofu plan

# For detailed output, use -detailed-exitcode
tofu plan -detailed-exitcode
# Exit codes:
#   0 = No changes (no drift)
#   1 = Error
#   2 = Changes detected (drift exists)
```

#### 5.3 Expected Output

You should see output similar to:

```hcl
# aws_s3_bucket.demo will be updated in-place
~ resource "aws_s3_bucket" "demo" {
    id     = "drift-lab-a1b2c3d4"
    # (other attributes unchanged)
    
  ~ tags = {
      - "ManualChange" = "EmergencyFix" -> null
        # (other tags unchanged)
    }
  }

# aws_s3_bucket_versioning.demo will be updated in-place
~ resource "aws_s3_bucket_versioning" "demo" {
    id     = "drift-lab-a1b2c3d4"
    
  ~ versioning_configuration {
      ~ status = "Suspended" -> "Enabled"
    }
  }

# aws_security_group.demo will be updated in-place
~ resource "aws_security_group" "demo" {
    id   = "sg-0123456789abcdef"
    name = "drift-demo-sg-a1b2c3d4"
    
  - ingress {
      - cidr_blocks = ["0.0.0.0/0"]
      - from_port   = 22
      - protocol    = "tcp"
      - to_port     = 22
    }
  }

Plan: 0 to add, 3 to change, 0 to destroy.
```

> 💡 **Reading the Plan**: The `~` symbol indicates in-place updates. The `-` prefix shows attributes that will be removed to match desired state. The plan shows exactly what will change to eliminate drift.

#### 5.4 Using tofu refresh

The `tofu refresh` command updates the state file to match actual infrastructure without making changes:

```bash
# Refresh state from actual infrastructure
tofu refresh

# Now run plan again
tofu plan
# This will still show the same drift because
# we want to bring infrastructure to desired state
```

> ⚠️ **Important**: `tofu refresh` only updates the state file. It does NOT change your infrastructure. Use refresh when you want to update state to match reality without reverting infrastructure changes.

---

## Section 6: Detect Drift with Spacelift

### STEP 6: CONFIGURE SPACELIFT DRIFT DETECTION

#### 6.1 Spacelift Drift Detection Benefits

Spacelift provides automated drift detection with:

1. Scheduled drift detection runs (hourly, daily, weekly)
2. Automatic reconciliation options
3. Drift notifications via Slack, email, or webhooks
4. Drift history and audit trail
5. Policy-based drift handling

#### 6.2 Create Stack in Spacelift (UI Method)

Follow these steps to create the stack:

1. Push your code to GitHub
2. Navigate to Stacks in Spacelift
3. Click "Create Stack"
4. Configure stack settings as shown below

| Setting | Value |
|---------|-------|
| Name | drift-detection-lab |
| Repository | drift-detection-lab |
| Branch | main |
| Project Root | stacks/drift-lab |
| Workflow Tool | OpenTofu |
| Manage State | Enabled |

#### 6.3 Enable Drift Detection

Configure drift detection in stack settings:

1. Go to Stack Settings > Behavior
2. Find "Drift Detection" section
3. Enable "Schedule drift detection"
4. Set schedule (e.g., "0 */4 * * *" for every 4 hours)
5. Optionally enable "Auto-reconcile" for automatic fixes

#### 6.4 Configure via OpenTofu (Admin Stack)

Alternatively, manage drift detection as code:

```hcl
# admin/drift-stack.tf
# Manage drift detection lab stack via OpenTofu

resource "spacelift_stack" "drift_lab" {
  name        = "drift-detection-lab"
  description = "Lab environment for drift detection training"
  
  repository   = "drift-detection-lab"
  branch       = "main"
  project_root = "stacks/drift-lab"
  
  # Use OpenTofu
  terraform_workflow_tool = "OPEN_TOFU"
  
  # Enable state management
  manage_state = true
  
  # Labels for organization
  labels = ["training", "drift-detection", "lab"]
}

# Configure Drift Detection
resource "spacelift_drift_detection" "drift_lab" {
  stack_id = spacelift_stack.drift_lab.id
  
  # Run drift detection every 4 hours
  schedule = ["0 */4 * * *"]
  
  # Reconcile drift automatically (use with caution!)
  reconcile = false
  
  # Ignore specific runs from triggering alerts
  ignore_state = false
  
  # Timezone for schedule
  timezone = "UTC"
}
```

> ⚠️ **Auto-Reconcile Caution**: The `reconcile = true` setting will automatically apply changes to fix drift. Use this only in environments where automated changes are acceptable. For production, keep `reconcile = false` and review changes manually.

#### 6.5 Trigger Manual Drift Detection

To test drift detection immediately:

1. Navigate to your stack in Spacelift
2. Click "Trigger" button
3. Select "Detect drift" option
4. Wait for the run to complete
5. Review the drift report

#### 6.6 Understanding Spacelift Drift Reports

The Spacelift drift detection run shows:

| Element | Description |
|---------|-------------|
| Drift Status | DRIFTED or NO DRIFT indicator |
| Resources Changed | Count of resources with drift |
| Plan Output | Full plan showing required changes |
| Timestamps | When drift was detected |
| Run ID | Unique identifier for audit trail |

> 💡 **Drift Notifications**: Configure notifications in Spacelift to alert your team when drift is detected. Go to Settings > Notifications to set up Slack, email, or webhook integrations.

---

## Section 7: Resolve Drift - Multiple Strategies

There are several strategies for resolving infrastructure drift. The right approach depends on your situation and the nature of the drift.

### 7.1 Strategy Overview

| Strategy | When to Use | Command |
|----------|-------------|---------|
| **Reconcile (Apply)** | Manual changes were wrong, revert to IaC | `tofu apply` |
| **Accept (Update Config)** | Manual changes were correct, update IaC | Edit .tf files + apply |
| **Import** | Resource exists but not in state | `tofu import` |
| **Refresh Only** | State is stale, infrastructure is correct | `tofu refresh` |

### STEP 7: STRATEGY 1 - RECONCILE (REVERT DRIFT)

#### 7.2 Reconcile the Security Group

The unauthorized SSH rule (0.0.0.0/0) is a security risk. We will revert this drift by applying our desired configuration:

```bash
# First, review what will change
tofu plan

# Apply to reconcile - this removes the unauthorized rule
tofu apply

# When prompted, type 'yes' to confirm

# Verify the unauthorized rule is removed
SG_ID=$(tofu output -raw security_group_id)
aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --query "SecurityGroups[0].IpPermissions"
```

> 💡 **Security Restored**: The `tofu apply` command removed the unauthorized 0.0.0.0/0 SSH rule and restored the secure 10.0.0.0/8 restriction. This is the most common drift resolution for security-related changes.

### STEP 8: STRATEGY 2 - ACCEPT DRIFT (UPDATE CONFIGURATION)

#### 7.3 Accept the Manual Tag

Sometimes manual changes are valid and should be incorporated into your IaC. Let's say the ManualChange tag is actually useful for tracking:

```bash
# First, introduce the drift again for this exercise
BUCKET_NAME=$(tofu output -raw bucket_name)
aws s3api put-bucket-tagging \
  --bucket $BUCKET_NAME \
  --tagging 'TagSet=[{Key=Name,Value=Drift Detection Demo Bucket},{Key=Purpose,Value=Training},{Key=CostCenter,Value=Training-001},{Key=ChangeHistory,Value=Manual-2024-01}]'

# Verify drift exists
tofu plan
```

#### 7.4 Update Configuration to Accept Change

Modify main.tf to include the new tag:

```hcl
# Update the S3 bucket resource in main.tf
resource "aws_s3_bucket" "demo" {
  bucket = "${var.bucket_prefix}-${random_id.suffix.hex}"
  
  tags = {
    Name          = "Drift Detection Demo Bucket"
    Purpose       = "Training"
    CostCenter    = "Training-001"
    ChangeHistory = "Manual-2024-01"  # Accepted from drift
  }
}
```

```bash
# Now plan shows no drift for this resource
tofu plan

# Apply to sync state with configuration
tofu apply -auto-approve
```

### STEP 9: STRATEGY 3 - IMPORT EXISTING RESOURCES

#### 7.5 Understanding tofu import

The import command brings existing infrastructure into OpenTofu management. This is useful when resources were created outside of IaC or when state is lost.

```bash
# Example: Import an existing S3 bucket
# First, add the resource block to your configuration

# Then import:
# tofu import aws_s3_bucket.example bucket-name

# For our lab, let's demonstrate with a new resource
# Create a bucket manually first
aws s3 mb s3://import-demo-$(date +%s) --region us-east-1

# Note the bucket name for import
```

#### 7.6 Import Block (OpenTofu 1.7+)

OpenTofu 1.7+ supports declarative imports using import blocks:

```hcl
# import.tf
# Declarative import for existing resources

import {
  to = aws_s3_bucket.imported
  id = "import-demo-1234567890"  # Replace with actual bucket name
}

# The resource block must also exist
resource "aws_s3_bucket" "imported" {
  bucket = "import-demo-1234567890"
  
  tags = {
    Name      = "Imported Bucket"
    ManagedBy = "OpenTofu"
  }
}
```

```bash
# Run plan to see the import
tofu plan

# Apply to perform the import
tofu apply

# The resource is now managed by OpenTofu
```

### STEP 10: STRATEGY 4 - REFRESH STATE

#### 7.7 When to Use Refresh

Use `tofu refresh` when you want to update the state file without changing infrastructure. Common scenarios include updating state after external changes that should be preserved, or synchronizing state with auto-scaling changes.

```bash
# Update state to match current infrastructure
tofu refresh

# Verify state was updated
tofu show

# Note: This doesn't change infrastructure
# It only updates the state file
```

> ⚠️ **Refresh Carefully**: After refresh, your state reflects actual infrastructure. If you then run apply without configuration changes, OpenTofu will attempt to revert infrastructure to match your configuration.

---

## Section 8: Prevent Future Drift

### 8.1 Preventive Measures

| Measure | Implementation | Effectiveness |
|---------|---------------|---------------|
| IAM Restrictions | Limit console/CLI access to resources | High |
| Scheduled Detection | Regular automated drift checks | High |
| Resource Tagging | Tag resources as IaC-managed | Medium |
| Policy-as-Code | OPA policies to detect manual changes | High |
| Training | Educate teams on IaC workflows | Medium |

### 8.2 IAM Policy to Prevent Manual Changes

Restrict manual modifications to IaC-managed resources:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyManualModification",
      "Effect": "Deny",
      "Action": [
        "s3:PutBucketTagging",
        "s3:PutBucketVersioning",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/ManagedBy": "OpenTofu"
        },
        "StringNotLike": {
          "aws:PrincipalArn": "arn:aws:iam::*:role/spacelift-*"
        }
      }
    }
  ]
}
```

### 8.3 OPA Policy for Drift Alerts

Create a Spacelift policy to alert on specific drift types:

```rego
# drift-alert.rego
# Alert on security-related drift

package spacelift

# Deny runs with security group drift without approval
warn["Security group drift detected - review required"] {
  input.spacelift.run.type == "DRIFT_DETECTION"
  resource := input.terraform.resource_changes[_]
  resource.type == "aws_security_group"
  resource.change.actions[_] == "update"
}

# Warn on any S3 versioning changes
warn["S3 versioning drift detected"] {
  input.spacelift.run.type == "DRIFT_DETECTION"
  resource := input.terraform.resource_changes[_]
  resource.type == "aws_s3_bucket_versioning"
}
```

### 8.4 Spacelift Notification Configuration

```hcl
# admin/notifications.tf
# Configure drift notifications

resource "spacelift_webhook" "drift_alerts" {
  endpoint = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  enabled  = true
  
  # Only trigger on drift detection runs
  labels = ["drift-detection"]
}

# Slack integration for drift alerts
resource "spacelift_slack_integration" "drift_channel" {
  name        = "drift-alerts"
  webhook_url = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  channel     = "#infrastructure-alerts"
  
  # Notification events
  run_state_changed = true
}
```

---

## Section 9: Troubleshooting Guide

### 9.1 Plan Shows No Changes But Drift Exists

**Symptom:** You know resources changed but `tofu plan` shows no changes.

```bash
# 1. Refresh state first
tofu refresh

# 2. Clear cached providers
rm -rf .terraform
tofu init

# 3. Check if resource is in state
tofu state list | grep resource_name

# 4. Verify provider configuration
tofu providers
```

### 9.2 State Lock Errors

**Symptom:** Error acquiring state lock

```bash
# Check who holds the lock (DynamoDB backend)
aws dynamodb scan \
  --table-name terraform-locks \
  --filter-expression "LockID = :lockid" \
  --expression-attribute-values '{":lockid":{"S":"your-state-path"}}'

# Force unlock (use with extreme caution!)
tofu force-unlock LOCK_ID

# Better: Wait for the other process to complete
```

### 9.3 Import Fails with Resource Not Found

**Symptom:** `tofu import` can't find the resource

```bash
# 1. Verify resource ID format
# S3 buckets use bucket name
tofu import aws_s3_bucket.example bucket-name

# EC2 security groups use sg-xxx ID
tofu import aws_security_group.example sg-0123456789abcdef

# 2. Check AWS region
export AWS_REGION=us-east-1
tofu import ...

# 3. Verify resource exists
aws s3api head-bucket --bucket bucket-name
```

### 9.4 Spacelift Drift Detection Not Running

**Symptom:** Scheduled drift detection not triggering

| Check | Solution |
|-------|----------|
| Stack State | Ensure stack is not paused or disabled |
| Schedule Syntax | Verify cron expression is valid |
| Cloud Integration | Confirm AWS credentials are valid |
| Stack Dependencies | Check if stack is blocked by dependency |

### 9.5 False Positive Drift Detection

**Symptom:** Plan shows changes that aren't real drift

```hcl
# 1. Provider version mismatch
# Lock provider versions in versions.tf
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "5.31.0"  # Exact version
  }
}

# 2. Lifecycle ignore_changes
resource "aws_instance" "example" {
  # Ignore changes to tags made outside OpenTofu
  lifecycle {
    ignore_changes = [tags["LastModified"]]
  }
}

# 3. Computed values changing
# Some attributes are computed on every read
# Check if the "drift" is actually expected
```

---

## Section 10: Best Practices and Next Steps

### 10.1 Drift Detection Best Practices

#### Detection

1. Schedule drift detection at least daily for production environments
2. Configure alerts for critical resources (security groups, IAM, encryption)
3. Maintain an audit log of all drift detection runs
4. Document expected drift patterns (auto-scaling, etc.)

#### Resolution

1. Always investigate root cause before resolving drift
2. Document why drift occurred and how it was resolved
3. Use lifecycle blocks for expected variability
4. Test drift resolution in non-production first

#### Prevention

1. Restrict direct access to IaC-managed resources
2. Establish clear emergency change procedures that include IaC updates
3. Train all team members on proper IaC workflows
4. Use policy-as-code to enforce compliance

### 10.2 Recommended Next Steps

Continue your learning with these advanced topics:

- [ ] Implement cross-account drift detection strategies
- [ ] Create custom OPA policies for drift governance
- [ ] Set up comprehensive alerting with PagerDuty/Slack integration
- [ ] Explore drift detection for complex resources (EKS, RDS)
- [ ] Practice incident response scenarios with drift
- [ ] Implement GitOps workflows to minimize drift opportunities

### 10.3 Lab Cleanup

Clean up the lab resources to avoid charges:

```bash
# Navigate to stack directory
cd stacks/drift-lab

# Destroy all resources
tofu destroy -auto-approve

# Verify cleanup
aws s3 ls | grep drift-lab
aws ec2 describe-security-groups --filters "Name=group-name,Values=drift-demo-sg-*"

# Remove Spacelift stack (if created)
# Via UI: Delete stack from Spacelift console
# Via OpenTofu: tofu destroy (in admin stack)
```

---

## 🎉 Congratulations!

You have completed the OpenTofu Drift Detection lab. You now know how to detect, analyze, resolve, and prevent infrastructure drift using both OpenTofu CLI and Spacelift.

---

## Quick Reference Card

### Essential Commands

```bash
# Detect drift (shows plan)
tofu plan

# Detect drift with exit code
tofu plan -detailed-exitcode
# 0 = No changes, 1 = Error, 2 = Changes/drift detected

# Refresh state from infrastructure
tofu refresh

# Apply to reconcile drift
tofu apply

# Import existing resource
tofu import <resource_type>.<name> <resource_id>

# View current state
tofu show

# List resources in state
tofu state list
```

### Drift Resolution Decision Tree

| Question | Yes Action | No Action |
|----------|------------|-----------|
| Was the change intentional? | Update IaC config | Run `tofu apply` |
| Is the change correct? | Accept and document | Revert with apply |
| Is resource in state? | Plan/apply to fix | Import first |
| Is it a security issue? | Fix immediately | Schedule remediation |

### Spacelift Drift Detection Schedule Examples

| Frequency | Cron Expression | Use Case |
|-----------|-----------------|----------|
| Every hour | `0 * * * *` | High-sensitivity production |
| Every 4 hours | `0 */4 * * *` | Standard production |
| Daily at 6 AM | `0 6 * * *` | Development environments |
| Weekly Monday 9 AM | `0 9 * * 1` | Low-change environments |

### Common Resource Import IDs

| Resource Type | Import ID Format | Example |
|---------------|------------------|---------|
| aws_s3_bucket | bucket-name | my-bucket |
| aws_security_group | sg-xxxxx | sg-0123456789 |
| aws_instance | i-xxxxx | i-0123456789 |
| aws_vpc | vpc-xxxxx | vpc-0123456789 |
| aws_iam_role | role-name | my-role |

### Key URLs

| Resource | URL |
|----------|-----|
| OpenTofu Docs | https://opentofu.org/docs |
| Spacelift Docs | https://docs.spacelift.io |
| AWS Provider | https://registry.terraform.io/providers/hashicorp/aws |
| OPA (Rego) | https://www.openpolicyagent.org/docs |

---

*© Training Materials - For authorized use only*
