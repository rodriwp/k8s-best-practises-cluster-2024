variable "account_id" {
  description = "AWS Account Id"
  type        = string
}
variable "account_name" {
  description = "AWS Account Name"
  type        = string
}
variable "region_code" {
  description = "AWS region code"
  type        = string
  default     = "eu-central-1"
}
variable "region" {
  description = "AWS region code"
  type        = string
  default     = "eu-central-1"
}
variable "min_size" {
  description = "Node group min size"
  type        = number
}
variable "max_size" {
  description = "Node group max size"
  type        = number
}
variable "desired_size" {
  description = "Node group desired capacity"
  type        = number
}
variable "disk_size" {
  description = "Node group disk size"
  type        = number
}
variable "instance_type" {
  description = "The list types for the nodes"
  type        = list(string)
}
variable "private_subnets" {
  description = "The list of private subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "The list of public subnets"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "The CIDR of the VPC"
  type        = string
}