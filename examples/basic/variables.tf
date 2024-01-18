variable "resource_group_name" {
  description = "The name of the resource group to create the resources in."
  type        = string
}

variable "location" {
  description = "The location to create the resources in."
  type        = string
}

variable "container_registry_name" {
  description = "The name of the container registry"
  type        = string
}

variable "container_registry_server" {
  description = "The the server URL of the container registry."
  type        = string
}

variable "container_registry_resource_group_name" {
  description = "The resource group of the container registry."
  type        = string
}
