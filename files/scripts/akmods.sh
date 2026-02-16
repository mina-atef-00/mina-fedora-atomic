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

# Install NVIDIA kernel modules and userspace drivers for ASUS profile
if [[ "$HOST_PROFILE" == "asus" ]]; then
  log "INFO" "Installing NVIDIA drivers..."
  
  # Enable RPM Fusion first (required for NVIDIA userspace drivers)
  log "INFO" "Enabling RPM Fusion repositories..."
  dnf5 install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" --quiet 2>&1 | tail -5
  dnf5 install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" --quiet 2>&1 | tail -5
  
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

  # Install NVIDIA userspace drivers
  dnf_install_quiet \
    nvidia-driver \
    nvidia-driver-cuda \
    nvidia-driver-libs \
    nvidia-modprobe \
    nvidia-persistenced \
    nvidia-settings \
    libnvidia-fbc \
    libva-nvidia-driver
else
  log "INFO" "Profile is not 'asus', skipping NVIDIA drivers"
fi

log "INFO" "Kernel Modules: Complete"
