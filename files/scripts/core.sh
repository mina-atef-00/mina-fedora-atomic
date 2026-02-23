#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log_init

start_phase "Package Installation"

section "STAGE 3: Core Desktop + Filesystems + Networking"

# Note: RPM Fusion already enabled in akmods stage for NVIDIA support

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

end_phase
