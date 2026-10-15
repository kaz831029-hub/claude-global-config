# ToDo.md

Work one module at a time, in this order (Agent.md section 3). Structure: Agent.md section 10.

## Modules
- [x] global-tools: `setup-tools.ps1` (Reticle, Ouroboros), README "Global tools", Agent.md section 7 rule (PR #5, merged)
- [x] hardening-1 setup-tools.ps1: dry-run writes nothing, `-Prepare` + `-ExpectedSha256` gate, Node 20.11 check, wider backup (written, not run - no PowerShell)
- [x] hardening-2 install-cloud.sh: backup + rollback, single-object settings check, matcher-aware dedupe, newline-safe import, license copied (tested in temp HOME)
- [x] hardening-3 `.gitignore`, githooks executable + `-x` chain check, README Git protection section (hooks tested by direct invocation)
- [x] global-tools-verify: run `setup-tools.ps1` on the Windows PC (dry-run first), confirm MCP tools load, fix script bugs found (PR #8; the hardened script's `-Prepare`/`-ExpectedSha256` path and `-Apply` end-to-end are still unrun)
- [x] agent-md-harness: Agent.md rules from the Karpathy-inspired harness prompt (data not instructions, retry check, backup before risky edits, prose is not enforcement, no weakened checks, blocker/measured reporting) and the four-section ToDo.md structure
- [ ] github-main-protection: user sets a ruleset on `main` in GitHub settings (agent cannot)
- [ ] powershell-matcher: change `.claude/settings.json` matcher to `Bash|PowerShell` and verify `tool_input.command` on the Windows PC
- [ ] codex-port: AGENTS.md + `~/.codex/agents/*.toml` (planner, security-reviewer) + hook equivalent - needs its own plan
- [ ] tools-review: check Image to 3JS and UI Skills (only if 3D / web UI work exists)
- [ ] chisle-trial (optional): `npx chisle --dry-run`, trial with `--only claude` on one project, measure before deciding

## Checks (current module)
| Requirement | Verdict | Evidence | Correction |
|---|---|---|---|

## Handoff (latest only)
- Task: keep the global config (Agent.md, agents, hooks, installers) correct and installable on the Windows PC and in cloud sessions.
- Outputs: `Agent.md`, `ToDo.md`, `README.md`, `setup-tools.ps1`, `install-cloud.sh`, `githooks/`, `.gitignore`
- Done: agent-md-harness - Agent.md sections 1, 2, 3, 4, 5, 10 extended; ToDo.md moved to the four-section structure (content kept).
- Decisions: one ToDo.md with four sections instead of separate progress.md / checks.md files (fewer files to keep in sync). Chisle excluded. Ouroboros backend `claude` (SDK profile; `claude-cli` is the alternative).
- Open issues:
  - `setup-tools.ps1` after the PR #7 + #8 merge has not been run end-to-end with `-Prepare` / `-Apply` / `-Uninstall -Apply`. `ooo setup` has not been run once as the user.
  - Unverified: Reticle uninstall steps (inferred as the inverse of install), `OUROBOROS_TELEMETRY` variable name, Chisle's modified files (docs/usage.md unread).
  - Side effects to know before uninstalling: `reticle setup install` registered MCP in 17 agents (Claude Code, Gemini, OpenCode, Antigravity, Codex, VS Code, Zed, Cline, etc.); Ouroboros wrote rules and 23 skills to `~/.codex` and installed a uv-managed Python 3.13 into `~/.local/bin`.
  - The Windows PC's `~/.claude/Agent.md` must be re-synced after this change is merged.
  - `reticle init` changes a project (dev dependencies, build config, CLAUDE.md): get approval per project. Use Ouroboros for new projects and complex features only.
- Next action: re-sync `~/.claude/Agent.md` on the Windows PC, then set the GitHub ruleset on `main` (module github-main-protection).

## Progress log
- 2026-10-14: Reticle, Ouroboros, Chisle reviewed from READMEs. Chisle excluded (no clear saving, clashes with Agent.md reporting). `setup-tools.ps1` written in a Linux container without PowerShell; PR #5 merged.
- 2026-10-14 (Windows PC): syntax check and dry-run passed on PowerShell 5.1. Installer SHA256 checked against the reviewed file before install. Reticle 3.7.0 and Ouroboros 0.55.7 (backend `claude`) installed; `claude mcp list` shows reticle Connected, plugin `ouroboros@ouroboros` enabled, reticle_* and ouroboros_* MCP tools loaded in a new session. Telemetry off for both (`~/.ouroboros/.env`, `config.yaml` `enabled: false`, `reticle telemetry disable`). Backup: `~\.claude-tools-backup\20261014-094107`.
- 2026-10-14: Bug found: `-Apply` stopped twice because `reticle` and `uv` write progress to stderr, which PowerShell 5.1 treats as a terminating error under `$ErrorActionPreference='Stop'`. The remaining steps were run by hand. Fixed in `Invoke-Step` (exit code decides success); fix tested on the function only.
- 2026-10-14: Global `~/.claude/Agent.md` synced with the repo (section 2 Refactor line, section 7 tool rule).
- 2026-10-14: Audit report applied (PR #7): setup-tools.ps1 prepare/hash gate, install-cloud.sh backup + rollback, `.gitignore`, githooks. PR #8 (stderr fix) merged on top. Merged branches deleted.
- 2026-10-15: agent-md-harness - Agent.md extended from the Karpathy-inspired harness prompt; ToDo.md moved to Modules / Checks / Handoff / Progress log. Checks: 6 rules added and placed in sections 1/2/4/5 - pass (git diff); section 10 structure defined and this file follows it - pass (manual read); existing content preserved - pass (every old line kept in Modules, Handoff or Progress log); global sync to the PC - unresolved (needs the user).
