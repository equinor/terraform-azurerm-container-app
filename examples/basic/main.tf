provider "azurerm" {
  features {}
}

resource "random_id" "this" {
  byte_length = 8
}

data "azurerm_subscription" "current" {}

data "azurerm_container_registry" "this" {
  name                = var.container_registry_name
  resource_group_name = var.container_registry_resource_group_name
}

module "log_analytics" {
  source = "github.com/equinor/terraform-azurerm-log-analytics?ref=v1.4.0"

  workspace_name      = "log-${random_id.this.hex}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "id-${random_id.this.hex}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = data.azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_container_app_environment" "this" {
  name                       = "cae-${random_id.this.hex}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = module.log_analytics.workspace_id
}

module "container_app" {
  source = "../.."

  app_name                     = "ca-${random_id.this.hex}"
  container_app_environment_id = azurerm_container_app_environment.this.id
  workload_profile_name        = "workload-profile"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  container_registry_server    = var.container_registry_server
  identity_ids                 = [azurerm_user_assigned_identity.this.id]
  ingress = {
    external_enabled = true
    target_port      = 8000
  }
  containers = {
    con1 = {
      name   = "con-${random_id.this.hex}"
      image  = "${var.container_registry_server}/hello-world:latest"
      cpu    = 1
      memory = "2Gi"
      env = {
        url = {
          name  = "exampleenv"
          value = "examle env value"
        }
      }
    }
  }
}
