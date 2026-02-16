#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log "INFO" "CLI Tools and GUI Utilities..."

# Enable COPR repositories needed for this layer
log "INFO" "Enabling COPR repositories..."
dnf5 -y copr enable lihaohong/yazi
dnf5 -y copr enable alternateved/eza
dnf5 -y copr enable atim/starship
dnf5 -y copr enable lilay/topgrade
dnf5 -y copr enable atim/bottom

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
  "ShellCheck"

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

# Store COPR list for later cleanup
COPR_LIST=(
  "avengemedia/dms"
  "dejan/rpms"
  "lihaohong/yazi"
  "alternateved/eza"
  "atim/starship"
  "lilay/topgrade"
  "atim/bottom"
)
printf '%s\n' "${COPR_LIST[@]}" > /tmp/copr-list.txt

log "INFO" "CLI Tools & GUI Utilities: Complete"
