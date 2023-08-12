# Resource group scope

## Allowed virtual machine sizes
resource "azurerm_resource_group_policy_assignment" "rg_allowed_vm_sku_pa" {
  count                = var.scope == "rg" ? 1 : 0
  name                 = "${var.scope_name}-allowed-vm-sku-pa"
  resource_group_id    = var.scope_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cccc23c7-8427-4f53-ad12-b6a63eb452b3"
  description          = "Allowed virtual machine SKUs in resource group ${var.scope_name}"
  display_name         = "Allowed virtual machine SKUs in resource group ${var.scope_name}"

  parameters = <<PARAMETERS
    {
      "listOfAllowedSKUs": {
        "value": ${var.sku_list}
      }
    }
  PARAMETERS
}

# Subscription scope

## Allowed virtual machine sizes
resource "azurerm_subscription_policy_assignment" "sub_allowed_vm_sku_pa" {
  count                = var.scope == "sub" ? 1 : 0
  name                 = "${var.scope_name}-allowed-vm-sku-pa"
  subscription_id      = var.scope_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cccc23c7-8427-4f53-ad12-b6a63eb452b3"
  description          = "Allowed virtual machine SKUs in subscription ${var.scope_name}"
  display_name         = "Allowed virtual machine SKUs in subscription ${var.scope_name}"

  parameters = <<PARAMETERS
    {
      "listOfAllowedSKUs": {
        "value": ${var.sku_list}
      }
    }
  PARAMETERS
}
