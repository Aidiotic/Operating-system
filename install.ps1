# NexusOS Windows Installer
# Run in PowerShell (Admin recommended for WSL2):
#   irm https://raw.githubusercontent.com/Aidiotic/Operating-system/main/install.ps1 | iex
# Or from a cloned repo:
#   .\install.ps1

param(
    [switch]$Wsl,
    [switch]$Iso,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$Repo = if ($env:NEXUSOS_REPO) { $env:NEXUSOS_REPO } else { "Aidiotic/Operating-system" }

function Show-Help {
    Write-Host @"
NexusOS Windows Installer

  .\install.ps1           Install NexusOS into WSL2
  .\install.ps1 -Wsl      Same as default
  .\install.ps1 -Iso      Show dual-boot ISO instructions
  .\install.ps1 -Help     Show this help

Requires: Windows 10 21H2+ or Windows 11 with WSL2
"@
}

if ($Help) { Show-Help; exit 0 }

if ($Iso) {
    if (Get-Command bash -ErrorAction SilentlyContinue) {
        bash ./install.sh --iso
    } else {
        Write-Host "Download ISO from: https://github.com/$Repo/releases"
    }
    exit 0
}

# Ensure WSL is available
if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    Write-Error "WSL not found. Run: wsl --install"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installSh = Join-Path $scriptDir "install.sh"

if (-not (Test-Path $installSh)) {
    Write-Host "Cloning NexusOS..."
    $tmp = Join-Path $env:TEMP "nexusos-install"
    git clone --depth 1 "https://github.com/$Repo.git" $tmp
    $installSh = Join-Path $tmp "install.sh"
}

Write-Host "Installing NexusOS via WSL2..."
bash $installSh --wsl @args

Write-Host ""
Write-Host "Done! Launch with: wsl -d NexusOS"
