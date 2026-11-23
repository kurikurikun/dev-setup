#!/bin/bash
# One-time setup for a Mac that works on move-ment's apps:
#   curl -fsSL https://raw.githubusercontent.com/kurikurikun/dev-setup/main/setup.sh | bash
#
# 1. Clones the apps (and the website) into ~/Developer — never into iCloud.
#    Existing clones are left alone.
# 2. Installs a Claude Code SessionStart hook: a session opened inside
#    ~/Developer/<repo> fast-forwards that repo from GitHub first (never merges,
#    never touches uncommitted work; it tells you instead).
# Safe to run again: it only adds what's missing.
set -euo pipefail

RAW="https://raw.githubusercontent.com/kurikurikun/dev-setup/main"
REPOS=(
  "peripheral-speed:peripheral-speed-app"
  "day-offload:day-offload"
  "callnotes:callnotes"
  "movement-website:movement-website"
  "filminginjapan:filminginjapan"
  "tesutemo:tesutemo"
  "crew-book:crew-book"
  "Minpaku-register:minpaku-register"
  "looplapse:looplapse"
  "remotion:remotion"
  "lead-hub:lead-hub"
)
# Where these used to live (iCloud-synced Documents). Only used to copy over
# .env.local, which is never in git, so a fresh clone can still run locally.
OLD="$HOME/Documents/claude"

command -v git >/dev/null || { echo "git is missing. Run:  xcode-select --install   then run this again." >&2; exit 1; }
command -v jq  >/dev/null || { echo "jq is missing (it ships with macOS 15+). Run:  brew install jq   then run this again." >&2; exit 1; }

echo "== Repos in ~/Developer"
mkdir -p "$HOME/Developer"
for entry in "${REPOS[@]}"; do
  repo=${entry%%:*}; dir="$HOME/Developer/${entry##*:}"
  if [ -d "$dir/.git" ]; then
    echo "  ✓ ${entry##*:} (already here)"
  else
    git clone -q "https://github.com/kurikurikun/$repo.git" "$dir" && echo "  + ${entry##*:} cloned"
  fi
  old="$OLD/${entry##*:}/.env.local"
  if [ -f "$old" ] && [ ! -f "$dir/.env.local" ]; then
    cp "$old" "$dir/.env.local" && echo "    + .env.local copied from $OLD"
  fi
done

echo "== Claude Code auto-pull hook"
mkdir -p "$HOME/.claude/hooks"
HOOK="$HOME/.claude/hooks/dev-autopull.sh"
curl -fsSL "$RAW/hooks/dev-autopull.sh" -o "$HOOK.new"
grep -q "SessionStart hook" "$HOOK.new" || { echo "downloaded hook looks wrong — stopping" >&2; rm -f "$HOOK.new"; exit 1; }
mv "$HOOK.new" "$HOOK" && chmod +x "$HOOK" && echo "  ✓ $HOOK"

SETTINGS="$HOME/.claude/settings.json"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
jq empty "$SETTINGS" 2>/dev/null || { echo "$SETTINGS isn't valid JSON — fix it, then run this again." >&2; exit 1; }
if jq -e '[.hooks.SessionStart[]?.hooks[]?.command] | any(test("dev-autopull"))' "$SETTINGS" >/dev/null; then
  echo "  ✓ already in $SETTINGS"
else
  cp "$SETTINGS" "$SETTINGS.bak-autopull"
  jq '.hooks = (.hooks // {}) | .hooks.SessionStart = ((.hooks.SessionStart // []) + [{"hooks":[{"type":"command","command":"~/.claude/hooks/dev-autopull.sh","timeout":30,"statusMessage":"Pulling latest from GitHub…"}]}])' \
    "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  echo "  + added to $SETTINGS (backup: settings.json.bak-autopull)"
fi

echo
echo "Done. Start Claude Code sessions inside the app's folder, e.g. ~/Developer/callnotes,"
echo "and it pulls the latest from GitHub first. Commit + push when you finish on a Mac."
echo "The old copies in $OLD are not touched; delete them once you're happy."
