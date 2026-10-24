variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "identity_id" {
  description = "User-assigned managed identity to attach to the VM."
  type        = string
}

variable "admin_ssh_public_key" {
  description = "Public key only. The private key never touches Terraform or GitHub."
  type        = string
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "os_disk_size_gb" {
  description = "64 GB (P6) is the managed-disk size older free-account guides say is covered. Verify in Cost Management."
  type        = number
  default     = 64
}

variable "enabled" {
  description = "Set false to remove the VM (and its cost) without touching the rest."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
