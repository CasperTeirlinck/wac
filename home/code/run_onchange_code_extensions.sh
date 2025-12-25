#!/bin/bash

plugins=(
# --- Language support
bbenoist.nix
ecmel.vscode-html-css
golang.go
hashicorp.terraform
ms-azuretools.vscode-docker
ms-python.python
ms-vscode.makefile-tools
ms-vscode.cmake-tools
ms-vscode.cpptools
ms-vscode.cpptools-extension-pack
redhat.vscode-xml
redhat.vscode-yaml
samuelcolvin.jinjahtml
swiftlang.swift-vscode
tamasfe.even-better-toml
timonwong.shellcheck

# --- Language support - Python
ms-python.vscode-pylance
ms-python.mypy-type-checker
ms-python.black-formatter
ms-python.debugpy
ms-python.isort
charliermarsh.ruff
ms-toolsai.jupyter
ms-toolsai.jupyter-keymap
ms-toolsai.jupyter-renderers
ms-toolsai.vscode-jupyter-cell-tags
ms-toolsai.vscode-jupyter-slideshow
njpwerner.autodocstring

# --- Tooling
bruno-api-client.bruno
editorconfig.editorconfig
grapecity.gc-excelviewer
ms-vsliveshare.vsliveshare
platformio.platformio-ide
# elijah-potter.harper
ms-vscode-remote.remote-containers
ms-vscode-remote.remote-ssh
ms-vscode-remote.remote-ssh-edit
ms-vscode-remote.remote-wsl
ms-vscode.remote-explorer

# --- Git
eamodio.gitlens
mhutchie.git-graph

# --- Theming
aaron-bond.better-comments
kamikillerto.vscode-colorize

# --- AI
github.copilot
github.copilot-chat

# --- Misc
cs50.vscode-presentation-mode
)

for plugin in "${plugins[@]}"; do
  code --install-extension "$plugin" --force 2>/dev/null || echo "Failed to install VSCode extension: $plugin. You cannot run this from a VSCode integrated terminal."
done