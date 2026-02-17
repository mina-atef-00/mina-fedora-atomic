#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log "INFO" "Finalization..."

# Remove unwanted packages
REMOVE_PKGS=(
  "firefox"
  "firefox-langpacks"
  "toolbox"
  "console-login-helper-messages"
  "gnome-tour"
  "gnome-software"
  "swaylock"
  "waybar"
  "fuzzel"
  "alacritty"
  "nodejs"
  "nodejs-docs"
  "nodejs-full-i18n"
  "rpmfusion-free-release"
  "rpmfusion-nonfree-release"
)

log "INFO" "Removing unwanted packages..."
dnf5 remove -y "${REMOVE_PKGS[@]}" 2>/dev/null || true

# Disable COPRs to keep runtime clean
if [ -f /tmp/copr-list.txt ]; then
  log "INFO" "Disabling COPR repositories..."
  while IFS= read -r copr; do
    dnf5 -y copr disable "$copr" 2>/dev/null || true
  done < /tmp/copr-list.txt
fi

# Setup Flathub
log "INFO" "Adding Flathub repository..."
curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

# Package manager cleanup
log "INFO" "Cleaning DNF artifacts..."
dnf5 clean all
rm -rf /var/lib/dnf
rm -rf /var/cache/dnf
rm -rf /var/cache/libdnf5

# UI debloat - Remove clutter from Application Menu
log "INFO" "Removing clutter from Application Menu..."
REMOVE_DESKTOP_FILES=(
  "byobu"
  "nvim"
  "btop"
  "echomixer"
  "envy24control"
  "hdajackretask"
  "hdspmixer"
  "hdspconf"
  "htop"
  "hwmixvolume"
  "nvtop"
  "cmake-gui"
  "fish"
)

for file in "${REMOVE_DESKTOP_FILES[@]}"; do
  rm -vf "/usr/share/applications/${file}.desktop" 2>/dev/null || true
done

# Filesystem minimization
log "INFO" "Removing unused system files..."
rm -rf /usr/share/doc
rm -rf /usr/share/doc/just
rm -rf /usr/bin/chsh

# Remove Skel fluff
rm -rvf /etc/skel/.mozilla 2>/dev/null || true
rm -rvf /etc/skel/.config/user-tmpfiles.d 2>/dev/null || true

# Boot cleanup
log "INFO" "Sanitizing /boot..."
rm -rf /boot/*
mkdir -p /boot

# Var cleanup
log "INFO" "Sanitizing /var..."
rm -rf /var/lib/alternatives
rm -rf /var/lib/freeipmi
rm -rf /var/lib/greetd
rm -rf /var/lib/AccountsService

# General cleanup
rm -rf /var/log/*
mkdir -p /var/log/journal

# Tmp cleanup
log "INFO" "Cleaning temporary directories..."
rm -rf /var/tmp/*
chmod 1777 /var/tmp

# Clean up temporary files
rm -rf /tmp/*
rm -f /tmp/copr-list.txt

# Fix systemd service permissions BEFORE dracut to avoid warnings
log "INFO" "Fixing systemd service permissions..."
find /usr/lib/systemd/system -type f -name "*.service" -exec chmod 644 {} + 2>/dev/null || true

# Rebuild initramfs for any kernel modules
if command -v dracut &>/dev/null; then
  log "INFO" "Rebuilding initramfs..."
  dracut --force --regenerate-all || die "Initramfs generation failed - build aborted"
fi

log "INFO" "Finalization: Complete"
log "INFO" "Build finished successfully for image: ${IMAGE_NAME}"
log "INFO" "Profile: ${HOST_PROFILE}"
