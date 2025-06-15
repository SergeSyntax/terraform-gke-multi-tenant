variable "project_id" {
  type = string
}

variable "total_min_node_count" {
  type    = number
  default = 1
}

variable "total_max_node_count" {
  type    = number
  default = 5
}

variable "project_name" {
  type = string
}

variable "network_self_link" {
  description = "VPC network where the GKE cluster will be deployed"
  type        = string
}

variable "subnetwork_self_link" {
  description = "Subnet where GKE nodes will be provisioned"
  type        = string
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "reserved for GKE's managed control plane can't overlap with pods ip and service ip"
}

variable "cluster_secondary_range_name" {
  type = string
}

variable "services_secondary_range_name" {
  type = string
}

variable "node_machine_type" {
  type    = string
  default = "e2-medium"
}
