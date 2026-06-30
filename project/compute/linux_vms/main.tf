# Linux VMs wrapper: fans var.details.count out into that many identical
# linux_vm instances, naming each <name>-<index> and tagging it with its node
# index. All other settings pass straight through to the linux_vm module.

module "linux_vm" {
  source = "./linux_vm"

  count = var.details.count

  # Dependencies and info
  name      = "${var.name}-${count.index}"
  location  = var.location
  rg_name   = var.rg_name
  subnet_id = var.subnet_id

  # Optional log collection
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Virtual machine size
  sku = var.details.sku

  # Access (admin username and password are generated per VM)
  admin_ssh_public_key_path = var.details.admin_ssh_public_key_path

  # Optional public IP
  public_ip         = var.details.public_ip
  allocation_method = var.details.ip_allocation
  public_ip_sku     = var.details.public_ip_sku

  # Optional data disk
  data_disk      = var.details.data_disk
  data_disk_size = var.details.data_disk_size # GB

  # Tags
  tags = merge(var.tags, { "node" = tostring(count.index) })

  # Optional pinned OS image override
  os_image = var.details.os_image
}
