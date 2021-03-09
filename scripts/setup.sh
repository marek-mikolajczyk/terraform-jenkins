#!/bin/bash

set -e

sudo useradd -m -s /bin/bash automation
echo "automation ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/automation
sudo mkdir -p /home/automation/.ssh
sudo chmod 700 /home/automation/.ssh
sudo cp ../secrets/id_rsa_ssh_terraform-jenkins.pub /home/automation/.ssh/authorized_keys
sudo chmod 600 /home/terraform/.ssh/authorized_keys
sudo chown -R automation /home/automation/.ssh
