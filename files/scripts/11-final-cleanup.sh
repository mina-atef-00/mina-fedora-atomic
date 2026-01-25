#!/usr/bin/env bash
set -oue pipefail
source "${SCRIPTS_DIR}/lib.sh"
log "INFO" "Starting Cleanup..."

# --- 1. SETUP FLATHUB ---
log "INFO" "Adding Flathub Repository..."
curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

# --- 2. PACKAGE MANAGER CLEANUP ---
log "INFO" "Cleaning DNF artifacts..."
dnf5 clean all
# Aggressively remove DNF state (fixes 'var-tmpfiles' lint warning)
rm -rf /var/lib/dnf
rm -rf /var/cache/dnf
rm -rf /var/cache/libdnf5

# --- 3. UI DEBLOAT ---
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
  # Use -f to avoid errors if the file doesn't exist
  rm -vf "/usr/share/applications/${file}.desktop"
done

# --- 4. FILESYSTEM MINIMIZATION ---
log "INFO" "Removing unused system files..."
rm -rf /usr/share/doc
rm -rf /usr/share/doc/just
# Note: Removing chsh prevents users from changing shells later,
# but valid if you enforce via sysusers.d
rm -rf /usr/bin/chsh

# Remove Skel fluff
rm -rvf /etc/skel/.mozilla
rm -rvf /etc/skel/.config/user-tmpfiles.d

# --- 5. BOOT CLEANUP (Linter Fix) ---
log "INFO" "Sanitizing /boot..."
rm -rf /boot/*
mkdir -p /boot

# --- 6. VAR CLEANUP ---
log "INFO" "Sanitizing /var (Runtime State)..."
rm -rf /var/lib/alternatives
rm -rf /var/lib/freeipmi
rm -rf /var/lib/greetd
rm -rf /var/lib/AccountsService

# General cleanup
rm -rf /var/log/*
mkdir -p /var/log/journal

# --- 7. TMP CLEANUP ---
log "INFO" "Cleaning temporary directories..."
rm -rf /var/tmp/*
# Ensure permissions are correct for runtime
chmod 1777 /var/tmp

log "INFO" "Cleanup Complete."
