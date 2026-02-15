#!/usr/bin/env bash
set -oue pipefail

SCRIPTS_DIR="/ctx/files/scripts"
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Layer 6: Desktop Environment..."

# Install desktop packages
PKGS=(
  # Core Desktop
  "niri"
  "dms"
  "greetd"
  "dms-greeter"
  "qt5ct"
  "qt6ct"
  "power-profiles-daemon"
  "cava"
  "adw-gtk3-theme"
  "papirus-icon-theme"
  "breeze-cursor-theme"
  "xwayland-satellite"
  "xdg-desktop-portal-gnome"
  "xdg-terminal-exec"
  "xdg-user-dirs"

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

  # Editors & Git
  "neovim"
  "git"
  "gh"

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

  # Multimedia & Codecs
  "playerctl"
  "webp-pixbuf-loader"
  "alsa-tools"
  "gammastep"
  "accountsservice"
  "pavucontrol"
  "audispd-plugins"
  "gum"
  "uxplay"

  # Networking
  "vpnc"
  "openssh-askpass"
  "openconnect"
  "bluez-tools"
  "firewall-config"

  # Filesystems/Backends
  "gnome-keyring"
  "gnome-keyring-pam"
  "gvfs"
  "gvfs-fuse"
  "gvfs-gphoto2"
  "gvfs-goa"
  "gvfs-mtp"
  "gvfs-smb"
  "seatd"
  "cabextract"
  "fontconfig"
  "xorg-x11-font-utils"
  "nautilus-python"
  "greetd-selinux"
  "p7zip"
  "p7zip-plugins"
  "unrar"
  "android-tools"
)

dnf5 install -y "${PKGS[@]}"

# Set default shell to Fish
if [ -f /etc/default/useradd ]; then
  sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd
fi

log "INFO" "Layer 6: Complete"
