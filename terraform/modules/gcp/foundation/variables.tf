variable "project_name" {
  type = string
}

variable "billing_account" {
  type = string
}

variable "deletion_policy" {
  type    = string
  default = "DELETE"
}
