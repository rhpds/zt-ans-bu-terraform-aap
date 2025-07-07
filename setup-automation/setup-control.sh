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

#!/bin/bash
#
## Fix dns resolution in automation-controller rhel9 image
echo "search $_SANDBOX_ID.svc.cluster.local." >> /etc/resolv.conf
echo "127.0.0.1 ansible-1 controller localhost" >> /etc/hosts
#

##### TEST


# ## setup rhel user
# touch /etc/sudoers.d/rhel_sudoers
# echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
# cp -a /root/.ssh/* /home/$USER/.ssh/.
# chown -R rhel:rhel /home/$USER/.ssh

## ansible home
mkdir /home/$USER/ansible
## ansible-files dir
mkdir /home/$USER/ansible-files

## ansible.cfg
echo "[defaults]" > /home/$USER/.ansible.cfg
echo "inventory = /home/$USER/ansible-files/hosts" >> /home/$USER/.ansible.cfg
echo "host_key_checking = False" >> /home/$USER/.ansible.cfg

## chown and chmod all files in rhel user home
chown -R rhel:rhel /home/$USER/ansible
chmod 777 /home/$USER/ansible
#touch /home/rhel/ansible-files/hosts
chown -R rhel:rhel /home/$USER/ansible-files

## Set controller access env variables for system
cat >/etc/environment <<EOL
CONTROLLER_HOST=controller.${_SANDBOX_ID}.svc.cluster.local
CONTROLLER_USERNAME=admin
CONTROLLER_PASSWORD='ansible123!'
CONTROLLER_VERIFY_SSL=false

EOL
cat /etc/environment

## install python3 libraries needed for the Cloud Report
dnf install -y python3-pip python3-libsemanage

# Create a playbook for the user to execute
tee /tmp/setup.yml << EOF
### Automation Controller setup 
###
- name: Setup Controller 
  hosts: localhost
  connection: local
  collections:
    - ansible.controller
  vars:
    aws_access_key: "{{ lookup('env', 'AWS_ACCESS_KEY_ID') | default('AWS_ACCESS_KEY_ID_NOT_FOUND', true) }}"
    aws_secret_key: "{{ lookup('env', 'AWS_SECRET_ACCESS_KEY') | default('AWS_SECRET_ACCESS_KEY_NOT_FOUND', true) }}"
    aws_default_region: "{{ lookup('env', 'AWS_DEFAULT_REGION') | default('AWS_DEFAULT_REGION_NOT_FOUND', true) }}"
  tasks:

  - name: Add AWS credential
    ansible.controller.credential:
      name: 'AWS Credential'
      organization: Default
      credential_type:  "Amazon Web Services"
      controller_host: "https://localhost"
      controller_username: admin
      controller_password: ansible123!
      validate_certs: false
      inputs:
        username: "{{ aws_access_key }}"
        password: "{{ aws_secret_key }}"

  - name: Ensure inventory exists
    ansible.controller.inventory:
      controller_host: "https://localhost"
      controller_username: admin
      controller_password: ansible123!
      validate_certs: false
      name: "AWS Inventory example"
      organization: Default
      state: present
    register: aws_inventory_result
  
  - name: Ensure AWS EC2 inventory source exists
    ansible.controller.inventory_source:
      controller_host: "https://localhost"
      controller_username: admin
      controller_password: ansible123!
      validate_certs: false
      name: "AWS EC2 Instances Source"
      inventory: "AWS Inventory example"
      source: ec2
      credential: "AWS Credential"
      source_vars:
        regions: ["{{ aws_default_region }}"]
      overwrite: true
      overwrite_vars: true
      update_on_launch: true
      update_cache_timeout: 300
      state: present
    register: aws_inventory_source_result

    
  - name: Add EE to the controller instance
    ansible.controller.execution_environment:
      name: "Terraform Execution Environment"
      image: quay.io/acme_corp/terraform_ee
      credential: Quay Registry Credential
      controller_username: "{{ username }}"
      controller_password: "{{ admin_password }}"
      controller_host: "https://{{ ansible_host }}"
      validate_certs: false

  - name: Add project
    ansible.controller.project:
      name: "Terraform Demos Project"
      description: "This is from github.com/ansible-cloud"
      organization: "Default"
      state: present
      scm_type: git
      scm_url: https://github.com/HichamMourad/terraform-aap
      default_environment: "Terraform Execution Environment"
      controller_username: "{{ username }}"
      controller_password: "{{ admin_password }}"
      controller_host: "https://{{ ansible_host }}"
      validate_certs: false

  - name: Delete native job template
    ansible.controller.job_template:
      name: "Demo Job Template"
      state: "absent"
      controller_username: "{{ username }}"
      controller_password: "{{ admin_password }}"
      controller_host: "https://{{ ansible_host }}"
      validate_certs: false

  - name: Add a TERRAFORM INVENTORY
    ansible.controller.inventory:
      name: "Terraform Inventory"
      description: "Our Terraform Inventory"
      organization: "Default"
      state: present
      controller_username: "{{ username }}"
      controller_password: "{{ admin_password }}"
      controller_host: "https://{{ ansible_host }}"
      validate_certs: false
      
EOF
export ANSIBLE_LOCALHOST_WARNING=False
export ANSIBLE_INVENTORY_UNPARSED_WARNING=False

#ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml
