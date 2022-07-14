variable "env_code" {
  type        = string
  default     = "ProjIAC"
  description = "Tag Naming Variable"
}

variable "inst_secgrp" {
  type = string
}

variable "private0subnet" {
  type = string
}

variable "private1subnet" {
  type = string
}

variable "lbtargetgrp_arn" {
  type = string
}

