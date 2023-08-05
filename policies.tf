resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "${data.azurerm_subscription.current.display_name}-allowed-locations-policy"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  description          = "Allowed locations in subscription ${data.azurerm_subscription.current.display_name}."
  display_name         = "Allowed locations in ${data.azurerm_subscription.current.display_name}"

  metadata = <<METADATA
    {
      "category": "Locations"
    }
  METADATA

  parameters = <<PARAMETERS
    {
      "listOfAllowedLocations": {
        "value": ${var.location_list}
      }
    }
  PARAMETERS

}
