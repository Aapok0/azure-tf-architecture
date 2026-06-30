# Azure Terraform architecture for my personal projects

Deploys and manages the Azure resources for my personal projects — currently my homepage, hosted on a VM running Nginx. The modules are a compromise between my own needs and writing scalable, reusable code: some variables are deliberately restricted for my use case and would need loosening to be fully general.

### Related repositories

- [Homepage version 1](https://github.com/Aapok0/homepage)
- [Homepage version 2](https://github.com/Aapok0/homepage-bulma)
- [Ansible for Nginx webserver](https://github.com/Aapok0/homepage-webserver-ansible)

## How it works

Modules are called from the root `.tf` files. The `project` module calls its own submodules (subnet/NSG, compute VMs, Container Apps, DNS, Key Vault).

| Module | Purpose |
|--------|---------|
| `general/budget` | Budget + threshold/forecast alerts (RG, subscription or MG scope) |
| `general/network_watcher` | Network Watcher for a region |
| `general/log_analytics` | Shared Log Analytics workspace (logs for VMs and Container Apps) |
| `policy/location` | Allowed-regions policy |
| `policy/tags` | Required / inherited tag policies |
| `policy/vm_sku` | Allowed VM SKU policy |
| `project` | Per-project VNet, subnets + NSG, VMs, Container Apps, DNS and Key Vault |

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

Log Analytics (shared workspace; create it once with `count`, then pass its ID to resources that opt in):

```terraform
module "log_analytics_example" {
  source = "./general/log_analytics"

  count = var.log_analytics_enabled ? 1 : 0

  name     = "${var.location_abbreviation[var.location]}-law"
  location = var.location

  daily_quota_gb = 0.16  # ~4.96 GB/month cap (0.16 * 31); bump if needed
  tf_tags        = var.tf_tags
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

  location    = each.value.location
  environment = each.value.environment
  project     = each.key

  vnet           = each.value.vnet
  subnets        = each.value.subnets
  vms            = each.value.vms
  container_apps = each.value.container_apps
  domains        = each.value.domains

  # Shared workspace ID; resources opt in per-resource via their log_analytics flag
  log_analytics_workspace_id = var.log_analytics_enabled ? module.log_analytics[0].workspace_id_out : null

  tf_tags = var.tf_tags
}
```

`project.auto.tfvars` — the central project definition:

```terraform
# Admin IP allowlist. Synced to Ansible as the UFW SSH fallback via
# scripts/sync-firewall-allowlist.sh. Also available to any NSG rule flagged
# admin_restricted = true (none by default — ping works over Tailscale).
admin_allowed_ips = ["203.0.113.10"]

# Create the shared subscription-level Log Analytics workspace. Compute
# resources opt in individually via their own log_analytics flag (see below).
log_analytics_enabled = true

projects = {

  homepage = {
    location    = "swedencentral"
    environment = "prd"
    vnet        = ["10.0.0.0/26"]
    # No vnet or subnets are created, if subnet = {}
    subnets = {
      frontend = {
        cidr = ["10.0.0.0/28"]
        nsg_rules = {
          # No public SSH rule — SSH is over Tailscale. No ICMP rule — ping works
          # over the tailnet. To restrict a rule's source to admin_allowed_ips,
          # set admin_restricted = true on it.
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
        log_analytics             = true  # optional; ship syslog to the shared workspace
      }
    }

    # Container Apps. One or more containers per app share a replica and network
    # namespace; min_replicas defaults to 0 (scale to zero), ingress target_port
    # to 8080. Images are pulled from a public registry.
    container_apps = {
      app = {
        log_analytics = true  # optional; send environment logs to the shared workspace
        containers = [
          { name = "frontend", image = "ghcr.io/owner/frontend:1.0.0" },
          { name = "sidecar", image = "ghcr.io/owner/sidecar:1.0.0" },
        ]
        service_tags = { "service" = "app" }
        # optional: revision_mode, min_replicas, max_replicas,
        #           ingress_external, ingress_target_port, per-container cpu/memory/env
      }
    }

    domains = {
      "example.com" = {
        # Point records at the project VMs (ips default to the VM public IPs) or
        # at explicit IPs:
        records = { "@" = {}, www = {} }

        # Or host the domain on a container app instead — creates apex A / www
        # CNAME / asuid TXT records and binds the app with a free managed
        # certificate (defaults to hostnames ["@", "www"]):
        # container_app = "app"
      }
    }
  }

}
```

### Security model (NSG + UFW + Tailscale)

SSH is reached over a **Tailscale** tailnet, so there is **no public inbound SSH** — a changing home IP can't lock you out and port 22 is never exposed. Defense in depth:

| Layer | SSH (22) | HTTP/HTTPS (80,443) | ICMP / ping | Default |
|-------|----------|---------------------|-------------|---------|
| **NSG** (Azure edge) | no public rule | Internet | over tailnet only | deny |
| **UFW** (host) | `tailscale0` only | any | over tailnet only | deny incoming |
| **Tailscale** | tailnet peers | — | tailnet peers | — |

- `admin_allowed_ips` in `project.auto.tfvars` feeds any NSG rule flagged `admin_restricted = true` (none by default — SSH and ping both go over Tailscale); the subnet module injects it where used.
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

> If `terraform plan` fails on resource provider registration: this stack registers only the providers it needs (`Microsoft.App`, `Microsoft.Authorization`, `Microsoft.Compute`, `Microsoft.Consumption`, `Microsoft.Network`, `Microsoft.OperationalInsights`) via `resource_providers_to_register` in `terraform.tf`. To register manually, set `resource_provider_registrations = "none"`, drop `resource_providers_to_register`, and run `az provider register --namespace <ns>` for each.

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

### Container Apps

`project/compute/container_app` creates a Consumption Container App Environment (Azure-managed network — no VNet integration or subnet) and one app per `container_apps` entry. The app runs the containers from the `containers` list in a single replica; they share a network namespace, so a sidecar reaches the primary container over `127.0.0.1`. Ingress is external on `ingress_target_port` (default 8080), and `min_replicas` defaults to 0 (scale to zero), keeping idle cost within the Container Apps free grant.

Images are pulled from a public registry (GHCR), so no registry or pull credentials are managed here. The app FQDNs are exposed via the `container_app_fqdns_out` output (per-project), useful as a staging hostname before DNS cutover. Set `log_analytics = true` on an entry to send environment logs to the shared workspace.

#### Custom domains

A `domains` entry with `container_app = "<app key>"` hosts that domain on the app. For each hostname (default `@` and `www`) the DNS zone gets:

- apex `@` → **A** record to the environment static inbound IP;
- `www` → **CNAME** to the app FQDN;
- `asuid` / `asuid.<sub>` → **TXT** record with the app's domain verification ID.

The app is then bound to each hostname (`azurerm_container_app_custom_domain`) and issued a free, auto-renewed **managed certificate** (`azurerm_container_app_environment_managed_certificate`). The apex validates over HTTP (an apex can't be a CNAME); subdomains validate via CNAME.

Ordering matters: the verification records must exist before the binding, so the binding/certificate resources live in the project root (not the `container_app` module, which the DNS records depend on) and `depends_on` the DNS zone. Azure binds the certificate asynchronously, so its id and binding type are in `ignore_changes`. Because the binding needs DNS to resolve to the app first, expect a brief window (and a short HTTP-only period while the certificate provisions) during a live cutover — apply the DNS/binding/certificate first, confirm the certificate is active, then prune any old origin.

##### Manual step: attach the certificate

After `apply`, the custom domain exists but its `BindingType` is `Disabled` — the managed certificate is issued but not attached, so HTTPS on the custom hostname serves no certificate. This is a provider limitation: setting the certificate on `azurerm_container_app_custom_domain` would make it reference a certificate that itself `depends_on` the domain (a cycle, unavoidable for an apex that can't use CNAME validation), so the SNI binding is left out of Terraform via `ignore_changes` and must be done once out-of-band:

```bash
az containerapp hostname bind -g <rg> -n <app> \
  --environment <env> \
  --hostname <hostname> --certificate <managed-cert-name>
```

Run it per hostname (e.g. the apex and `www`). It flips the binding to `SniEnabled`; `ignore_changes` keeps a later `terraform apply` from reverting it. Verify with `az containerapp hostname list -n <app> -g <rg> -o table` (expect `SniEnabled`).

### Log Analytics

One shared workspace at subscription scope (`general/log_analytics`, in its own `{abbr}-law-rg`), created only when `log_analytics_enabled = true`. Compute resources do not attach automatically — each opts in with its own `log_analytics = true` flag, and the root passes the workspace ID down.

- **Container Apps** consume the workspace ID directly: the environment sets `logs_destination = "log-analytics"`.
- **VMs** need more than an ID, so the `linux_vm` module adds, only when opted in: a system-assigned identity, the **Azure Monitor Agent** extension, and a **data collection rule** (all syslog facilities, Info and above) associated to the VM.

Cost is bounded by a workspace-wide `daily_quota_gb` (default `0.16` → ~4.96 GB/month). The cap is shared across **all** sources writing to the workspace; bump it in the `general/log_analytics` module call if you enable more.

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
