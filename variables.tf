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

  validation {
    condition     = alltrue([for cidr in var.address_prefixes : can(cidrhost(cidr, 0))])
    error_message = "Every entry in address_prefixes must be a valid IPv4 or IPv6 CIDR range, for example \"10.0.1.0/24\"."
  }

  # Azure stores the masked network address, so a prefix carrying host bits
  # ("10.0.1.5/24") is either rejected outright or normalised to "10.0.1.0/24"
  # and then produces a permanent diff. Comparing against the same address
  # masked to a host prefix normalises formatting, so shorthand IPv6 is not
  # falsely rejected.
  validation {
    condition = alltrue([
      for cidr in var.address_prefixes : try(
        cidrhost(cidr, 0) == cidrhost("${split("/", cidr)[0]}/${strcontains(cidr, ":") ? 128 : 32}", 0),
        true
      )
    ])
    error_message = "Every entry in address_prefixes must be the network address of its range, for example \"10.0.1.0/24\" rather than \"10.0.1.5/24\"."
  }
}

variable "service_endpoints" {
  description = "List of service endpoints to associate with the subnet, e.g. Microsoft.Storage."
  type        = list(string)
  default     = []
}

variable "private_endpoint_network_policies" {
  description = <<-EOT
    Enablement of network policies for private endpoints. One of `Disabled`,
    `Enabled`, `NetworkSecurityGroupEnabled` or `RouteTableEnabled`. `Disabled`
    matches the Azure default; `Enabled` makes network security group and route
    table rules apply to private endpoint traffic in this subnet.
  EOT
  type        = string
  default     = "Disabled"

  validation {
    condition = contains(
      ["Disabled", "Enabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"],
      var.private_endpoint_network_policies
    )
    error_message = "private_endpoint_network_policies must be one of \"Disabled\", \"Enabled\", \"NetworkSecurityGroupEnabled\" or \"RouteTableEnabled\"."
  }
}

variable "private_link_service_network_policies_enabled" {
  description = "Whether network policies for the private link service on the subnet are enabled. Must be false in the subnet that hosts a private link service."
  type        = bool
  default     = true
}

variable "delegations" {
  description = <<-EOT
    List of service delegations applied to the subnet. `service_name` is the
    Azure delegation identifier, for example
    `Microsoft.DBforPostgreSQL/flexibleServers`; a name Azure does not know is
    only rejected at apply time. `actions` may be omitted, in which case Azure
    applies the delegation's own default action set.
  EOT

  type = list(object({
    name         = string
    service_name = string
    actions      = optional(list(string))
  }))
  default = []

  # Delegation identifiers are always "<Namespace>/<resourceType>", e.g.
  # "Microsoft.ContainerInstance/containerGroups". This catches the common
  # typos - a bare service name, a trailing slash, a resource ID pasted by
  # mistake - locally instead of after a round trip to the Azure API.
  validation {
    condition = alltrue([
      for delegation in var.delegations :
      can(regex("^[A-Za-z][A-Za-z0-9]*(\\.[A-Za-z][A-Za-z0-9]*)+(/[A-Za-z][A-Za-z0-9]*)+$", delegation.service_name))
    ])
    error_message = "Every delegations[*].service_name must look like \"Microsoft.DBforPostgreSQL/flexibleServers\": an Azure resource provider namespace, a slash and a resource type."
  }

  validation {
    condition     = length(distinct([for delegation in var.delegations : delegation.name])) == length(var.delegations)
    error_message = "delegations[*].name must be unique within a subnet."
  }
}

variable "network_security_group_id" {
  description = <<-EOT
    Resource ID of an existing network security group to associate with the
    subnet. `null` creates no association, leaving any association managed
    elsewhere untouched.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.network_security_group_id == null ? true : can(regex("^/subscriptions/[^/]+/", var.network_security_group_id))
    error_message = "network_security_group_id must be the full Azure resource ID of a network security group, starting with \"/subscriptions/\"."
  }
}

variable "route_table_id" {
  description = <<-EOT
    Resource ID of an existing route table to associate with the subnet. `null`
    creates no association, leaving any association managed elsewhere
    untouched.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.route_table_id == null ? true : can(regex("^/subscriptions/[^/]+/", var.route_table_id))
    error_message = "route_table_id must be the full Azure resource ID of a route table, starting with \"/subscriptions/\"."
  }
}
