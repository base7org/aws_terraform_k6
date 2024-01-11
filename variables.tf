# Main Variables
variable "site_region" {
  description = "The region to use."
  type        = string
  default     = "us-west-1"
}

variable "site_name" {
  description = "The region to use."
  type        = string
  default     = "base7"
}

# Domain Information

variable "site_domain" {
  description = "The domain name to be set up."
  type        = string
  default     = "fun.base7.org"
}

variable "site_ttl" {
  description = "The default TTL."
  type        = number
  default     = 60
}

# VPC Information

variable "site_vpc" {
  description = "The VPC to be used by the environment."
  type        = string
  default     = "10.0.0.0/16"
}

# EC2 Information

variable "site_ami" {
  description = "The default piblic AMI to use for the environment."
  type        = string
  default     = "ami-0a5ed7a812aeb495a"
}

variable "site_instance_size" {
  description = "The size of the instance to use for the environment."
  type        = string
  default     = "t2.micro"
}