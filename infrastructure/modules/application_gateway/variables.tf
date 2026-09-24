variable "resource_group_name" {
  type        = string
  description = "Resource group name where networking resources will be deployed."
}

variable "resource_group_location" {
  type        = string
  description = "Location of the resource group where networking resources will be deployed."
}

variable "app_gateway_name" {
  type        = string
  description = "Name of the Application Gateway."
}


variable "app_gateway_subnet_id" {
  type        = string
  description = "ID of the subnet where the Application Gateway will be deployed."
}

variable "ssl_certificate_path" {
  type        = string
  description = "Path to the PFX certificate used by the Application Gateway HTTPS listener."
}

variable "ssl_certificate_password" {
  type        = string
  sensitive   = true
  description = "Password for the Application Gateway PFX certificate."
}
