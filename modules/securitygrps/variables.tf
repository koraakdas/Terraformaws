
variable "vpcid" {
  type        = string
  description = "VPC ID"
}

variable "secgrpcidr" {
  type        = list(string)
  description = "Ingress & Egress Rules CIDR"
}
