#!/bin/sh
echo "Starting module called module-02" >> /tmp/progress.log

sudo dnf install python3.9 -y
sudo dnf remove python3 -y
sudo dnf upgrade crun -y
python3 --version
pip3 install --upgrade ansible-builder
#
#
touch /home/rhel/terraform-ee/execution-environment.yml
touch /home/rhel/terraform-ee/requirements.yml
chown -R rhel:rhel /home/rhel/
chmod -R 777 /home/rhel/
#
#
#Enable linger for the user `rhel`
loginctl enable-linger rhel
#
#
RUNAS="sudo -u rhel"
cd /tmp || exit 1
#Runs bash with commands in the here-document as the `rhel` user
$RUNAS bash<<'EOF'
podman login --username lab-aapongcp --password ansible123! registry.redhat.io
podman pull registry.redhat.io/ansible-automation-platform-25/ee-minimal-rhel8:latest
loginctl enable-linger rhel
EOF
#
#
