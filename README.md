![WaC](logo.png)

# WaC - Workstation as Code

## Overview

- 🏗️ [Ansible](https://docs.ansible.com/ansible/latest/):  
   Provisioning of system components.
- 📦 [Nix Home Manager](https://nixos.wiki/wiki/Home_Manager):  
   Provisioning of user-specific components.
- 🗃️ [Chezmoi](https://www.chezmoi.io/):  
   Managing dotfiles.

## Installation
0. Install Ubuntu Server 22.04 LTS & update `sudo apt update && sudo apt upgrade`
   > **TIP**: setup ssh server and use ssh client on another machine to complete the rest of the setup in a familiar environment.
1. Clone this repo: `git clone <repo-ssh-url> ~/.dotfiles`  
   > First [setup private GitHub SHH-key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=linux#generating-a-new-ssh-key):
2. Check configuration in `/config` and make copies of `.example` files.
3. Run bootstrap: `./wac.sh bootstrap`
4. Run apply: `./wac.sh apply`

## Usage