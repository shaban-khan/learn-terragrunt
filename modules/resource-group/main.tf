resource "azurerm_resource_group" "rsg" {
  name     = var.resource_group_name
  location = var.location
}