#!/usr/bin/env bash
set -oue pipefail

SCRIPTS_DIR="/ctx/files/scripts"
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Layer 4: NVIDIA Kernel Modules..."

# Install NVIDIA kernel modules for ASUS profile
if [[ "$HOST_PROFILE" == "asus" ]]; then
  if [ -d "/tmp/akmods-nvidia" ]; then
    log "INFO" "Installing NVIDIA kernel modules..."
    
    if [ -d "/tmp/akmods-nvidia/ublue-os" ]; then
      dnf5 install -y /tmp/akmods-nvidia/ublue-os/ublue-os-nvidia*.rpm
    fi
    
    if [ -d "/tmp/akmods-nvidia/kmods" ]; then
      dnf5 install -y /tmp/akmods-nvidia/kmods/kmod-nvidia*.rpm
    fi
  else
    log "WARN" "NVIDIA akmods directory not found at /tmp/akmods-nvidia"
  fi
else
  log "INFO" "Profile is not 'asus', skipping NVIDIA kernel modules"
fi

log "INFO" "Layer 4: Complete"
