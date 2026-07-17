<#
  install-into-project.ps1 — copy the dot-copilot config into a project's .github\.

  Deterministic alternative to the INSTALL.md Copilot prompt. SAFE for a NON-EMPTY
  .github: it never wipes the folder, backs up any conflicting file to
  <name>.bak.<timestamp> before overwriting, and merges directories file-by-file.
  It will NOT overwrite an existing copilot-instructions.md — it drops the kit's copy
  alongside as copilot-instructions.base.md for you to merge (Copilot reads only
  copilot-instructions.md).

  Run from the extracted field-kit folder:
    .\install-into-project.ps1 -Project C:\path\to\your\repo
    .\install-into-project.ps1 -Project ..\myrepo -DryRun   # show actions, write nothing

  Windows PowerShell 5.1+. No admin, no symlinks (plain copies).
#>
param(
  [Parameter(Mandatory = $true)][string]$Project,
  [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

$KitCopilot = Join-Path $PSScriptRoot 'copilot'
if (-not (Test-Path $KitCopilot)) {
  Write-Error "copilot\ not found — run this from the extracted field-kit folder."
  exit 1
}
if (-not (Test-Path $Project)) { Write-Error "project path not found: $Project"; exit 1 }

$ProjectFull = (Resolve-Path $Project).Path
$GitHub      = Join-Path $ProjectFull '.github'
$Stamp       = Get-Date -Format 'yyyyMMdd-HHmmss'
$backups     = @()
$mergeNote   = $null

Write-Host "Installing dot-copilot config -> $GitHub" -ForegroundColor Cyan
if ($DryRun) { Write-Host "(dry run — nothing will be written)" -ForegroundColor Yellow }
if (-not (Test-Path $GitHub)) {
  if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $GitHub | Out-Null }
  Write-Host "  created .github\"
}

function Install-File($src, $dst) {
  if (Test-Path $dst) {
    $same = (Get-FileHash $src).Hash -eq (Get-FileHash $dst).Hash
    if ($same) { Write-Host "  = $(Split-Path $dst -Leaf) (identical, skipped)"; return }
    $bak = "$dst.bak.$Stamp"
    if (-not $DryRun) { Move-Item $dst $bak -Force }
    $script:backups += $bak
    Write-Host "  ~ backed up $(Split-Path $dst -Leaf) -> $(Split-Path $bak -Leaf)" -ForegroundColor Yellow
  }
  if (-not $DryRun) {
    New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
    Copy-Item $src $dst -Force
  }
  Write-Host "  + $(Split-Path $dst -Leaf)"
}

# 1. copilot-instructions.md — never clobber a project's own global brief
$ciSrc = Join-Path $KitCopilot 'copilot-instructions.md'
$ciDst = Join-Path $GitHub 'copilot-instructions.md'
if (Test-Path $ciDst) {
  $baseDst = Join-Path $GitHub 'copilot-instructions.base.md'
  if (-not $DryRun) { Copy-Item $ciSrc $baseDst -Force }
  $mergeNote = "This project already had copilot-instructions.md — kept it untouched. " +
               "The kit's version is saved as copilot-instructions.base.md. Copilot reads " +
               "ONLY copilot-instructions.md, so merge in the rules you want, then delete the .base copy."
  Write-Host "  ! kept existing copilot-instructions.md; kit copy -> copilot-instructions.base.md" -ForegroundColor Yellow
} else {
  Install-File $ciSrc $ciDst
}

# 2. instructions\, prompts\, hooks\ — merge file-by-file, back up real conflicts
foreach ($d in 'instructions', 'prompts', 'hooks') {
  $srcDir = Join-Path $KitCopilot $d
  if (-not (Test-Path $srcDir)) { continue }
  Write-Host "$d\"
  Get-ChildItem -Recurse -File $srcDir | ForEach-Object {
    $rel = $_.FullName.Substring($srcDir.Length).TrimStart('\', '/')
    Install-File $_.FullName (Join-Path (Join-Path $GitHub $d) $rel)
  }
}

# 3. summary
Write-Host ""
Write-Host "Done." -ForegroundColor Green
if ($backups.Count) {
  Write-Host "Backed up $($backups.Count) conflicting file(s) — review and reconcile:" -ForegroundColor Yellow
  $backups | ForEach-Object { Write-Host "  $_" }
}
if ($mergeNote) { Write-Host ""; Write-Host $mergeNote -ForegroundColor Yellow }
Write-Host ""
Write-Host "Reload VS Code, then type /lets-go in Copilot Chat to confirm the commands loaded."
