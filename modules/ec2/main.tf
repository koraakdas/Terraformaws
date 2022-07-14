
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["149500239764"]

  filter {
    name   = "name"
    values = ["ami-rhel8"]
  }
}

resource "aws_iam_role" "ec2instrole" {
  name = "EC2_InstanceRole"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

data "aws_iam_policy" "ssmngpolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}


resource "aws_iam_policy_attachment" "policy_ssmrole_attach" {
  name       = "Instance_SessionMgPolicy_Attachment"
  roles      = [aws_iam_role.ec2instrole.name]
  policy_arn = data.aws_iam_policy.ssmngpolicy.arn
}

resource "aws_iam_instance_profile" "ec2instprofile" {
  name = "EC2_instanceRole"
  role = aws_iam_role.ec2instrole.name
}

resource "aws_launch_template" "template" {
  name                                 = "${var.env_code}-ec2template"
  image_id                             = data.aws_ami.amazon_linux.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "t2.micro"
  key_name                             = "main"
  vpc_security_group_ids               = [var.inst_secgrp]
  user_data                            = filebase64("${path.module}/instprep.sh")

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2instprofile.arn
  }
}

resource "aws_autoscaling_group" "autoscalegrp" {
  name                = "${var.env_code}-AutoScaleGrp"
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = [var.private0subnet, var.private1subnet]
  target_group_arns   = [var.lbtargetgrp_arn]


  launch_template {
    id = aws_launch_template.template.id
  }
}
