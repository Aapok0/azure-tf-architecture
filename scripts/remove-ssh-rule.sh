#!/usr/bin/env bash
# Remove the temporary inbound SSH rule added by scripts/bootstrap-ssh-rule.sh
# from each project NSG. Safe to run if the rule is absent.
#
# Usage (from azure-tf-architecture root):
#   ./scripts/remove-ssh-rule.sh
#   RULE_NAME=MyTempSSH ./scripts/remove-ssh-rule.sh
#
# Requires: terraform, jq, az (logged in)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RULE_NAME="${RULE_NAME:-TempAllowSSHBootstrap}"

for cmd in terraform jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required." >&2
    exit 1
  fi
done

cd "$ROOT_DIR"

nsg_json="$(terraform output -json nsg_info_out 2>/dev/null || echo '[]')"

if [[ "$(echo "$nsg_json" | jq 'length')" -eq 0 ]]; then
  echo "No NSGs found in terraform output (nsg_info_out)." >&2
  exit 1
fi

echo "$nsg_json" | jq -c '.[]' | while read -r row; do
  rg="$(jq -r '.resource_group' <<<"$row")"
  nsg="$(jq -r '.nsg_name' <<<"$row")"
  echo "Removing '$RULE_NAME' from NSG $nsg in $rg ..."
  az network nsg rule delete \
    --resource-group "$rg" \
    --nsg-name "$nsg" \
    --name "$RULE_NAME" \
    --output none || true
  echo "  done"
done

echo "Temporary SSH rule '$RULE_NAME' removed where present."
