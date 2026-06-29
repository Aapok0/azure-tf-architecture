output "workspace_id_out" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.law.id
}

output "workspace_name_out" {
  description = "Name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.law.name
}
