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

# --- CONFIG: HOSTNAME ---
log "INFO" "Setting Hostname..."
if [[ "$HOST_PROFILE" == "asus" ]]; then
  echo "mina-asus" >/etc/hostname
elif [[ "$HOST_PROFILE" == "lnvo" ]]; then
  echo "mina-lnvo" >/etc/hostname
else
  echo "mina-atomic" >/etc/hostname
fi

# --- CONFIG: TIMEZONE ---
log "INFO" "Setting timezone to Africa/Cairo..."
ln -sf /usr/share/zoneinfo/Africa/Cairo /etc/localtime

log "INFO" "Environment Prepared."
