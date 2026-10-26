#!/usr/bin/env bash
# Idempotent dotfiles apply. Run on any machine after `git pull`.
# - Symlinks zshrc, ~/.ssh/rc and the 1Password agent.toml into place.
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
mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
# sshd runs ~/.ssh/rc at each login; it keeps ~/.ssh/agent.sock (pinned by zshrc) live.
link "$DOT/ssh/rc" "$HOME/.ssh/rc"

# Ensure ~/.ssh/config pulls in the synced host fragments (idempotent, prepended).
SSHCFG="$HOME/.ssh/config"; INC="Include ~/dotfiles/ssh/config.d/*"
touch "$SSHCFG"; chmod 600 "$SSHCFG"
if ! grep -qF "$INC" "$SSHCFG"; then
  { printf '%s\n\n' "$INC"; cat "$SSHCFG"; } > "$SSHCFG.tmp" && mv "$SSHCFG.tmp" "$SSHCFG"
  echo "  added Include -> ~/.ssh/config"
fi

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

# --- remotes: fetch over public HTTPS (agent-free, works under cron/launchd), push over SSH ---
git -C "$DOT" remote set-url origin https://github.com/nickpdawson/dotfiles.git 2>/dev/null || true
git -C "$DOT" remote set-url --push origin git@github.com:nickpdawson/dotfiles.git 2>/dev/null || true

# --- schedule the connectivity-checked pull every 30 min ---
case "$(uname -s)" in
  Darwin)
    PL="$HOME/Library/LaunchAgents/net.dzsec.dotfiles-pull.plist"
    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$PL" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>net.dzsec.dotfiles-pull</string>
  <key>ProgramArguments</key><array><string>$DOT/bin/pull-dotfiles.sh</string></array>
  <key>StartInterval</key><integer>1800</integer>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>/tmp/dotfiles-pull.log</string>
  <key>StandardErrorPath</key><string>/tmp/dotfiles-pull.log</string>
</dict></plist>
PLIST
    launchctl bootout "gui/$(id -u)/net.dzsec.dotfiles-pull" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$PL" 2>/dev/null && echo "  scheduled: launchd every 30m" || echo "  launchd bootstrap skipped"
    ;;
  Linux)
    LINE="*/30 * * * * $DOT/bin/pull-dotfiles.sh >/dev/null 2>&1"
    ( crontab -l 2>/dev/null | grep -vF "pull-dotfiles.sh"; echo "$LINE" ) | crontab - && echo "  scheduled: cron every 30m"
    ;;
esac

echo "done. (ssh host pins live in $DOT/ssh/config.d/, included by ~/.ssh/config)"
