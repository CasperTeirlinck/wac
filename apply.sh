#!/bin/bash

if [ -z "$1" ]; then
    ansible-playbook ~/.dotfiles/main.yml -K
    home-manager switch --flake ~/.dotfiles/home-manager
else
    ansible-playbook main.yml -K --tags ""$1""
fi