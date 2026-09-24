data "azurerm_resource_group" "sharedservices" {
  name = "sharedservices-rg"
}

resource "azurerm_log_analytics_workspace" "log_analytics_main" {
  name                = var.workspace_name
  location            = data.azurerm_resource_group.sharedservices.location
  resource_group_name = data.azurerm_resource_group.sharedservices.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
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
