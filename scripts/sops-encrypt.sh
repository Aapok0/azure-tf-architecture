#!/usr/bin/env bash
# Encrypt plaintext auto.tfvars to committed *.auto.tfvars.enc files.
# Use after editing plaintext locally, or to refresh .enc after decrypt + change.
# Prefer editing encrypted files directly: sops budget.auto.tfvars.enc
#
# Usage (from azure-tf-architecture root):
#   ./scripts/sops-encrypt.sh
#
# Requires: sops, age private key at ~/.config/sops/age/keys.txt

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v sops >/dev/null 2>&1; then
  echo "sops is required." >&2
  exit 1
fi

encrypt() {
  local plain="$1"
  local enc="$2"
  if [[ ! -f "$plain" ]]; then
    echo "skip $plain (not found)" >&2
    return 0
  fi
  sops -e --input-type binary --output-type binary \
    --filename-override "$enc" --output "$enc" "$plain"
  echo "encrypted $plain -> $enc"
}

encrypt budget.auto.tfvars budget.auto.tfvars.enc
encrypt project.auto.tfvars project.auto.tfvars.enc
