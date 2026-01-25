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

# --- CONFIG: HOSTNAME ---
log "INFO" "Setting Hostname..."
if [[ "$HOST_PROFILE" == "asus" ]]; then
  echo "asus" >/etc/hostname
elif [[ "$HOST_PROFILE" == "lnvo" ]]; then
  echo "lnvo" >/etc/hostname
else
  echo "mina-atomic" >/etc/hostname
fi

log "INFO" "Environment Prepared."
