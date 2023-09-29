# variable "subscription_id" {
#   type        = string
#   description = "Subscription id to echo"
# }

# variable "resource_groups" {
#   type = map(object({
#     location = string
#     name     = string
#   }))
#   description = "Specifies the map of objects for a resource group"
#   default     = {}
# }

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resource group"
}