# Resource group scope

## Allowed locations for resource groups
resource "azurerm_resource_group_policy_assignment" "rg_allowed_rg_locations_pa" {
  count                = var.scope == "rg" ? 1 : 0
  name                 = "${var.scope_name}-allowed-rg-locations-pa"
  resource_group_id    = var.scope_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
  description          = "Allowed resource group locations in resource group ${var.scope_name}"
  display_name         = "Allowed resource group locations in resource group ${var.scope_name}"

  parameters = <<PARAMETERS
    {
      "listOfAllowedLocations": {
        "value": ${var.location_list}
      }
    }
  PARAMETERS
}

## Allowed locations for resources
resource "azurerm_resource_group_policy_assignment" "rg_allowed_locations_pa" {
  count                = var.scope == "rg" ? 1 : 0
  name                 = "${var.scope_name}-allowed-locations-pa"
  resource_group_id    = var.scope_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  description          = "Allowed resource locations in resource group ${var.scope_name}"
  display_name         = "Allowed resource locations in resource group ${var.scope_name}"

  parameters = <<PARAMETERS
    {
      "listOfAllowedLocations": {
        "value": ${var.location_list}
      }
    }
  PARAMETERS
}

# Subscription scope

## Allowed locations for resource groups
resource "azurerm_subscription_policy_assignment" "sub_allowed_rg_locations_pa" {
  count                = var.scope == "sub" ? 1 : 0
  name                 = "${var.scope_name}-allowed-rg-locations-pa"
  subscription_id      = var.scope_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
  description          = "Allowed resource group locations in subscription ${var.scope_name}"
  display_name         = "Allowed resource group locations in subscription ${var.scope_name}"

  parameters = <<PARAMETERS
    {
      "listOfAllowedLocations": {
        "value": ${var.location_list}
      }
    }
  PARAMETERS
}

## Allowed locations for resources
resource "azurerm_subscription_policy_assignment" "sub_allowed_locations_pa" {
  count                = var.scope == "sub" ? 1 : 0
  name                 = "${var.scope_name}-allowed-locations-pa"
  subscription_id      = var.scope_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  description          = "Allowed resource locations in subscription ${var.scope_name}"
  display_name         = "Allowed resource locations in subscription ${var.scope_name}"

  parameters = <<PARAMETERS
    {
      "listOfAllowedLocations": {
        "value": ${var.location_list}
      }
    }
  PARAMETERS
}
