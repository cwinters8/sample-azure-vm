resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# This doesn't actually work to connect to the VM.
# Error when trying to connect: "There was an error in requesting a session. Please try again."
# Error in the dev console: "Failed to get a data pod from the brain for bastion - omnibrain.centralus.bastionglobal.azure.com"
# Not sure if this is a bug in Azure or if something is misconfigured.
resource "azurerm_bastion_host" "bastion" {
  name                = "${local.name}-bastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Developer"
  virtual_network_id  = azurerm_virtual_network.main.id
}
