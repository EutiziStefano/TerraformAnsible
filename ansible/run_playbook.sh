#!/bin/bash
ansible-playbook playbook.yaml -i inventory.ini  --ssh-extra-args "-F ./ssh_config" --user testadmin
