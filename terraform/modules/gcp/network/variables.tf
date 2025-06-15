variable "routing_mode" {
  type    = string
  default = "REGIONAL"
}

variable "pod_ip_range" {
  type = string
}

variable "service_ip_range" {
  type = string
}

variable "public_cidr_range" {
  type = string
}

variable "private_cidr_range" {
  type = string
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
