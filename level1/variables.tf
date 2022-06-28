variable "env_code" {
  type        = string
  default     = "ProjIAC"
  description = "Tag Naming Variable"
}

variable "client_public_ip" {
  type        = string
  default     = "103.242.199.160/32"
  description = "client IP address"
}
