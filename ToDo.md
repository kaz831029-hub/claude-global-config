# ToDo.md

Work one module at a time, in this order (Agent.md section 3).

## Modules
- [x] global-tools: `setup-tools.ps1` (Reticle, Ouroboros), README "Global tools", Agent.md section 7 rule (PR #5, merged)
- [x] hardening-1 setup-tools.ps1: dry-run writes nothing, `-Prepare` + `-ExpectedSha256` gate, Node 20.11 check, wider backup (written, not run - no PowerShell)
- [x] hardening-2 install-cloud.sh: backup + rollback, single-object settings check, matcher-aware dedupe, newline-safe import, license copied (tested in temp HOME)
- [x] hardening-3 `.gitignore`, githooks executable + `-x` chain check, README Git protection section (hooks tested by direct invocation)
- [ ] github-main-protection: user sets a ruleset on `main` in GitHub settings (agent cannot)
- [ ] powershell-matcher: change `.claude/settings.json` matcher to `Bash|PowerShell` and verify `tool_input.command` on the Windows PC
- [ ] codex-port: AGENTS.md + `~/.codex/agents/*.toml` (planner, security-reviewer) + hook equivalent - needs its own plan
- [x] global-tools-verify: run `setup-tools.ps1` on the Windows PC (dry-run first), confirm MCP tools load, fix script bugs found (branch `fix/setup-tools-stderr`; the hardened script's `-Prepare`/`-ExpectedSha256` path and `-Apply` end-to-end are still unrun)
- [ ] tools-review: check Image to 3JS and UI Skills (only if 3D / web UI work exists)
- [ ] chisle-trial (optional): `npx chisle --dry-run`, trial with `--only claude` on one project, measure before deciding

## Progress log
- 2026-10-14: Reticle, Ouroboros, Chisle reviewed from READMEs. Chisle excluded (no clear saving, clashes with Agent.md reporting). `setup-tools.ps1` written in a Linux container without PowerShell; PR #5 merged.
- 2026-10-14 (Windows PC): syntax check and dry-run passed on PowerShell 5.1. Installer SHA256 checked against the reviewed file before install. Reticle 3.7.0 and Ouroboros 0.55.7 (backend `claude`) installed; `claude mcp list` shows reticle Connected, plugin `ouroboros@ouroboros` enabled, reticle_* and ouroboros_* MCP tools loaded in a new session. Telemetry off for both (`~/.ouroboros/.env`, `config.yaml` `enabled: false`, `reticle telemetry disable`). Backup: `~\.claude-tools-backup\20261014-094107`.
- Bug found: `-Apply` stopped twice because `reticle` and `uv` write progress to stderr, which PowerShell 5.1 treats as a terminating error under `$ErrorActionPreference='Stop'`. The remaining steps were run by hand. Fixed in `Invoke-Step` (exit code decides success); fix tested on the function only.
- Global `~/.claude/Agent.md` synced with the repo (section 2 Refactor line, section 7 tool rule).

## Next steps / cautions
- Not verified: the fixed script has not been run end-to-end with `-Apply` or `-Uninstall -Apply`. `ooo setup` has not been run once as the user.
- Side effects to know before uninstalling: `reticle setup install` registered MCP in 17 agents (Claude Code, Gemini, OpenCode, Antigravity, Codex, VS Code, Zed, Cline, etc.); Ouroboros wrote rules and 23 skills to `~/.codex` and installed a uv-managed Python 3.13 into `~/.local/bin`.
- Unverified: Reticle uninstall steps (inferred as the inverse of install), Chisle's modified files (docs/usage.md unread). Ouroboros backend `claude` is the SDK profile; `claude-cli` is the alternative.
- `reticle init` changes a project (dev dependencies, build config, CLAUDE.md): get approval per project.
- Use Ouroboros for new projects and complex features only.
