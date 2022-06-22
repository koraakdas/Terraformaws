output "public0_subnet_id" {
  value = aws_subnet.public[0].id
}

output "public1_subnet_id" {
  value = aws_subnet.public[1].id
}

output "private0_subnet_id" {
  value = aws_subnet.private[0].id
}

output "private1_subnet_id" {
  value = aws_subnet.private[1].id
}
