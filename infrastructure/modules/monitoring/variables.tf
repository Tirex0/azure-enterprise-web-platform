variable "sharedservices_resource_group_name" {
  type        = string
  description = "Resource group where shared monitoring services are deployed."
}

variable "workspace_name" {
  type        = string
  description = "Name of the Log Analytics Workspace."
}

variable "app_vm_id" {
  type        = string
  description = "Resource ID of the application VM."
}

variable "web_vmss_id" {
  type        = string
  description = "Resource ID of the web VMSS."
}

variable "app_gateway_id" {
  type        = string
  description = "Resource ID of the Application Gateway."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}
