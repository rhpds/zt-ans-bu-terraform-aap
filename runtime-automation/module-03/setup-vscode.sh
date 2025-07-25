#!/bin/sh
echo "Starting module called module-03" >> /tmp/progress.log

#
cat <<EOF > /home/rhel/lab_exercises/1.Terraform_Basics/main.tf
# Use AWS provider for Terraform
provider "aws" {
  region = "us-east-1"
}
#
resource "aws_instance" "basic_rhel" {
  ami           = "ami-0005e0cfe09cc9050"
  instance_type = "t2.micro" 
#
  }  
#
EOF
#
#
chown -R rhel:rhel /home/rhel/
chmod -R 777 /home/rhel/
#
#
