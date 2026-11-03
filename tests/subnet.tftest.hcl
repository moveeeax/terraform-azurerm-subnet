# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or OpenTofu
# >= 1.7). The module itself still supports Terraform >= 1.5 - running the
# tests is not a prerequisite for using it. Mocking keeps `terraform test`
# offline: no Azure credentials and no API calls.
#
# The subnet ID is pinned to a well-formed one because the association
# resources validate the shape of `subnet_id`, and OpenTofu fills mocked
# attributes in during plan rather than leaving them unknown.
mock_provider "azurerm" {
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Network/virtualNetworks/example-vnet/subnets/app-subnet"
    }
  }
}

variables {
  name                 = "app-subnet"
  resource_group_name  = "example-rg"
  virtual_network_name = "example-vnet"
  address_prefixes     = ["10.0.1.0/24"]
}

run "defaults_are_conservative" {
  command = plan

  assert {
    condition     = azurerm_subnet.this.private_endpoint_network_policies == "Disabled"
    error_message = "private_endpoint_network_policies should default to Disabled, matching the Azure default."
  }

  assert {
    condition     = azurerm_subnet.this.private_link_service_network_policies_enabled == true
    error_message = "private_link_service_network_policies_enabled should default to true; it is only turned off for a subnet hosting a private link service."
  }

  assert {
    condition     = length(azurerm_subnet_network_security_group_association.this) == 0
    error_message = "No network security group association should be created when network_security_group_id is null."
  }

  assert {
    condition     = length(azurerm_subnet_route_table_association.this) == 0
    error_message = "No route table association should be created when route_table_id is null."
  }
}

run "associations_are_created_when_ids_are_given" {
  command = plan

  variables {
    network_security_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Network/networkSecurityGroups/example-nsg"
    route_table_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Network/routeTables/example-rt"
  }

  assert {
    condition     = azurerm_subnet_network_security_group_association.this[0].network_security_group_id == var.network_security_group_id
    error_message = "The network security group association should point at the supplied network security group."
  }

  assert {
    condition     = azurerm_subnet_route_table_association.this[0].route_table_id == var.route_table_id
    error_message = "The route table association should point at the supplied route table."
  }
}

run "delegation_actions_may_be_omitted" {
  command = plan

  variables {
    delegations = [
      {
        name         = "postgresql"
        service_name = "Microsoft.DBforPostgreSQL/flexibleServers"
      },
    ]
  }

  assert {
    condition     = azurerm_subnet.this.delegation[0].service_delegation[0].name == "Microsoft.DBforPostgreSQL/flexibleServers"
    error_message = "The delegation should carry the requested service name."
  }

  assert {
    condition     = azurerm_subnet.this.delegation[0].service_delegation[0].actions == null
    error_message = "An omitted actions list must stay null so Azure applies the delegation's default actions."
  }
}

run "rejects_malformed_address_prefix" {
  command = plan

  variables {
    address_prefixes = ["10.0.1.0/33"]
  }

  expect_failures = [var.address_prefixes]
}

run "rejects_address_prefix_with_host_bits" {
  command = plan

  variables {
    address_prefixes = ["10.0.1.5/24"]
  }

  expect_failures = [var.address_prefixes]
}

run "rejects_unknown_private_endpoint_network_policy" {
  command = plan

  variables {
    private_endpoint_network_policies = "NotAValidValue"
  }

  expect_failures = [var.private_endpoint_network_policies]
}

run "rejects_delegation_service_name_without_namespace" {
  command = plan

  variables {
    delegations = [
      {
        name         = "postgresql"
        service_name = "flexibleServers"
      },
    ]
  }

  expect_failures = [var.delegations]
}

run "rejects_duplicate_delegation_names" {
  command = plan

  variables {
    delegations = [
      {
        name         = "duplicate"
        service_name = "Microsoft.DBforPostgreSQL/flexibleServers"
      },
      {
        name         = "duplicate"
        service_name = "Microsoft.ContainerInstance/containerGroups"
      },
    ]
  }

  expect_failures = [var.delegations]
}

run "rejects_network_security_group_name_instead_of_id" {
  command = plan

  variables {
    network_security_group_id = "example-nsg"
  }

  expect_failures = [var.network_security_group_id]
}

run "rejects_route_table_name_instead_of_id" {
  command = plan

  variables {
    route_table_id = "example-rt"
  }

  expect_failures = [var.route_table_id]
}

run "service_endpoints_become_blocks" {
  command = plan

  variables {
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
  }

  assert {
    condition     = [for endpoint in azurerm_subnet.this.service_endpoint : endpoint.service] == ["Microsoft.Storage", "Microsoft.KeyVault"]
    error_message = "Each entry in service_endpoints should become one service_endpoint block, in order."
  }
}
