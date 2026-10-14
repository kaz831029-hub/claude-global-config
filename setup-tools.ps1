# setup-tools.ps1 - install or remove global tools (Reticle, Ouroboros) for Claude Code on Windows.
# Three stages, so what you review is what runs:
#   (default) dry-run : checks the environment and prints planned commands. Writes nothing.
#   -Prepare          : downloads the Ouroboros installer to %TEMP% and prints its SHA256 (the only write).
#   -Apply            : installs. Ouroboros runs only the prepared file, and only if -ExpectedSha256 matches.
# Chisle is intentionally not included (README, "Global tools").
#
#   .\setup-tools.ps1 -Tool reticle,ouroboros                          # dry-run
#   .\setup-tools.ps1 -Tool ouroboros -Prepare                         # download + hash; review the file
#   .\setup-tools.ps1 -Tool reticle,ouroboros -Apply -ExpectedSha256 <hash from -Prepare>
#   .\setup-tools.ps1 -Tool reticle,ouroboros -Uninstall -Apply
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('reticle', 'ouroboros')][string[]]$Tool,
    [switch]$Prepare,
    [switch]$Apply,
    [switch]$Uninstall,
    [string]$ExpectedSha256,
    # Assumption: 'claude' is the right backend for Claude Code (installer accepts claude|claude-sdk|claude-cli|...).
    [string]$OuroborosRuntime = 'claude'
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $HOME ".claude-tools-backup\$stamp"
$ouroUrl = 'https://raw.githubusercontent.com/Q00/ouroboros/main/scripts/install.ps1'
$ouroFile = Join-Path $env:TEMP 'ouroboros-install.ps1'
$minNode = [version]'20.11'
# Reticle's installer registers every agent it detects, so back up and watch their config files too.
$watchDirs = @("$HOME\.claude", "$HOME\.reticle", "$HOME\.ouroboros", "$HOME\.codex")
$watchFiles = @(
    "$HOME\.claude\settings.json", "$HOME\.claude.json", "$HOME\.ouroboros\config.yaml",
    "$HOME\.codex\config.toml", "$HOME\.cursor\mcp.json", "$HOME\.codeium\windsurf\mcp_config.json"
)

