#!/usr/bin/env bash
# Sync ~/.ssh/config entries from terraform output.
# Replaces only blocks between terraform-managed markers; other entries are kept.
# Hosts removed from state are dropped on the next sync.
#
# Usage (from azure-tf-architecture root):
#   ./scripts/sync-ssh-config.sh                     # default: Tailscale node name
#   ./scripts/sync-ssh-config.sh --public-ip         # use the public IP
#   ./scripts/sync-ssh-config.sh --tailnet-suffix tailXXXX.ts.net   # MagicDNS FQDN
#
# IMPORTANT: before the FIRST Ansible server_init run, Tailscale is not installed
# yet, so run with --public-ip (HostName = public IP reachable via the temporary
# NSG rule). After Tailscale is up, run with the defaults (Tailscale node name).
#
# Flags override the SSH_USE_TAILSCALE / TAILNET_SUFFIX environment variables.
#
# Requires: terraform, jq

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_CONFIG="${SSH_CONFIG:-$HOME/.ssh/config}"
IDENTITY_FILE="${IDENTITY_FILE:-}"
# SSH goes over Tailscale, so HostName points at the tailnet node name (= the VM
# name / OS hostname / MagicDNS name) rather than the public IP. Use --public-ip
# (or SSH_USE_TAILSCALE=0) for the public IP, and --tailnet-suffix (or
# TAILNET_SUFFIX) for the MagicDNS FQDN instead of the bare name.
SSH_USE_TAILSCALE="${SSH_USE_TAILSCALE:-1}"
TAILNET_SUFFIX="${TAILNET_SUFFIX:-}"
MANAGED_BEGIN='# BEGIN terraform-managed:'
MANAGED_END='# END terraform-managed:'

while [[ $# -gt 0 ]]; do
  case "$1" in
    --public-ip) SSH_USE_TAILSCALE=0 ;;
    --tailscale) SSH_USE_TAILSCALE=1 ;;
    --tailnet-suffix) SSH_USE_TAILSCALE=1; TAILNET_SUFFIX="${2:-}"; shift ;;
    --tailnet-suffix=*) SSH_USE_TAILSCALE=1; TAILNET_SUFFIX="${1#*=}" ;;
    -h | --help)
      grep '^#' "$0" | grep -v '^#!' | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

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

for cmd in terraform jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required." >&2
    exit 1
  fi
done

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

  if [[ "$SSH_USE_TAILSCALE" == "1" ]]; then
    if [[ -n "$TAILNET_SUFFIX" ]]; then
      host_name="${vm_name}.${TAILNET_SUFFIX}"
    else
      host_name="$vm_name"
    fi
  else
    host_name="$public_ip"
  fi

  {
    printf '%s\n' "${MANAGED_BEGIN} ${host_alias}"
    echo "# ${vm_name} (public IP: ${public_ip})"
    echo "Host ${host_alias}"
    echo "    HostName ${host_name}"
    echo "    User ${admin_user}"
    echo "    IdentityFile ${identity_file}"
    printf '%s\n' "${MANAGED_END} ${host_alias}"
  } >>"$blocks_tmp"

  echo "Synced SSH host: $host_alias ($host_name)"
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
