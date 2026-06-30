# Linux VMs wrapper: fans var.details.count out into that many identical
# linux_vm instances, naming each <name>-<index> and tagging it with its node
# index. All other settings pass straight through to the linux_vm module.

module "linux_vm" {
  source = "./linux_vm"

  count = var.details.count

  name                       = "${var.name}-${count.index}"
  location                   = var.location
  rg_name                    = var.rg_name
  subnet_id                  = var.subnet_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  sku                        = var.details.sku
  admin_ssh_public_key_path  = var.details.admin_ssh_public_key_path
  public_ip                  = var.details.public_ip
  allocation_method          = var.details.ip_allocation
  public_ip_sku              = var.details.public_ip_sku
  data_disk                  = var.details.data_disk
  data_disk_size             = var.details.data_disk_size
  tags                       = merge(var.tags, { "node" = tostring(count.index) })
  os_image                   = var.details.os_image
}
