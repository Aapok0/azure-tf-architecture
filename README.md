# Azure Terraform architecture for my personal projects

Deploys and manages the Azure resources for my personal projects — currently my homepage, hosted on a VM running Nginx. The modules are a compromise between my own needs and writing scalable, reusable code: some variables are deliberately restricted for my use case and would need loosening to be fully general.

### Related repositories

- [Homepage version 1](https://github.com/Aapok0/homepage)
- [Homepage version 2](https://github.com/Aapok0/homepage-bulma)
- [Ansible for Nginx webserver](https://github.com/Aapok0/homepage-webserver-ansible)

## How it works

Modules are called from the root `.tf` files. The `project` module calls its own submodules (subnet/NSG, compute, DNS, Key Vault).

| Module | Purpose |
|--------|---------|
| `general/budget` | Budget + threshold/forecast alerts (RG, subscription or MG scope) |
| `general/network_watcher` | Network Watcher for a region |
| `policy/location` | Allowed-regions policy |
| `policy/tags` | Required / inherited tag policies |
| `policy/vm_sku` | Allowed VM SKU policy |
| `project` | Per-project VNet, subnets + NSG, VMs, DNS and Key Vault |

Key points:

- **State** lives in Azure Blob Storage (see [Remote state](#remote-state-one-time-setup)).
- **Secrets and project config** go in `budget.auto.tfvars` and `project.auto.tfvars` — both gitignored.
- **VMs** run Ubuntu 24.04 LTS on a pinned image, with a random admin user/password stored in Key Vault. Azure accepts **RSA SSH keys only**.
- **SSH is over Tailscale** — there is no public inbound SSH rule (see [Security model](#security-model-nsg--ufw--tailscale)).

## Configuration

Create `budget.auto.tfvars` and `project.auto.tfvars` (gitignored) for sensitive values and the project definition. Module `source` paths are relative to the root module — adjust them if you call modules elsewhere.

> Placeholder IPs like `203.0.113.x` below are [RFC 5737](https://datatracker.ietf.org/doc/html/rfc5737) documentation addresses — replace them.

Modules scoped to a subscription or management group expect a data source in the root module:

```terraform
data "azurerm_subscription" "current" {}
```

### General modules

Budget:

```terraform
module "budget_example" {
  source = "./general/budget"

  scope    = "sub"  # rg | sub | mg
  scope_id = data.azurerm_subscription.current.id
  name     = "${data.azurerm_subscription.current.display_name}-budget"

  amount     = 10                       # USD limit
  time_grain = "Monthly"                # BillingMonth/Quarter/Annual or Monthly/Quarterly/Annually
  start_date = "2023-08-01T00:00:00Z"   # YYYY-MM-01T00:00:00Z; set to first of current month when extending
  end_date   = "2027-12-01T00:00:00Z"   # extend before it passes (bump start_date too)

  threshold_alert = true
  threshold       = 75.0                # percent
  forecast_alert  = true                # alert when forecast exceeds 100%
  contact_emails  = var.contact_emails  # use a variable; can be sensitive
  contact_roles   = ["Owner"]
}
```

`budget.auto.tfvars`:

```terraform
contact_emails = ["email1@invalid.com", "email2@invalid.com"]
```

Network Watcher:

```terraform
module "nw_example" {
  source = "./general/network_watcher"

  name     = "${var.location_abbreviation[var.location]}-nwatcher"
  location = var.location
  tf_tags  = var.tf_tags
}
```

### Policy modules

All three share the same scope inputs (`scope` = `rg | sub`, plus `scope_id` / `scope_name`):

```terraform
module "location_example" {
  source = "./policy/location"

  scope      = "sub"
  scope_id   = data.azurerm_subscription.current.id
  scope_name = data.azurerm_subscription.current.display_name

  location_list = var.location_list  # allowed Azure regions
}

module "tags_example" {
  source = "./policy/tags"

  scope      = "sub"
  scope_id   = data.azurerm_subscription.current.id
  scope_name = data.azurerm_subscription.current.display_name
  location   = var.location          # region for the inherited-tags policy

  required_tags    = var.required_tags      # required on all resources
  required_rg_tags = var.required_rg_tags    # required on all resource groups
  inherited_tags   = var.inherited_tags      # inherited from resource groups
}

module "sku_example" {
  source = "./policy/vm_sku"

  scope      = "sub"
  scope_id   = data.azurerm_subscription.current.id
  scope_name = data.azurerm_subscription.current.display_name

  sku_list = var.sku_list  # allowed VM SKUs
}
```

### Project module

```terraform
module "project_example" {
  source   = "./project"
  for_each = var.projects  # from project.auto.tfvars

  location    = lookup(each.value, "location", "swedencentral")
  environment = lookup(each.value, "environment", "prd")
  project     = each.key

  vnet    = lookup(each.value, "vnet", ["10.0.0.0/26"])
  subnets = lookup(each.value, "subnets", { default = { cidr = ["10.0.0.0/28"] } })
  vms     = lookup(each.value, "vms", {})
  domains = lookup(each.value, "domains", {})

  tf_tags = var.tf_tags
}
```

`project.auto.tfvars` — the central project definition:

```terraform
# Admin IP allowlist for NSG rules flagged admin_restricted (ICMP/ping only; SSH is over
# Tailscale). Also synced to Ansible as the UFW SSH fallback via scripts/sync-firewall-allowlist.sh.
admin_allowed_ips = ["203.0.113.10"]

projects = {

  homepage = {
    location    = "swedencentral"
    environment = "prd"
    vnet        = ["10.0.0.0/26"]
    subnets = {
      frontend = {
        cidr = ["10.0.0.0/28"]
        nsg_rules = {
          # No public SSH rule — SSH is reached over Tailscale.
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
            admin_restricted           = true  # source set from admin_allowed_ips
            source_port_range          = "*"
            destination_address_prefix = "*"
            destination_port_range     = "*"
          }
        }
      }
    }

    vms = {
      webserver = {
        count                     = 1
        sku                       = "Standard_B1ls"
        subnet                    = "frontend"
        public_ip                 = true
        ip_allocation             = "Static"
        admin_ssh_public_key_path = "~/.ssh/id_rsa.pub"  # optional; RSA only — Azure rejects ed25519
        service_tags              = { "service" = "nginx" }
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

### Security model (NSG + UFW + Tailscale)

SSH is reached over a **Tailscale** tailnet, so there is **no public inbound SSH** — a changing home IP can't lock you out and port 22 is never exposed. Defense in depth:

| Layer | SSH (22) | HTTP/HTTPS (80,443) | ICMP | Default |
|-------|----------|---------------------|------|---------|
| **NSG** (Azure edge) | no public rule | Internet | `admin_allowed_ips` | deny |
| **UFW** (host) | `tailscale0` only | any | (via SSH allow) | deny incoming |
| **Tailscale** | tailnet peers | — | — | — |

- `admin_allowed_ips` in `project.auto.tfvars` is the single source of truth for NSG rules flagged `admin_restricted = true` (currently ICMP/ping only, **not** SSH); the subnet module injects it.
- `scripts/sync-firewall-allowlist.sh` mirrors it into **homepage-webserver-ansible** `group_vars/servers/firewall_allowed_ips.yml`, used by UFW only as the SSH **fallback** (`firewall_ssh_over_tailscale_only: false`).
- Web traffic uses `source_address_prefix = "*"` so the site is reachable from the Internet.
- Tailscale setup (OAuth key, join, lockout-safe migration) is documented in the **homepage-webserver-ansible** README.

**Fresh-host SSH bootstrap** (no permanent public SSH rule): `scripts/bootstrap-ssh-rule.sh` adds a temporary port 22 rule to every project NSG (source = `admin_allowed_ips`, or `*` if empty); `scripts/remove-ssh-rule.sh` removes it. Use them for the first connection before Tailscale is up, then remove.

## Remote state (one-time setup)

Terraform state is stored in Azure Blob Storage. Bootstrap once, then point Terraform at it.

1. Bootstrap the storage account and backend config:
   ```bash
   ./scripts/bootstrap-remote-state.sh --owner "Your Name"
   # or pin the name: --storage-account sdctfstate1234
   ```
   Creates resource group `sdc-tfstate-rg` (naming varies by environment), applies the subscription-required tags (`owner`, `location`, `environment`, `project`), and writes `backend.hcl` from `backend.hcl.example`. `--owner` is required (prompts in a TTY if omitted).

2. Initialise against the backend:
   ```bash
   terraform init -backend-config=backend.hcl
   # migrating existing local state:
   terraform init -migrate-state -backend-config=backend.hcl
   ```

Cost is negligible (fractions of a cent per month for a small state file).

> If `terraform plan` fails on resource provider registration: this stack registers only the providers it needs (`Microsoft.Authorization`, `Microsoft.Compute`, `Microsoft.Consumption`, `Microsoft.Network`) via `resource_providers_to_register` in `terraform.tf`. To register manually, set `resource_provider_registrations = "none"`, drop `resource_providers_to_register`, and run `az provider register --namespace <ns>` for each.

## Deploy

Requires Azure CLI and Terraform ≥ 1.5.7 (1.15.x recommended) with azurerm provider 4.x.

1. Log in and select the subscription:
   ```bash
   az login
   az account set --subscription <name-or-id>
   ```
   azurerm 4.x uses that subscription (or export `ARM_SUBSCRIPTION_ID`).

2. Initialise with the remote backend (see [Remote state](#remote-state-one-time-setup)):
   ```bash
   terraform init -upgrade -backend-config=backend.hcl
   ```

3. Format, validate, plan and apply:
   ```bash
   terraform fmt -recursive
   terraform validate
   terraform plan -out tfplan
   terraform apply tfplan
   ```

4. Sync the **homepage-webserver-ansible** inventory, firewall allowlist and SSH config:
   ```bash
   ./scripts/sync-ansible-inventory.sh
   ./scripts/sync-firewall-allowlist.sh
   ./scripts/sync-ssh-config.sh
   ```
   Inventory and SSH `HostName` default to the Tailscale node name. Before the **first** `server_init` run (Tailscale not installed yet), add `--public-ip` to both sync scripts so they target the public IP via the temporary NSG rule — see `scripts/bootstrap-ssh-rule.sh` and the ansible repo README.

After apply, retrieve the generated admin credentials:

```bash
terraform output admin_user_out
terraform output -json admin_pass_out   # sensitive
```

## Reference

### Continuous integration

`.github/workflows/terraform.yml` runs on pushes to `main` and on pull requests: `terraform fmt -check -recursive`, `terraform init -backend=false`, `terraform validate`. Formatting stays a local action (`terraform fmt`); CI only verifies it. No `plan`/`apply` runs in CI, so no secrets are needed.

### VM image

Linux VMs use **Ubuntu 24.04 LTS** with a **pinned image version** (not `latest`). Canonical's current Azure format is offer `ubuntu-24_04-lts` / SKU **`server`** (the older `0001-com-ubuntu-server-noble` offer is retired in many regions). The default pin is in `project/compute/linux_vms/linux_vm/main.tf`; override per VM with `os_image` in `project.auto.tfvars`.

List **server** images for your region (version strings are per-SKU — a version under `minimal` or `ubuntu-pro` may not exist for `server`):

```bash
az vm image list --publisher Canonical --offer ubuntu-24_04-lts --sku server \
  --location swedencentral --all -o table
```

Pick a `Version` from the `server` rows only, then set it in `main.tf` or via `os_image`. **homepage-webserver-ansible** installs PHP 8.3 (php-fpm) to match Ubuntu 24.04.

> **SSH keys:** Azure Linux VMs accept **RSA public keys only** (ed25519 is rejected). Default path is `~/.ssh/id_rsa.pub`; override per VM with `admin_ssh_public_key_path`.

### Key Vault

Each project gets a Key Vault (`{name_prefix}-kv`, e.g. `sdc-prd-homepage-kv`) using the **RBAC** authorization model. Standard SKU, effectively zero cost here. Disable per project with `key_vault_enabled = false`.

Terraform stores these secrets per VM (e.g. `sdc-prd-homepage-webserver-vm-0-...`):

- `<vm>-admin-username`
- `<vm>-admin-password`
- `<vm>-ssh-public-key`

The deploying user is granted **Key Vault Administrator** (data-plane). RBAC propagation can lag a few seconds, so the first apply may 403 while writing secrets — just re-run `terraform apply`.

> **Secrets and state:** anything Terraform writes to Key Vault is also in the (remote, encrypted) state. Key Vault here is for convenient retrieval, auditing and RBAC delegation — not for keeping secrets out of state.

Read a secret without Terraform:

```bash
VAULT=$(terraform output -json key_vault_name_out | jq -r '.homepage')
az keyvault secret show --vault-name "$VAULT" \
  --name sdc-prd-homepage-webserver-vm-0-admin-password --query value -o tsv
```

**SSH private key (added manually, on purpose):** the private key lives only on your machine and is deliberately **not** read by Terraform (that would copy it into state). Upload it out-of-band once, and restore it on a new machine:

```bash
# upload
az keyvault secret set --vault-name "$VAULT" \
  --name sdc-prd-homepage-webserver-vm-0-ssh-private-key --file ~/.ssh/id_rsa_azure

# restore
az keyvault secret show --vault-name "$VAULT" \
  --name sdc-prd-homepage-webserver-vm-0-ssh-private-key --query value -o tsv > ~/.ssh/id_rsa_azure
chmod 600 ~/.ssh/id_rsa_azure
```

### Troubleshooting

**VM replace fails on a deallocated VM** — if `terraform apply` errors with `powerOff is not allowed` / `VM is deallocated`, the old VM was stopped in Azure while Terraform tries to power it off before destroy. Either start it and re-plan:

```bash
az vm start -g sdc-prd-homepage-rg -n sdc-prd-homepage-webserver-vm-0
terraform plan -out tfplan && terraform apply tfplan
```

Or delete it in Azure, refresh state, then apply (do **not** reuse a stale `tfplan` from before the failed apply):

```bash
az vm delete -g sdc-prd-homepage-rg -n sdc-prd-homepage-webserver-vm-0 --yes
terraform refresh -backend-config=backend.hcl
terraform plan -out tfplan && terraform apply tfplan
```
