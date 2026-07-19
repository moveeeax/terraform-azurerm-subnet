# terraform-azurerm-subnet

Terraform module that manages an [Azure](https://azure.microsoft.com/) subnet
within an existing virtual network. It supports service endpoints and service
delegations, allowing the subnet to be dedicated to services such as Azure
Container Instances or the PostgreSQL Flexible Server.

## Usage

```hcl
module "subnet" {
  source = "github.com/moveeeax/terraform-azurerm-subnet"

  name                 = "app-subnet"
  resource_group_name  = "prod-rg"
  virtual_network_name = "prod-vnet"
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| azurerm   | >= 3.0   |

## Inputs

| Name                                            | Description                                                                     | Type           | Default      | Required |
|-------------------------------------------------|---------------------------------------------------------------------------------|----------------|--------------|:--------:|
| `name`                                          | Name of the subnet.                                                             | `string`       | n/a          |   yes    |
| `resource_group_name`                           | Name of the resource group in which the virtual network exists.                 | `string`       | n/a          |   yes    |
| `virtual_network_name`                          | Name of the virtual network to which the subnet belongs.                        | `string`       | n/a          |   yes    |
| `address_prefixes`                              | List of address prefixes, in CIDR notation, assigned to the subnet.             | `list(string)` | n/a          |   yes    |
| `service_endpoints`                             | List of service endpoints to associate with the subnet.                         | `list(string)` | `[]`         |    no    |
| `private_endpoint_network_policies`             | Enablement of network policies for private endpoints.                           | `string`       | `"Disabled"` |    no    |
| `private_link_service_network_policies_enabled` | Whether network policies for the private link service on the subnet are enabled.| `bool`         | `true`       |    no    |
| `delegations`                                   | List of service delegations applied to the subnet.                              | `list(object)` | `[]`         |    no    |

## Outputs

| Name               | Description                            |
|--------------------|----------------------------------------|
| `id`               | ID of the subnet.                      |
| `name`             | Name of the subnet.                    |
| `address_prefixes` | Address prefixes assigned to the subnet.|

## License

[MIT](LICENSE)
