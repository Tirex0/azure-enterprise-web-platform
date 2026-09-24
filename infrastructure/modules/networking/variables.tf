variable "resource_group_name" {
  type        = string
  description = "Resource group name where networking resources will be deployed."
}

variable "resource_group_location" {
  type        = string
  description = "Location of the resource group where networking resources will be deployed."
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

