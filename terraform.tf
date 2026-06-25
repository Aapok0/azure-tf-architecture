terraform {
  required_version = "~>1.5.4" # At least this version, but not the next minor or major version
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.68.0" # At least this version, but not the next minor or major version
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.5.1" # At least this version, but not the next minor or major version
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {} # Required even when empty

  # Avoid auto-registration failures for deprecated/unavailable RPs (e.g. Microsoft.MixedReality).
  # Required providers for this stack should already be registered on the subscription.
  skip_provider_registration = true
}
