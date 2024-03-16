#!/bin/bash
# Apply the dotfiles.
# 
# When arguments are suplied, apply using only a specific tool:
# ./apply.sh [ansible | hm | chezmoi]
# When using `ansible`, additionally you can give a list of tags to target:
# ./apply.sh ansible packages,othertag

if [ -z "$1" ]; then
    ansible-playbook ~/.dotfiles/main.yml -K
    home-manager switch --flake ~/.dotfiles/home-manager
    chezmoi apply
elif [ "$1" == "ansible" ]; then
    if [ -z "$2" ]; then
        ansible-playbook ~/.dotfiles/main.yml -K
    else
        ansible-playbook ~/.dotfiles/main.yml -K --tags ""$2""
    fi
elif [ "$1" == "hm" ]; then
    home-manager switch --flake ~/.dotfiles/home-manager
elif [ "$1" == "chezmoi" ]; then
    chezmoi apply
fi