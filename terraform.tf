terraform {
  required_version = ">= 1.5.7, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.79.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {} # Required even when empty

  # Subscription ID: set ARM_SUBSCRIPTION_ID or use the default from `az account set`.
  # Do not reference data sources here — azurerm 4.x creates a provider cycle.

  # azurerm 4.x: register only RPs this stack uses (replaces skip_provider_registration).
  resource_provider_registrations = "none"
  resource_providers_to_register = [
    "Microsoft.App",
    "Microsoft.Authorization",
    "Microsoft.Compute",
    "Microsoft.Consumption",
    "Microsoft.Network",
    "Microsoft.OperationalInsights",
  ]
}
