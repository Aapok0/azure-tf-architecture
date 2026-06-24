# Azure Terraform architecture for my personal projects

The main purpose of this Terraform architecture is to deploy and manage the Azure resources I want to use for my personal projects. Currently main one is my homepage, which I want to host on a virtual machine with Nginx. At some point I will move on to using an app service or a container, but for now I want to work on my skills with Ansible and Nginx.

The way I arranged the modules and wrote them is a compromise between of the needs of my project and wanting to write scalable code, that could fit into a larger architecture. Scalability and reusability could be improved in many ways, but I don't want to make things too complicated. This code still needs to serve my own purposes. For example, I have made some restrictions for the variables, which would need to be removed to make the code more reusable for others.

### Related repositories

- [Homepage version 1](https://github.com/Aapok0/homepage)
- [Homepage version 2](https://github.com/Aapok0/homepage-bulma)
- [Ansible for Nginx webserver](https://github.com/Aapok0/homepage-webserver-ansible)

## How to use

### Configuration

Modules are to generally be called in the **main.tf** or other **.tf** files in the root module. Source of the modules will reflect that. Project module has submodules, which it calls itself inside the module. The path needs to be changed, if the modules are called elsewhere.

The files **budget.auto.tfvars** and **project.auto.tfvars** should be created to pass sensitive variables and a project variable. They are not pushed into this repository.

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
  end_date   = "2027-12-01T00:00:00Z" # Needs to be in this format; extend before it passes

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

  # DNS
  domains = lookup(each.value, "domains", {})

  # Tags for everything in this architecture deployed with Terraform
  tf_tags = var.tf_tags
}
```

Project - `project.auto.tfvars` (local file in **azure-tf-architecture**, not committed):

> **Placeholders:** `203.0.113.x` addresses are [RFC 5737 documentation IPs](https://datatrfc.ietf.org/doc/html/rfc5737), not real public IPs. `your_admin_user` is an example — use a non-obvious username in your real tfvars.

```terraform
projects = {

  homepage = {
    location    = "swedencentral"
    environment = "prd"
    vnet        = ["10.0.0.0/26"]
    subnets = {
      frontend = {
        cidr = ["10.0.0.0/28"]
        nsg_rules = {
          ssh = {
            name                       = "AllowSSHInBoundFromOwnIPs"
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_address_prefixes    = ["203.0.113.10"] # Your home IP(s); match firewall_allowed_ips in homepage-webserver-ansible/group_vars/servers.yml
            source_port_range          = "*"
            destination_address_prefix = "*"
            destination_port_range     = "22"
          }
          web = {
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
          ping = {
            name                       = "AllowICMPInBoundFromOwnIPs"
            priority                   = 120
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Icmp"
            source_address_prefixes    = ["203.0.113.10"]
            source_port_range          = "*"
            destination_address_prefix = "*"
            destination_port_range     = "*"
          }
        }
      }
    }

    vms = {
      webserver = {
        count         = 1
        sku           = "Standard_B1ls"
        subnet        = "frontend"
        public_ip     = true
        ip_allocation = "Static"
        admin_user    = "your_admin_user"
        service_tags  = { "service" = "nginx" }
      }
    }

    domains = {
      "example.com" = {
        records = { "@" = {}, www = {} }
      }
    }
  }

}
```

NSG `source_address_prefixes` for SSH and ICMP should match `firewall_allowed_ips` in **homepage-webserver-ansible** `group_vars/servers.yml`. Web traffic uses `source_address_prefix = "*"` so the site is reachable from the Internet.

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
