variable "resource_group_name" {
  type        = string
  description = "Resource group name where networking resources will be deployed."
}

variable "resource_group_location" {
  type        = string
  description = "Location of the resource group where networking resources will be deployed."
}


variable "app_vm" {
  type = map(object({
    name                  = string
    size                  = string
    admin_username        = string
    private_ip_allocation = string
  }))
}

variable "app_subnet_id" {
  type = string
}

variable "web_vmss" {
  type = object({
    name           = string
    sku            = string
    instances      = number
    admin_username = string
    autoscale_min  = number
    autoscale_max  = number
    image_sku      = string
  })
}
variable "web_subnet_id" {
  type = string
}


variable "application_gateway_backend_address_pool_ids" {
  type        = list(string)
  description = "List of backend address pool IDs for the application gateway."
  default     = []
}
