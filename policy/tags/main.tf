# Tags policy module: dispatches the tag governance policies (required tags,
# required resource group tags, inherited tags) to the scope-specific submodule.
# var.scope selects rg_tags or sub_tags; the other is count 0.

module "rg_tags" {
  source = "./rg_tags"
  count  = var.scope == "rg" ? 1 : 0

  scope_name       = var.scope_name
  scope_id         = var.scope_id
  location         = var.location
  required_tags    = var.required_tags
  required_rg_tags = var.required_rg_tags
  inherited_tags   = var.inherited_tags
}

module "sub_tags" {
  source = "./sub_tags"
  count  = var.scope == "sub" ? 1 : 0

  scope_name       = var.scope_name
  scope_id         = var.scope_id
  location         = var.location
  required_tags    = var.required_tags
  required_rg_tags = var.required_rg_tags
  inherited_tags   = var.inherited_tags
}
