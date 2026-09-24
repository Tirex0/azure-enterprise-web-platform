module "resource_groups" {
  source = "./modules/resource_groups"

  resource_groups = var.resource_groups
}


module "networking" {
  source = "./modules/networking"

  resource_group_name     = module.resource_groups.resource_group_name["network"]
  resource_group_location = module.resource_groups.resource_group_location["network"]

  vnet_details   = var.vnet_details
  subnet_details = var.subnet_details
  nsg_rules      = var.nsg_rules
}


module "compute" {
  source = "./modules/compute"

  resource_group_name     = module.resource_groups.resource_group_name["network"]
  resource_group_location = module.resource_groups.resource_group_location["network"]

  app_subnet_id = module.networking.subnet_ids["app_subnet"]
  web_subnet_id = module.networking.subnet_ids["web_subnet"]

  app_vm   = var.app_vm
  web_vmss = var.web_vmss

  application_gateway_backend_address_pool_ids = [
    module.application_gateway.backend_address_pool_id
  ]
}


module "application_gateway" {
  source = "./modules/application_gateway"

  resource_group_name     = module.resource_groups.resource_group_name["network"]
  resource_group_location = module.resource_groups.resource_group_location["network"]

  app_gateway_name      = "app-gateway-01"
  app_gateway_subnet_id = module.networking.subnet_ids["app_gateway"]

  ssl_certificate_path     = var.ssl_certificate_path
  ssl_certificate_password = var.ssl_certificate_password
}

module "monitoring" {
  source         = "./modules/monitoring"
  workspace_name = var.workspace_name
  app_vm_id      = module.compute.app_vm_id
  web_vmss_id    = module.compute.web_vmss_id
  environment    = var.environment
}
