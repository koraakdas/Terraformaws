variable "env_code" {
  type        = string
  default     = "ProjectIAC"
  description = "Tag Naming Variable"
}

variable "client_public_ip" {
  type        = string
  default     = "115.187.59.35/32"
  description = "client IP address"
}
