#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log_init

start_phase "Finalization"

collect_build_metrics() {
    local duration
    duration=$(get_build_duration)
    
    local layers=8
    local packages_installed
    local packages_removed="${PACKAGES_REMOVED:-0}"
    
    packages_installed=$(rpm -qa | wc -l)
    
    local image_size
    image_size=$(du -sh /usr 2>/dev/null | cut -f1 || echo "unknown")
    
    local date_str
    date_str=$(date +%Y%m%d)
    
    local tags="latest
latest.${date_str}
${date_str}"
    
    echo "$duration|$image_size|$packages_installed|$packages_removed|$tags|$layers"
}

# Note: image_size uses 'du -sh /usr' as a proxy metric because the actual
# container image size is not available during build (image not yet finalized).
# This provides a reasonable approximation of installed payload size.
# Note: layers is fixed at 8, matching the number of RUN stages in the Containerfile.
# This is determined by the build architecture and cannot be dynamically computed during build.

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
PACKAGES_BEFORE=$(rpm -qa | wc -l)
dnf5 remove -y "${REMOVE_PKGS[@]}" 2>/dev/null || true
PACKAGES_AFTER=$(rpm -qa | wc -l)
PACKAGES_REMOVED=$((PACKAGES_BEFORE - PACKAGES_AFTER))
if [[ $PACKAGES_REMOVED -lt 0 ]]; then
    PACKAGES_REMOVED=0
fi

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

# Clean up build state file (phase counter persistence)
rm -rf /var/lib/build-state

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

end_phase

IFS='|' read -r duration image_size packages_installed packages_removed tags layers <<< "$(collect_build_metrics)"

print_footer \
    "success" \
    "${duration}" \
    "${image_size}" \
    "${layers}" \
    "${packages_installed}" \
    "${packages_removed}" \
    "${tags}"
