# Already existing data from Azure

data "azurerm_subscription" "current" {}

# Subscription scoped resources

## Budget - subscription
module "sub_budget" {
  source = "./general/budget"

  scope = "sub"
  id    = data.azurerm_subscription.current.id
  name  = "${data.azurerm_subscription.current.display_name}-budget"

  amount     = 10
  time_grain = "Monthly"
  start_date = "2023-08-01T00:00:00Z"
  end_date   = "2025-08-01T00:00:00Z"

  threshold_alert = true
  threshold       = 75.0
  forecast_alert  = true

  contact_emails = var.contact_emails
  contact_roles  = ["Owner"]
}

## Network watcher - Sweden Central
module "sdc_nwatcher" {
  source = "./general/network_watcher"

  name     = "${var.location_abbreviation[var.location]}-nwatcher"
  location = var.location

  tf_tags = var.tf_tags
}

# Projects

## Homepage production

### Base resources
module "homepage_prd" {
  source = "./project"

  # General settings
  location    = "swedencentral"
  environment = "prd"
  project     = "homepage"

  # Virtual network
  virtual_network = ["10.0.0.0/26"]
  subnets         = { subnet1 = ["10.0.0.0/28"] }

  # Addresses for SSH access
  ssh_addr_prefixes = var.ssh_addr_prefixes

  # Tags for everything in this architecture deployed with Terraform
  tf_tags = var.tf_tags
}

### Webserver
module "webserver_vm" {
  source = "./compute/virtual_machine"

  name_prefix         = "${module.homepage_prd.name_prefix}-webserver"
  location            = module.homepage_prd.location
  resource_group_name = module.homepage_prd.name
  subnet_id           = module.homepage_prd.subnets["subnet1"].id

  vm_sku            = "Standard_B1ls"
  admin_user        = var.admin_user
  ssh_addr_prefixes = var.ssh_addr_prefixes

  public_ip         = true
  allocation_method = "Static"

  data_disk      = false
  data_disk_size = 0 # GB

  tags = merge(var.tf_tags, module.homepage_prd.tags)
}

resource "azurerm_network_security_group" "webserver_nsg" {
  name                = "${module.homepage_prd.name_prefix}-webserver-nsg"
  location            = module.homepage_prd.location
  resource_group_name = module.homepage_prd.name
  tags                = merge(var.tf_tags, module.homepage_prd.tags)

  security_rule {
    name                       = "AllowSSHInBound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefixes    = var.ssh_addr_prefixes
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "22"
  }

  security_rule {
    name                       = "AllowInternetInBound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_ranges    = ["80", "443"]
  }
}

resource "azurerm_network_interface_security_group_association" "webserver_nsg_assoc" {
  network_interface_id      = module.webserver_vm.nic_id_out
  network_security_group_id = azurerm_network_security_group.webserver_nsg.id
}
