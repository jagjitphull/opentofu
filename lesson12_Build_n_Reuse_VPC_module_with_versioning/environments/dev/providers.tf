provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "VPC-Module-Lab"
      Environment = "dev"
      ManagedBy   = "OpenTofu"
    }
  }
}