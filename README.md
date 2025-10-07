# Dotfiles

My personal dotfiles for zsh configuration across multiple machines.

## Quick Install
```bash
curl -fsSL https://raw.githubusercontent.com/nickpdawson/dotfiles/main/zshrc -o ~/.zshrc && source ~/.zshrc
Update Existing Installation
bashcurl -fsSL https://raw.githubusercontent.com/nickpdawson/dotfiles/main/zshrc -o ~/.zshrc && source ~/.zshrc
Or use the built-in alias:
bashupdate-zsh
Machines Using This Config

Ridge (macOS) - canonical source
bridger.dzsec.net (FreeBSD)
showdown.dzsec.net (FreeBSD)
yellowstone.dzsec.net (FreeBSD)
matterhorn.dzsec.net (FreeBSD)
wintergreen.dzsec.net (FreeBSD)
Various Proxmox VMs and containers

Host-Specific Customizations
Add a ~/.zshrc.local file on each machine for host-specific settings.
This file won't be overwritten by updates.
