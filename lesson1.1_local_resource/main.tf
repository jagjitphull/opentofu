terraform {
  required_version = ">= 1.7.0" # or the version you use for OpenTofu
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "local" {}

resource "local_file" "hello" {
  filename = "${path.module}/hello-opentofu.txt"
  content  = "Hello, OpenTofu! Managed by IaC."
}
