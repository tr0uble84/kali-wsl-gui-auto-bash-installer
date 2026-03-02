#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Enables WSL2 and installs Kali Linux on Windows 11, with optional GUI setup.

.DESCRIPTION
  Runs Windows-side steps: enable WSL, set WSL2 default, install Kali.
  Optionally runs the Kali GUI setup script inside WSL (install-kali-gui.sh).

.EXAMPLE
  .\install-wsl-kali.ps1
  .\install-wsl-kali.ps1 -SkipWslInstall -SkipKaliInstall -RunGuiSetupOnly
  .\install-wsl-kali.ps1 -GuiScriptPath "C:\path\to\install-kali-gui.sh"

.COPYRIGHT
  Copyright (c) 2025 Jay Behi. All rights reserved.
  Author: Jay Behi
#>

param(
    [switch]$SkipWslInstall,      # Skip wsl --install (already done)
    [switch]$SkipKaliInstall,     # Skip installing Kali (already installed)
    [switch]$RunGuiSetupOnly,     # Only run the bash GUI script inside Kali
    [string]$GuiScriptPath = "",  # Path to install-kali-gui.sh (default: same dir as this script)
    [switch]$NonInteractive       # Do not prompt; use defaults where applicable
)

$ErrorActionPreference = "Stop"
$distroName = "kali-linux"

function Write-Info  { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Ok    { Write-Host "[OK] $args" -ForegroundColor Green }
function Write-Warn  { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Err   { Write-Host "[ERROR] $args" -ForegroundColor Red }

# Resolve path to bash script (same directory as this script)
if ([string]::IsNullOrWhiteSpace($GuiScriptPath)) {
    $GuiScriptPath = Join-Path $PSScriptRoot "install-kali-gui.sh"
}

# Convert Windows path to WSL path for use inside Kali
function Get-WslPath {
    param([string]$WinPath)
    $p = (wsl -d $distroName wslpath -a $WinPath 2>$null)
    if ($p) { $p.Trim() } else { $WinPath -replace '\\', '/' -replace '^([A-Za-z]):', '/mnt/$1' -replace '^([A-Za-z])', '/mnt/$1' }
}

# --- Step 0: Run GUI setup only (already have WSL + Kali) ---
if ($RunGuiSetupOnly) {
    $kaliExists = wsl -l -q 2>$null | Where-Object { $_ -eq $distroName }
    if (-not $kaliExists) {
        Write-Err "Kali Linux is not installed in WSL (no distribution named '$distroName')."
        Write-Host ""
        Write-Host "Install Kali first, then run GUI setup again. Options:" -ForegroundColor Yellow
        Write-Host "  1. Run this script WITHOUT -RunGuiSetupOnly to install WSL + Kali:" -ForegroundColor Yellow
        Write-Host "     powershell -ExecutionPolicy Bypass -File .\install-wsl-kali.ps1" -ForegroundColor Cyan
        Write-Host "  2. Or install Kali manually: wsl --install -d kali-linux" -ForegroundColor Cyan
        Write-Host "     Then complete first-time setup (username/password) and run this again with -RunGuiSetupOnly." -ForegroundColor Yellow
        exit 1
    }
    if (-not (Test-Path $GuiScriptPath)) {
        $guiUrl = "https://raw.githubusercontent.com/tr0uble84/kali-wsl-gui-auto-bash-installer/main/install-kali-gui.sh"
        Write-Info "GUI script not found. Downloading from repo..."
        try {
            Invoke-WebRequest -Uri $guiUrl -OutFile $GuiScriptPath -UseBasicParsing
            Write-Ok "Downloaded install-kali-gui.sh to $GuiScriptPath"
        } catch {
            Write-Err "GUI script not found and download failed: $GuiScriptPath"
            Write-Host "Download manually: $guiUrl" -ForegroundColor Yellow
            exit 1
        }
    }
    $wslPath = Get-WslPath $GuiScriptPath
    Write-Info "Running Kali GUI setup inside WSL: $GuiScriptPath"
    wsl -d $distroName bash -c "sudo bash '$wslPath'"
    Write-Ok "Done. Start GUI with: wsl -d $distroName kex --win -s"
    exit 0
}

# --- Step 1: Install WSL (if not skipped) ---
if (-not $SkipWslInstall) {
    Write-Info "Installing WSL (wsl --install)..."
    wsl --install
    Write-Warn "If the system prompted for a reboot, please restart and run this script again."
    if (-not $NonInteractive) {
        $reboot = Read-Host "Did the command ask you to reboot? Reboot now? (y/N)"
        if ($reboot -match '^[yY]') { shutdown /r /t 0 }
    }
    exit 0
}

# --- Step 2: Set WSL2 as default ---
Write-Info "Setting WSL default version to 2..."
wsl --set-default-version 2 2>$null
Write-Ok "WSL2 set as default."

# --- Step 3: Install Kali (if not skipped) ---
if (-not $SkipKaliInstall) {
    $exists = wsl -l -q 2>$null | Where-Object { $_ -eq $distroName }
    if (-not $exists) {
        Write-Info "Installing Kali Linux (wsl --install -d kali-linux)..."
        wsl --install -d $distroName
        Write-Info "Complete the Kali first-time setup (username/password) when the window opens."
        if (-not $NonInteractive) {
            Read-Host "Press Enter after you have created your Kali user"
        }
    } else {
        Write-Ok "Kali Linux is already installed."
    }
}

# --- Step 4: Ensure Kali is WSL2 ---
$list = wsl -l -v 2>$null
if ($list -notmatch "kali-linux\s+(\S+)\s+2") {
    Write-Info "Setting Kali Linux to WSL2..."
    wsl --set-version $distroName 2
}

# --- Step 5: Optional .wslconfig ---
$wslconfig = Join-Path $env:USERPROFILE ".wslconfig"
if (-not (Test-Path $wslconfig) -and -not $NonInteractive) {
    $create = Read-Host "Create .wslconfig for resource allocation (e.g. memory=8GB)? (y/N)"
    if ($create -match '^[yY]') {
        @"
[wsl2]
memory=8GB
processors=4
swap=4GB
"@ | Set-Content -Path $wslconfig -Encoding UTF8
        Write-Ok "Created $wslconfig. Run 'wsl --shutdown' and restart WSL for it to take effect."
    }
}

# --- Step 6: Run Kali GUI setup script ---
if (Test-Path $GuiScriptPath) {
    $wslScriptPath = Get-WslPath $GuiScriptPath
    if ($NonInteractive) {
        Write-Info "Running Kali GUI setup (non-interactive)..."
        wsl -d $distroName bash -c "DESKTOP=1 INSTALL_KEX=y KALI_TOOLS=none sudo bash '$wslScriptPath'"
    } else {
        $run = Read-Host "Run Kali GUI setup script now? (Y/n)"
        if ($run -notmatch '^[nN]') {
            wsl -d $distroName bash -c "sudo bash '$wslScriptPath'"
        }
    }
    Write-Ok "To start Kali desktop later: wsl -d $distroName kex --win -s"
} else {
    Write-Warn "GUI script not found: $GuiScriptPath"
    Write-Info "Copy install-kali-gui.sh to this folder, then run inside Kali: sudo bash install-kali-gui.sh"
}

Write-Ok "Setup complete."
