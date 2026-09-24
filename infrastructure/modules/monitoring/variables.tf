variable "workspace_name" {
  type        = string
  description = "Name of the Log Analytics Workspace declared as an input variable for reusability purposes."
}


variable "app_vm_id" {
  type        = string
  description = "Resource ID of the application VM."
}

variable "web_vmss_id" {
  type        = string
  description = "Resource ID of the web VMSS."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}
