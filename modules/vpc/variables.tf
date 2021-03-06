variable "env_code" {
  type        = string
  description = "Tag Naming Variable"
}

variable "pubsubnet" {
  type        = list(any)
  description = "Public Subnet Range"
}

variable "privsubnet" {
  type        = list(any)
  description = "Private Subnet Range"
}

variable "vpccidr" {
  type        = string
  description = "VPC CIDR Range for the Whole Network"

}

variable "secgrpcidr" {
  type        = string
  description = "Ingress & Egress Rules CIDR"
}
