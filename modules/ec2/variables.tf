variable "env_code" {
  type        = string
  default     = "ProjIAC"
  description = "Tag Naming Variable"
}

variable "inst_secgrp" {
  type        = string
  description = "EC2 Instance Security Group"
}

variable "private0subnet" {
  type        = string
  description = "First Private Subnet Range"
}

variable "private1subnet" {
  type        = string
  description = "Second Pivate Subnet Range"
}

variable "lbtargetgrp_arn" {
  type        = string
  description = "AppLodabalancer Target Grp ARN"
}

