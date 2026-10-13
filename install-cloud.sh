#!/bin/sh
# install-cloud.sh - install this repo's global rules into ~/.claude (cloud/Linux sessions).
# Installs: Agent.md, CLAUDE.md (@Agent.md), agents/, the sh Bash guard hook, and its settings.json entry.
# Does NOT touch git config (core.hooksPath) - Agent.md section 5.
# Safe to run repeatedly. On any problem it stops before writing anything it cannot undo.
set -eu

src=$(cd "$(dirname "$0")" && pwd)
dest="$HOME/.claude"
settings="$dest/settings.json"
hook_cmd='sh "$HOME/.claude/hooks/block-main-commit.sh"'

command -v jq >/dev/null 2>&1 || { echo "install-cloud: jq is required" >&2; exit 1; }
for f in Agent.md agents/planner.md agents/security-reviewer.md .claude/hooks/block-main-commit.sh; do
  [ -f "$src/$f" ] || { echo "install-cloud: missing $src/$f" >&2; exit 1; }
done

# Build the merged settings first; nothing is written if this fails.
base='{}'
if [ -f "$settings" ]; then
  base=$(cat "$settings")
fi
merged=$(printf '%s' "$base" | jq --arg cmd "$hook_cmd" '
  .hooks.PreToolUse = (.hooks.PreToolUse // [])
  | if any(.hooks.PreToolUse[]?; any(.hooks[]?; .command == $cmd)) then .
    else .hooks.PreToolUse += [{matcher: "Bash", hooks: [{type: "command", command: $cmd}]}] end
') || { echo "install-cloud: cannot parse $settings; left untouched" >&2; exit 1; }

mkdir -p "$dest/agents" "$dest/hooks"
cp "$src/Agent.md" "$dest/Agent.md"
cp "$src/agents/planner.md" "$src/agents/security-reviewer.md" "$dest/agents/"
cp "$src/.claude/hooks/block-main-commit.sh" "$dest/hooks/block-main-commit.sh"
chmod +x "$dest/hooks/block-main-commit.sh"

touch "$dest/CLAUDE.md"
grep -qx '@Agent.md' "$dest/CLAUDE.md" || printf '@Agent.md\n' >> "$dest/CLAUDE.md"

printf '%s\n' "$merged" > "$settings.tmp" && mv "$settings.tmp" "$settings"
echo "install-cloud: installed into $dest"
