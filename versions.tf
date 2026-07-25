terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # `private_endpoint_network_policies` (the string that replaced the
      # boolean `private_endpoint_network_policies_enabled`) only exists from
      # azurerm 3.103.0 onwards. Against 3.102.0 and older `terraform validate`
      # fails with `An argument named "private_endpoint_network_policies" is
      # not expected here.`, so the constraint has to start there.
      version = ">= 3.103.0"
    }
  }
}
