# WaC — Workstation as Code

This is my personal dotfiles + workstation provisioning repo. It targets **macOS**, **Linux (Ubuntu)** and **Linux on WSL** (with optional Windows-side management from WSL).

Three layers, each with its own responsibility:

| Layer | Tool | What it does | Where it lives |
|---|---|---|---|
| 🏗️ System provisioning | **Ansible** | OS-level setup: drivers, bluetooth, sound, network, docker, WSL, desktop environment, system packages | `main.yml`, `roles/`, `handlers/` |
| 📦 Declarative user env | **Nix (home-manager + nix-darwin)** | User-level packages and applications (CLIs, GUIs via Homebrew on macOS, system defaults) | `nix/Darwin/`, `nix/Linux/` |
| 🗃️ Dotfiles | **Chezmoi** | Templated dotfiles synced into `$HOME` (and into Windows via Ansible on WSL) | `home/`, `home-windows/` |

The orchestrator that ties them together is `./wac.sh`.

## Layout

```
.
├── wac.sh                  # entrypoint
├── main.yml                # Ansible playbook root
├── config/                 # local (gitignored) config
├── roles/                  # Ansible roles
├── nix/
│   ├── Darwin/             #   flake.nix + configuration.nix (nix-darwin) + home.nix
│   └── Linux/              #   flake.nix + home.nix (home-manager standalone)
├── home/                   # chezmoi source, `.chezmoiroot` points here
└── home-windows/AppData/   # chezmoi source for Windows
```

## How to apply changes

`./wac.sh <cmd> [layers] [--tags TAG] [--dry]`

- **Layers** (omit all = apply all): `ansible`, `nix`, `chezmoi`
- `--tags TAG` is Ansible-only (e.g. `--tags chezmoi-windows`)
- `--dry` runs the layer in dry-run / check mode

### Editing chezmoi-managed dotfiles

The source files in `home/` are NOT the live files in `$HOME`. After editing anything under `home/`, push the change into `$HOME` with chezmoi:

```bash
# Whole tree
chezmoi apply

# A single target file (use the destination path in $HOME, not the source path)
chezmoi apply ~/.config/nvim/init.lua
chezmoi apply ~/.config/nvim/lua/plugins/blink.lua
```

Naming conventions you'll see in `home/`:

- `dot_foo` → `~/.foo`
- `dot_config/...` → `~/.config/...`
- `*.tmpl` → chezmoi-templated (e.g. `dot_zshrc.tmpl` branches on `.chezmoi.os`)
- `executable_*` → applied with the executable bit set
- `private_*` → applied with `0600` perms

Useful chezmoi commands while iterating:

- `chezmoi diff [path]` — preview what `apply` would change
- `chezmoi status` — show pending changes
- `chezmoi edit <target-path>` — edit the *source* file by giving the destination path
- `chezmoi cd` — drop into the chezmoi source dir (= `home/`)

`.chezmoiroot` pins the source to `home/`. `home-windows/` is applied separately by Ansible (`--tags chezmoi-windows`) over SSH to the Windows host.

### Editing Nix-managed packages / system settings

- macOS GUI apps + CLIs + system defaults (Dock, Finder, key repeat, fonts) live in `nix/Darwin/configuration.nix` — managed by **nix-darwin**, installs Homebrew casks/brews declaratively.
- macOS per-user home-manager bits live in `nix/Darwin/home.nix`.
- Linux user packages live in `nix/Linux/home.nix` (standalone home-manager).

After editing any `.nix` file, apply with:

```bash
./wac.sh apply nix
```

### Editing Ansible roles

Roles dispatch by OS — `roles/<role>/tasks/main.yml` includes `{{ ansible_facts.system }}/main.yml` (`Darwin` / `Linux` / `Win32NT`). To target one role:

```bash
./wac.sh apply ansible --tags <role>           # if the role uses tags
```

`main.yml` has two plays: `localhost` (the dev machine) and `windows` (optional, configured via `config/inventory.ini` and `role_system_wsl_windows: true`).
