locals {
  admin_username = "ops"
}

resource "azurerm_network_interface" "vm" {
  name                = "${local.name}-vm-nic"
  location            = local.location
  resource_group_name = local.rg_name

  ip_configuration {
    name                          = "${local.name}-vm-ip"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "${local.name}-vm"
  location                        = local.location
  resource_group_name             = local.rg_name
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

# Secrets may fail to create if the AD role assignment isn't up to date locally.
# I had to `az logout && az login` to get it to work.
resource "azurerm_key_vault_secret" "vm_private_key" {
  key_vault_id = azurerm_key_vault.main.id
  name         = "${local.name}-vm-ssh-private-key"
  value        = tls_private_key.vm.private_key_pem

  depends_on = [
    azuread_group_member.my_user,
    azurerm_role_assignment.keyvault_admin,
  ]
}

resource "azurerm_key_vault_secret" "vm_public_key" {
  key_vault_id = azurerm_key_vault.main.id
  name         = "${local.name}-vm-ssh-public-key"
  value        = tls_private_key.vm.public_key_openssh

  depends_on = [
    azuread_group_member.my_user,
    azurerm_role_assignment.keyvault_admin,
  ]
}

resource "azurerm_network_security_group" "vm" {
  name                = "${local.name}-vm-nsg"
  location            = local.location
  resource_group_name = local.rg_name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "168.63.129.16/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "168.63.129.16/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutbound"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.vm.id
}
