#!/bin/sh
# install-cloud.sh - install this repo's global rules into ~/.claude (cloud/Linux sessions).
# Installs: Agent.md, CLAUDE.md (@Agent.md), agents/, licenses/, the sh Bash guard hook, and its settings.json entry.
# Does NOT touch git config (core.hooksPath) - Agent.md section 5.
# Safe to run repeatedly. Files it would overwrite are backed up to ~/.claude/.install-backup/<time>/
# and restored if any later step fails.
set -eu

src=$(cd "$(dirname "$0")" && pwd)
dest="$HOME/.claude"
settings="$dest/settings.json"
hook_cmd='sh "$HOME/.claude/hooks/block-main-commit.sh"'
files='Agent.md agents/planner.md agents/security-reviewer.md hooks/block-main-commit.sh licenses/ECC-LICENSE.txt CLAUDE.md settings.json'

command -v jq >/dev/null 2>&1 || { echo "install-cloud: jq is required" >&2; exit 1; }
for f in Agent.md agents/planner.md agents/security-reviewer.md .claude/hooks/block-main-commit.sh licenses/ECC-LICENSE.txt; do
  [ -f "$src/$f" ] || { echo "install-cloud: missing $src/$f" >&2; exit 1; }
done

# Build the merged settings first; nothing is written if this fails.
# The existing file (if any) must be exactly one JSON object; hooks/PreToolUse must have the expected types.
base='{}'
if [ -f "$settings" ] && [ -n "$(tr -d '[:space:]' < "$settings")" ]; then
  base=$(cat "$settings")
fi
printf '%s' "$base" | jq -se '
  length == 1 and (.[0] | type == "object")
  and ((.[0].hooks // {}) | type == "object")
  and ((.[0].hooks.PreToolUse // []) | type == "array")' >/dev/null 2>&1 \
  || { echo "install-cloud: $settings is not a single JSON object with an array hooks.PreToolUse; left untouched" >&2; exit 1; }
merged=$(printf '%s' "$base" | jq --arg cmd "$hook_cmd" '
  .hooks.PreToolUse = (.hooks.PreToolUse // [])
  | if any(.hooks.PreToolUse[]?; .matcher == "Bash" and any(.hooks[]?; .type == "command" and .command == $cmd)) then .
    else .hooks.PreToolUse += [{matcher: "Bash", hooks: [{type: "command", command: $cmd}]}] end
') || { echo "install-cloud: cannot merge $settings; left untouched" >&2; exit 1; }

# Back up everything this script may overwrite; remember what did not exist so rollback can remove it.
backup="$dest/.install-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
: > "$backup/.new"
for f in $files; do
  if [ -e "$dest/$f" ]; then
    mkdir -p "$backup/$(dirname "$f")"
    cp -p "$dest/$f" "$backup/$f"
  else
    echo "$f" >> "$backup/.new"
  fi
done

ok=0
rollback() {
  echo "install-cloud: failed; restoring from $backup" >&2
  for f in $files; do
    if [ -e "$backup/$f" ]; then cp -p "$backup/$f" "$dest/$f"; fi
  done
  while read -r f; do [ -n "$f" ] && rm -f "$dest/$f"; done < "$backup/.new"
}
trap '[ "$ok" = 1 ] || rollback' EXIT

mkdir -p "$dest/agents" "$dest/hooks" "$dest/licenses"
cp "$src/Agent.md" "$dest/Agent.md"
cp "$src/agents/planner.md" "$src/agents/security-reviewer.md" "$dest/agents/"
cp "$src/licenses/ECC-LICENSE.txt" "$dest/licenses/ECC-LICENSE.txt"
cp "$src/.claude/hooks/block-main-commit.sh" "$dest/hooks/block-main-commit.sh"
chmod +x "$dest/hooks/block-main-commit.sh"

touch "$dest/CLAUDE.md"
if ! grep -qx '@Agent.md' "$dest/CLAUDE.md"; then
  # Start the import on its own line even when the file does not end with a newline.
  if [ -s "$dest/CLAUDE.md" ] && [ -n "$(tail -c1 "$dest/CLAUDE.md")" ]; then printf '\n' >> "$dest/CLAUDE.md"; fi
  printf '@Agent.md\n' >> "$dest/CLAUDE.md"
fi

printf '%s\n' "$merged" > "$settings.tmp" && mv "$settings.tmp" "$settings"
ok=1
echo "install-cloud: installed into $dest (backup: $backup)"
