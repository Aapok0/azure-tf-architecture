# (Optional) Public IP

resource "azurerm_public_ip" "vm_pip" {
  count               = var.public_ip ? 1 : 0
  name                = "${var.name_prefix}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.allocation_method
  tags                = var.tags
}

# Network interface

## Non-public
resource "azurerm_network_interface" "vm_nic" {
  count               = var.public_ip ? 0 : 1
  name                = "${var.name_prefix}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "${var.name_prefix}-pip-conf"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

## Public
resource "azurerm_network_interface" "vm_nic_public" {
  count               = var.public_ip ? 1 : 0
  name                = "${var.name_prefix}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "${var.name_prefix}-pip-conf"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip[count.index].id
  }
}

# Network security group, security rules and association

resource "azurerm_network_security_group" "nsg" {
  count               = var.nsg ? 1 : 0
  name                = "${var.name_prefix}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "nsg_rule" {
  for_each                    = var.nsg_rules
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[0].name

  name                         = each.value["name"]
  priority                     = each.value["priority"]
  direction                    = each.value["direction"]
  access                       = each.value["access"]
  protocol                     = each.value["protocol"]
  source_address_prefixes      = lookup(each.value, "source_address_prefixes", null)
  source_address_prefix        = lookup(each.value, "source_address_prefix", null)
  source_port_ranges           = lookup(each.value, "source_port_ranges", null)
  source_port_range            = lookup(each.value, "source_port_range", null)
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefix", null)
  destination_port_ranges      = lookup(each.value, "destination_port_ranges", null)
  destination_port_range       = lookup(each.value, "destination_port_range", null)
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = var.public_ip ? azurerm_network_interface.vm_nic_public[0].id : azurerm_network_interface.vm_nic[0].id
  network_security_group_id = azurerm_network_security_group.nsg[0].id
}

# Random password for admin user

resource "random_password" "admin_pass" {
  length           = 20
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Virtual machine

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "${var.name_prefix}-vm"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_sku
  admin_username        = var.admin_user
  admin_password        = random_password.admin_pass.result
  network_interface_ids = var.public_ip ? [azurerm_network_interface.vm_nic_public[0].id] : [azurerm_network_interface.vm_nic[0].id]
  tags                  = merge(var.tags, var.service_tag)

  admin_ssh_key {
    username   = var.admin_user
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "${var.name_prefix}-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = templatefile("${path.module}/ssh-config-apply.tpl", {
      name         = self.name
      host         = "${self.tags.project}-web"
      ip           = self.public_ip_address
      user         = self.admin_username
      identityfile = "~/.ssh/id_rsa"
      service      = self.tags.service
    })
    interpreter = ["bash", "-c"]
    on_failure  = continue
  }

  provisioner "local-exec" {
    when = destroy
    command = templatefile("${path.module}/ssh-config-destroy.tpl", {
      name = self.name
      ip   = self.public_ip_address
    })
    interpreter = ["bash", "-c"]
    on_failure  = continue
  }
}

# (Optional) Data disk

resource "azurerm_managed_disk" "project_vm_disk" {
  count                = var.data_disk ? 1 : 0
  name                 = "${var.name_prefix}-vm-disk"
  location             = var.location
  resource_group_name  = var.resource_group_name
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
