#!/usr/bin/env bash
# Decrypt committed *.auto.tfvars.enc files to plaintext auto.tfvars for Terraform.
# Plaintext files are gitignored; run this before terraform plan/apply on a new machine.
#
# Usage (from azure-tf-architecture root):
#   ./scripts/sops-decrypt.sh
#
# Requires: sops, age private key at ~/.config/sops/age/keys.txt

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v sops >/dev/null 2>&1; then
  echo "sops is required." >&2
  exit 1
fi

decrypt() {
  local enc="$1"
  local plain="$2"
  if [[ ! -f "$enc" ]]; then
    echo "skip $enc (not found)" >&2
    return 0
  fi
  sops -d "$enc" >"$plain"
  chmod 600 "$plain"
  echo "decrypted $enc -> $plain"
}

decrypt budget.auto.tfvars.enc budget.auto.tfvars
decrypt project.auto.tfvars.enc project.auto.tfvars
