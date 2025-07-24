#!/bin/bash
curl -k  -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt
update-ca-trust
rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm

subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY}
setenforce 0
echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
chmod 440 /etc/sudoers.d/rhel_sudoers

systemctl stop firewalld
systemctl stop code-server
mv /home/rhel/.config/code-server/config.yaml /home/rhel/.config/code-server/config.bk.yaml

cat /home/rhel/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:8080
auth: none
cert: false
EOF

chown rhel:rhel /home/rhel/.config/code-server/config.yaml
chmod 644 /home/rhel/.config/code-server/config.yaml
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

# Create directory if it doesn't exist
mkdir -p /home/rhel/.aws

# Create the credentials file
cat > /home/rhel/.aws/credentials << EOF
[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOF

# Set proper ownership and permissions
chown rhel:rhel /home/rhel/.aws/credentials
chmod 600 /home/rhel/aws/credentials

cat > /home/rhel/aws/config << EOF
[default]
region = $AWS_DEFAULT_REGION
EOF

# Set proper ownership and permissions
chown rhel:rhel /home/rhel/aws/config
chmod 600 /home/rhel/aws/config

#
#
#Create the DEFAULT AWS VPC
aws ec2 create-default-vpc --region $AWS_DEFAULT_REGION
#
#
#Create the S3 bucket for the users of this AAP / Terraform lab
# Variables
BUCKET_PREFIX="aap-tf-bucket"  # Change this to your desired bucket prefix
RANDOM_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')  # Generate a random UUID and convert to lowercase
BUCKET_NAME="${BUCKET_PREFIX}-${RANDOM_ID}"
AWS_REGION="$AWS_DEFAULT_REGION"  # Change this to your desired AWS region
#
#
# Create the S3 STORAGE BUCKET NEEDED BY THE AAP 2.X CHALLENGE
echo "Creating S3 bucket: $BUCKET_NAME in region $AWS_REGION"
aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION
#
#
