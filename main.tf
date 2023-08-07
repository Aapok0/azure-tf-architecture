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
}

provider "azurerm" {
  features {} # Required even, when empty
}

# Already existing data from Azure

data "azurerm_subscription" "current" {}

# Modules

module "webserver_homepage_prd" {
  source      = "./webserver"
  location    = "swedencentral"
  environment = "prd"
  project     = "homepage"
  tf_tags     = var.tf_tags
}
