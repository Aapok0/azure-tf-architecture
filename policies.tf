# Location policy assignments

resource "azurerm_subscription_policy_assignment" "allowed_rg_locations_pa" {
  name                 = "${data.azurerm_subscription.current.display_name}-allowed-rg-locations-pa"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
  description          = "Allowed resource group locations in subscription ${data.azurerm_subscription.current.display_name}"
  display_name         = "Allowed resource group locations in ${data.azurerm_subscription.current.display_name}"

  parameters = <<PARAMETERS
    {
      "listOfAllowedLocations": {
        "value": ${var.location_list}
      }
    }
  PARAMETERS
}

resource "azurerm_subscription_policy_assignment" "allowed_locations_pa" {
  name                 = "${data.azurerm_subscription.current.display_name}-allowed-locations-pa"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  description          = "Allowed resource locations in subscription ${data.azurerm_subscription.current.display_name}"
  display_name         = "Allowed resource locations in ${data.azurerm_subscription.current.display_name}"

  parameters = <<PARAMETERS
    {
      "listOfAllowedLocations": {
        "value": ${var.location_list}
      }
    }
  PARAMETERS
}

# Tagging policy assignments:

resource "azurerm_subscription_policy_assignment" "required_tags_pa" {
  for_each             = var.required_tags
  name                 = "${data.azurerm_subscription.current.display_name}-required-tags-pa-${each.value["id"]}"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
  description          = "Tag (${each.value["key"]}) required in all resources in ${data.azurerm_subscription.current.display_name}"
  display_name         = "Tag (${each.value["key"]}) required in all resources in ${data.azurerm_subscription.current.display_name}"
  location             = var.location # Required, when identity is used

  identity { # Required since the assignment creates a tag, if missing
    type = "SystemAssigned"
  }

  parameters = <<PARAMETERS
    {
      "tagName": {
        "value": "${each.value["key"]}"
      }
    }
  PARAMETERS
}

resource "azurerm_subscription_policy_assignment" "required_rg_tags_pa" {
  for_each             = merge(var.required_tags, var.required_rg_tags)
  name                 = "${data.azurerm_subscription.current.display_name}-required-rg-tags-pa-${each.value["id"]}"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  description          = "Tag (${each.value["key"]}) required in all resource groups in ${data.azurerm_subscription.current.display_name}"
  display_name         = "Tag (${each.value["key"]}) required in all resource groups in ${data.azurerm_subscription.current.display_name}"
  location             = var.location # Required, when identity is used

  identity { # Required since the assignment creates a tag, if missing
    type = "SystemAssigned"
  }

  parameters = <<PARAMETERS
    {
      "tagName": {
        "value": "${each.value["key"]}"
      }
    }
  PARAMETERS
}

resource "azurerm_subscription_policy_assignment" "inherited_rg_tags_pa" {
  for_each             = var.required_rg_tags
  name                 = "${data.azurerm_subscription.current.display_name}-inherited-rg-tags-pa-${each.value["id"]}"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"
  description          = "Tag (${each.value["key"]}) that is inherited from any resource group in ${data.azurerm_subscription.current.display_name}"
  display_name         = "Tag (${each.value["key"]}) that is inherited from any resource group in ${data.azurerm_subscription.current.display_name}"
  location             = var.location # Required, when identity is used

  identity { # Required since the assignment creates a tag, if missing
    type = "SystemAssigned"
  }

  parameters = <<PARAMETERS
    {
      "tagName": {
        "value": "${each.value["key"]}"
      }
    }
  PARAMETERS
}

