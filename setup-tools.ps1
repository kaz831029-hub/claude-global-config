# setup-tools.ps1 - install or remove global tools (Reticle, Ouroboros) for Claude Code on Windows.
# Default is a dry-run: nothing is installed or changed. Add -Apply to run for real.
# Chisle is intentionally not included (README, "Global tools").
#
#   .\setup-tools.ps1 -Tool reticle,ouroboros              # dry-run: checks + planned commands
#   .\setup-tools.ps1 -Tool reticle,ouroboros -Apply       # install
#   .\setup-tools.ps1 -Tool reticle,ouroboros -Uninstall -Apply
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('reticle', 'ouroboros')][string[]]$Tool,
    [switch]$Apply,
    [switch]$Uninstall,
    # Assumption: 'claude' is the right backend for Claude Code (installer accepts claude|claude-sdk|claude-cli|...).
    [string]$OuroborosRuntime = 'claude'
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $HOME ".claude-tools-backup\$stamp"
$watchDirs = @("$HOME\.claude", "$HOME\.reticle", "$HOME\.ouroboros")
$watchFiles = @("$HOME\.claude\settings.json", "$HOME\.claude.json", "$HOME\.ouroboros\config.yaml")

function Info($m) { Write-Host "[info] $m" -ForegroundColor Cyan }
function Plan($m) { Write-Host "[plan] $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "[error] $m" -ForegroundColor Red; exit 1 }

function Test-Cmd($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }

function Show-Env {
    Info "OS: $([Environment]::OSVersion.VersionString), PowerShell: $($PSVersionTable.PSVersion)"
    foreach ($c in 'node', 'npm', 'git', 'uv', 'claude', 'winget') {
        if (Test-Cmd $c) { Info "$c found: $((Get-Command $c).Source)" } else { Info "$c NOT found" }
    }
    if (Test-Cmd node) {
        $v = [version]((node --version).TrimStart('v'))
        Info "node $v (Reticle needs 20.11+)"
    }
}

function Get-Snapshot {
    foreach ($d in $watchDirs) {
        if (Test-Path $d) {
            Get-ChildItem $d -Recurse -File -ErrorAction SilentlyContinue |
                Select-Object @{n = 'Path'; e = { $_.FullName } }, Length, LastWriteTimeUtc
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
    Info "backup folder: $backupDir"
}

function Invoke-Step($label, [scriptblock]$Block) {
    if (-not $Apply) { Plan $label; return }
    Info "run: $label"
    & $Block
    if ($LASTEXITCODE -ne 0) { Fail "failed: $label (exit $LASTEXITCODE)" }
}

function Install-Reticle {
    if (-not (Test-Cmd node) -or -not (Test-Cmd npm)) { Fail 'Node.js 20.11+ is required for Reticle (winget install OpenJS.NodeJS.LTS).' }
    Invoke-Step 'npm install -g @reticlehq/server' { npm install -g '@reticlehq/server' }
    Invoke-Step 'reticle setup install   (registers the MCP server with detected agents)' { reticle setup install }
    Invoke-Step 'reticle telemetry disable' { reticle telemetry disable }
    Info 'Not done here on purpose: `reticle init` changes a project (dev dependencies, build config, CLAUDE.md). Run it per project after approval.'
}

function Uninstall-Reticle {
    # Unverified: the README documents no uninstall command; these are the inverse of the install steps.
    Invoke-Step 'claude mcp remove reticle -s user' { claude mcp remove reticle -s user }
    Invoke-Step 'npm uninstall -g @reticlehq/server' { npm uninstall -g '@reticlehq/server' }
    Info 'Per-project leftovers from `reticle init` must be reverted in that project (git diff). State folder: ~/.reticle'
}

function Install-Ouroboros {
    $url = 'https://raw.githubusercontent.com/Q00/ouroboros/main/scripts/install.ps1'
    $file = Join-Path $env:TEMP "ouroboros-install-$stamp.ps1"
    Info "downloading installer for review: $url"
    Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing
    Info "saved: $file  SHA256: $((Get-FileHash $file -Algorithm SHA256).Hash)"
    Info 'Review the file before -Apply. It may install Git and uv through winget, then run `uv tool install ouroboros-ai`.'
    Invoke-Step "powershell -File $file -Runtime $OuroborosRuntime" {
        powershell -NoProfile -ExecutionPolicy Bypass -File $file -Runtime $OuroborosRuntime
    }
    Info 'Telemetry: read https://github.com/Q00/ouroboros/blob/main/TELEMETRY.md and decide before real use.'
}

function Uninstall-Ouroboros {
    Invoke-Step 'ouroboros uninstall   (removes configuration, MCP registration and data)' { ouroboros uninstall }
}

Show-Env
if (-not $Apply) { Info 'DRY-RUN: nothing will be changed. Add -Apply to run.' }
if ($Apply) { Backup-Config }
$before = if ($Apply) { Get-Snapshot } else { @() }

foreach ($t in $Tool) {
    switch ($t) {
        'reticle' { if ($Uninstall) { Uninstall-Reticle } else { Install-Reticle } }
        'ouroboros' { if ($Uninstall) { Uninstall-Ouroboros } else { Install-Ouroboros } }
    }
}

if ($Apply) {
    $after = Get-Snapshot
    Info 'changed files under ~/.claude, ~/.reticle, ~/.ouroboros (<= before, => after):'
    Compare-Object $before $after -Property Path, Length, LastWriteTimeUtc |
        Sort-Object Path | Format-Table -AutoSize | Out-String | Write-Host
    Info 'Restart Claude Code so it loads the new MCP tools.'
}
