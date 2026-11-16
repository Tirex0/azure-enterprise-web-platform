data "azurerm_resource_group" "sharedservices" {
  name = var.sharedservices_resource_group_name
}

resource "azurerm_log_analytics_workspace" "log_analytics_main" {
  name                = var.workspace_name
  location            = data.azurerm_resource_group.sharedservices.location
  resource_group_name = data.azurerm_resource_group.sharedservices.name
  sku                 = "PerGB2018"
  retention_in_days   = 90

  internet_query_access_type = "Disabled"
}

resource "azurerm_monitor_data_collection_rule" "enterprise_web" {
  name                = "dcr-enterprise-web-${var.environment}"
  resource_group_name = data.azurerm_resource_group.sharedservices.name
  location            = data.azurerm_resource_group.sharedservices.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.log_analytics_main.id
      name                  = "log-analytics-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["log-analytics-destination"]
  }

  data_sources {
    syslog {
      facility_names = ["*"]
      log_levels     = ["*"]
      name           = "linux-syslog"
      streams        = ["Microsoft-Syslog"]
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "app_vm" {
  name                    = "app-vm-dcr-association"
  target_resource_id      = var.app_vm_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.enterprise_web.id
}

resource "azurerm_monitor_data_collection_rule_association" "web_vmss" {
  name                    = "web-vmss-dcr-association"
  target_resource_id      = var.web_vmss_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.enterprise_web.id
}

data "azurerm_monitor_diagnostic_categories" "app_gateway" {
  resource_id = var.app_gateway_id
}

resource "azurerm_monitor_diagnostic_setting" "app_gateway" {
  name                           = "diag-app-gateway-${var.environment}"
  target_resource_id             = var.app_gateway_id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.log_analytics_main.id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.app_gateway.log_category_types

    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.app_gateway.metrics

    content {
      category = enabled_metric.value
    }
  }
}
