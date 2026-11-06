# install.ps1 - install the "always answer in Russian" rule for every tool.
# Usage:
#   .\install.ps1                              global install (skills + instruction files)
#   .\install.ps1 -Force                       overwrite existing files (a .bak-<timestamp> copy is kept)
#   .\install.ps1 -ListOnly                    show what would be installed
#   .\install.ps1 -ProjectDir "C:\path\to\p"   also install project-level rules (Cursor, Windsurf, Cline)
#   .\install.ps1 -HomeDir "C:\path\to\home"   install into another home directory (used by tests)
param(
    [switch]$Force,
    [switch]$ListOnly,
    [string]$ProjectDir = "",
    [string]$HomeDir = $HOME
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$ruleSource = Join-Path $repo "shared\language-rule.md"
$beginMarker = "<!-- russian-skill:begin -->"
$endMarker = "<!-- russian-skill:end -->"

# OpenCode reads its config from $XDG_CONFIG_HOME/opencode when the variable is set.
$configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HomeDir ".config" }
$opencodeDir = Join-Path $configHome "opencode"

function Write-TextFile($path, $text) {
    $dir = Split-Path -Parent $path
    if ($dir) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($path, $text, $encoding)
}

function Backup-Path($path) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = "$path.bak-$stamp"
    Copy-Item $path $backup -Recurse -Force
    Write-Output ("backup: {0}" -f $backup)
}

function Install-File($src, $dest, $label) {
    if ($ListOnly) {
        Write-Output ("[dry-run] {0}: {1} -> {2}" -f $label, $src, $dest)
        return
    }
    if (Test-Path $dest) {
        if (-not $Force) {
            Write-Warning ("skip {0}: {1} already exists (use -Force)" -f $label, $dest)
            return
        }
        Backup-Path $dest
    }
    $destDir = Split-Path -Parent $dest
    if ($destDir) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Copy-Item $src $dest -Force
    Write-Output ("installed {0}: {1}" -f $label, $dest)
}

function Install-Dir($srcDir, $destDir, $label) {
    if ($ListOnly) {
        Write-Output ("[dry-run] {0}: {1} -> {2}" -f $label, $srcDir, $destDir)
        return
    }
    if (Test-Path $destDir) {
        if (-not $Force) {
            Write-Warning ("skip {0}: {1} already exists (use -Force)" -f $label, $destDir)
            return
        }
        Backup-Path $destDir
    }
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Copy-Item (Join-Path $srcDir "*") $destDir -Recurse -Force
    Write-Output ("installed {0}: {1}" -f $label, $destDir)
}

# Merge the language rule into an existing instruction file instead of replacing it.
# The block is wrapped in markers, so re-running the installer updates it in place
# and never duplicates it. Everything outside the markers is left untouched.
function Install-RuleBlock($dest, $label) {
    if ($ListOnly) {
        Write-Output ("[dry-run] {0} (merged block): {1} -> {2}" -f $label, $ruleSource, $dest)
        return
    }
    if (-not (Test-Path $ruleSource)) {
        throw "missing rule source: $ruleSource"
    }

    $rule = ([System.IO.File]::ReadAllText($ruleSource)).Trim()
    $existing = if (Test-Path $dest) { [System.IO.File]::ReadAllText($dest) } else { $null }

    $newline = if ($existing -and $existing.Contains("`r`n")) { "`r`n" } else { "`n" }
    $normalizedRule = ($rule -replace "`r`n", "`n") -replace "`n", $newline
    $block = $beginMarker + $newline + $normalizedRule + $newline + $endMarker

    if (-not $existing) {
        Write-TextFile $dest ($block + $newline)
        Write-Output ("created {0}: {1}" -f $label, $dest)
        return
    }

    if ($existing.Contains($beginMarker) -and $existing.Contains($endMarker)) {
        $pattern = "(?s)" + [regex]::Escape($beginMarker) + ".*?" + [regex]::Escape($endMarker)
        $updated = [regex]::new($pattern).Replace($existing, { param($m) $block }, 1)
        if ($updated -ne $existing) {
            Write-TextFile $dest $updated
            Write-Output ("updated {0}: {1}" -f $label, $dest)
        } else {
            Write-Output ("unchanged {0}: {1}" -f $label, $dest)
        }
        return
    }

    $separator = if ($existing.EndsWith($newline)) { $newline } else { $newline + $newline }
    Write-TextFile $dest ($existing + $separator + $block + $newline)
    Write-Output ("merged {0}: {1} (existing content preserved)" -f $label, $dest)
}

# --- Claude Code (global skill) ---
Install-Dir (Join-Path $repo "claude-code\russian") (Join-Path $HomeDir ".claude\skills\russian") "Claude Code skill"

# --- OpenCode (global skill + always-on AGENTS.md) ---
Install-Dir (Join-Path $repo "opencode\russian") (Join-Path $opencodeDir "skills\russian") "OpenCode skill"
Install-RuleBlock (Join-Path $opencodeDir "AGENTS.md") "OpenCode AGENTS.md (always-on)"

# --- Codex CLI (global instruction) ---
Install-RuleBlock (Join-Path $HomeDir ".codex\AGENTS.md") "Codex CLI AGENTS.md"

# --- Gemini CLI (global instruction) ---
Install-RuleBlock (Join-Path $HomeDir ".gemini\GEMINI.md") "Gemini CLI GEMINI.md"

# --- Cline (global Custom Instructions hint) ---
Write-Output "Cline global: paste cline/user-instructions.txt into Cline Settings -> Custom Instructions"

# --- Project-level rules: Cursor / Windsurf / Cline ---
if ($ProjectDir -ne "") {
    if (-not (Test-Path $ProjectDir)) {
        throw "ProjectDir not found: $ProjectDir"
    }
    Install-File (Join-Path $repo "cursor\.cursor\rules\russian.mdc") (Join-Path $ProjectDir ".cursor\rules\russian.mdc") "Cursor rule"
    Install-File (Join-Path $repo "windsurf\.windsurf\rules\russian.md") (Join-Path $ProjectDir ".windsurf\rules\russian.md") "Windsurf rule"
    Install-File (Join-Path $repo "cline\.clinerules\russian.md") (Join-Path $ProjectDir ".clinerules\russian.md") "Cline rule"
} else {
    Write-Output "Project-level rules (Cursor, Windsurf, Cline): re-run with -ProjectDir 'C:\path\to\project'"
}

if ($ListOnly) {
    Write-Output "dry run - nothing was written (remove -ListOnly to install)"
    return
}

# --- Verification: catch a wrong destination path instead of silently "succeeding" ---
$failed = $false
$skillFile = Join-Path $opencodeDir "skills\russian\SKILL.md"
if (Test-Path $skillFile) {
    Write-Output "verify: OpenCode skill -> $skillFile"
} else {
    Write-Warning "verify: OpenCode skill is missing at $skillFile"
    $failed = $true
}
$agentsFile = Join-Path $opencodeDir "AGENTS.md"
if ((Test-Path $agentsFile) -and ([System.IO.File]::ReadAllText($agentsFile).Contains($beginMarker))) {
    Write-Output "verify: OpenCode AGENTS.md -> $agentsFile"
} else {
    Write-Warning "verify: language rule is missing in $agentsFile"
    $failed = $true
}
if ($failed) { exit 1 }
