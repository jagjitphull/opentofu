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
See main documentation below.


#Option B: Use Existing Key Pair (Flexible Approach)

#Create new key:
tofu apply -var="create_key_pair=true"

#Use existing key:
tofu apply \
  -var="create_key_pair=false" \
  -var="existing_key_pair_name=my-existing-key"
