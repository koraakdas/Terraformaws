#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd.service
systemctl enable httpd.service
echo "The page was created by the user data" | tee /var/www/html/index.html