# Agent.md (Global Rules; reply to the user in the language of the OS environment)

## 0. Reference Documents
- Priority: Agent.md > Concept.md > ToDo.md > Design.md
- Code work (adding or changing features): read Concept.md and ToDo.md before starting. If the work has a UI, also read Design.md.
- If a required document is missing or empty, propose a draft instead of writing code and get approval. Questions, analysis, and typo fixes can proceed without reference documents (fixes still need approval).
- If documents conflict, ask the user.

## 1. Absolute Prohibitions
- No code changes or deletions before user approval. Plan first: files to change, what changes, and the scope of impact.
- Edits within an approved plan need no re-approval. Scope expansion, new dependencies, and deletions or file changes not in the approved plan need additional approval.
- No adding libraries without approval (explain the reason and alternatives to get approval).
- One module at a time, in ToDo.md order. Do not touch anything outside the request.
- No guessing. If something is unclear, ask with options.
- When reporting errors, analyze the full original error text, state the cause, and show the fix. Mask secrets and personal data, and quote only the necessary lines.
- Do not use colors, fonts, or spacing that are not in Design.md.
- Never hard-code API keys or passwords in code. For development, use .env as the default, add it to .gitignore, and never commit it. For production or deployment, the secret-management method needs separate approval (.env is not a secure store).
- Label any unavoidable default as "Assumption:" in the report.

## 2. Coding Principles (based on Karpathy's guidelines)
- Think first: state assumptions. If there are several interpretations, show all of them. Do not silently pick one.
- If a simpler approach exists, say so and push back if needed.
- Simplicity first: no features that were not requested, no single-use abstractions, no configuration options, and no error handling for impossible scenarios.
- Fewer lines is not a goal. Prioritize minimal change and clarity. Simplify only when behavior stays the same and the result is clearly simpler.
- Surgical changes: do not "improve" adjacent code, comments, or formatting. Do not refactor code that is not broken.
- Follow the existing style. Every changed line must be traceable to the request.
- Remove only unused imports, variables, and functions that your own change made unused.
- Report existing dead code without deleting it. Deletion happens only after cleanup approval.
- Goal-driven: turn each task into a verifiable goal.
  - Bug fix = write a reproducing test first, then make it pass.
  - Feature = state the verification method in the plan.
  - Multi-step work = plan as `step -> verify: method`.
- Trivial tasks (typo, one-line change) can be reported in one line (files and change). Approval is still required.

## 3. Work Order (repeat for each module)
1. Check documents -> summarize goal and completion criteria
2. Report implementation plan -> wait for approval
3. Create a work branch and implement
4. Verify by running and testing
5. Garbage cleaning (section 6)
6. Check off ToDo.md and update the progress log
7. Perform only the Git actions the user approved (commit after approval; push asked separately with "Push now?") -> report the result

## 4. Completion Criteria
- Code implementation: runs locally without errors, tests pass or manual checks are recorded, Design.md followed (UI work), garbage cleaning done, ToDo.md updated.
- Analysis and documents: sources were checked, and anything not verified is marked "Unverified".
- If code that needs running or testing was not run or tested, do not call it "done." Report what was not verified and why.

## 5. Git Rules
- No direct commit or push to main or master. The global Git hook blocks it. Bypassing with `--no-verify`, changing `core.hooksPath`, or similar is forbidden.
- Commit and push only when the user approves.
- Branch names: `feat/module-name`, `fix/problem-summary`, `docs/document-name`, `chore/cleanup`
- Commit message: `[module] one-line summary` (example: `[login] Email login screen complete`)
- Commit small and often. Tell the user the branch name every time.

## 6. Garbage Cleaning
- When: when a module is complete, or when the user asks for "cleanup"
- Targets: temporary files (`*.tmp`, `*.bak`, `*.log`), cache and build folders (check .gitignore)
- Targets: debug output (`print`, `console.log`), unused imports, functions, and variables, commented-out dead code
- Targets: resolved TODO/FIXME, unused dependencies, merged branches, duplicate or old-version files (`_old`, `_v2`, `copy`)
- Procedure: report a candidate table (path / reason / action) -> clean only approved items -> retest -> (if commit is approved) commit `[cleanup] garbage cleaning - summary`
- Protected: `.md` documents, `.env`, `raw/` originals, user-created files. If the purpose of a file is unknown, do not delete it; ask.

## 7. Environment
- Baseline: Windows + PowerShell + VS Code
- Python uses uv; Node.js uses npm
- Record run instructions in README; provide `setup.ps1` if needed

## 8. Data Collection and Analysis
- Record sources (URL, file name, collection date/time)
- Keep originals in `raw/`, processed data in `processed/`
- Follow terms of service and robots.txt. Do not collect personal data, or mask it.
- State filters, conditions, and assumptions in the results

## 9. Report Format (when a module is complete)
- ✅ Done / 📁 Changed files / 🌿 Branch and commit / 🧹 Cleaned items
- 🧪 How to test: 1) preparation 2) commands to copy and run 3) expected result 4) common errors and fixes
- ⚠️ Assumptions and open issues / ➡️ Next module

## 10. Session Handoff
- If the project has a ToDo.md: a new session reads the progress log first, summarizes the current state, then starts.
- In the same case, at session end, record "next steps / cautions" in the progress log (sessions that only asked questions or did analysis are excluded).
