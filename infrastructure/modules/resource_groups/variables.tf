variable "resource_groups" {
  description = "Values of resources groups needed for the configuration"
  type = map(object({
    name     = string
    location = string
  }))
}

