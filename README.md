# Azure Terraform architecture for my personal projects

The main purpose of this Terraform architecture is to deploy and manage the Azure resources I want to use for my personal projects. Currently main one is my homepage, which I want to host on a virtual machine with Nginx. At some point I will move on to using an app service or a container, but for now I want to work on my skills with Ansible and Nginx.

The way I arranged the modules and wrote them is a compromise between of the needs of my project and wanting to write scalable code, that could fit into a larger architecture. Scalability and reusability could be improved in many ways, but I don't want to make things too complicated. This code still needs to serve my own purposes. For example, I have made some restrictions for the variables, which would need to be removed to make the code more reusable for others.

### Related repositories

- [Homepage version 1](https://github.com/Aapok0/homepage)
- [Homepage version 2](https://github.com/Aapok0/homepage-bulma)
- [Ansible for Nginx webserver](https://github.com/Aapok0/homepage-webserver-ansible)

## Structure

Repository has the following directories and files:

- **compute/** &rarr; compute resource modules
  - **virtual_machine** &rarr; module to create a virtual machine
    - **main.tf**
    - **outputs.tf**
    - **variables.tf**
    - **ssh-config-apply** &rarr; script to add host information to ssh config file
    - **ssh-config-destroy** &rarr; script to remove host information from ssh config file
- **general/** &rarr; general resource modules
  - **budget/** &rarr; module to create a budget
    - **main.tf**
    - **variables.tf**
  - **networks_watcher/** &rarr; module to create a network watcher
    - **main.tf**
    - **variables.tf**
- **policy/** &rarr; policy assignment modules
  - **location/** &rarr; module to create allowed locations policy
    - **main.tf**
    - **variables.tf**
  - **tags/** &rarr; module to create required and inherited tags policy
    - **rg_tags/** &rarr; submodule for the resource group scope
      - **main.tf**
      - **variables.tf**
    - **sub_tags/** &rarr; submodule for the subscription scope
      - **main.tf**
      - **variables.tf**
    - **main.tf**
    - **variables.tf**
  - **vm_sku** &rarr; module to create allowed virtual machine SKUs policy
    - **main.tf**
    - **variables.tf**
- **project/** &rarr; module to create the main wrapper for a project
  - **main.tf**
  - **outputs.tf**
  - **variables.tf**
- **data.tf** &rarr; file to call existing data from Azure
- **main.tf** &rarr; main file to call modules and other needed resources
- **outputs.tf** &rarr; main outputs that show, when running apply
- **terraform.tf** &rarr; terraform and provider versions
- **variables.tf** &rarr; file that defines variables

The file **terraform.tfvars** should also be created to pass sensitive variables. It is not pushed into this repository. Currently the following variables are passed with it.

```terraform
contact_emails    = ["email1@invalid.com", "email2@invalid.com"]
ssh_addr_prefixes = ["123.123.123.123", "111.111.111.111"]
admin_user        = "adminuser"
```

## How to use

### Calling the modules

Modules are to generally be called in the **main.tf** or other **.tf** files in the root module. Source of the modules will reflect that. The path needs to be changed, if the modules are called elsewhere.

#### General

Budget:

```terraform
data "azurerm_subscription" "current" {} # Existing subscription for this example to work

module "budget_example" {
  source = "./general/budget"

  # Scope of the budget
  scope    = "sub" # rg for resource group, sub for subscription or mg for management group
  scope_id = data.azurerm_subscription.current.id # rg or sub id
  name     = "${data.azurerm_subscription.current.display_name}-budget" # Name for the resource

  # General settings
  amount     = 10 # Budget limit in dollars
  time_grain = "Monthly" # BillingAnnual, BillingMonth, BillingQuarter, Annually, Monthly or Quarterly
  start_date = "2023-08-01T00:00:00Z" # Needs to be in this format
  end_date   = "2025-08-01T00:00:00Z" # Needs to be in this format

  # Notification settings
  threshold_alert = true # Whether threshold alert is enabled
  threshold       = 75.0 # Threshold percentage for alert
  forecast_alert  = true # Whether forecast alert for exceeding 100% is enabled
  contact_emails  = var.contact_emails # List of emails that are alerted (can be sensitive so better to use variable)
  contact_roles   = ["Owner"] # Roles that are alerted
}
```

Network Watcher:

```terraform
data "azurerm_subscription" "current" {} # Existing subscription for this example to work

module "nw_example" {
  source = "./general/network_watcher"

  # Name and location
  name     = "we-nwatcher" # Name for the resource
  location = "westeurope" # Azure region for the resource

  # Tags for everything in this architecture deployed with Terraform
  tf_tags = { # Tags that are added when deploying with Terraform
    "source" = "terraform"
  }
}
```

#### Policy

Location:

```terraform
data "azurerm_subscription" "current" {} # Existing subscription for this example to work

module "location_example" {
  source = "./policy/location"

  # Scope of the policies
  scope      = "sub" # rg for resource group or sub for subscription 
  scope_id   = data.azurerm_subscription.current.id # rg or sub id
  scope_name = data.azurerm_subscription.current.display_name # Name for the scope (used to generate resource name)

  # Locations
  location_list = "[\"westeurope\", \"northeurope\"]" # List of allowed Azure regions in this format
}
```

Tags:

```terraform
data "azurerm_subscription" "current" {} # Existing subscription for this example to work

module "tags_example" {
  source = "./policy/tags"

  # Scope of the policies
  scope      = "sub" # rg for resource group or sub for subscription 
  scope_id   = data.azurerm_subscription.current.id # rg or sub id
  scope_name = data.azurerm_subscription.current.display_name # Name for the scope (used to generate resource name)
  location   = "westeurope" # Azure region for the inherited tags policy

  # Required in all resources
  required_tags = {
    "owner" = "Eddy Example"
  }

  # Required in all resource groups
  required_rg_tags = {
    "owner"       = "Eddy Example"
    "environment" = "tst"
    "location"    = "we"
    "project"     = "example"
  }

  # Inherited from resource groups
  inherited_tags = {
    "environment" = "tst"
    "location"    = "we"
    "project"     = "example"
  }
}
```

VM SKU:

```terraform
data "azurerm_subscription" "current" {} # Existing subscription for this example to work

module "sku_example" {
  source = "./policy/vm_sku"

  # Scope of the policies
  scope      = "sub" # rg for resource group or sub for subscription 
  scope_id   = data.azurerm_subscription.current.id # rg or sub id
  scope_name = data.azurerm_subscription.current.display_name # Name for the scope (used to generate resource name)

  # Sizes
  sku_list = "[\"Standard_B1s\", \"Standard_B1ms\"]" # List of allowed VM SKUs in this format
}
```

#### Project

```terraform
module "project_example" {
  source = "./project"

  # General settings
  location    = "westeurope" # Azure region for the project (restricted to northeurope, norwayeast, swedencentral and westeurope in variables)
  environment = "tst" # Project environment (dev, tst or prd)
  project     = "example" # Name for the project

  # Virtual network
  virtual_network = ["10.0.0.0/26"] # List of address spaces in CIDR
  subnets         = { # Map of subnets in CIDR
    subnet1 = ["10.0.0.0/28"]
    subnet2 = ["10.0.0.16/28"]
  }

  # Addresses for SSH access
  ssh_addr_prefixes = var.ssh_addr_prefixes # List of IP addresses that should have SSH access (can be sensitive so better to use a variable)

  # Tags for everything in this architecture deployed with Terraform
  tf_tags = { # Tags that are added when deploying with Terraform
    "source" = "terraform"
  }
}
```

#### Compute

Virtual machine:

- *Note: The module currently has scripts that add and remove host information to and from ssh config and an Ansible inventory to automate my development workflow.*

```terraform
module "vm_example" {
  source = "./compute/virtual_machine"

  # Dependencies and info
  name_prefix         = "${module.project_example.name_prefix_out}-example" # Prefix to use in all resource names in the module (project output used here)
  location            = module.homepage_prd.rg_location_out # Azure region for the resources (project output used here)
  resource_group_name = module.homepage_prd.rg_name_out # Resource group name for the resources (project output used here)
  subnet_id           = module.homepage_prd.subnets_out["subnet1"].id # Subnet ID for the virtual machine (project output used here)

  # Virtual machine size
  vm_sku = "Standard_B1ls" 

  # Access
  admin_user        = var.admin_user # Username for the admin in the virtual machine (can be sensitive so better to use a variable)
  ssh_addr_prefixes = var.ssh_addr_prefixes # List of IP addresses that should have SSH access (can be sensitive so better to use a variable)

  # Optional public IP
  public_ip         = true # Whether the virtual machine has a public IP or not
  allocation_method = "Static" # Static or Dynamic IP

  # Optional network security group
  nsg       = true # Whether network security group is created or not
  nsg_rules = { # Rules to be added to the network security group
    ssh = {
      name                       = "AllowSSHInBound" # Name for the rule
      priority                   = 100 # Priority of the rule (has to be unique in nsg, lower -> higher priority)
      direction                  = "Inbound" # Direction of traffix in the rule
      access                     = "Allow" # Whether the rule will Allow or Deny traffic
      protocol                   = "Tcp" # Protocol of the traffic in the rule (Tcp, Udp, Icmp, Esp, Ah or * (=any protocol))

      # Use a list of strings with plural attributes and a string with singular ones ("*" for any)
      source_address_prefixes    = var.ssh_addr_prefixes
      source_port_range          = "*"
      destination_address_prefix = "10.0.0.0/28"
      destination_port_range     = "22"
    }
    web = {
      name                      = "AllowInternetInBound"
      priority                  = 110
      direction                 = "Inbound"
      access                    = "Allow"
      protocol                  = "Tcp"
      source_address_prefixes   = ["123.123.123.123", "111.111.111.111"]
      source_port_range         = "*"
      destination_address_range = "*"
      destination_port_ranges   = ["80", "443"]
    }
  }

  # Optional data disk
  data_disk      = false # Whether the virtual machine has a data disk
  data_disk_size = 0 # Data disk size in GB

  # Tags
  tags        = merge(var.tf_tags, module.homepage_prd.tags_out) # Map of general tags for the  resources (project output and variable used here)
  service_tag = { "service" = "nginx" } # Service tag for the virtual machine
}
```

### Deploying

```bash
# Requires Azure CLI and Terraform (required version 1.5.4 or any patch above that)

# Clone repository and configure to your liking

# Login to your Azure account and switch to preferred subscription, if you have multiple.
az login
az account set --subscription <name-or-id>

# Initialize terraform (in the root of the repository)
terraform init

# Optionally format the code and validate, that it works
terraform fmt
terraform validate

# Create a plan (I prefer using a file)
terraform plan -out tfplan

# If everything looks good, apply to deploy to Azure
terraform apply tfplan
```
