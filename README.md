# WaC: Ubuntu
Workstation as Code

## Overview

- 🏗️ [Ansible](https://docs.ansible.com/ansible/latest/):  
   Provisioning of system components.
- 📦 [Nix Home Manager](https://nixos.wiki/wiki/Home_Manager):  
   Provisioning of user-specific components.
- 🗃️ [Chezmoi](https://www.chezmoi.io/):  
   Managing dotfiles.
- 🔧 [Asdf](https://asdf-vm.com/):  
   Managing tool runtime versions.

## Installation
0. Install Ubuntu Server 22.04 LTS & update `sudo apt update && sudo apt upgrade`
   > **TIP**: setup ssh server and use ssh client on another machine to complete the rest of the setup in a familiar environment.
1. Clone this repo: `git clone <repo-ssh-url> ~/.dotfiles`  
   > First [setup private GitHub SHH-key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=linux#generating-a-new-ssh-key):
2. Check configuration in:
   - `./inventory.ini`
   - `./home-manager/home.nix`
3. Run init: `./init.sh`
   > This installs core dependencies (Ansible) needed to use this repository.
4. Run apply: `./apply.sh`

## Usage