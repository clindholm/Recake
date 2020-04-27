#!/bin/bash
ansible-playbook release_playbook.yml -i staging-hosts --vault-password-file ~/.vault_password