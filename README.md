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
  start_date = "2023-08-01T00:00:00Z" # YYYY-MM-01T00:00:00Z; when extending end_date, set to the first day of the current month
  end_date   = "2027-12-01T00:00:00Z" # YYYY-MM-01T00:00:00Z; extend before it passes (update start_date too)

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

> **Placeholders:** `203.0.113.x` addresses are [RFC 5737 documentation IPs](https://datatrfc.ietf.org/doc/html/rfc5737), not real public IPs.

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
        admin_ssh_public_key_path = "~/.ssh/id_rsa.pub" # optional; RSA only — Azure does not support ed25519
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

### Remote state (one-time setup)

Terraform state is stored in Azure Blob Storage. Bootstrap once, then point Terraform at it.

1. **Bootstrap storage and backend config** (from **azure-tf-architecture**):

```bash
./scripts/bootstrap-remote-state.sh --owner "Your Name"
# or: ./scripts/bootstrap-remote-state.sh --owner "Your Name" --storage-account sdctfstate1234
```

Creates resource group `sdc-tfstate-rg` by default (`{region}-{project}-rg` when environment is `all`; `{region}-{environment}-{project}-rg` otherwise). Applies subscription-required tags (`owner`, `location`, `environment`, `project`). Writes `backend.hcl` from `backend.hcl.example`. `--owner` is required; the script prompts in a TTY if omitted.

2. **Initialize** — from **azure-tf-architecture** root (after bootstrap writes `backend.hcl`):

```bash
terraform init -backend-config=backend.hcl
# If you already have local terraform.tfstate:
terraform init -migrate-state -backend-config=backend.hcl
```

Cost is negligible (fractions of a cent/month for a small state file).

If `terraform plan` fails on resource provider registration, **azure-tf-architecture** registers only the providers this stack needs (`Microsoft.Authorization`, `Microsoft.Compute`, `Microsoft.Consumption`, `Microsoft.Network`) via `resource_providers_to_register` in `terraform.tf`. To register manually instead, set `resource_provider_registrations = "none"` and omit `resource_providers_to_register`, then for example:

```bash
az provider register --namespace Microsoft.Authorization
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Consumption
az provider register --namespace Microsoft.Network
```

### VM image

Linux VMs use **Ubuntu 24.04 LTS** with a **pinned image version** (not `latest`). Canonical’s current Azure format is `ubuntu-24_04-lts` / **`server`** SKU (the older `0001-com-ubuntu-server-noble` offer is retired in many regions). Default pin is in `project/compute/linux_vms/linux_vm/main.tf`; override per VM with `os_image` in **azure-tf-architecture** `project.auto.tfvars`.

List **server** images in your region — version strings are per-SKU; a version listed under `minimal` or `ubuntu-pro` may not work for `server`:

```bash
az vm image list \
  --publisher Canonical \
  --offer ubuntu-24_04-lts \
  --sku server \
  --location swedencentral \
  --all \
  -o table
```

Pick a `Version` from the `server` rows only, then set it in `main.tf` or `os_image` in tfvars.

**homepage-webserver-ansible** installs **PHP 8.3** (php-fpm) to match Ubuntu 24.04.

**SSH keys:** Azure Linux VMs accept **RSA public keys only** (ed25519 is rejected). Default path is `~/.ssh/id_rsa.pub`; override per VM with `admin_ssh_public_key_path` in **azure-tf-architecture** `project.auto.tfvars` (e.g. `~/.ssh/id_rsa_azure.pub` if that key is RSA).

Each VM gets a **random admin username and password** (SSH key auth is what you use day-to-day). After apply:

```bash
terraform output admin_user_out
terraform output -json admin_pass_out   # sensitive
```

### Key Vault

Each project gets a Key Vault (`{name_prefix}-kv`, e.g. `sdc-prd-homepage-kv`) using the **RBAC authorization** model. Standard SKU — cost is effectively zero for this usage. Disable per project with `key_vault_enabled = false` in the project block of `project.auto.tfvars`.

Terraform stores these secrets per VM (e.g. `sdc-prd-homepage-webserver-vm-0-...`):

- `<vm>-admin-username`
- `<vm>-admin-password`
- `<vm>-ssh-public-key`

The deploying user is granted **Key Vault Administrator** (data-plane). Because RBAC role propagation can lag a few seconds, the first apply may fail writing secrets with a 403 — just re-run `terraform apply` if so.

> **Secrets and state:** anything Terraform writes to Key Vault is also in the (remote, encrypted) state. Key Vault here is for convenient retrieval (any machine, no Terraform), access auditing, and RBAC delegation — not for removing secrets from state.

Read secrets without Terraform:

```bash
VAULT=$(terraform output -json key_vault_name_out | jq -r '.homepage')
az keyvault secret show --vault-name "$VAULT" --name sdc-prd-homepage-webserver-vm-0-admin-password --query value -o tsv
```

**SSH private key (added manually, on purpose):** the private key lives only on your machine and is deliberately **not** read by Terraform (that would copy it into state). Upload it out-of-band once:

```bash
az keyvault secret set --vault-name "$VAULT" \
  --name sdc-prd-homepage-webserver-vm-0-ssh-private-key \
  --file ~/.ssh/id_rsa_azure
```

Restore it on a new machine:

```bash
az keyvault secret show --vault-name "$VAULT" \
  --name sdc-prd-homepage-webserver-vm-0-ssh-private-key \
  --query value -o tsv > ~/.ssh/id_rsa_azure
chmod 600 ~/.ssh/id_rsa_azure
```

### Deploying

```bash
# Requires Azure CLI and Terraform (>= 1.5.7; 1.15.x recommended) and azurerm provider 4.x

# Clone repository and configure to your liking

# Login to your Azure account and switch to preferred subscription, if you have multiple.
az login
az account set --subscription <name-or-id>
# azurerm 4.x uses that subscription (or export ARM_SUBSCRIPTION_ID explicitly)

# Initialize terraform with remote backend (see Remote state above)
terraform init -upgrade -backend-config=backend.hcl

# Optionally format the code and validate, that it works
terraform fmt
terraform validate

# Create a plan (I prefer using a file)
terraform plan -out tfplan

# If everything looks good, apply to deploy to Azure
terraform apply tfplan

# Sync homepage-webserver-ansible inventory and optional SSH config
# (inventory: full rewrite per environment; SSH: replace terraform-managed blocks only)
./scripts/sync-ansible-inventory.sh
./scripts/sync-ssh-config.sh
```

### Troubleshooting

#### Apply on VM fails

**VM replace fails on deallocated VM:** If `terraform apply` errors with `powerOff is not allowed` / `VM is deallocated`, the old VM was stopped in Azure while Terraform tries to power it off before destroy. Either start it, then re-plan and apply:

```bash
az vm start -g sdc-prd-homepage-rg -n sdc-prd-homepage-webserver-vm-0
terraform plan -out tfplan
terraform apply tfplan
```

Or delete it in Azure, refresh state, then apply (do **not** reuse a stale `tfplan` from before the failed apply):

```bash
az vm delete -g sdc-prd-homepage-rg -n sdc-prd-homepage-webserver-vm-0 --yes
terraform refresh -backend-config=backend.hcl
terraform plan -out tfplan
terraform apply tfplan
```
