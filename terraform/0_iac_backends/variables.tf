variable "backend_names_list" {
  description = "List of Backend Names for storing Terraform/OpenTofu states"
  default     = []
}

variable "account_id" {
  description = "AWS Account Id"
  type        = string
}
