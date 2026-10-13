# claude-global-config
Claude Setting from beginning. Win11 with Poweshell and VS Code

## Cloud sessions (Linux)
`install-cloud.sh` installs `Agent.md`, `CLAUDE.md` (`@Agent.md`), `agents/` and the `sh` Bash guard hook into `~/.claude`.
It needs `jq`, merges into an existing `settings.json` without overwriting it, and does not touch git config.

Paste this into the cloud environment's Setup script (environment menu > Edit; network access to github.com required):

    git clone --depth 1 https://github.com/kaz831029-hub/claude-global-config /tmp/claude-global-config && sh /tmp/claude-global-config/install-cloud.sh

Check in a new session: `/memory` lists `Agent.md`, and `/hooks` shows the `PreToolUse` Bash hook.
