#!/usr/bin/env bash
# Pull dotfiles when the git origin is reachable; silent no-op when offline.
# Intended for cron/launchd. ff-only so it never creates a merge/conflict on a client.
# Does NOT run install.sh (selector regen needs an unlocked 1P agent, absent under cron);
# a plain pull propagates zshrc/agent.toml (symlinks) + ssh config.d fragments live.
REPO="${DOTFILES:-$HOME/dotfiles}"
export GIT_SSH_COMMAND="ssh -o ConnectTimeout=6 -o BatchMode=yes"
[ -d "$REPO/.git" ] || exit 0
# Reachability + fetch in one bounded step; skip quietly if origin is unreachable.
if timeout 25 git -C "$REPO" fetch --quiet origin 2>/dev/null; then
  git -C "$REPO" merge --ff-only --quiet '@{u}' 2>/dev/null || true
fi
