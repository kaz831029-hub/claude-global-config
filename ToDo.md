# ToDo.md

Work one module at a time, in this order (Agent.md section 3).

## Modules
- [x] global-tools: `setup-tools.ps1` (Reticle, Ouroboros), README "Global tools", Agent.md section 7 rule (PR #5, merged)
- [ ] global-tools-verify: run `setup-tools.ps1` on the Windows PC (dry-run first), confirm MCP tools load, fix script bugs found
- [ ] tools-review: check Image to 3JS and UI Skills (only if 3D / web UI work exists)
- [ ] chisle-trial (optional): `npx chisle --dry-run`, trial with `--only claude` on one project, measure before deciding

## Progress log
- 2026-10-14: Reticle, Ouroboros, Chisle reviewed from READMEs. Chisle excluded (no clear saving, clashes with Agent.md reporting). `setup-tools.ps1` written in a Linux container without PowerShell; PR #5 merged.

## Next steps / cautions
- `setup-tools.ps1` is untested (no PowerShell where it was written). Run the dry-run on the Windows PC first and review the saved Ouroboros installer before `-Apply`.
- Unverified: Reticle uninstall steps (inferred as the inverse of install), Ouroboros telemetry policy (read TELEMETRY.md), Chisle's modified files (docs/usage.md unread), Ouroboros backend `claude` (assumption).
- `reticle init` changes a project (dev dependencies, build config, CLAUDE.md): get approval per project.
- Use Ouroboros for new projects and complex features only.
