#!/bin/sh
echo "Starting module called module-04" >> /tmp/progress.log

#
wget https://raw.githubusercontent.com/HichamMourad/terraform-aap/refs/heads/main/images/2main.tf -P /tmp/
mv /tmp/2main.tf /home/rhel/lab_exercises/2.Terraform_Ansible/main.tf
#
#
tee /home/rhel/lab_exercises/2.Terraform_Ansible/variables.tf << EOF
# variables.tf
variable "aws_security_group" {
  default = "terraform_ec2" # AWS Security Group name
}
variable "instance_name" {
  default = "Terraform_ec2" # AWS Name of instance
}
variable "instance_type" {
  default = "t2.micro" # AWS Instance type
}
variable "private_ip_address" {
  type    = string
  default = "10.20.20.120"
}
EOF
#
#
tee /home/rhel/lab_exercises/3.Terraform_Provider/main.tf << EOF
# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
# Provider
provider "aws" {
  region     = "us-east-1"
}
# Add key for ssh connection
resource "aws_key_pair" "my_key" {
  key_name   = "my_key"
  public_key = "<< Your id_rsa.pub >>"
}
# Add security group for ssh
resource "aws_security_group" "ssh" {
  name = "ssh"
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Add security group for http
resource "aws_security_group" "http" {
  name = "http"
  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Create ec2 instance
resource "aws_instance" "my_ec2" {
  ami           = "ami-0005e0cfe09cc9050" ##a RHEL AMI
  instance_type = "t2.micro"
  tags = {
    Name = "Terraform Instance"
  }
  key_name        = aws_key_pair.my_key.key_name
  security_groups = [aws_security_group.ssh.name, aws_security_group.http.name, "default"]
}
## Ansible Host Resource: 
EOF
#
#
tee /home/rhel/lab_exercises/3.Terraform_Provider/nginx.yml << EOF
---
- name: Install nginx on remote host
  hosts: nginx
  become: true
  gather_facts: false
  tasks:
    - name: Wait
      ansible.builtin.wait_for_connection:

    - name: Setup
      ansible.builtin.setup:

    - name: Install nginx
      ansible.builtin.package:
        name: nginx
        state: present

    - name: Start nginx
      ansible.builtin.service:
        name: nginx
        state: started
EOF
#
#
tee /home/rhel/lab_exercises/3.Terraform_Provider/inventory.yml << EOF
---
plugin: cloud.terraform.terraform_provider
EOF
#
#
chown -R rhel:rhel /home/rhel/
chmod -R 777 /home/rhel/
chmod -R 600 /home/rhel/.ssh/*
#
#
cd /home/rhel/lab_exercises
#
#
