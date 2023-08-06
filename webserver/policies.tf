resource "azurerm_resource_group_policy_assignment" "rg_tags_pa" {
  for_each             = local.tags
  name                 = "${local.name_prefix}-rg-tags-pa-${each.value["id"]}"
  resource_group_id    = azurerm_resource_group.webserver_rg.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/726aca4c-86e9-4b04-b0c5-073027359532"
  description          = "Tag (${each.value["key"]}) to be added to resource group ${azurerm_resource_group.webserver_rg.name}."
  display_name         = "Tag (${each.value["key"]}) to be added to resource group ${azurerm_resource_group.webserver_rg.name}"
  location             = azurerm_resource_group.webserver_rg.location # Required, when identity is used

  identity { # Required since the assignment creates a tag, if missing
    type = "SystemAssigned"
  }

  parameters = <<PARAMETERS
    {
      "tagName": {
        "value": "${each.value["key"]}"
      },
      "tagValue": {
        "value": "${each.value["value"]}"
      }
    }
  PARAMETERS
}
