provider "azurerm" {
  features {}
}

resource "random_id" "this" {
  byte_length = 8
}


##TODO: Remove this resource and use var.resource_group_name and var.location
resource "azurerm_resource_group" "this" {
  name     = "rg-cont-app-test"
  location = "northeurope"
}

module "log_analytics" {
  source = "github.com/equinor/terraform-azurerm-log-analytics?ref=v1.4.0"

  workspace_name      = "log-${random_id.this.hex}"
  resource_group_name = azurerm_resource_group.this.name     #var.resource_group_name
  location            = azurerm_resource_group.this.location #var.location
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "id-${random_id.this.hex}"
  location            = azurerm_resource_group.this.location #var.location
  resource_group_name = azurerm_resource_group.this.name     #var.resource_group_name
}

resource "azurerm_container_app_environment" "this" {
  name                       = "cae-cont-test"
  location                   = azurerm_resource_group.this.location #var.location
  resource_group_name        = azurerm_resource_group.this.name     #var.resource_group_name
  log_analytics_workspace_id = module.log_analytics.workspace_id
}

module "container_app" {
  source = "../.."

  app_name                     = "test-app"
  container_app_environment_id = azurerm_container_app_environment.this.id
  workload_profile_name        = "workload-profile"
  location                     = azurerm_resource_group.this.location #var.location
  resource_group_name          = azurerm_resource_group.this.name     #var.resource_group_name
  revision_mode                = "Single"
  container_registry_server    = "crimcommon.azurerm.io"
  ingress = {
    external_enabled = true
    target_port      = 8000

  }
  containers = {
    con1 = {
      container = {
        name   = "test-app1"
        image  = "crimcommon.azurecr.io/test/model1"
        cpu    = 1
        memory = "2Gi"
        env = {
          url = {
            name  = "testenv"
            value = "https://events.sparkbeyond.com/events"
          }
          secret = {
            name        = "supersecret"
            secret_name = "pwd123"
          }

        }
      }
    }
  }
}
