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

### Windows

WaC also support configuring Windows when running from WSL.
To allow managing Windows from WSL, set the following:

1. Enable the role `role_system_wsl_windows` in `config/config.yml`
2. Add the Windows host to `config/inventory.ini` (see `inventory.ini.example`)
3. Make sure OpenSSH Server is installed and running on Windows

#### OpenSSH Server on Windows 11

> ref: https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=powershell&pivots=windows-11#install-openssh-server--client

To install and enable the OpenSSH server on Windows 11, run the following PowerShell commands as Administrator:

1. Install OpenSSH Server
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
```

2. Configure the SSH server
```powershell
code C:\ProgramData\ssh\sshd_config
# Uncomment:
# PasswordAuthentication yes
# PubkeyAuthentication yes
# Comment:
# #Match Group administrators
# #       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
Restart-Service sshd
```

3. Set default shell to PowerShell (required for Ansible modules to work correctly)
```powershell
$shellParams = @{
    Path         = 'HKLM:\SOFTWARE\OpenSSH'
    Name         = 'DefaultShell'
    Value        = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
    PropertyType = 'String'
    Force        = $true
}
New-ItemProperty @shellParams
```

Test if the ssh connection is working from WSL:

```bash
# Get the Windows ip:
ip route show | grep default
# Connect using ssh:
ssh -o PreferredAuthentications=password casper@172.x.x.x
```

## Usage
