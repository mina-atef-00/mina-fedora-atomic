#!/bin/bash
set -ouex pipefail

echo "Running Desktop Specific Build..."

### Install Akmods
# Install NVIDIA RPMs copied from akmods images
# These are copied to /tmp/rpms by the Containerfile instruction for the desktop profile
echo "Installing NVIDIA and Common Akmods..."
if [ -d "/tmp/rpms/akmods-nvidia" ]; then
	dnf5 install -y /tmp/rpms/akmods-nvidia/ublue-os/ublue-os-nvidia*.rpm
	dnf5 install -y /tmp/rpms/akmods-nvidia/kmods/kmod-nvidia*.rpm
fi

if [ -d "/tmp/rpms/akmods-common" ]; then
	dnf5 install -y /tmp/rpms/akmods-common/ublue-os/ublue-os-akmods*.rpm
fi

### Install Desktop Specific Packages
echo "Installing Desktop Specific Packages..."
dnf5 install -y \
	i2c-tools \
	ddcutil

### cleanup
dnf5 clean all
