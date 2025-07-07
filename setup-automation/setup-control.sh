#!/bin/bash

systemctl stop systemd-tmpfiles-setup.service
systemctl disable systemd-tmpfiles-setup.service

#!/bin/bash

# Setup rhel user
cp -a /root/.ssh/* /home/rhel/.ssh/.
chown -R rhel:rhel /home/rhel/.ssh
mkdir -p /home/rhel/lab_exercises/1.Terraform_Basics
mkdir -p /home/rhel/lab_exercises/2.Terraform_Ansible
mkdir -p /home/rhel/lab_exercises/3.Terraform_Provider
mkdir -p /home/rhel/lab_exercises/4.Terraform_AAP_Provider
mkdir -p /home/rhel/terraform-ee
mkdir /tmp/terraform_lab/
mkdir /tmp/terraform-ansible
mkdir /tmp/terraform-aap-provider
mkdir -p /home/rhel/.terraform.d/plugin-cache
#
#
#chown rhel:rhel /home/rhel/.terraformrc
chown -R rhel:rhel /home/rhel/lab_exercises/
chown rhel:rhel /home/rhel/.terraform.d/plugin-cache
chmod -R 777 /home/rhel/lab_exercises/
#
firewall-cmd --permanent --add-port=8043/tcp
firewall-cmd --reload
#
yum install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -qq awscliv2.zip
sudo ./aws/install
chown -R rhel:rhel /home/rhel/lab_exercises
chmod -R 777 /home/rhel/lab_exercises
#
yum install -y dnf
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum install terraform -y
#
#
tee /home/rhel/lab_exercises/4.Terraform_AAP_Provider/main.tf << EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.2.0"
    }
####### UNCOMMENT the lines BELOW #######
#    aap = {
#      source = "ansible/aap"
#    }
  }
}
#
provider "aws" {
  region = "us-east-1"
}
#
resource "aws_instance" "tf-instance-aap-provider" {
  ami           = "ami-0005e0cfe09cc9050"
  instance_type = "t2.micro"
  tags = {
    Name = "tf-instance-aap-provider"
  }
}
####### UNCOMMENT the lines BELOW #######
#provider "aap" {
#  host     = "https://controller"
#  username = "admin"
#  password = "ansible123!"
#  insecure_skip_verify = true
#}
####### UNCOMMENT the lines BELOW #######
#resource "aap_host" "tf-instance-aap-provider" {
#  inventory_id = 2
#  name = "aws_instance_tf"
#  description = "An EC2 instance created by Terraform"
#  variables = jsonencode(aws_instance.tf-instance-aap-provider)
#}
#
EOF
#
chown rhel:rhel /home/rhel/lab_exercises/4.Terraform_AAP_Provider/main.tf
#
#
#
#Create the DEFAULT AWS VPC
aws ec2 create-default-vpc --region us-east-1
#
#
#Create the S3 bucket for the users of this AAP / Terraform lab
# Variables
BUCKET_PREFIX="aap-tf-bucket"  # Change this to your desired bucket prefix
RANDOM_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')  # Generate a random UUID and convert to lowercase
BUCKET_NAME="${BUCKET_PREFIX}-${RANDOM_ID}"
AWS_REGION="us-east-1"  # Change this to your desired AWS region
#
#
# Create the S3 STORAGE BUCKET NEEDED BY THE AAP 2.X CHALLENGE
echo "Creating S3 bucket: $BUCKET_NAME in region $AWS_REGION"
aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION
#
#
