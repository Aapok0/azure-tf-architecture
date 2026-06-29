# Container App on a Consumption environment. The environment uses the
# Azure-managed network (no VNet integration), so the module creates no subnet
# or registry. Containers in a replica share a network namespace and reach each
# other over 127.0.0.1.

resource "azurerm_container_app_environment" "env" {
  name                       = "${var.name}-env"
  location                   = var.location
  resource_group_name        = var.rg_name
  logs_destination           = var.log_analytics_workspace_id != null ? "log-analytics" : null
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = var.tags
}

resource "azurerm_container_app" "app" {
  name                         = var.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = var.rg_name
  revision_mode                = var.details.revision_mode
  tags                         = var.tags

  template {
    min_replicas = var.details.min_replicas
    max_replicas = var.details.max_replicas

    dynamic "container" {
      for_each = var.details.containers
      content {
        name   = container.value.name
        image  = container.value.image
        cpu    = container.value.cpu
        memory = container.value.memory

        dynamic "env" {
          for_each = container.value.env
          content {
            name  = env.value.name
            value = env.value.value
          }
        }
      }
    }
  }

  ingress {
    external_enabled = var.details.ingress_external
    target_port      = var.details.ingress_target_port
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
