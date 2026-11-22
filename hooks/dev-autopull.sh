#!/bin/bash
# SessionStart hook: when a Claude Code session opens inside ~/Developer/<repo>,
# fast-forward that repo from GitHub so every Mac starts from the latest code.
# Never merges, never touches uncommitted work: anything unusual is skipped and
# reported to Claude as context instead.

input=$(cat)
cwd=$(printf '%s' "$input" | /usr/bin/jq -r '.cwd // empty' 2>/dev/null)
[ -z "$cwd" ] && cwd=$PWD

case "$cwd" in
  "$HOME/Developer"/*) ;;
  *) exit 0 ;;
esac

root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0
name=$(basename "$root")
git -C "$root" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1 || exit 0

say() {
  /usr/bin/jq -n --arg c "$1" --arg m "$2" \
    '{systemMessage: $m, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
  exit 0
}

if ! GIT_TERMINAL_PROMPT=0 git -C "$root" -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=10 fetch --quiet 2>/dev/null; then
  say "Auto-pull: could not reach GitHub for $name; working from the local copy, which may be behind." "$name: offline, not pulled"
fi

behind=$(git -C "$root" rev-list --count 'HEAD..@{u}')
ahead=$(git -C "$root" rev-list --count '@{u}..HEAD')
[ "$behind" = 0 ] && [ "$ahead" = 0 ] && exit 0

if [ -n "$(git -C "$root" status --porcelain --untracked-files=no)" ]; then
  say "Auto-pull: $name is $behind commit(s) behind GitHub but has uncommitted changes, so it was NOT pulled. Tell the user before editing." "$name: $behind behind, not pulled (uncommitted changes)"
fi

if [ "$behind" -gt 0 ] && [ "$ahead" -gt 0 ]; then
  say "Auto-pull: $name has diverged from GitHub ($ahead local commit(s) not pushed, $behind new on GitHub). Not pulled; tell the user before editing." "$name: diverged from GitHub, not pulled"
fi

if [ "$behind" -gt 0 ]; then
  if git -C "$root" merge --ff-only --quiet '@{u}' 2>/dev/null; then
    say "Auto-pull: fast-forwarded $name by $behind commit(s) from GitHub at session start." "$name: pulled $behind new commit(s)"
  else
    say "Auto-pull: fast-forward of $name failed; check git status before editing." "$name: pull failed"
  fi
fi

say "Auto-pull: $name has $ahead local commit(s) not yet pushed to GitHub. Remind the user to push when this work is done." "$name: $ahead unpushed commit(s)"
