variable "region" {
  type    = string
  default = "us-central1"
}

variable "project_name" {
  type = string
}

variable "billing_account" {
  type = string
}

variable "main_cidr" {
  type        = string
  description = "Main CIDR block for the VPC. Recommended: /19 for dev (8K IPs), /17 for prod (32K IPs)"

  validation {
    condition     = can(cidrhost(var.main_cidr, 0))
    error_message = "Must be a valid CIDR block (e.g., '10.1.0.0/19')."
  }
}
