resource "azurerm_virtual_network" "vnet" {
  name = "skhan-test-vnet"
    address_space = ["10.1.10.0/16"]
      location = "eastus"
        resource_group_name = azurerm_resource_group.rg.name
}