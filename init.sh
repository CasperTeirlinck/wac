#!/bin/bash
# Install core dependencies for using this dotfiles repository.

# 1. Ansible
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible