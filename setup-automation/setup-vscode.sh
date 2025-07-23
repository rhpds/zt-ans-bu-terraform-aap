#!/bin/bash
curl -k  -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt
update-ca-trust
rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm

subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY}



systemctl stop systemd-tmpfiles-setup.service
systemctl disable systemd-tmpfiles-setup.service

setenforce 0

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
#Create the DEFAULT AWS VPC
su - rhel -c "aws ec2 create-default-vpc --region $AWS_DEFAULT_REGION"
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
echo "Creating S3 bucket: $BUCKET_NAME in region $AWS_DEFAULT_REGION"
su - rhel -c "aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_DEFAULT_REGION --create-bucket-configuration LocationConstraint=$AWS_DEFAULT_REGION"
#
# ## ansible home
# mkdir /home/$USER/ansible
# ## ansible-files dir
# mkdir /home/$USER/ansible-files

# ## ansible.cfg
# echo "[defaults]" > /home/$USER/.ansible.cfg
# echo "inventory = /home/$USER/ansible-files/hosts" >> /home/$USER/.ansible.cfg
# echo "host_key_checking = False" >> /home/$USER/.ansible.cfg

# ## chown and chmod all files in rhel user home
# chown -R rhel:rhel /home/$USER/ansible
# chmod 777 /home/$USER/ansible
# chown -R rhel:rhel /home/$USER/ansible-files

## install python3 libraries needed for the Cloud Report
dnf install -y python3-pip python3-libsemanage
# Install code-server as rhel user
su - rhel -c "curl -fsSL https://code-server.dev/install.sh | sh"

# Enable and start the service
su - rhel -c "sudo systemctl enable --now code-server@rhel"
su - rhel -c "sudo systemctl start --now code-server@rhel"

# # Create config directory if it doesn't exist
# su - rhel -c "mkdir -p /home/rhel/.config/code-server"

# # Create config file
# cat > /home/rhel/.config/code-server/config.yaml << EOF
# bind-addr: 0.0.0.0:80
# auth: password
# password: ansible123!
# cert: false
# EOF

# # Fix ownership
# chown -R rhel:rhel /home/rhel/.config/code-server/

# Restart the service
sudo systemctl start code-server@rhel
