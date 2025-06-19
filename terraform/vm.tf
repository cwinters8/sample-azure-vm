locals {
  admin_username = "ops"
}

resource "azurerm_network_interface" "vm" {
  name                = "${local.name}-vm-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${local.name}-vm-ip"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "${local.name}-vm"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  network_interface_ids           = [azurerm_network_interface.vm.id]
  size                            = "Standard_B2ts_v2"
  admin_username                  = local.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = local.admin_username
    public_key = tls_private_key.vm.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "tls_private_key" "vm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# This may fail to create if the AD role assignment isn't up to date locally.
# I had to `az logout && az login` to get it to work.
resource "azurerm_key_vault_secret" "vm" {
  key_vault_id = azurerm_key_vault.main.id
  name         = "${local.name}-vm-ssh-key"
  content_type = "application/json"
  value = jsonencode({
    public_key      = tls_private_key.vm.public_key_openssh
    private_key_pem = tls_private_key.vm.private_key_pem
  })

  depends_on = [
    azuread_group_member.my_user,
    azurerm_role_assignment.keyvault_admin,
  ]
}

resource "azurerm_network_security_group" "vm" {
  name                = "${local.name}-vm-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    destination_port_range     = "22"
    source_address_prefix      = "168.63.129.16/32"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowRDP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3389"
    destination_port_range     = "3389"
    source_address_prefix      = "168.63.129.16/32"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.vm.id
}
