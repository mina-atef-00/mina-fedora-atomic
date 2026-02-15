#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log "INFO" "Base Setup..."

# Pre-cleanup
log "INFO" "Performing pre-build cleanup..."
dnf5 clean all
rm -rf /usr/share/backgrounds/fedora-workstation
rm -rf /usr/share/backgrounds/f*

# Environment preparation
log "INFO" "Preparing OS environment..."
mkdir -vp /var/roothome
chmod 700 /var/roothome
mkdir -vp /var/lib/alternatives
mkdir -vp /etc/environment.d

# Make /opt immutable
if [ -d /opt ]; then
  rm -v /opt && mkdir -vp /opt
fi

log "INFO" "Base Setup: Complete"
