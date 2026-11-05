# install.ps1 — install the "always answer in Russian" rule for every tool.
# Usage:
#   .\install.ps1                              global install (skills + instruction files)
#   .\install.ps1 -Force                       overwrite existing files
#   .\install.ps1 -ListOnly                    show what would be installed
#   .\install.ps1 -ProjectDir "C:\path\to\p"   also install project-level rules (Cursor, Windsurf, Cline)
param(
    [switch]$Force,
    [switch]$ListOnly,
    [string]$ProjectDir = ""
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$homeDir = $HOME

function Install-File($src, $dest, $label) {
    if ($ListOnly) {
        Write-Output ("[dry-run] {0}: {1} -> {2}" -f $label, $src, $dest)
        return
    }
    if ((Test-Path $dest) -and -not $Force) {
        Write-Warning ("skip {0}: {1} already exists (use -Force)" -f $label, $dest)
        return
    }
    $destDir = Split-Path -Parent $dest
    if ($destDir) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Copy-Item $src $dest -Force:$Force
    Write-Output ("installed {0}: {1}" -f $label, $dest)
}

function Install-Dir($srcDir, $destDir, $label) {
    if ($ListOnly) {
        Write-Output ("[dry-run] {0}: {1} -> {2}" -f $label, $srcDir, $destDir)
        return
    }
    if ((Test-Path $destDir) -and -not $Force) {
        Write-Warning ("skip {0}: {1} already exists (use -Force)" -f $label, $destDir)
        return
    }
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Copy-Item "$srcDir\*" $destDir -Recurse -Force:$Force
    Write-Output ("installed {0}: {1}" -f $label, $destDir)
}

# --- Claude Code (global skill) ---
Install-Dir (Join-Path $repo "claude-code\russian") (Join-Path $homeDir ".claude\skills\russian") "Claude Code skill"

# --- OpenCode (global skill + always-on AGENTS.md) ---
Install-Dir (Join-Path $repo "opencode\russian") (Join-Path $homeDir ".config\opencode\skill\russian") "OpenCode skill"
Install-File (Join-Path $repo "opencode\AGENTS.md") (Join-Path $homeDir ".config\opencode\AGENTS.md") "OpenCode AGENTS.md (always-on)"

# --- Codex CLI (global instruction) ---
Install-File (Join-Path $repo "codex\AGENTS.md") (Join-Path $homeDir ".codex\AGENTS.md") "Codex CLI AGENTS.md"

# --- Gemini CLI (global instruction) ---
Install-File (Join-Path $repo "gemini\GEMINI.md") (Join-Path $homeDir ".gemini\GEMINI.md") "Gemini CLI GEMINI.md"

# --- Cline (global Custom Instructions hint) ---
Write-Output "Cline global: paste cline/user-instructions.txt into Cline Settings -> Custom Instructions"

# --- Project-level rules: Cursor / Windsurf / Cline ---
if ($ProjectDir -ne "") {
    if (-not (Test-Path $ProjectDir)) {
        Write-Error "ProjectDir not found: $ProjectDir"
    }
    Install-File (Join-Path $repo "cursor\.cursor\rules\russian.mdc") (Join-Path $ProjectDir ".cursor\rules\russian.mdc") "Cursor rule"
    Install-File (Join-Path $repo "windsurf\.windsurf\rules\russian.md") (Join-Path $ProjectDir ".windsurf\rules\russian.md") "Windsurf rule"
    Install-File (Join-Path $repo "cline\.clinerules\russian.md") (Join-Path $ProjectDir ".clinerules\russian.md") "Cline rule"
} else {
    Write-Output "Project-level rules (Cursor, Windsurf, Cline): re-run with -ProjectDir 'C:\path\to\project'"
}

if ($ListOnly) { Write-Output "dry run — nothing was written (remove -ListOnly to install)" }
