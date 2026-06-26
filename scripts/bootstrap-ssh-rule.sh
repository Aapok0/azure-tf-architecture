#!/usr/bin/env bash
# Add a TEMPORARY inbound SSH (port 22) allow rule to each project NSG, to
# bootstrap access on a host before Tailscale is up (there is no permanent
# public SSH rule). Source is admin_allowed_ips if set, otherwise any (*).
#
# Remove it again with scripts/remove-ssh-rule.sh once Tailscale works.
#
# Usage (from azure-tf-architecture root):
#   ./scripts/bootstrap-ssh-rule.sh
#   PRIORITY=205 RULE_NAME=MyTempSSH ./scripts/bootstrap-ssh-rule.sh
#
# Requires: terraform, jq, az (logged in)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RULE_NAME="${RULE_NAME:-TempAllowSSHBootstrap}"
PRIORITY="${PRIORITY:-200}"

for cmd in terraform jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required." >&2
    exit 1
  fi
done

cd "$ROOT_DIR"

nsg_json="$(terraform output -json nsg_info_out 2>/dev/null || echo '[]')"
ips_json="$(terraform output -json admin_allowed_ips_out 2>/dev/null || echo '[]')"

if [[ "$(echo "$nsg_json" | jq 'length')" -eq 0 ]]; then
  echo "No NSGs found in terraform output (nsg_info_out)." >&2
  exit 1
fi

mapfile -t src < <(echo "$ips_json" | jq -r '.[]')
if ((${#src[@]})); then
  echo "Source = admin_allowed_ips: ${src[*]}"
else
  src=("*")
  echo "WARNING: admin_allowed_ips is empty — opening SSH to ANY source (*)." >&2
fi

echo "$nsg_json" | jq -c '.[]' | while read -r row; do
  rg="$(jq -r '.resource_group' <<<"$row")"
  nsg="$(jq -r '.nsg_name' <<<"$row")"
  echo "Adding '$RULE_NAME' (priority $PRIORITY) to NSG $nsg in $rg ..."
  az network nsg rule create \
    --resource-group "$rg" \
    --nsg-name "$nsg" \
    --name "$RULE_NAME" \
    --priority "$PRIORITY" \
    --direction Inbound --access Allow --protocol Tcp \
    --destination-port-ranges 22 \
    --source-address-prefixes "${src[@]}" \
    --destination-address-prefixes '*' \
    --output none
  echo "  done"
done

echo "Temporary SSH rule '$RULE_NAME' added. Remove it with scripts/remove-ssh-rule.sh"
