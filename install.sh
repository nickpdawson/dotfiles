#!/usr/bin/env bash
# Idempotent dotfiles apply. Run on any machine after `git pull`.
# - Symlinks zshrc + the 1Password agent.toml into place.
# - Regenerates ~/.ssh/*.pub SELECTORS from the running 1Password agent.
#   Private keys never leave 1Password; the .pub files just tell SSH which
#   agent key to offer for a pinned host (IdentityFile + IdentitiesOnly).
#   Nothing key-shaped is stored in git.
# macOS + Linux. Needs the 1P SSH agent running + unlocked when regenerating selectors.
set -euo pipefail
DOT="$(cd "$(dirname "$0")" && pwd)"

link() { mkdir -p "$(dirname "$2")"; ln -snf "$1" "$2"; echo "  link $2 -> $1"; }

# --- configs ---
link "$DOT/zshrc" "$HOME/.zshrc"
link "$DOT/1password/agent.toml" "$HOME/.config/1Password/ssh/agent.toml"
mkdir -p "$HOME/.ssh"

# --- regenerate public-key selectors from the 1P agent ---
# gen "<exact 1P item name>" <selector filename>
gen() {
  local name="$1" out="$HOME/.ssh/$2" line
  line="$(ssh-add -L 2>/dev/null | awk -v n="$name" '
    { c=""; for(i=3;i<=NF;i++) c=c (i>3?" ":"") $i; if(c==n){print; exit} }')"
  if [ -n "$line" ]; then printf '%s\n' "$line" > "$out"; echo "  pub  $2 (from \"$name\")"
  else echo "  MISS $2 — 1P item \"$name\" not offered by the agent (unlock 1P?)"; fi
}
gen "DZsec Roots"          dzsec_roots.pub
gen "DZsec Administrators" admin_dzsec.pub
gen "ndawson@dzsec.net"    ndawson.pub
gen "Canyon DMZ Key"       canyon_dmz.pub
gen "GitHub 2026"          github_2026.pub

echo "done. (ssh host pins live in $DOT/ssh/config.d/, included by ~/.ssh/config)"
