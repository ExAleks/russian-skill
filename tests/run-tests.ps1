# Smoke tests for install.ps1.
# They exist to catch the regressions that actually bit users:
#   - a wrong destination path (e.g. "skill" instead of "skills")
#   - an existing AGENTS.md being replaced instead of extended
#   - the rule block being duplicated on re-run
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$installer = Join-Path $repo "install.ps1"
$marker = "<!-- russian-skill:begin -->"
$fail = 0
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("russian-skill-test-" + [guid]::NewGuid().ToString("N"))

function Ok($message) { Write-Host "ok: $message" }
function Bad($message) { Write-Host "FAIL: $message" -ForegroundColor Red; $script:fail = 1 }

function Check-File($label, $path) {
    if (Test-Path $path) { Ok $label } else { Bad "$label ($path missing)" }
}

function Check-Contains($label, $needle, $path) {
    if ((Test-Path $path) -and [System.IO.File]::ReadAllText($path).Contains($needle)) {
        Ok $label
    } else {
        Bad "$label (`"$needle`" not found in $path)"
    }
}

function Check-Count($label, $needle, $path, $expected) {
    $count = 0
    if (Test-Path $path) {
        $count = [regex]::Matches([System.IO.File]::ReadAllText($path), [regex]::Escape($needle)).Count
    }
    if ($count -eq $expected) { Ok $label } else { Bad "$label (expected $expected, got $count)" }
}

function Check-Utf8($label, $path) {
    if (-not (Test-Path $path)) { Bad "$label (file missing)"; return }
    $strict = New-Object System.Text.UTF8Encoding($false, $true)
    try {
        [void]$strict.GetString([System.IO.File]::ReadAllBytes($path))
        Ok $label
    } catch {
        Bad "$label (file is not valid UTF-8)"
    }
}

function New-TestHome($name) {
    $testHome = Join-Path $tmp $name
    New-Item -ItemType Directory -Path (Join-Path $testHome ".config\opencode") -Force | Out-Null
    return $testHome
}

function Invoke-Installer($testHome, [string[]]$extra = @()) {
    $global:LASTEXITCODE = 0
    & $installer -HomeDir $testHome @extra *> $null
    if ($LASTEXITCODE -ne 0) { Bad "install.ps1 exited $LASTEXITCODE" }
}

$savedXdg = $env:XDG_CONFIG_HOME
$env:XDG_CONFIG_HOME = $null

try {
    # --- existing AGENTS.md must be extended, not replaced -------------------
    $testHome = New-TestHome "existing"
    $opencode = Join-Path $testHome ".config\opencode"
    $agents = Join-Path $opencode "AGENTS.md"
    Set-Content -Path $agents -Value "# My own rules`n`n- keep me" -Encoding utf8

    Invoke-Installer $testHome
    Check-File "OpenCode skill installed" (Join-Path $opencode "skills\russian\SKILL.md")
    Check-Contains "user content preserved" "keep me" $agents
    Check-Contains "language rule added" "API, deploy, merge, pull request" $agents
    Check-Count "rule block appears once" $marker $agents 1
    Check-Utf8 "AGENTS.md stays valid UTF-8" $agents
    if (Test-Path (Join-Path $opencode "skill")) { Bad "singular 'skill' directory was created" }

    # --- re-running must not duplicate the block ----------------------------
    Invoke-Installer $testHome
    Check-Count "no duplicate block on re-run" $marker $agents 1

    # --- CRLF files are handled too -----------------------------------------
    $testHome = New-TestHome "crlf"
    $opencode = Join-Path $testHome ".config\opencode"
    $agents = Join-Path $opencode "AGENTS.md"
    [System.IO.File]::WriteAllText($agents, "# My own rules`r`n`r`n- keep me`r`n", (New-Object System.Text.UTF8Encoding($false)))
    Invoke-Installer $testHome
    Invoke-Installer $testHome
    Check-Contains "CRLF: user content preserved" "keep me" $agents
    Check-Count "CRLF: no duplicate block" $marker $agents 1

    # --- file without a trailing newline ------------------------------------
    $testHome = New-TestHome "no-eol"
    $opencode = Join-Path $testHome ".config\opencode"
    $agents = Join-Path $opencode "AGENTS.md"
    [System.IO.File]::WriteAllText($agents, "# My own rules`n- keep me", (New-Object System.Text.UTF8Encoding($false)))
    Invoke-Installer $testHome
    Check-Contains "no-EOL: user content preserved" "keep me" $agents
    Check-Count "no-EOL: block appears once" $marker $agents 1

    # --- fresh home: AGENTS.md is created -----------------------------------
    $testHome = New-TestHome "fresh"
    $agents = Join-Path $testHome ".config\opencode\AGENTS.md"
    Invoke-Installer $testHome
    Check-File "fresh: AGENTS.md created" $agents
    Check-Count "fresh: block appears once" $marker $agents 1

    # --- XDG_CONFIG_HOME is respected ---------------------------------------
    $testHome = Join-Path $tmp "xdg"
    New-Item -ItemType Directory -Path $testHome -Force | Out-Null
    $env:XDG_CONFIG_HOME = Join-Path $testHome "cfg"
    Invoke-Installer $testHome
    Check-File "XDG: skill installed under XDG_CONFIG_HOME" (Join-Path $env:XDG_CONFIG_HOME "opencode\skills\russian\SKILL.md")
} finally {
    $env:XDG_CONFIG_HOME = $savedXdg
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

if ($fail -eq 0) {
    Write-Host "all tests passed"
} else {
    Write-Host "tests failed" -ForegroundColor Red
    exit 1
}
