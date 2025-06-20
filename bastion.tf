resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "bastion" {
  name                = "${local.name}-bastion-ip"
  location            = local.location
  resource_group_name = local.rg_name
  allocation_method   = "Static"
}

# A Developer SKU doesn't work to connect to the VM.
resource "azurerm_bastion_host" "bastion" {
  name                = "${local.name}-bastion"
  location            = local.location
  resource_group_name = local.rg_name
  sku                 = "Basic"

  ip_configuration {
    name                 = "${local.name}-bastion-ip"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}
