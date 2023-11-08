output "ILBID" {
  value = azurerm_lb.app_lb.id
}

output "BackendPoolID" {
  value = azurerm_lb_backend_address_pool.app_lb_backend_address_pool.id
}

output "NIC" {
  value = azurerm_network_interface.app_vm_nic.id
}

# output "StorageAccount" {
#   value = azurerm_storage_account.bootdiag_storage_account.id
# }

output "VMID" {
  value = azurerm_virtual_machine.azureVM.id
}
