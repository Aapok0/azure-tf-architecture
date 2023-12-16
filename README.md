# Azure Terraform architecture for my personal projects

The main purpose of this Terraform architecture is to deploy and manage the Azure resources I want to use for my personal projects. Currently main one is my homepage, which I want to host on a virtual machine with Nginx. At some point I will move on to using an app service or a container, but for now I want to work on my skills with Ansible and Nginx.

The way I arranged the modules and wrote them is a compromise between of the needs of my project and wanting to write scalable code, that could fit into a larger architecture. Scalability and reusability could be improved in many ways, but I don't want to make things too complicated. This code still needs to serve my own purposes. For example, I have made some restrictions for the variables, which would need to be removed to make the code more reusable for others.

### Related repositories

- [Homepage version 1](https://github.com/Aapok0/homepage)
- [Homepage version 2](https://github.com/Aapok0/homepage-bulma)
- [Ansible for Nginx webserver](https://github.com/Aapok0/homepage-webserver-ansible)

## Structure

Repository has the following directories and files:

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
  - **compute/** &rarr; compute resource modules
    - **linux_vms/** &rarr; module to create linux virtual machines
      - **linux_vm/** &rarr; module to create a single linux virtual machine
          - **main.tf**
          - **outputs.tf**
          - **variables.tf**
          - **ansible-inventory-apply.bash** &rarr; script to add host information to Ansible inventory
          - **ansible-inventory-destroy.bash** &rarr; script to remove host information from Ansible inventory
          - **ssh-config-apply** &rarr; script to add host information to ssh config file
          - **ssh-config-destroy** &rarr; script to remove host information from ssh config file
      - **subnet/** &rarr; module to create subnet, network security group and security rules
        - **main.tf**
        - **outputs.tf**
        - **variables.tf**
      - **main.tf**
      - **outputs.tf**
      - **variables.tf**
- **data.tf** &rarr; file to call existing data from Azure
- **main.tf** &rarr; main file to call modules and other needed resources
- **outputs.tf** &rarr; main outputs that show, when running apply
- **terraform.tf** &rarr; terraform and provider versions
- **variables.tf** &rarr; file that defines variables

The files **budget.auto.tfvars** and **project.auto.tfvars** should also be created to pass sensitive variables and a project variable. They are not pushed into this repository.

## How to use

### Configuration

Modules are to generally be called in the **main.tf** or other **.tf** files in the root module. Source of the modules will reflect that. Project module has submodules, which it calls itself inside the module. The path needs to be changed, if the modules are called elsewhere.

#### General

Budget - main.tf:

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

Budget - budget.auto.tfvars

```terraform
contact_emails = ["email1@invalid.com", "email2@invalid.com"]
```

Network Watcher - main.tf:

```terraform
data "azurerm_subscription" "current" {} # Existing subscription for this example to work

module "nw_example" {
  source = "./general/network_watcher"

  # Name and location
  name     = "${var.location_abbreviation[var.location]}-nwatcher" # Name for the resource
  location = var.location # Azure region for the resource

  # Tags for everything in this architecture deployed with Terraform
  tf_tags = var.tf_tags
}
```

#### Policy

Location - main.tf:

```terraform
data "azurerm_subscription" "current" {} # Existing subscription for this example to work

module "location_example" {
  source = "./policy/location"

  # Scope of the policies
  scope      = "sub" # rg for resource group or sub for subscription 
  scope_id   = data.azurerm_subscription.current.id # rg or sub id
  scope_name = data.azurerm_subscription.current.display_name # Name for the scope (used to generate resource name)

  # Locations
  location_list = var.location_list # List of allowed Azure regions in this format
}
```

Tags - main.tf:

```terraform
data "azurerm_subscription" "current" {} # Existing subscription for this example to work

module "tags_example" {
  source = "./policy/tags"

  # Scope of the policies
  scope      = "sub" # rg for resource group or sub for subscription 
  scope_id   = data.azurerm_subscription.current.id # rg or sub id
  scope_name = data.azurerm_subscription.current.display_name # Name for the scope (used to generate resource name)
  location   = var.location # Azure region for the inherited tags policy

  # Required in all resources
  required_tags = var.required_tags # Map of tags

  # Required in all resource groups
  required_rg_tags = var.required_rg_tags # Map of tags

  # Inherited from resource groups
  inherited_tags = var.inherited_tags # Map of tags
}
```

VM SKU - main.tf:

```terraform
data "azurerm_subscription" "current" {} # Existing subscription for this example to work

module "sku_example" {
  source = "./policy/vm_sku"

  # Scope of the policies
  scope      = "sub" # rg for resource group or sub for subscription 
  scope_id   = data.azurerm_subscription.current.id # rg or sub id
  scope_name = data.azurerm_subscription.current.display_name # Name for the scope (used to generate resource name)

  # Sizes
  sku_list = var.sku_list # List of allowed VM SKUs in this format
}
```

#### Project

Project - main.tf:

```terraform
module "project_example" {
  source = "./project"

  for_each = var.projects # Project configurations from project.auto.tfvars

  # General settings
  location    = lookup(each.value, "location", "swedencentral")
  environment = lookup(each.value, "environment", "prd")
  project     = each.key

  # Virtual network
  vnet    = lookup(each.value, "vnet", ["10.0.0.0/26"])
  subnets = lookup(each.value, "subnets", { default = { cidr = ["10.0.0.0/28"] }})

  # Compute resources
  vms = lookup(each.value, "vms", {})

  # Tags for everything in this architecture deployed with Terraform
  tf_tags = var.tf_tags
}
```

Project - project.auto.tfvars:

```terraform
projects = {

  homepage = { # This will be the name of the project
    location    = "westeurope" # Azure region for the project (restricted to northeurope, norwayeast, swedencentral and westeurope in variables)
    environment = "tst" # Project environment (dev, tst or prd)
    vnet    = ["10.0.0.0/26"] # List of address spaces in CIDR
    subnets = { # Map of subnets with nsg rules
      frontend = { # Name of the subnet
        cidr = ["10.0.0.0/28"] # List of address spaces in CIDR
        nsg_rules = { # Map of network security group rules (does not create network security group, if there are no rules)
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
      }
    }

    vms = { # Map of vms to be created
      webserver = { # Name of the virtual machine node/nodes
        count = 1 # Number of nodes of this virtual machine

        sku   = "Standard_B1ls" # Size of the virtual machine
        subnet        = "frontend" # Name of the subnet the nodes should use (must be configured above)
        public_ip     = true # Whether the virtual machine has a public IP or not
        ip_allocation = "Static" # Static or Dynamic IP
        admin_user    = "adminuser" # Name of the admin user to be used (sensitive)
        service_tags  = { "service" = "nginx" } # Service tags for the nodes

        # Optional data disk
        data_disk      = false # Whether the virtual machine has a data disk (true/false)
        data_disk_size = 0 # Data disk size in GB
      }
    }
  }

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
