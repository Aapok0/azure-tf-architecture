# Linux VM and its dependent resources

locals {
  default_os_image = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "24.04.202606060"
  }
  os_image = var.os_image != null ? var.os_image : local.default_os_image
}

## (Optional) Public IP

resource "azurerm_public_ip" "vm_pip" {
  count               = var.public_ip ? 1 : 0
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = var.allocation_method
  tags                = var.tags
}

## Network interface

### Non-public

resource "azurerm_network_interface" "vm_nic" {
  count               = var.public_ip ? 0 : 1
  name                = "${var.name}-nic"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  ip_configuration {
    name                          = "${var.name}-pip-conf"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

### Public

resource "azurerm_network_interface" "vm_nic_public" {
  count               = var.public_ip ? 1 : 0
  name                = "${var.name}-nic"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  ip_configuration {
    name                          = "${var.name}-pip-conf"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip[count.index].id
  }
}

## Random admin credentials

resource "random_string" "admin_user" {
  length  = 10
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  admin_user = "u${random_string.admin_user.result}"
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

## Virtual machine

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.name
  resource_group_name   = var.rg_name
  location              = var.location
  size                  = var.sku
  admin_username        = local.admin_user
  admin_password        = random_password.admin_pass.result
  network_interface_ids = var.public_ip ? [azurerm_network_interface.vm_nic_public[0].id] : [azurerm_network_interface.vm_nic[0].id]
  tags                  = merge(var.tags)

  admin_ssh_key {
    username   = local.admin_user
    public_key = file(pathexpand(var.admin_ssh_public_key_path))
  }

  os_disk {
    name                 = "${var.name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = local.os_image.publisher
    offer     = local.os_image.offer
    sku       = local.os_image.sku
    version   = local.os_image.version
  }
}

## (Optional) Data disk

resource "azurerm_managed_disk" "project_vm_disk" {
  count                = var.data_disk ? 1 : 0
  name                 = "${var.name}-disk"
  location             = var.location
  resource_group_name  = var.rg_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "project_disk_att" {
  count              = var.data_disk ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.project_vm_disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = "1"
  caching            = "ReadWrite"
}
