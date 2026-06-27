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

  # Access (admin username and password are generated per VM)
  admin_ssh_public_key_path = lookup(var.details, "admin_ssh_public_key_path", "~/.ssh/id_rsa.pub")

  # Optional public IP
  public_ip         = lookup(var.details, "public_ip", false)
  allocation_method = lookup(var.details, "ip_allocation", "Static")
  public_ip_sku     = lookup(var.details, "public_ip_sku", "Standard")

  # Optional data disk
  data_disk      = lookup(var.details, "data_disk", false)
  data_disk_size = lookup(var.details, "data_disk_size", 0) # GB

  # Tags
  tags = merge(var.tags, { "node" = tostring(count.index) })

  # Optional pinned OS image override
  os_image = lookup(var.details, "os_image", null)
}
