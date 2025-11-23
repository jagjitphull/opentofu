# Data sources for dynamic information

# Get available availability zones in current region
data "aws_availability_zones" "available" {
  state = "available"

  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Get latest Amazon Linux 2023 AMI (Recommended - Most Reliable)
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

# Alternative: Get latest Ubuntu AMI (Uncomment if you prefer Ubuntu)
# Note: If using Ubuntu, change references from data.aws_ami.amazon_linux.id 
# to data.aws_ami.ubuntu.id throughout the configuration
# data "aws_ami" "ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"]
#   
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#   }
#   
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}