#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log "INFO" "Kernel Modules (Akmods)..."

# Debug info
log "INFO" "Kernel version: $(uname -r)"
log "INFO" "Checking /tmp/akmods-nvidia contents..."
ls -la /tmp/akmods-nvidia/ 2>/dev/null || log "WARN" "akmods-nvidia directory not found"

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
  dnf5 install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" --quiet 2>&1 | tail -5 || true
  dnf5 install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" --quiet 2>&1 | tail -5 || true
  
  if [ -d "/tmp/akmods-nvidia" ]; then
    log "INFO" "Installing NVIDIA kernel modules..."
    
    if [ -d "/tmp/akmods-nvidia/ublue-os" ]; then
      log "INFO" "Installing ublue-os-nvidia-addons..."
      ls -la /tmp/akmods-nvidia/ublue-os/
      dnf5 install -y /tmp/akmods-nvidia/ublue-os/ublue-os-nvidia*.rpm
    fi
    
    if [ -d "/tmp/akmods-nvidia/kmods" ]; then
      log "INFO" "Installing kmod-nvidia packages..."
      ls -la /tmp/akmods-nvidia/kmods/
      dnf5 install -y /tmp/akmods-nvidia/kmods/kmod-nvidia*.rpm
    fi
    
    # Debug: Check what's in the modules directory after installation
    log "INFO" "Checking kernel modules directory..."
    KERNEL_VERSION=$(uname -r)
    ls -la /usr/lib/modules/${KERNEL_VERSION}/ 2>/dev/null || log "WARN" "No modules dir for ${KERNEL_VERSION}"
    ls -la /usr/lib/modules/${KERNEL_VERSION}/extra/ 2>/dev/null || log "WARN" "No extra modules dir"
    
    # Verify NVIDIA modules are installed for the current kernel
    NVIDIA_MODULE_DIR="/usr/lib/modules/${KERNEL_VERSION}/extra/nvidia"
    
    if [ -d "$NVIDIA_MODULE_DIR" ]; then
      log "INFO" "Checking NVIDIA kernel modules in ${NVIDIA_MODULE_DIR}..."
      ls -la ${NVIDIA_MODULE_DIR}/
      
      # Check for required NVIDIA modules (.ko.xz extension as built by akmods)
      REQUIRED_MODULES="nvidia nvidia-drm nvidia-modeset nvidia-peermem nvidia-uvm"
      MISSING_MODULES=""
      
      for mod in $REQUIRED_MODULES; do
        if [ ! -f "${NVIDIA_MODULE_DIR}/${mod}.ko.xz" ]; then
          MISSING_MODULES="${MISSING_MODULES} ${mod}"
        fi
      done
      
      if [ -z "$MISSING_MODULES" ]; then
        log "INFO" "All NVIDIA kernel modules verified for kernel ${KERNEL_VERSION}"
      else
        log "WARN" "Missing NVIDIA kernel modules:${MISSING_MODULES}"
        log "WARN" "NVIDIA support may not work on first boot - modules will be built by akmods-dkms on boot"
      fi
    else
      log "WARN" "NVIDIA kernel module directory not found at ${NVIDIA_MODULE_DIR}"
      log "WARN" "Checking all module directories..."
      find /usr/lib/modules -name "nvidia*.ko*" 2>/dev/null || log "WARN" "No nvidia modules found anywhere"
      log "WARN" "NVIDIA support may not work on first boot - modules will be built by akmods-dkms on boot"
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
