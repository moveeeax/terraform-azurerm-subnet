# terraform-azurerm-subnet

Terraform module that manages an [Azure](https://azure.microsoft.com/) subnet
within an existing virtual network. It supports service endpoints and service
delegations, allowing the subnet to be dedicated to services such as Azure
Container Instances or the PostgreSQL Flexible Server, and can associate the
subnet with an existing network security group, route table and NAT gateway.

## Usage

```hcl
module "subnet" {
  source = "github.com/moveeeax/terraform-azurerm-subnet?ref=v2.0.0"

  name                 = "app-subnet"
  resource_group_name  = "prod-rg"
  virtual_network_name = "prod-vnet"
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
}
```

A runnable example lives in [`examples/basic`](examples/basic).

### Delegation

`service_name` is the Azure delegation identifier, not a friendly name; Azure
rejects an unknown one at apply time. Leaving `actions` out applies the
delegation's own default action set, which is what you usually want:

```hcl
module "postgresql_subnet" {
  source = "github.com/moveeeax/terraform-azurerm-subnet?ref=v2.0.0"

  name                 = "pg-subnet"
  resource_group_name  = "prod-rg"
  virtual_network_name = "prod-vnet"
  address_prefixes     = ["10.0.2.0/24"]

  delegations = [
    {
      name         = "postgresql"
      service_name = "Microsoft.DBforPostgreSQL/flexibleServers"
    },
  ]
}
```

### Network security group and route table associations

Since azurerm 3.0 the network security group and route table links are no
longer attributes of `azurerm_subnet`; they are separate association resources,
and Azure allows at most one of each per subnet. Set `network_security_group_id`
and `route_table_id` to have this module own them:

```hcl
module "subnet" {
  source = "github.com/moveeeax/terraform-azurerm-subnet?ref=v2.0.0"

  name                 = "app-subnet"
  resource_group_name  = "prod-rg"
  virtual_network_name = "prod-vnet"
  address_prefixes     = ["10.0.1.0/24"]

  network_security_group_id = module.nsg.id
  route_table_id            = module.route_table.id
}
```

Leave them `null` (the default) if the association is created elsewhere -
two Terraform resources pointing at the same subnet will fight over it on every
apply.

### NAT gateway

Azure is retiring default outbound access for virtual machines, so a new subnet
needs an explicit egress path, and a NAT gateway is the usual one. Set
`nat_gateway_id` to have this module create the
`azurerm_subnet_nat_gateway_association`:

```hcl
module "subnet" {
  source = "github.com/moveeeax/terraform-azurerm-subnet?ref=v2.1.0"

  name                 = "app-subnet"
  resource_group_name  = "prod-rg"
  virtual_network_name = "prod-vnet"
  address_prefixes     = ["10.0.1.0/24"]

  nat_gateway_id = azurerm_nat_gateway.egress.id
}
```

The NAT gateway itself (and its public IP or prefix) is created outside the
module. `azurerm_subnet` has no NAT gateway argument, so this association is
the only place the link lives, and Azure allows one NAT gateway per subnet. The
same ownership rule as above applies: leave `nat_gateway_id` at `null` (the
default) when the association is declared somewhere else, for example next to
the NAT gateway, or the two resources will fight over the subnet. The default
creates nothing, so upgrading the module does not change existing plans.

### Use with terraform-azurerm-vnet

`azurerm_virtual_network` also accepts inline `subnet` blocks, and that
attribute is authoritative: a virtual network that declares it deletes and
recreates every subnet it does not list, including subnets managed as standalone
`azurerm_subnet` resources and their association resources. The companion
module [terraform-azurerm-vnet](https://github.com/moveeeax/terraform-azurerm-vnet)
deliberately never sets it, so the two modules compose safely. If you point this
module at a virtual network managed by something else, check first that it does
not declare subnets inline.

## Requirements

| Name      | Version           |
|-----------|-------------------|
| terraform | >= 1.5            |
| azurerm   | >= 5.0, < 6.0     |

azurerm 5.0 removed the `service_endpoints` argument of `azurerm_subnet` and
replaced it with repeated `service_endpoint` blocks, which 4.x does not have,
so no single configuration works against both majors. Version 2.x of this
module targets azurerm 5.x; for azurerm 3.103.0 up to 4.x use the 1.x line
(`?ref=v1.0.1`). The `service_endpoints` input is unchanged between the two.

## Inputs

| Name                                            | Description                                                                      | Type           | Default      | Required |
|-------------------------------------------------|----------------------------------------------------------------------------------|----------------|--------------|:--------:|
| `name`                                          | Name of the subnet.                                                              | `string`       | n/a          |   yes    |
| `resource_group_name`                           | Name of the resource group in which the virtual network exists.                  | `string`       | n/a          |   yes    |
| `virtual_network_name`                          | Name of the virtual network to which the subnet belongs.                         | `string`       | n/a          |   yes    |
| `address_prefixes`                              | List of address prefixes, in CIDR notation, assigned to the subnet.              | `list(string)` | n/a          |   yes    |
| `service_endpoints`                             | List of service endpoints to associate with the subnet.                          | `list(string)` | `[]`         |    no    |
| `private_endpoint_network_policies`             | Enablement of network policies for private endpoints. One of `Disabled`, `Enabled`, `NetworkSecurityGroupEnabled`, `RouteTableEnabled`. | `string` | `"Disabled"` | no |
| `private_link_service_network_policies_enabled` | Whether network policies for the private link service on the subnet are enabled. | `bool`         | `true`       |    no    |
| `delegations`                                   | List of service delegations applied to the subnet: `name`, `service_name` and optional `actions`. | `list(object)` | `[]` | no |
| `network_security_group_id`                     | Resource ID of an existing network security group to associate with the subnet.  | `string`       | `null`       |    no    |
| `route_table_id`                                | Resource ID of an existing route table to associate with the subnet.             | `string`       | `null`       |    no    |
| `nat_gateway_id`                                | Resource ID of an existing NAT gateway to associate with the subnet.             | `string`       | `null`       |    no    |

## Outputs

| Name               | Description                            |
|--------------------|----------------------------------------|
| `id`               | ID of the subnet.                      |
| `name`             | Name of the subnet.                    |
| `address_prefixes` | Address prefixes assigned to the subnet.|
| `nat_gateway_association_id` | ID of the NAT gateway association, or `null` when `nat_gateway_id` is not set. |

## Development

```sh
terraform fmt -recursive
terraform init -backend=false && terraform validate
terraform test
```

`terraform test` mocks the azurerm provider, so it needs no Azure credentials
and makes no API calls. The suite needs Terraform (or OpenTofu) >= 1.7 for
`mock_provider`; the module itself still supports >= 1.5.

## License

[MIT](LICENSE)
