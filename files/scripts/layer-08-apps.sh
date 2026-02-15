#!/usr/bin/env bash
set -oue pipefail

SCRIPTS_DIR="/ctx/files/scripts"
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Layer 8: CLI Tools and GUI Utilities..."

PKGS=(
  # CLI Tools
  "eza"
  "bat"
  "ripgrep"
  "fd-find"
  "zoxide"
  "inxi"
  "bottom"
  "tealdeer"
  "du-dust"
  "procs"
  "fastfetch"
  "starship"
  "fish"
  "topgrade"
  "yazi"
  "chezmoi"
  "udiskie"
  "evtest"
  "wev"
  "age"
  "wlr-randr"

  # GUI Utilities
  "kitty"
  "nautilus"
  "file-roller"
  "qalculate-gtk"
  "audacity"
  "sox"
  "v4l-utils"
  "qalculate"
  "picard"
  "syncplay"
  "swappy"
  "gnome-disk-utility"
  "chromium"
  "seahorse"
  "loupe"
  "mpv"
)

dnf5 install -y "${PKGS[@]}"

# Set default shell to Fish
if [ -f /etc/default/useradd ]; then
  sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd
fi

log "INFO" "Layer 8: Complete"
