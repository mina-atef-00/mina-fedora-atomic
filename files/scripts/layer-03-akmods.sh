#!/usr/bin/env bash
set -oue pipefail

SCRIPTS_DIR="/ctx/files/scripts"
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Layer 3: Common Kernel Modules (Akmods)..."

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

log "INFO" "Layer 3: Complete"
