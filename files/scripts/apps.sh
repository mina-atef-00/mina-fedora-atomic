#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log_init

start_phase "Theming & Fonts"

section "STAGE 5: CLI Tools + GUI Utilities"

# Enable COPR repositories needed for this layer
log "INFO" "Enabling COPR repositories..."
COPRS=(
  "lihaohong/yazi"
  "alternateved/eza"
  "atim/starship"
  "lilay/topgrade"
  "atim/bottom"
)

for repo in "${COPRS[@]}"; do
  copr_enable_quiet "$repo"
done

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
  "wtype"
  "ShellCheck"
  "xset"
  "podman-compose"
  "yt-dlp"

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
  "baobab"
  "chromium"
  "seahorse"
  "loupe"
  "mpv"
  "transmission"
  "@virtualization"
)

dnf_install_quiet "${PKGS[@]}"

# Set default shell to Fish
if [ -f /etc/default/useradd ]; then
  sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd
fi

# Store COPR list for later cleanup
printf '%s\n' "${COPRS[@]}" >/tmp/copr-list.txt

log "INFO" "CLI Tools & GUI Utilities: Complete"

end_phase
