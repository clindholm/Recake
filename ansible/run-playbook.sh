#!/bin/bash
ansible-playbook playbook.yml -i staging-hosts --vault-password-file ~/.vault_password