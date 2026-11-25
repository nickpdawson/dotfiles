# Dotfiles

zsh, SSH and 1Password agent config for Nick's machines. Hosted on Gitea on matterhorn (internal only); the old GitHub copy is retired.

## Install

```
git clone https://git.dzsec.net:30008/ndawson/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Run `install.sh` with 1Password unlocked (it builds the `~/.ssh/*.pub` key selectors from the agent). It also schedules `bin/pull-dotfiles.sh` every 30 minutes, which fast-forwards from Gitea and skips quietly when matterhorn is unreachable.

Push from a host with the 1Password agent: `git -C ~/dotfiles push` (origin pushes over `ssh://git@git.dzsec.net:30009`).

## Host-specific settings

Put them in `~/.zshrc.local`; updates never overwrite it.
