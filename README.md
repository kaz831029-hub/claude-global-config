# claude-global-config
Claude Setting from beginning. Win11 with Poweshell and VS Code

## Cloud sessions (Linux)
`install-cloud.sh` installs `Agent.md`, `CLAUDE.md` (`@Agent.md`), `agents/` and the `sh` Bash guard hook into `~/.claude`.
It needs `jq`, merges into an existing `settings.json` without overwriting it, and does not touch git config.
Files it would overwrite are first copied to `~/.claude/.install-backup/<time>/` and restored if a later step fails. It refuses to touch a `settings.json` that is not a single JSON object with an array `hooks.PreToolUse`. `licenses/ECC-LICENSE.txt` is installed too, because the agents are adapted from ECC (MIT).

Paste this into the cloud environment's Setup script (environment menu > Edit; network access to github.com required):

    git clone --depth 1 https://github.com/kaz831029-hub/claude-global-config /tmp/claude-global-config && sh /tmp/claude-global-config/install-cloud.sh

Check in a new session: `/memory` lists `Agent.md`, and `/hooks` shows the `PreToolUse` Bash hook.

## Secrets and Git protection
- `.gitignore` excludes `.env*`, local Claude settings and credentials, and the backup folders the installers create. Never put a real key in this repository; if one is ever committed, revoke and rotate it first - deleting the file does not remove it from Git history.
- `githooks/pre-commit` and `githooks/pre-push` block commits on `main`/`master` and any push that creates, updates or deletes `main`/`master` on the remote. They do nothing until you install them. Install them yourself in your own terminal; Agent.md section 5 forbids the agent from changing the Git hooks path setting, and the Claude guard hook blocks commands that mention it. Steps: copy both files into a folder of your choice, `chmod +x` them, then point the global Git hooks path setting at that folder. Check: on `main`, `git commit --allow-empty -m test` must print `BLOCKED by git hook`.
- On Windows use Git Bash for the copy and `chmod`, and keep LF line endings in the hook files (CRLF breaks shell scripts).
- A repository's own `.git/hooks/pre-commit` / `pre-push` still run through these hooks, but only if the file is executable.
- `.claude/hooks/block-main-commit.sh` is a mistake guard, not a security boundary: it only inspects the Bash command text, and it allows the command when the input cannot be parsed or `jq`/`python3` is missing. Local hooks run with your own permissions. Real protection also needs server-side branch rules on GitHub.

## Global tools (Windows, local PC)
`setup-tools.ps1` installs or removes Reticle and Ouroboros for Claude Code. Chisle is excluded: its own benchmark shows no clear saving, and its terse-output rules clash with `Agent.md` reporting.

Stages (what you review is what runs):

    .\setup-tools.ps1 -Tool reticle,ouroboros                  # 1. dry-run: checks + planned commands, writes nothing
    .\setup-tools.ps1 -Tool ouroboros -Prepare                 # 2. downloads the Ouroboros installer to %TEMP%, prints SHA256
    # read %TEMP%\ouroboros-install.ps1
    .\setup-tools.ps1 -Tool reticle,ouroboros -Apply -ExpectedSha256 <hash from step 2>   # 3. install
    .\setup-tools.ps1 -Tool reticle,ouroboros -Uninstall -Apply

| Tool | Does | Needs | Check after install | Remove |
|---|---|---|---|---|
| Reticle | Verifies web apps in a real browser (MCP) | Node 20.11+ (checked, install stops if older) | restart Claude Code, `claude mcp list` shows `reticle` | script `-Uninstall` (inverse of install; README documents no uninstall command - Unverified) |
| Ouroboros | Requirement interview before coding (`ooo`) | winget (installs Git and uv if missing) | restart Claude Code, `ouroboros --version`, run `ooo setup` once | `ouroboros uninstall` |

- Reticle registers itself with every coding agent it detects (Claude Code, Cursor, Windsurf, Codex, ...). The script backs up their known config files, but `-Uninstall` removes only the Claude Code entry; remove the others by hand.
- Telemetry: with `-Apply` the script sets `DO_NOT_TRACK=1`, `RETICLE_TELEMETRY=0`, `OUROBOROS_TELEMETRY=0` for the install process (the Ouroboros variable name is Unverified), then runs `reticle telemetry disable`. Read Ouroboros's TELEMETRY.md before real use.
- `reticle init` changes a project (dev dependencies, build config, appends to CLAUDE.md), so run it per project after approval.
- Backups go to `~\.claude-tools-backup\<timestamp>` and may contain credentials. Never commit or share them.
- Native Windows support of Ouroboros is marked experimental upstream; Ouroboros with the Codex CLI backend is supported only under WSL 2.
- Not tested: the script was written in a Linux container without PowerShell; syntax and behavior are unverified.
