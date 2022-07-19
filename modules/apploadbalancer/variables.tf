variable "env_code" {
  type        = string
  description = "Tag Naming Variable"
}

variable "vpcid" {
  type = string
  description = "VPC ID"
}

variable "lb_secgrp" {
  type = string
  description = "AppLoadbalancer Security Group"
}

variable "public0_subnet_id" {
  type = string
  description = "Public0 subnet Range"
}

variable "public1_subnet_id" {
  type = string
  description = "Public1 Subnet Range"
}

variable "domainzone" {
  type = string
  description = "Route 53 Domain Zone"
}

