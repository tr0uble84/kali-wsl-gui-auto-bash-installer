#!/usr/bin/env bash
#
# Kali Linux GUI Setup for WSL2
# Run this script INSIDE Kali Linux (wsl -d kali-linux)
# Supports interactive prompts and non-interactive mode via environment variables.
#
# Copyright (c) 2025 Jay Behi. All rights reserved.
# Author: Jay Behi
#

set -e

# --- Configuration (override with env vars for non-interactive use) ---
# DESKTOP: 1=Full XFCE (kali-desktop-xfce), 2=GNOME, 3=Minimal XFCE
# INSTALL_KEX: y/n
# KALI_TOOLS: none | large | everything
DESKTOP="${DESKTOP:-}"
INSTALL_KEX="${INSTALL_KEX:-}"
KALI_TOOLS="${KALI_TOOLS:-none}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Check we're on Kali ---
if ! grep -qi kali /etc/os-release 2>/dev/null; then
  err "This script is intended for Kali Linux. Detected OS: $(cat /etc/os-release 2>/dev/null | head -1)"
  exit 1
fi

# --- Interactive: Desktop choice ---
choose_desktop() {
  if [[ -n "$DESKTOP" ]]; then
    return
  fi
  echo ""
  echo "Select desktop environment:"
  echo "  1) Full Kali Desktop (XFCE) - Recommended"
  echo "  2) GNOME Desktop"
  echo "  3) Minimal XFCE (xfce4 + xfce4-goodies)"
  echo ""
  read -rp "Choice [1]: " DESKTOP
  DESKTOP="${DESKTOP:-1}"
  if [[ "$DESKTOP" != "1" && "$DESKTOP" != "2" && "$DESKTOP" != "3" ]]; then
    warn "Invalid choice; using 1 (Full Kali XFCE)."
    DESKTOP=1
  fi
}

# --- Interactive: KEX ---
choose_kex() {
  if [[ -n "$INSTALL_KEX" ]]; then
    return
  fi
  echo ""
  read -rp "Install/use Kali Win-KEX for GUI in Windows? [Y/n]: " INSTALL_KEX
  INSTALL_KEX="${INSTALL_KEX:-y}"
  INSTALL_KEX="${INSTALL_KEX,,}"
}

# --- Interactive: Kali tools ---
choose_tools() {
  if [[ -n "$KALI_TOOLS" && "$KALI_TOOLS" != "choose" ]]; then
    return
  fi
  if [[ "$KALI_TOOLS" == "choose" ]]; then
    KALI_TOOLS=""
  fi
  echo ""
  echo "Install additional Kali tool metapackages?"
  echo "  1) None (faster)"
  echo "  2) kali-linux-large (common tools)"
  echo "  3) kali-linux-everything (full suite)"
  echo ""
  read -rp "Choice [1]: " tool_choice
  tool_choice="${tool_choice:-1}"
  case "$tool_choice" in
    2) KALI_TOOLS=large ;;
    3) KALI_TOOLS=everything ;;
    *) KALI_TOOLS=none ;;
  esac
}

# --- Run if interactive (no DESKTOP set and stdin is a TTY) ---
if [[ -z "$DESKTOP" && -t 0 ]]; then
  choose_desktop
  choose_kex
  choose_tools
fi

# Defaults for non-interactive
DESKTOP="${DESKTOP:-1}"
INSTALL_KEX="${INSTALL_KEX:-y}"
KALI_TOOLS="${KALI_TOOLS:-none}"

# --- Summary ---
echo ""
info "Configuration:"
echo "  Desktop: $DESKTOP (1=Full XFCE, 2=GNOME, 3=Minimal XFCE)"
echo "  Install KEX: $INSTALL_KEX"
echo "  Kali tools: $KALI_TOOLS"
echo ""
if [[ -t 0 ]]; then
  read -t 10 -rp "Press Enter to continue (or wait 10s)..." _ || true
fi
echo ""

# --- 1. Update system ---
info "Updating system..."
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y -qq
ok "System updated."

# --- 2. Install desktop ---
info "Installing desktop environment..."
case "$DESKTOP" in
  1)
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq kali-desktop-xfce
    ;;
  2)
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq kali-desktop-gnome
    ;;
  3)
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq xfce4 xfce4-goodies
    ;;
  *)
    err "Invalid DESKTOP value: $DESKTOP"
    exit 1
    ;;
esac
ok "Desktop installed."

# --- 3. KEX ---
if [[ "$INSTALL_KEX" == "y" || "$INSTALL_KEX" == "yes" ]]; then
  info "Installing kali-win-kex (for GUI in Windows)..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq kali-win-kex 2>/dev/null || true
  ok "KEX ready. Start GUI with: kex --win -s"
fi

# --- 4. Optional Kali tools ---
if [[ "$KALI_TOOLS" == "large" ]]; then
  info "Installing kali-linux-large..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq kali-linux-large
  ok "kali-linux-large installed."
elif [[ "$KALI_TOOLS" == "everything" ]]; then
  warn "kali-linux-everything is large and may take a long time."
  read -rp "Continue? [y/N]: " confirm
  if [[ "${confirm,,}" == "y" || "${confirm,,}" == "yes" ]]; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y kali-linux-everything
    ok "kali-linux-everything installed."
  fi
fi

# --- Done ---
echo ""
ok "Kali GUI setup complete."
echo ""
if [[ "$INSTALL_KEX" == "y" || "$INSTALL_KEX" == "yes" ]]; then
  echo "To start the Kali desktop from Windows (PowerShell or Run):"
  echo "  wsl -d kali-linux kex --win -s"
  echo ""
  echo "Or from inside this terminal:"
  echo "  kex --win -s"
  echo ""
fi
echo "If GUI does not start, try: wsl --update (in PowerShell as Admin)"
echo "Black screen fix: kex --win --stop && kex --win -s"
echo ""
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║              Follow me on GitHub                          ║"
echo "  ║                                                          ║"
echo "  ║     Jay Behi (tr0uble84)                                 ║"
echo "  ║     https://github.com/tr0uble84/                        ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo ""
