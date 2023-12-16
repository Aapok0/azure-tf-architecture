# Linux VM

module "linux_vm" {
  source = "./linux_vm"

  count = lookup(var.details, "count", 1)

  # Dependencies and info
  name      = "${var.name}-${count.index}"
  location  = var.location
  rg_name   = var.rg_name
  subnet_id = var.subnet_id

  # Virtual machine size
  sku = lookup(var.details, "sku", "Standard_B1ls")

  # Access
  admin_user        = lookup(var.details, "admin_user", "admin")

  # Optional public IP
  public_ip         = lookup(var.details, "public_ip", false)
  allocation_method = lookup(var.details, "ip_allocation", "Static")

  # Optional data disk
  data_disk      = lookup(var.details, "data_disk", false)
  data_disk_size = lookup(var.details, "data_disk_size", 0) # GB

  # Tags
  tags = merge(var.tags, { "node" = "${count.index}" })
}
