terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # azurerm 5.0 removed the `service_endpoints` list in favour of repeated
      # `service_endpoint` blocks, which 4.x does not have, so this module
      # needs 5.x. Stay on the 1.x release line of the module for azurerm
      # 3.103.0 - 4.x.
      version = ">= 5.0, < 6.0"
    }
  }
}
