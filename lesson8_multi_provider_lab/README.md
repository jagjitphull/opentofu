# Multi-Provider Lab: Providers, Resources & Data Sources

## Overview
This lab demonstrates:
- Multiple provider configuration (AWS + Random)
- Data sources for dynamic infrastructure queries
- Implicit and explicit resource dependencies
- Provider version constraints
- Output values from multiple sources

## What This Lab Creates
1. Random ID for unique naming
2. Random password for demonstration
3. Security group with HTTP/SSH access
4. EC2 instance with Amazon Linux 2023
5. Elastic IP attached to instance
6. Web server accessible via HTTP

## Deployment Instructions

## Step 1: Initialize the Project
# Create project directory
mkdir multi-provider-lab
cd multi-provider-lab

# Create all files (versions.tf, variables.tf, etc.)
# Contents are in the files provided on github

# Initialize OpenTofu (downloads providers)
tofu init

## Step 2:Validate Configuration
tofu validate

## Step 3: Preview Changes
tofu plan

tofu plan -var="aws_region=us-east-1" -var="environment=dev" -var="create_key_pair=true".......

## Step 4: Apply the Deployment
tofu apply

## Step 5: Verify the Deployment and Outputs, Inspect Data Sources.
tofu output
tofu output instance_information
tofu output generated_password
tofu output connection_instructions 
tofu output ami_information
tofu output account_information
tofu output vpc_information
tofu output availability_zones
tofu output server_suffix
tofu output security_group_id

## Step 6: Test Deployment
# Get the public IP
PUBLIC_IP=$(tofu output -raw instance_information | grep -oP 'public_ip\s*=\s*"\K[^"]+')

# Test HTTP connection (wait 1-2 minutes for web server to start)
curl http://$PUBLIC_IP

# Or open in browser

## Step 7: Understand the Deployment, dependencies, outputs, data sources, etc.
# View dependency graph
tofu graph | dot -Tpng > graph.png

# Or use tofu show to see the state
tofu show

## Step 8: Clean Up
# Destroy the resources
tofu destroy



#Key Pair Name: jp_rsa_key generate locally and uploaded to aws create key pair options and then on command line with tofu command to associate with instance.

tofu apply -var="key_pair_name=jp_rsa_key"