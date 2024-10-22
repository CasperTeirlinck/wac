#!/bin/bash

cd "$(dirname "$0")" || exit 1

function main_apply() {
    if [ "$dry" = false ]; then
        echo "🦎 Applying dotfiles:"
    else
        echo "🦎 Applying dotfiles (dry):"
    fi

    if [ "$ansible" = true ]; then
        apply_ansible
    fi
    if [ "$nix" = true ]; then
        apply_nix
    fi
    if [ "$chezmoi" = true ]; then
        apply_chezmoi
    fi
}

function main_bootstrap() {
    echo "🚀 Bootstrapping..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt update
        sudo apt install software-properties-common
        sudo add-apt-repository --yes --update ppa:ansible/ansible
        sudo apt install ansible
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        python3 -m ensurepip
        pip install --user ansible
    fi

    echo "🦎 Ready to apply WAC!"
}


function apply_ansible() {
    echo "→ 🏗️  Applying Ansible..."
    if [ -n "$tags" ]; then
        echo "only for tags: $tags"
        if [ "$dry" = true ]; then
            ansible-playbook main.yml -K --tags ""$tags"" --check --diff
        else
            ansible-playbook main.yml -K --tags ""$tags""
        fi
    else
        if [ "$dry" = true ]; then
            ansible-playbook main.yml -K --check --diff
        else
            ansible-playbook main.yml -K
        fi
    fi
}

function apply_nix() {
    echo "→ 📦 Applying Nix..."
    # home-manager switch --impure --flake ~/.dotfiles/home-manager
}

function apply_chezmoi() {
    echo "→ 🗃️  Applying Chezmoi..."
    # chezmoi apply
}

# Command
cmd=""
case "$1" in
apply)
    cmd="apply"
    shift 1
    ;;
bootstrap)
    cmd="bootstrap"
    shift 1
    ;;
*)
    echo "Invalid command: ${1:-}"
    exit 1
    ;;
esac

# Options
ansible=false
nix=false
chezmoi=false
tags=""
dry=false
while [[ $# -gt 0 ]]; do
    case "$1" in
    ansible)
        ansible=true
        shift 1
        ;;
    nix)
        nix=true
        shift 1
        ;;
    chezmoi)
        chezmoi=true
        shift 1
        ;;
    -t | --tags)
        tags="$2"
        shift 2
        ;;
    -d | --dry)
        dry=true
        shift 1
        ;;
    *)
        echo "Invalid option: ${1:-}"
        exit 1
        ;;
    esac
done

if [ "$ansible" = false ] && [ "$nix" = false ] && [ "$chezmoi" = false ]; then
    ansible=true
    nix=true
    chezmoi=true
fi
if [ -n "$tags" ] && [ "$ansible" = false ]; then
    echo "tags unused when not applying ansible"
fi

case "$cmd" in
apply)
    main_apply
    ;;
bootstrap)
    main_bootstrap
    ;;
esac
