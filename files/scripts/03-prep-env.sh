#!/usr/bin/env bash
set -oue pipefail
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Preparing OS Environment..."

# --- Bootc RootHome Requirement ---
log "INFO" "Creating /var/roothome..."
mkdir -vp /var/roothome
chmod 700 /var/roothome

mkdir -vp /var/lib/alternatives
mkdir -vp /etc/environment.d

# To make /opt immutable, needed for some rpm? packages (browsers, docker-desktop)
rm -v /opt && mkdir -vp /opt

log "INFO" "Environment Prepared."
