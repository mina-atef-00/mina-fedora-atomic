#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log_init

start_phase "Theming & Fonts"

section "STAGE 5: CLI Tools + GUI Utilities"

# Enable COPR repositories needed for this layer
log "INFO" "Enabling COPR repositories..."
copr_enable_quiet lihaohong/yazi
copr_enable_quiet alternateved/eza
copr_enable_quiet atim/starship
copr_enable_quiet lilay/topgrade
copr_enable_quiet atim/bottom

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
  "xset"
  "podman-compose"

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

dnf_install_quiet "${PKGS[@]}"

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

end_phase
