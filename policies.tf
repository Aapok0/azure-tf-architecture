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

resource "azurerm_subscription_policy_assignment" "inherited_rg_tags_pa" {
  for_each             = var.inherited_rg_tags
  name                 = "${data.azurerm_subscription.current.display_name}-inherited-rg-tags-pa"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"
  description          = "Tag (${each.value}) that is inherited from any resource group in ${data.azurerm_subscription.current.display_name}"
  display_name         = "Tag (${each.value}) that is inherited from any resource group in ${data.azurerm_subscription.current.display_name}"

  parameters = <<PARAMETERS
    {
      "tagName": {
        "value": "${each.value}"
      }
    }
  PARAMETERS
}

