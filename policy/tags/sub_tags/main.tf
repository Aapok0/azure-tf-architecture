# Required tags in resources

resource "azurerm_subscription_policy_assignment" "sub_required_tags_pa" {
  for_each             = var.required_tags
  name                 = "${var.scope_name}-required-tags-pa-${each.value["id"]}"
  subscription_id      = var.scope_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
  description          = "Tag (${each.value["key"]}) required in all resources in subscription ${var.scope_name}"
  display_name         = "Tag (${each.value["key"]}) required in all resources in subscription ${var.scope_name}"

  parameters = <<PARAMETERS
    {
      "tagName": {
        "value": "${each.value["key"]}"
      }
    }
  PARAMETERS
}

# Required tags in resource groups

resource "azurerm_subscription_policy_assignment" "sub_required_rg_tags_pa" {
  for_each             = var.required_rg_tags
  name                 = "${var.scope_name}-required-rg-tags-pa-${each.value["id"]}"
  subscription_id      = var.scope_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  description          = "Tag (${each.value["key"]}) required in all resource groups in subscription ${var.scope_name}"
  display_name         = "Tag (${each.value["key"]}) required in all resource groups in subscription ${var.scope_name}"

  parameters = <<PARAMETERS
    {
      "tagName": {
        "value": "${each.value["key"]}"
      }
    }
  PARAMETERS
}

# Tags that resources inherit from resource groups

resource "azurerm_subscription_policy_assignment" "sub_inherited_rg_tags_pa" {
  for_each             = var.inherited_tags
  name                 = "${var.scope_name}-inherited-rg-tags-pa-${each.value["id"]}"
  subscription_id      = var.scope_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"
  description          = "Tag (${each.value["key"]}) that is inherited from any resource group in subscription ${var.scope_name}"
  display_name         = "Tag (${each.value["key"]}) that is inherited from any resource group in subscription ${var.scope_name}"
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
