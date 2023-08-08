# Local variables

locals {
  tags = {
    location    = "${var.location}"
    environment = "${var.environment}"
    project     = "${var.project}"
  }

  name_prefix = "${var.location_abbreviation[var.location]}-${var.environment}-${var.project}"
}

# Resource groups

resource "azurerm_resource_group" "webserver_rg" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = merge(var.tf_tags, local.tags)
}

# Network security groups and their rules

resource "azurerm_network_security_group" "webserver_nsg" {
  name                = "${local.name_prefix}-nsg"
  location            = azurerm_resource_group.webserver_rg.location
  resource_group_name = azurerm_resource_group.webserver_rg.name
  tags                = merge(var.tf_tags, local.tags)
}

# Virtual networks and their subnets

resource "azurerm_virtual_network" "webserver_vnet" {
  name                = "${local.name_prefix}-vnet"
  location            = azurerm_resource_group.webserver_rg.location
  resource_group_name = azurerm_resource_group.webserver_rg.name
  address_space       = ["10.0.0.0/26"]
  tags                = merge(var.tf_tags, local.tags)
}

resource "azurerm_subnet" "webserver_snet" {
  name                 = "${local.name_prefix}-snet"
  resource_group_name  = azurerm_resource_group.webserver_rg.name
  virtual_network_name = azurerm_virtual_network.webserver_vnet.name
  address_prefixes     = ["10.0.0.0/28"]
}

# Compute resources

resource "azurerm_public_ip" "webserver_public_ip" {
  name                = "${local.name_prefix}-webserver-public-ip"
  location            = azurerm_resource_group.webserver_rg.location
  resource_group_name = azurerm_resource_group.webserver_rg.name
  allocation_method   = "Static"
  tags                = merge(var.tf_tags, local.tags)
}

resource "azurerm_network_interface" "webserver_nic" {
  name                = "${local.name_prefix}-webserver-nic"
  location            = azurerm_resource_group.webserver_rg.location
  resource_group_name = azurerm_resource_group.webserver_rg.name
  tags                = merge(var.tf_tags, local.tags)

  ip_configuration {
    name                          = "${local.name_prefix}-public-ip-config"
    subnet_id                     = azurerm_subnet.webserver_snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.webserver_public_ip.id
  }
}

resource "random_password" "admin_pass" {
  length           = 20
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_linux_virtual_machine" "webserver_vm" {
  name                  = "${local.name_prefix}-webserver-vm"
  resource_group_name   = azurerm_resource_group.webserver_rg.name
  location              = azurerm_resource_group.webserver_rg.location
  size                  = var.vm_sku
  admin_username        = var.admin_user
  admin_password        = random_password.admin_pass.result
  network_interface_ids = [azurerm_network_interface.webserver_nic.id]
  tags                  = merge(var.tf_tags, local.tags)

  admin_ssh_key {
    username   = var.admin_user
    public_key = file(var.ssh_pubkey_path)
  }

  os_disk {
    name                 = "${local.name_prefix}-webserver-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
