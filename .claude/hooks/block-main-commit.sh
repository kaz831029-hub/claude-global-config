#!/bin/sh
# block-main-commit.sh - sh port of hooks/block-main-commit.ps1 (Agent.md section 5), for cloud/Linux sessions.
# Real main/master protection = git hooks (githooks/pre-commit, pre-push).
# This hook blocks common bypass attempts that appear directly in a Bash command.
# It is a mistake guard, not a security boundary. Exit 2 = block. Unreadable input = allow.
raw=$(cat) || exit 0
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$raw" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
elif command -v python3 >/dev/null 2>&1; then
  cmd=$(printf '%s' "$raw" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null) || exit 0
else
  exit 0
fi
[ -n "$cmd" ] || exit 0

ask='Ask the user to run it in their own terminal.'
reason=
if printf '%s' "$cmd" | grep -qiP '\.githooks'; then
  reason="Commands that mention ~/.githooks are blocked (reading too). $ask"
elif printf '%s' "$cmd" | grep -qiP 'hookspath'; then
  reason="Commands that mention core.hooksPath are blocked (reading too). $ask"
elif printf '%s' "$cmd" | grep -qiP 'GIT_CONFIG_(PARAMETERS|COUNT|KEY_|VALUE_|GLOBAL|SYSTEM|NOSYSTEM)'; then
  reason="GIT_CONFIG_* overrides can disable git hooks. Run git without them."
elif printf '%s' "$cmd" | grep -qiP '\bgit\b[^;&|\r\n]*\s["'\'']?--no-ve'; then
  reason='--no-verify skips the main/master protection hooks.'
elif printf '%s' "$cmd" | grep -qP '(?i)\bgit\b[^;&|\r\n]*\bcommit\b[^;&|\r\n]*\s["'\'']?(?-i:-[A-Za-z]*n[A-Za-z]*)["'\'']?(\s|$|[;&|])'; then
  reason='git commit -n (= --no-verify) skips the main/master protection hooks. If -n is only text in the message, reword it.'
fi

if [ -n "$reason" ]; then
  echo "BLOCKED by Claude hook: $reason Work on a feature branch (git switch -c feat/<module>) and use plain git commit/push." >&2
  exit 2
fi
exit 0
