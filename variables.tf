variable "name" {
  description = "Name of the subnet."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which the virtual network exists."
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the virtual network to which the subnet belongs."
  type        = string
}

variable "address_prefixes" {
  description = "List of address prefixes, in CIDR notation, assigned to the subnet."
  type        = list(string)

  validation {
    condition     = length(var.address_prefixes) > 0
    error_message = "At least one address prefix must be provided."
  }
}

variable "service_endpoints" {
  description = "List of service endpoints to associate with the subnet, e.g. Microsoft.Storage."
  type        = list(string)
  default     = []
}

variable "private_endpoint_network_policies" {
  description = "Enablement of network policies for private endpoints. One of Disabled, Enabled, NetworkSecurityGroupEnabled or RouteTableEnabled."
  type        = string
  default     = "Disabled"
}

variable "private_link_service_network_policies_enabled" {
  description = "Whether network policies for the private link service on the subnet are enabled."
  type        = bool
  default     = true
}

variable "delegations" {
  description = "List of service delegations applied to the subnet, each with a name, service_name and list of actions."
  type = list(object({
    name         = string
    service_name = string
    actions      = list(string)
  }))
  default = []
}
