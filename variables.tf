## Stack Variables
variable "app_name" {
  description = "The name of the App Environment."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to create the resources in."
  type        = string
}

variable "location" {
  description = "The location to create the resources in."
  type        = string
}

variable "container_app_environment_id" {
  description = "Variables for the Container App Environment."
  type        = string
}

variable "workload_profile_name" {
  description = "The name of the workload profile."
  type        = string
}

variable "revision_mode" {
  description = "The revision mode of the Container App."
  type        = string
}

variable "container_registry_server" {
  description = "The container registry used for the Container App."
  type        = string
}

variable "system_assigned_identity_enabled" {
  description = "Should the system-assigned identity be enabled for Container Web App?"
  type        = bool
  default     = false
}

variable "identity_ids" {
  description = "A list of IDs of managed identities to be assigned to this Container App."
  type        = list(string)
  default     = []
}

variable "ingress" {
  description = "Ingress properties."
  type = object({
    allow_insecure_connections = optional(bool, false)
    external_enabled           = bool
    target_port                = number
  })
}

variable "traffic_weight" {
  description = "Traffic weight properties."
  type = object({
    latest_revision = optional(bool, true)
    percentage      = optional(number, 100)
  })
  default = {}
}

variable "containers" {
  description = "Container App properties."
  type = map(object({
    name   = string
    image  = string
    cpu    = number
    memory = string
    env = map(object({
      name        = string
      secret_name = optional(string, "")
      value       = optional(string, "")
    }))
  }))
}
