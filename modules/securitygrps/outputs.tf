
output "inst_secgrp" {
  value = aws_security_group.instsecgrp.id
}

output "lb_secgrp" {
  value = aws_security_group.lbsecgrp.id
}
