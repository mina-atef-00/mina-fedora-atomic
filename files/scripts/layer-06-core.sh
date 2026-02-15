#!/usr/bin/env bash
set -oue pipefail

SCRIPTS_DIR="/ctx/files/scripts"
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Layer 6: Core Desktop, Filesystems, and Networking..."

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

  # Networking
  "vpnc"
  "openssh-askpass"
  "openconnect"
  "bluez-tools"
  "firewall-config"
)

dnf5 install -y "${PKGS[@]}"

log "INFO" "Layer 6: Complete"
