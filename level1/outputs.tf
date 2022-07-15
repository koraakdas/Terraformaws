
output "public0subnet" {
  value = module.vpc.public0_subnet_id
}

output "public1subnet" {
  value = module.vpc.public1_subnet_id
}

output "private0subnet" {
  value = module.vpc.private0_subnet_id
}

output "private1subnet" {
  value = module.vpc.private1_subnet_id
}

output "vpcid" {
  value = module.vpc.vpcid
}
