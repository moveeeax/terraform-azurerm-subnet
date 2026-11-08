output "id" {
  description = "ID of the subnet."
  value       = azurerm_subnet.this.id
}

output "name" {
  description = "Name of the subnet."
  value       = azurerm_subnet.this.name
}

output "address_prefixes" {
  description = "Address prefixes assigned to the subnet."
  value       = azurerm_subnet.this.address_prefixes
}

output "nat_gateway_association_id" {
  description = "ID of the subnet NAT gateway association, or null when nat_gateway_id is not set."
  value       = one(azurerm_subnet_nat_gateway_association.this[*].id)
}
