# Note: `azurerm_virtual_network` also accepts inline `subnet` blocks, and that
# attribute is authoritative - a virtual network that declares it deletes and
# recreates every subnet it does not list, including subnets managed as
# standalone `azurerm_subnet` resources like this one. The companion module
# terraform-azurerm-vnet deliberately never sets it, so the two compose safely.
# See README.md ("Use with terraform-azurerm-vnet").
resource "azurerm_subnet" "this" {
  name                 = var.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.address_prefixes

  private_endpoint_network_policies             = var.private_endpoint_network_policies
  private_link_service_network_policies_enabled = var.private_link_service_network_policies_enabled

  # azurerm 5.0 replaced the `service_endpoints` list with one
  # `service_endpoint` block per service. The input stays a list of service
  # names so callers upgrading from 1.x keep the same interface.
  dynamic "service_endpoint" {
    for_each = var.service_endpoints
    content {
      service = service_endpoint.value
    }
  }

  dynamic "delegation" {
    for_each = var.delegations
    content {
      name = delegation.value.name
      service_delegation {
        name = delegation.value.service_name
        # Null, rather than an empty set, so that Azure applies the
        # delegation's default action set when the caller omits `actions`.
        actions = delegation.value.actions
      }
    }
  }
}

# Since azurerm 3.0 the network security group and route table links are no
# longer attributes of `azurerm_subnet`; the association resources below are the
# only supported way to express them.
resource "azurerm_subnet_network_security_group_association" "this" {
  count = var.network_security_group_id == null ? 0 : 1

  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = var.network_security_group_id
}

resource "azurerm_subnet_route_table_association" "this" {
  count = var.route_table_id == null ? 0 : 1

  subnet_id      = azurerm_subnet.this.id
  route_table_id = var.route_table_id
}
