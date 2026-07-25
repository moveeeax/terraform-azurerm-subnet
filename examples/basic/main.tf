terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.103.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "subnet" {
  source = "../.."

  name                 = "example-subnet"
  resource_group_name  = "example-rg"
  virtual_network_name = "example-vnet"
  address_prefixes     = ["10.10.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

output "subnet_id" {
  value = module.subnet.id
}
