#!/bin/bash
# Install Ansible
sudo apt-get install -y ansible-core
# Clone your Ansible repository
git clone https://github.com/rzkw/ansible /home/ubuntu/ansible
# Run your initial Ansible playbook
ansible-galaxy collection install -r /home/ubuntu/ansible/collections/requirements.yml
ansible-playbook /home/ubuntu/ansible/playbooks/server.yml