#!/usr/bin/env bash
# Sync ~/.ssh/config entries from terraform output.
# Replaces only blocks between terraform-managed markers; other entries are kept.
# Hosts removed from state are dropped on the next sync.
#
# Usage (from azure-tf-architecture root):
#   ./scripts/sync-ssh-config.sh
#
# Requires: terraform, jq

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_CONFIG="${SSH_CONFIG:-$HOME/.ssh/config}"
IDENTITY_FILE="${IDENTITY_FILE:-}"
MANAGED_BEGIN='# BEGIN terraform-managed:'
MANAGED_END='# END terraform-managed:'

trim_trailing_blank_lines() {
  local file="$1"
  local trimmed
  trimmed="$(mktemp)"
  awk '
    { lines[NR] = $0 }
    END {
      end = NR
      while (end > 0 && lines[end] ~ /^[[:space:]]*$/) end--
      for (i = 1; i <= end; i++) print lines[i]
    }
  ' "$file" >"$trimmed"
  mv "$trimmed" "$file"
}

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required." >&2
  exit 1
fi

cd "$ROOT_DIR"

hosts_json="$(terraform output -json ansible_hosts_out 2>/dev/null || echo '[]')"

mkdir -p "$(dirname "$SSH_CONFIG")"
touch "$SSH_CONFIG"

tmp="$(mktemp)"
in_managed=0

while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == "${MANAGED_BEGIN}"* ]]; then
    in_managed=1
    if [[ -s "$tmp" ]]; then
      last="$(tail -n1 "$tmp")"
      if [[ -z "${last//[[:space:]]/}" ]]; then
        head -n -1 "$tmp" >"${tmp}.trim" && mv "${tmp}.trim" "$tmp"
      fi
    fi
    continue
  fi
  if [[ "$line" == "${MANAGED_END}"* ]]; then
    in_managed=0
    continue
  fi
  if [[ "$in_managed" -eq 1 ]]; then
    continue
  fi
  printf '%s\n' "$line" >>"$tmp"
done <"$SSH_CONFIG"

mv "$tmp" "$SSH_CONFIG"
trim_trailing_blank_lines "$SSH_CONFIG"

host_count="$(echo "$hosts_json" | jq 'length')"
added=0
blocks_tmp="$(mktemp)"
trap 'rm -f "$blocks_tmp"' EXIT

while IFS= read -r line; do
  [[ -n "$line" ]] || continue

  host_alias="$(echo "$line" | jq -r '.ssh_host_alias')"
  vm_name="$(echo "$line" | jq -r '.vm_name')"
  public_ip="$(echo "$line" | jq -r '.public_ip')"
  admin_user="$(echo "$line" | jq -r '.admin_user')"
  identity_file="$(echo "$line" | jq -r '.ssh_identity_file // empty')"
  if [[ -z "$identity_file" ]]; then
    identity_file="${IDENTITY_FILE:-$HOME/.ssh/id_rsa}"
  fi

  {
    printf '%s\n' "${MANAGED_BEGIN} ${host_alias}"
    echo "# ${vm_name}"
    echo "Host ${host_alias}"
    echo "    HostName ${public_ip}"
    echo "    User ${admin_user}"
    echo "    IdentityFile ${identity_file}"
    printf '%s\n' "${MANAGED_END} ${host_alias}"
  } >>"$blocks_tmp"

  echo "Synced SSH host: $host_alias ($public_ip)"
  added=$((added + 1))
done < <(echo "$hosts_json" | jq -c '.[] | select(.public_ip != null and .public_ip != "")')

if [[ -s "$blocks_tmp" ]]; then
  if [[ -s "$SSH_CONFIG" ]] && grep -q '[^[:space:]]' "$SSH_CONFIG"; then
    if [[ -n "$(tail -c 1 "$SSH_CONFIG")" ]]; then
      echo >>"$SSH_CONFIG"
    fi
    echo >>"$SSH_CONFIG"
  fi
  cat "$blocks_tmp" >>"$SSH_CONFIG"
fi

if [[ "$host_count" -eq 0 ]]; then
  echo "No hosts in terraform state; removed all terraform-managed SSH blocks."
elif [[ "$added" -eq 0 ]]; then
  echo "No public IPs in terraform state; removed all terraform-managed SSH blocks."
else
  echo "Synced $added terraform-managed SSH host(s)."
fi
