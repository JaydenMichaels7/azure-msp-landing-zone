output "vm_id" {
  value = try(azurerm_linux_virtual_machine.this[0].id, null)
}

output "vm_name" {
  value = try(azurerm_linux_virtual_machine.this[0].name, null)
}

output "private_ip" {
  value = try(azurerm_network_interface.this[0].private_ip_address, null)
}
