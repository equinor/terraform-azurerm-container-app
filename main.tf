
locals {
  # If system_assigned_identity_enabled is true, value is "SystemAssigned".
  # If identity_ids is non-empty, value is "UserAssigned".
  # If system_assigned_identity_enabled is true and identity_ids is non-empty, value is "SystemAssigned, UserAssigned".
  identity_type = join(", ", compact([var.system_assigned_identity_enabled ? "SystemAssigned" : "", length(var.identity_ids) > 0 ? "UserAssigned" : ""]))
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_app" "this" {
  name                         = var.app_name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode

  template {
    dynamic "container" {
      for_each = var.containers.container

      content {
        name   = container.value.name
        image  = container.value.image
        cpu    = container.value.cpu
        memory = container.value.memory

        dynamic "env" {
          for_each = container.value.env
          content {
            name        = env.value.name
            value       = env.value.value
            secret_name = env.value.secret_name
          }
        }
      }
    }
  }

  ingress {
    allow_insecure_connections = var.ingress.allow_insecure_connections
    external_enabled           = var.ingress.external_enabled
    target_port                = var.ingress.target_port
    traffic_weight {
      latest_revision = var.ingress.traffic_weight.latest_revision
      percentage      = var.ingress.traffic_weight.percentage
    }
  }

  dynamic "identity" {
    for_each = local.identity_type != "" ? [0] : []

    content {
      type         = local.identity_type
      identity_ids = var.identity_ids
    }
  }

  registry {
    server   = var.container_registry_server
    identity = var.identity_ids[0]
  }

}

# resource "azurerm_dns_cname_record" "this" {
#   for_each = var.container_apps

#   name                = "${each.key}.${var.stack.short_name}"
#   zone_name           = "ideation.equinor.com"
#   resource_group_name = "rg-plt-dns"
#   ttl                 = 300
#   record              = azurerm_container_app.this[each.key].ingress[0].fqdn
# }

# resource "azurerm_dns_txt_record" "this" {
#   for_each = var.container_apps

#   name                = "asuid.${each.key}.${var.stack.short_name}"
#   resource_group_name = "rg-plt-dns"
#   zone_name           = "ideation.equinor.com"
#   ttl                 = 300
#   record {
#     value = azurerm_container_app.this[each.key].custom_domain_verification_id
#   }
# }

# resource "null_resource" "configure_custom_domain" {
#   for_each = var.container_apps
#   provisioner "local-exec" {
#     command     = <<-EOT
#       Write-Output "Checking if user is logged in to az cli"
#       $account = az account show 2>&1 | ConvertFrom-Json
#       if ($LASTEXITCODE -ne 0) {
#         Write-Output "No user is logged in to Azure CLI. Running 'az login --service-principal'..."
#         az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
#       } else {
#           Write-Output "User '$($account.user.Name)' is logged in to '$($account.Name)'."
#       }

#       az account set --subscription "S294-Ideation Machine"

#       $fqdn = "${each.key}.${var.stack.short_name}.ideation.equinor.com"

#       Write-Output "Checking if custom domain exists on ca-${var.stack.short_name}-${each.key}, if not it will create it"
#       $hostname = az containerapp hostname list --resource-group ${azurerm_resource_group.this.name} --name ca-${var.stack.short_name}-${each.key} | Select-String $fqdn
#       if($null -ne $hostname){
#         Write-Output "Custom domain with hostname '$($fqdn)' already exist"
#       }else{
#         Write-Output "Creating custom domain with hostname '$($fqdn)"
#         az containerapp hostname add --resource-group ${azurerm_resource_group.this.name} --name ca-${var.stack.short_name}-${each.key} --hostname $fqdn
#       }

#       Write-Output "Checking if managed certificate named ${each.key}-${var.stack.short_name} already exists on ${azurerm_container_app_environment.this.name}. If not it will create it"
#       $managedCert = az containerapp env certificate list --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_container_app_environment.this.name} | Select-String ${each.key}-${var.stack.short_name}
#       if($managedCert){
#         Write-Output "Managed certificate with name '${each.key}-${var.stack.short_name}' already exists."
#       }else {
#         Write-Output "Creating a managed certificate with name ${each.key}-${var.stack.short_name}"
#         az containerapp env certificate create --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_container_app_environment.this.name} --certificate-name ${each.key}-${var.stack.short_name} --hostname $fqdn --validation-method CNAME
#       }

#     EOT
#     on_failure  = continue
#     interpreter = ["pwsh", "-Command"]
#   }

#   depends_on = [
#     azurerm_container_app.this,
#     azurerm_dns_cname_record.this,
#     azurerm_dns_txt_record.this
#   ]

#   lifecycle {
#     replace_triggered_by = [azurerm_container_app.this[each.key]]
#   }
# }

# resource "time_sleep" "wait_100_seconds" {
#   for_each        = var.container_apps
#   create_duration = "100s"

#   depends_on = [null_resource.configure_custom_domain]
# }

# resource "null_resource" "bind_hostname" {
#   for_each = var.container_apps
#   provisioner "local-exec" {
#     command     = <<-EOT
#       Write-Output "Checking if user is logged in to az cli"
#       $account = az account show 2>&1 | ConvertFrom-Json
#       if ($LASTEXITCODE -ne 0) {
#         Write-Output "No user is logged in to Azure CLI. Running 'az login'..."
#         az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
#       } else {
#           Write-Output "User '$($account.User.Name)' is logged in to '$($account.Name)'."
#       }
#       az containerapp hostname bind --resource-group ${azurerm_resource_group.this.name} --name ca-${var.stack.short_name}-${each.key} --hostname ${each.key}.${var.stack.short_name}.ideation.equinor.com --environment ${azurerm_container_app_environment.this.name}
#     EOT
#     on_failure  = continue
#     interpreter = ["pwsh", "-Command"]
#   }

#   depends_on = [
#     time_sleep.wait_100_seconds
#   ]

#   lifecycle {
#     replace_triggered_by = [azurerm_container_app.this[each.key]]
#   }
# }
