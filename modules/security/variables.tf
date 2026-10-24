variable "name_prefix" {
  description = "Naming prefix. Max 15 chars so the Key Vault name stays within 24."
  type        = string

  validation {
    condition     = length(var.name_prefix) <= 15
    error_message = "name_prefix must be 15 characters or fewer (Key Vault names max out at 24)."
  }
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "purge_protection_enabled" {
  description = "Leave false in a lab so terraform destroy works. Set true in production."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
