#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

section "STAGE 3: Core Desktop + Filesystems + Networking"

# Enable RPM Fusion (required for multimedia packages)
log "INFO" "Enabling RPM Fusion repositories..."
if ! rpm -q rpmfusion-free-release &>/dev/null; then
  dnf5 install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" --quiet 2>&1 | tail -5
fi
if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
  dnf5 install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" --quiet 2>&1 | tail -5
fi

# Enable COPR repositories needed for this layer
log "INFO" "Enabling COPR repositories..."
copr_enable_quiet avengemedia/dms
copr_enable_quiet dejan/rpms

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

dnf_install_quiet "${PKGS[@]}"

log "INFO" "Core Desktop: Complete"
