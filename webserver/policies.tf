resource "azurerm_resource_group_policy_assignment" "rg_tags_pa" {
  for_each             = local.tags
  name                 = "${local.name_prefix}-rg-tags-pa"
  resource_group_id      = resource.azurerm_resource_group.webserver_rg.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/726aca4c-86e9-4b04-b0c5-073027359532"
  description          = "Tag ${each.value["key"]} to be added to resource group ${resource.azurerm_resource_group.webserver_rg.name}."
  display_name         = "Tag ${each.value["key"]} to be added to resource group ${resource.azurerm_resource_group.webserver_rg.name}"

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
