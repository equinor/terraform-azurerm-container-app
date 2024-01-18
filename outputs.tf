output "app_id" {
  description = "The ID of this Container App."
  value       = azurerm_container_app.this.id
}

output "custom_domain_verification_id" {
  description = "The ID of the Custom Domain Verification for this Container App."
  value       = azurerm_container_app.this.id
}

output "latest_revision_fqdn" {
  description = "The FQDN of the Latest Revision of the Container App."
  value       = azurerm_container_app.this.latest_revision_fqdn
}

output "latest_revision_name" {
  description = "The name of the latest Container Revision."
  value       = azurerm_container_app.this.latest_revision_name
}

output "location" {
  description = " The location this Container App is deployed in. This is the same as the Environment in which it is deployed."
  value       = azurerm_container_app.this.location
}

output "outbound_ip_addresses" {
  description = "A list of the Public IP Addresses which the Container App uses for outbound network access."
  value       = azurerm_container_app.this.outbound_ip_addresses
}
