# claude-global-config
Claude Setting from beginning. Win11 with Poweshell and VS Code

## Cloud sessions (Linux)
`install-cloud.sh` installs `Agent.md`, `CLAUDE.md` (`@Agent.md`), `agents/` and the `sh` Bash guard hook into `~/.claude`.
It needs `jq`, merges into an existing `settings.json` without overwriting it, and does not touch git config.

Paste this into the cloud environment's Setup script (environment menu > Edit; network access to github.com required):

    git clone --depth 1 https://github.com/kaz831029-hub/claude-global-config /tmp/claude-global-config && sh /tmp/claude-global-config/install-cloud.sh

Check in a new session: `/memory` lists `Agent.md`, and `/hooks` shows the `PreToolUse` Bash hook.

## Global tools (Windows, local PC)
`setup-tools.ps1` installs or removes Reticle and Ouroboros for Claude Code. Default is a dry-run; `-Apply` runs for real. Chisle is excluded: its own benchmark shows no clear saving, and its terse-output rules clash with `Agent.md` reporting.

    .\setup-tools.ps1 -Tool reticle,ouroboros              # dry-run
    .\setup-tools.ps1 -Tool reticle,ouroboros -Apply       # install (backs up ~/.claude settings first)
    .\setup-tools.ps1 -Tool reticle,ouroboros -Uninstall -Apply

| Tool | Does | Needs | Check after install | Remove |
|---|---|---|---|---|
| Reticle | Verifies web apps in a real browser (MCP) | Node 20.11+ | restart Claude Code, `claude mcp list` shows `reticle` | script `-Uninstall` (inverse of install; README documents no uninstall command - Unverified) |
| Ouroboros | Requirement interview before coding (`ooo`) | winget (installs Git and uv if missing) | restart Claude Code, `ouroboros --version`, run `ooo setup` once | `ouroboros uninstall` |

- Reticle sends anonymous usage counts by default; the script runs `reticle telemetry disable`. `reticle init` changes a project (dev dependencies, build config, appends to CLAUDE.md), so run it per project after approval.
- Ouroboros downloads its installer to `%TEMP%` and prints the SHA256 so you can review it before `-Apply`. Telemetry: read its TELEMETRY.md. Native Windows support is marked experimental upstream.
- Backups go to `~\.claude-tools-backup\<timestamp>`.
- Not tested: the script was written in a Linux container without PowerShell; syntax and behavior are unverified.
