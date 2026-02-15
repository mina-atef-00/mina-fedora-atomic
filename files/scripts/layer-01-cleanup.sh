#!/usr/bin/env bash
set -oue pipefail

SCRIPTS_DIR="/ctx/files/scripts"
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Layer 1: Pre-Cleanup..."

# Clean up default repo metadata to ensure we fetch fresh data
dnf5 clean all

# Remove default Fedora backgrounds
rm -rf /usr/share/backgrounds/fedora-workstation
rm -rf /usr/share/backgrounds/f*

log "INFO" "Layer 1: Complete"
