#!/usr/bin/env bash
set -oue pipefail

SCRIPTS_DIR="/ctx/files/scripts"
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Layer 3: Core Desktop, Filesystems, and Networking..."

# Enable RPM Fusion (required for multimedia packages)
log "INFO" "Enabling RPM Fusion repositories..."
dnf5 install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
dnf5 install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Enable COPR repositories needed for this layer
log "INFO" "Enabling COPR repositories..."
dnf5 -y copr enable avengemedia/dms

PKGS=(
  # Core Desktop (includes dms, dms-greeter from COPR)
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

log "INFO" "Layer 3: Complete"
