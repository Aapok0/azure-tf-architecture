variable "name" {
  type        = string
  description = "Name prefix for all resources in the module."
}

variable "location" {
  type        = string
  description = "Azure region resource group or resource is located in."
}

variable "rg_name" {
  type        = string
  description = "Resource group name virtual machine is in."
}

variable "subnet_id" {
  type        = string
  description = "ID of the virtual machine's subnet."
}

variable "sku" {
  type        = string
  description = "Size of the virtual machine: Standard_B1ls, Standard_B1s or Standard_B1ms."
  default     = "Standard_B1ls"

  validation {
    condition = contains(
      ["Standard_B1ls", "Standard_B1s", "Standard_B1ms", "Standard_B2s"],
      var.sku
    )
    error_message = "Allowed virtual machine SKUs are Standard_B1ls, Standard_B1s, Standard_B1ms and Standard_B2s."
  }
}

variable "admin_ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key for the VM admin user (~ expands to home). Azure Linux VMs support RSA keys only, not ed25519."
  default     = "~/.ssh/id_rsa.pub"
}

variable "public_ip" {
  type        = bool
  description = "Whether a public ip is created for the virtual machine: true or false."
}

variable "allocation_method" {
  type        = string
  description = "Public IP allocation method: Static or Dynamic. Standard SKU requires Static."

  validation {
    condition = contains(
      ["Static", "Dynamic"],
      var.allocation_method
    )
    error_message = "Allowed allocation methods are Static and Dynamic."
  }
}

variable "public_ip_sku" {
  type        = string
  description = "Public IP SKU. Standard is required for new addresses. If an existing Basic IP is in state, set Basic until you run: az network public-ip update -g <rg> -n <pip-name> --sku Standard"
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.public_ip_sku)
    error_message = "public_ip_sku must be Basic or Standard."
  }

  validation {
    condition = (
      var.public_ip_sku == "Basic" ||
      var.allocation_method == "Static"
    )
    error_message = "Standard SKU public IPs require allocation_method Static."
  }
}

variable "data_disk" {
  type        = bool
  description = "Whether a data disk is created for virtual machine or not: true or false."
}

variable "data_disk_size" {
  type        = number
  description = "Size of data disk in gigabytes."
}

variable "tags" {
  type        = map(string)
  description = "Tags to be added to all resources in the module."
}

variable "os_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "Pinned Ubuntu image (offer ubuntu-24_04-lts, sku server). Override per VM via os_image in project.auto.tfvars. List versions: az vm image list --publisher Canonical --offer ubuntu-24_04-lts --sku server --location <region> --all -o table — use a version from server rows only."
  default     = null
}
