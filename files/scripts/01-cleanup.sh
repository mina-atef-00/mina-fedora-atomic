#!/usr/bin/env bash
set -oue pipefail
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Performing pre-build cleanup..."

# Remove desktopfiles
rm -vf /usr/share/applications/byobu.desktop
rm -vf /usr/share/applications/nvim.desktop
rm -vf /usr/share/applications/btop.desktop

# Clean up default repo metadata to ensure we fetch fresh data
dnf5 clean all

rm -rf /usr/share/backgrounds/fedora-workstation
rm -rf /usr/share/backgrounds/f*

log "INFO" "Pre-cleanup finished."
