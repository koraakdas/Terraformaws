variable "env_code" {
  type        = string
  description = "Tag Naming Variable"
}

variable "vpcid" {
  type = string
}

variable "lb_secgrp" {
  type = string
}

variable "public0_subnet_id" {
  type = string
}

variable "public1_subnet_id" {
  type = string
}
