variable "resource_groups" {
  description = "Values of resources groups needed for the configuration"
  type = map(object({
    name     = string
    location = string
  }))
}


variable "vnet_details" {
  type = map(object({
    name          = string
    address_space = list(string)
  }))
}


variable "subnet_details" {
  type = map(object({
    name             = string
    address_prefixes = list(string)
  }))
}


variable "nsg_rules" {
  type = map(map(object({
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_subnet              = optional(string)
    source_address_prefix      = optional(string)
    source_port_range          = string
    destination_address_prefix = string
    destination_port_range     = string
  })))
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

variable "workspace_name" {
  type        = string
  description = "Name of the Log Analytics Workspace declared as an input variable for reusability purposes."
}

variable "ssl_certificate_path" {
  type        = string
  description = "Path to the Application Gateway PFX certificate."
}

variable "ssl_certificate_password" {
  type        = string
  sensitive   = true
  description = "Password for the Application Gateway PFX certificate."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "ssh_public_key" {
  description = "SSH public key used to access Linux virtual machines."
  type        = string
  sensitive   = true
}
