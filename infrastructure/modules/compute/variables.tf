variable "resource_group_name" {
  type        = string
  description = "Resource group name where compute resources will be deployed."
}

variable "resource_group_location" {
  type        = string
  description = "Location of the resource group where compute resources will be deployed."
}

variable "app_subnet_id" {
  type        = string
  description = "ID of the application subnet."
}

variable "web_subnet_id" {
  type        = string
  description = "ID of the web subnet."
}

variable "app_vm" {
  type = map(object({
    name                  = string
    size                  = string
    admin_username        = string
    private_ip_allocation = string
  }))
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

variable "ssh_public_key" {
  type        = string
  description = "SSH public key used to access Linux virtual machines."
  sensitive   = true
}

variable "environment" {
  type        = string
  description = "Deployment environment used in the app health page."
}

variable "application_gateway_backend_address_pool_ids" {
  type        = list(string)
  description = "Application Gateway backend address pools attached to the web VMSS."
}
