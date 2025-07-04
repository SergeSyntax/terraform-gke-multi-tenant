variable "routing_mode" {
  type    = string
  default = "REGIONAL"
}

# "PREMIUM", "STANDARD" # performance effect cost
variable "network_tier" {
  type    = string
  default = "PREMIUM"
}

variable "project_id" {
  type = string
}

variable "project_name" {
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
