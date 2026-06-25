#!/usr/bin/env bash
# One-time bootstrap for Terraform remote state in Azure.
# Creates a resource group, storage account, and blob container.
#
# Resource group naming matches azure-tf-architecture:
#   {region}-{environment}-{project}-rg   e.g. sdc-prd-homepage-rg
#   {region}-{project}-rg when environment is "all"   e.g. sdc-tfstate-rg, sdc-nwatcher-rg
#
# Subscription policies require RG tags: owner, location, environment, project.
#
# Usage:
#   ./scripts/bootstrap-remote-state.sh --owner "Your Name"
#   ./scripts/bootstrap-remote-state.sh --owner "Your Name" --storage-account mytfstate1234
#
# Writes backend.hcl from backend.hcl.example, then run:
#   terraform init -backend-config=backend.hcl
#   terraform init -migrate-state -backend-config=backend.hcl   # if local state exists

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_EXAMPLE="${BACKEND_EXAMPLE:-$ROOT_DIR/backend.hcl.example}"
BACKEND_HCL="${BACKEND_HCL:-$ROOT_DIR/backend.hcl}"

LOCATION="${LOCATION:-swedencentral}"
RESOURCE_GROUP=""
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-}"
CONTAINER_NAME="${CONTAINER_NAME:-tfstate}"
STATE_KEY="${STATE_KEY:-subscription.tfstate}"
FORCE_BACKEND=0

TAG_OWNER="${TAG_OWNER:-}"
TAG_LOCATION=""
TAG_ENVIRONMENT="${TAG_ENVIRONMENT:-all}"
TAG_PROJECT="${TAG_PROJECT:-tfstate}"
TAG_SOURCE="${TAG_SOURCE:-bootstrap}"

usage() {
  echo "Usage: $0 --owner NAME [options]"
  echo
  echo "Options:"
  echo "  --owner NAME            Owner tag (required; prompted if omitted in a TTY)"
  echo "  --location REGION       Azure region (default: swedencentral)"
  echo "  --environment ENV       Environment tag (default: all)"
  echo "  --project PROJECT       Project tag (default: tfstate)"
  echo "  --resource-group NAME   Override computed RG name"
  echo "  --storage-account NAME  Storage account name (generated if omitted)"
  echo "  --force-backend         Overwrite backend.hcl without prompting"
  echo
  echo "Environment overrides: TAG_OWNER TAG_LOCATION TAG_ENVIRONMENT TAG_PROJECT"
  exit 1
}

location_abbreviation() {
  case "$1" in
    northeurope) echo ne ;;
    norwayeast) echo nwe ;;
    swedencentral) echo sdc ;;
    westeurope) echo we ;;
    *)
      echo "Unsupported location: $1 (expected northeurope, norwayeast, swedencentral, or westeurope)" >&2
      exit 1
      ;;
  esac
}

resource_group_name() {
  local loc_abbr="$1"
  local env="$2"
  local project="$3"

  if [[ "$env" == "all" ]]; then
    echo "${loc_abbr}-${project}-rg"
  else
    echo "${loc_abbr}-${env}-${project}-rg"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) TAG_OWNER="$2"; shift 2 ;;
    --location) LOCATION="$2"; shift 2 ;;
    --environment) TAG_ENVIRONMENT="$2"; shift 2 ;;
    --project) TAG_PROJECT="$2"; shift 2 ;;
    --resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
    --storage-account) STORAGE_ACCOUNT="$2"; shift 2 ;;
    --force-backend) FORCE_BACKEND=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

if [[ -z "$TAG_OWNER" ]]; then
  if [[ -t 0 ]]; then
    read -r -p "Owner tag (required by policy): " TAG_OWNER
  else
    echo "Owner tag required: pass --owner or set TAG_OWNER." >&2
    exit 1
  fi
fi

if [[ -z "$TAG_OWNER" ]]; then
  echo "Owner tag cannot be empty." >&2
  exit 1
fi

TAG_LOCATION="${TAG_LOCATION:-$LOCATION}"
LOC_ABBR="$(location_abbreviation "$LOCATION")"

if [[ -z "$RESOURCE_GROUP" ]]; then
  RESOURCE_GROUP="$(resource_group_name "$LOC_ABBR" "$TAG_ENVIRONMENT" "$TAG_PROJECT")"
fi

if [[ -z "$STORAGE_ACCOUNT" ]]; then
  suffix="$(openssl rand -hex 3 2>/dev/null || echo "$RANDOM")"
  STORAGE_ACCOUNT="${LOC_ABBR}tfstate${suffix}"
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI (az) is required." >&2
  exit 1
fi

rg_tags=(
  "owner=${TAG_OWNER}"
  "location=${TAG_LOCATION}"
  "environment=${TAG_ENVIRONMENT}"
  "project=${TAG_PROJECT}"
  "source=${TAG_SOURCE}"
)

echo "Creating resource group: $RESOURCE_GROUP ($LOCATION)"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags "${rg_tags[@]}" \
  --output none

echo "Creating storage account: $STORAGE_ACCOUNT (Standard_LRS)"
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags "${rg_tags[@]}" \
  --output none

echo "Creating blob container: $CONTAINER_NAME"
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --output none

write_backend_hcl() {
  if [[ ! -f "$BACKEND_EXAMPLE" ]]; then
    echo "backend.hcl.example not found at: $BACKEND_EXAMPLE" >&2
    exit 1
  fi

  if [[ -f "$BACKEND_HCL" && "$FORCE_BACKEND" -ne 1 ]]; then
    if [[ -t 0 ]]; then
      read -r -p "backend.hcl already exists. Overwrite? [y/N] " confirm
      if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Keeping existing backend.hcl"
        return
      fi
    else
      echo "backend.hcl already exists. Pass --force-backend to overwrite." >&2
      exit 1
    fi
  fi

  cp "$BACKEND_EXAMPLE" "$BACKEND_HCL"
  sed -i \
    -e "s|^resource_group_name.*|resource_group_name  = \"${RESOURCE_GROUP}\"|" \
    -e "s|^storage_account_name.*|storage_account_name = \"${STORAGE_ACCOUNT}\"|" \
    -e "s|^container_name.*|container_name       = \"${CONTAINER_NAME}\"|" \
    -e "s|^key.*|key                  = \"${STATE_KEY}\"|" \
    "$BACKEND_HCL"

  echo "Wrote $BACKEND_HCL"
}

write_backend_hcl

cat <<EOF

Bootstrap complete.

  Resource group:   $RESOURCE_GROUP
  Storage account:  $STORAGE_ACCOUNT
  Container:        $CONTAINER_NAME
  State key:        $STATE_KEY
  Backend config:   $BACKEND_HCL

From the azure-tf-architecture repository root:

  terraform init -backend-config=backend.hcl
  terraform init -migrate-state -backend-config=backend.hcl   # only if migrating local state

EOF
