#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log "INFO" "Kernel Modules (Akmods)..."

# Install common akmods (v4l2loopback, ublue-os-addons)
if [ -d "/tmp/akmods-common" ]; then
  log "INFO" "Installing common akmods..."
  
  if [ -d "/tmp/akmods-common/ublue-os" ]; then
    dnf5 install -y /tmp/akmods-common/ublue-os/ublue-os-akmods*.rpm || true
  fi
  
  if [ -d "/tmp/akmods-common/kmods" ]; then
    dnf5 install -y /tmp/akmods-common/kmods/kmod-v4l2loopback*.rpm || true
  fi
else
  log "WARN" "Common akmods directory not found at /tmp/akmods-common"
fi

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

log "INFO" "Kernel Modules: Complete"
