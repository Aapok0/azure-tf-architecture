module "rg_tags" {
  source = "./rg_tags"
  count  = var.scope == "rg" ? 1 : 0

  # Scope of the policies
  scope_name = var.scope_name
  scope_id   = var.scope_id
  location   = var.location

  # Required in all resources
  required_tags = var.required_tags

  # Required in all resource groups
  required_rg_tags = var.required_rg_tags

  # Inherited from resource groups
  inherited_tags = var.inherited_tags
}

module "sub_tags" {
  source = "./sub_tags"
  count  = var.scope == "sub" ? 1 : 0

  # Scope of the policies
  scope_name = var.scope_name
  scope_id   = var.scope_id
  location   = var.location

  # Required in all resources
  required_tags = var.required_tags

  # Required in all resource groups
  required_rg_tags = var.required_rg_tags

  # Inherited from resource groups
  inherited_tags = var.inherited_tags
}
