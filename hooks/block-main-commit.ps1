# block-main-commit.ps1 (v7) - Claude-side guard for Agent.md section 5.
# Real main/master protection = global git hooks (~/.githooks/pre-commit, pre-push).
# This hook blocks common bypass attempts that appear directly in a Bash/PowerShell command.
# It is a mistake guard, not a security boundary (aliases, scripts, Edit/Write tools are not checked).
# Exit 2 = block. Unreadable input = allow.
try {
  $ms = New-Object System.IO.MemoryStream
  [Console]::OpenStandardInput().CopyTo($ms)
  $raw = [System.Text.Encoding]::UTF8.GetString($ms.ToArray())
  $cmd = [string]($raw | ConvertFrom-Json).tool_input.command
} catch { exit 0 }
if (-not $cmd) { exit 0 }

$ask = 'Ask the user to run it in their own terminal.'
$reason = $null
if ($cmd -match '(?i)\.githooks') {
  $reason = "Commands that mention ~/.githooks are blocked (reading too). $ask"
} elseif ($cmd -match '(?i)hookspath') {
  $reason = "Commands that mention core.hooksPath are blocked (reading too). $ask"
} elseif ($cmd -match '(?i)GIT_CONFIG_(PARAMETERS|COUNT|KEY_|VALUE_|GLOBAL|SYSTEM|NOSYSTEM)') {
  $reason = "GIT_CONFIG_* overrides can disable git hooks. Run git without them."
} elseif ($cmd -match '(?i)\bgit\b[^;&|\r\n]*\s["'']?--no-ve') {
  $reason = '--no-verify skips the main/master protection hooks.'
} elseif ($cmd -match '(?i)\bgit\b[^;&|\r\n]*\bcommit\b[^;&|\r\n]*\s["'']?(?-i:-[A-Za-z]*n[A-Za-z]*)["'']?(\s|$|[;&|])') {
  $reason = 'git commit -n (= --no-verify) skips the main/master protection hooks. If -n is only text in the message, reword it.'
}

if ($reason) {
  [Console]::Error.WriteLine("BLOCKED by Claude hook: $reason Work on a feature branch (git switch -c feat/<module>) and use plain git commit/push.")
  exit 2
}
exit 0
