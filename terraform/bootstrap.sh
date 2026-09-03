#!/bin/bash
# Install Ansible
pipx install -y ansible-core
# Clone your Ansible repository
git clone https://github.com/rzkw/ansible /home/ubuntu/ansible
# Run your initial Ansible playbook
ansible-playbook /home/ubuntu/ansible/playbooks/server.yml