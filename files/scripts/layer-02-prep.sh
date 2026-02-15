#!/usr/bin/env bash
set -oue pipefail

SCRIPTS_DIR="/ctx/files/scripts"
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Layer 2: Environment Preparation..."

# Bootc RootHome Requirement
log "INFO" "Creating /var/roothome..."
mkdir -vp /var/roothome
chmod 700 /var/roothome

# Create required directories
mkdir -vp /var/lib/alternatives
mkdir -vp /etc/environment.d

# Make /opt immutable (needed for some rpm packages like browsers, docker-desktop)
if [ -d /opt ]; then
  rm -v /opt && mkdir -vp /opt
fi

log "INFO" "Layer 2: Complete"