function Info($m) { Write-Host "[info] $m" -ForegroundColor Cyan }
function Plan($m) { Write-Host "[plan] $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "[error] $m" -ForegroundColor Red; exit 1 }

function Test-Cmd($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }

function Show-Env {
    Info "OS: $([Environment]::OSVersion.VersionString), PowerShell: $($PSVersionTable.PSVersion)"
    foreach ($c in 'node', 'npm', 'git', 'uv', 'claude', 'winget') {
        if (Test-Cmd $c) { Info "$c found: $((Get-Command $c).Source)" } else { Info "$c NOT found" }
    }
}

function Get-Snapshot {
    foreach ($d in $watchDirs) {
        if (Test-Path $d) {
            Get-ChildItem $d -Recurse -File -ErrorAction SilentlyContinue |
                Select-Object @{n = 'Path'; e = { $_.FullName } }, Length, LastWriteTimeUtc
        }
    }
    foreach ($f in $watchFiles) {
        if ((Test-Path $f) -and -not ($watchDirs | Where-Object { $f.StartsWith($_) })) {
            Get-Item $f | Select-Object @{n = 'Path'; e = { $_.FullName } }, Length, LastWriteTimeUtc
        }
    }
}

function Backup-Config {
    New-Item -ItemType Directory -Force $backupDir | Out-Null
    foreach ($f in $watchFiles) {
        if (Test-Path $f) {
            $name = ($f.Substring($HOME.Length).TrimStart('\') -replace '[\\:]', '_')
            Copy-Item $f (Join-Path $backupDir $name)
            Info "backed up $f"
        }
    }
    Info "backup folder: $backupDir (may contain credentials; never commit or share it)"
}

function Invoke-Step($label, [scriptblock]$Block) {
    if (-not $Apply) { Plan $label; return }
    Info "run: $label"
    # Windows PowerShell 5.1 turns native stderr output (progress, notices) into a terminating error under 'Stop'; judge by exit code instead.
    $ErrorActionPreference = 'Continue'
    $global:LASTEXITCODE = 0
    & $Block
    if ($LASTEXITCODE -ne 0) { Fail "failed: $label (exit $LASTEXITCODE)" }
}

function Assert-Node {
    if (-not (Test-Cmd node) -or -not (Test-Cmd npm)) { Fail 'Node.js 20.11+ is required for Reticle (winget install OpenJS.NodeJS.LTS).' }
    $v = [version]((node --version).TrimStart('v'))
    if ($v -lt $minNode) { Fail "Node $v is too old; Reticle needs $minNode or newer." }
    Info "node $v OK"
}

function Install-Reticle {
    Assert-Node
    Invoke-Step 'npm install -g @reticlehq/server' { npm install -g '@reticlehq/server' }
    Invoke-Step 'reticle setup install   (registers the MCP server with every agent it detects)' { reticle setup install }
    Invoke-Step 'reticle telemetry disable' { reticle telemetry disable }
    Info 'Not done here on purpose: `reticle init` changes a project (dev dependencies, build config, CLAUDE.md). Run it per project after approval.'
}

function Uninstall-Reticle {
    # Unverified: the README documents no uninstall command; these are the inverse of the install steps.
    # Only the Claude Code user-scope entry is removed. Entries Reticle added to other agents must be removed by hand.
    Invoke-Step 'claude mcp remove reticle -s user' { claude mcp remove reticle -s user }
    Invoke-Step 'npm uninstall -g @reticlehq/server' { npm uninstall -g '@reticlehq/server' }
    Info 'Per-project leftovers from `reticle init` must be reverted in that project (git diff). State folder: ~/.reticle'
}

function Prepare-Ouroboros {
    Info "downloading installer for review: $ouroUrl"
    Invoke-WebRequest -Uri $ouroUrl -OutFile $ouroFile -UseBasicParsing
    $hash = (Get-FileHash $ouroFile -Algorithm SHA256).Hash
    Info "saved: $ouroFile"
    Info "SHA256: $hash"
    Info 'Read the file. It may install Git and uv through winget, then run `uv tool install ouroboros-ai`.'
    Info "If it is acceptable, run: .\setup-tools.ps1 -Tool ouroboros -Apply -ExpectedSha256 $hash"
}

function Install-Ouroboros {
    if (-not $Apply) {
        Plan "(-Prepare first) then: powershell -File $ouroFile -Runtime $OuroborosRuntime   (only if SHA256 matches -ExpectedSha256)"
        return
    }
    if (-not (Test-Path $ouroFile)) { Fail "No prepared installer at $ouroFile. Run with -Prepare first and review it." }
    if (-not $ExpectedSha256) { Fail 'Pass -ExpectedSha256 <hash printed by -Prepare> to run the reviewed installer.' }
    $actual = (Get-FileHash $ouroFile -Algorithm SHA256).Hash
    if ($actual -ne $ExpectedSha256) { Fail "SHA256 mismatch (file: $actual, expected: $ExpectedSha256). Run -Prepare again and re-review." }
    Invoke-Step "powershell -File $ouroFile -Runtime $OuroborosRuntime" {
        powershell -NoProfile -ExecutionPolicy Bypass -File $ouroFile -Runtime $OuroborosRuntime
    }
    Info 'Telemetry: read https://github.com/Q00/ouroboros/blob/main/TELEMETRY.md and decide before real use.'
}

function Uninstall-Ouroboros {
    Invoke-Step 'ouroboros uninstall   (removes configuration, MCP registration and data)' { ouroboros uninstall }
}

Show-Env
if ($Prepare -and $Apply) { Fail 'Use -Prepare and -Apply in separate runs, so you review the file between them.' }
if ($Prepare -and $Uninstall) { Fail '-Prepare does not combine with -Uninstall.' }

if ($Prepare) {
    if ($Tool -contains 'ouroboros') { Prepare-Ouroboros } else { Info 'Nothing to prepare: only Ouroboros downloads an installer.' }
    exit 0
}

if (-not $Apply) { Info 'DRY-RUN: nothing is written or changed. Add -Apply to run.' }
if ($Apply) {
    # Process-level opt-out so the installers' own first run does not report usage.
    # RETICLE_TELEMETRY is read by Reticle's installer; DO_NOT_TRACK is honored per Reticle's README.
    # Unverified: OUROBOROS_TELEMETRY name (taken from a third-party review of its TELEMETRY.md).
    $env:DO_NOT_TRACK = '1'; $env:RETICLE_TELEMETRY = '0'; $env:OUROBOROS_TELEMETRY = '0'
    Backup-Config
}
$before = if ($Apply) { Get-Snapshot } else { @() }

foreach ($t in $Tool) {
    switch ($t) {
        'reticle' { if ($Uninstall) { Uninstall-Reticle } else { Install-Reticle } }
        'ouroboros' { if ($Uninstall) { Uninstall-Ouroboros } else { Install-Ouroboros } }
    }
}

if ($Apply) {
    $after = Get-Snapshot
    Info 'changed files under ~/.claude, ~/.reticle, ~/.ouroboros, ~/.codex and agent MCP configs (<= before, => after):'
    Compare-Object $before $after -Property Path, Length, LastWriteTimeUtc |
        Sort-Object Path | Format-Table -AutoSize | Out-String | Write-Host
    Info 'Restart Claude Code so it loads the new MCP tools.'
}
