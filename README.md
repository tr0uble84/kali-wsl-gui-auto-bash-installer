# Kali Linux (Full GUI) on Windows 11 via WSL2

**Copyright (c) 2025 Jay Behi. All rights reserved.**  
**Author: Jay Behi**

Automated setup using a **PowerShell** script (Windows) and a **Bash** script (Kali) with input options.

---

## Auto-download and run as Administrator

Download the latest `install-wsl-kali.ps1` into `Documents\Install-Kali` and launch it in an **elevated (Administrator)** window. A UAC prompt will appear to allow Administrator access.

**PowerShell (run in PowerShell):**

```powershell
$dir = "$env:USERPROFILE\Documents\Install-Kali"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/tr0uble84/kali-wsl-gui-auto-bash-installer/main/install-wsl-kali.ps1" -OutFile "$dir\install-wsl-kali.ps1" -UseBasicParsing
Write-Host "Downloaded. Launching as Administrator..."
Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$dir\install-wsl-kali.ps1`""
```

**Command Prompt (cmd):**

```cmd
if not exist "%USERPROFILE%\Documents\Install-Kali" mkdir "%USERPROFILE%\Documents\Install-Kali"
curl -L -o "%USERPROFILE%\Documents\Install-Kali\install-wsl-kali.ps1" https://raw.githubusercontent.com/tr0uble84/kali-wsl-gui-auto-bash-installer/main/install-wsl-kali.ps1
echo Launching as Administrator...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoExit -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\Documents\Install-Kali\install-wsl-kali.ps1\"'"
```

Approve the UAC prompt; the installer will run in the new Administrator window. The window stays open when the script finishes so you can read the output (or any errors).

---

## Quick start

### Option 1: Full automated (PowerShell as Administrator)

1. Open **PowerShell as Administrator**.
2. Navigate to the folder containing the scripts:
   **PowerShell:**
   ```powershell
   cd "$env:USERPROFILE\Documents\Install-Kali"
   ```
   **Command Prompt (cmd):**
   ```cmd
   cd "%USERPROFILE%\Documents\Install-Kali"
   ```
   If you cloned the repo elsewhere, use that path instead.
3. Run (use `-ExecutionPolicy Bypass` if you get "running scripts is disabled"):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install-wsl-kali.ps1
   ```
   Or: `.\install-wsl-kali.ps1` (if your execution policy already allows scripts).
4. If prompted, **reboot** after `wsl --install`, then run the script again (use `-SkipWslInstall` if WSL is already installed).

### Option 2: Kali already installed — only GUI setup

From **PowerShell as Administrator** (with `install-kali-gui.sh` in this folder):

```powershell
powershell -ExecutionPolicy Bypass -File .\install-wsl-kali.ps1 -RunGuiSetupOnly
```
(If you get "scripts is disabled", the above bypasses it. Otherwise you can use `.\install-wsl-kali.ps1 -RunGuiSetupOnly`.)

Or inside Kali:

```bash
wsl -d kali-linux
# then copy or access the script and run:
sudo bash install-kali-gui.sh
```

---

## Bash script: `install-kali-gui.sh` (run inside Kali)

**Input options (interactive):**

- **Desktop:** 1 = Full Kali XFCE (recommended), 2 = GNOME, 3 = Minimal XFCE  
- **KEX:** Install/use Kali Win-KEX for GUI in a Windows window (Y/n)  
- **Kali tools:** None / kali-linux-large / kali-linux-everything  

**Non-interactive (env vars):**

```bash
# Defaults: Full XFCE, KEX yes, no extra tools
sudo DESKTOP=1 INSTALL_KEX=y KALI_TOOLS=none bash install-kali-gui.sh

# GNOME + KEX + large toolset
sudo DESKTOP=2 INSTALL_KEX=y KALI_TOOLS=large bash install-kali-gui.sh
```

| Variable     | Values                          |
|-------------|----------------------------------|
| `DESKTOP`   | `1` (full XFCE), `2` (GNOME), `3` (minimal XFCE) |
| `INSTALL_KEX` | `y` / `n`                    |
| `KALI_TOOLS`  | `none`, `large`, `everything` |

---

## PowerShell script: `install-wsl-kali.ps1`

**Parameters:**

| Parameter           | Description |
|--------------------|-------------|
| `-SkipWslInstall`  | Skip `wsl --install` (WSL already installed) |
| `-SkipKaliInstall` | Skip installing Kali (already installed) |
| `-RunGuiSetupOnly` | Only run `install-kali-gui.sh` inside Kali |
| `-GuiScriptPath`   | Path to `install-kali-gui.sh` (default: same folder) |
| `-NonInteractive` | No prompts; use defaults and run GUI setup with defaults |

**Examples:**

```powershell
# First time: install WSL + Kali (reboot when asked, then run again with -SkipWslInstall)
.\install-wsl-kali.ps1

# WSL already installed, install Kali and run GUI setup
.\install-wsl-kali.ps1 -SkipWslInstall

# Kali already installed, only run GUI setup
.\install-wsl-kali.ps1 -RunGuiSetupOnly

# Fully non-interactive (after WSL + Kali exist)
.\install-wsl-kali.ps1 -SkipWslInstall -SkipKaliInstall -NonInteractive
```

---

## After setup: start Kali GUI

From PowerShell or Run dialog:

```text
wsl -d kali-linux kex --win -s
```

Optional: create a shortcut with that as the target.

---

## Optional: `.wslconfig` (resources)

The script can create `C:\Users\YOURNAME\.wslconfig` with:

```ini
[wsl2]
memory=8GB
processors=4
swap=4GB
```

Then run `wsl --shutdown` and reopen WSL for it to take effect.

---

## Troubleshooting

- **"Running scripts is disabled" / execution policy:** Run with bypass:  
  `powershell -ExecutionPolicy Bypass -File .\install-wsl-kali.ps1`  
  (Add `-RunGuiSetupOnly` or other parameters as needed.)
- **`$'\r': command not found` / `invalid option` in bash:** The script had Windows (CRLF) line endings. The repo uses `.gitattributes` so `install-kali-gui.sh` is stored with LF; re-download or pull the latest. To fix a local copy in WSL: `sed -i 's/\r$//' install-kali-gui.sh`
- **GUI not launching:** In PowerShell (Admin): `wsl --update`
- **Black screen:** In Kali: `kex --win --stop` then `kex --win -s`
- **Check WSL version:** `wsl -l -v` — Kali should show version **2**

