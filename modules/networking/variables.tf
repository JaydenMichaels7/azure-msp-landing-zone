variable "name_prefix" {
  description = "Naming prefix, e.g. acme-dev."
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "address_space" {
  type    = list(string)
  default = ["10.10.0.0/16"]
}

variable "subnets" {
  description = "Map of subnet name => address prefix and NSG rules."
  type = map(object({
    address_prefix = string
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = optional(string, "*")
    })), [])
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
