#!/bin/bash
# Run your initial Ansible playbook
ansible-galaxy collection install -r /home/ubuntu/ansible/collections/requirements.yml
ansible-playbook /home/ubuntu/ansible/playbooks/server.yml