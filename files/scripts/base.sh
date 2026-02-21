#!/usr/bin/env bash
set -oue pipefail

BUILD_LOG="/tmp/build-output.log"

source "/ctx/files/scripts/lib.sh"

log_init

log_to_file() {
    echo "[$(date '+%H:%M:%S')] $*" >> "$BUILD_LOG"
}

log_to_file "=========================================="
log_to_file "MINA FEDORA ATOMIC BUILD STARTED"
log_to_file "Profile: ${HOST_PROFILE:-default}"
log_to_file "Image: ${IMAGE_NAME:-mina-fedora-atomic}"
log_to_file "=========================================="

echo ""
echo "=========================================="
echo " MINA FEDORA ATOMIC BUILD"
echo " Profile: ${HOST_PROFILE:-default}"
echo " Image: ${IMAGE_NAME:-mina-fedora-atomic}"
echo "=========================================="
echo ""

install_gum() {
    log_to_file "Installing gum..."
    echo ">>> Installing gum for enhanced logging..."
    if dnf5 install -y gum; then
        log_to_file "Gum installed successfully"
        echo ">>> Gum installed successfully!"
        return 0
    else
        log_to_file "Gum installation FAILED, using fallback"
        echo ">>> Gum installation failed, using fallback mode"
        export GUM_NO_EMOJI=1
        return 1
    fi
}

if command -v gum &>/dev/null; then
    log_to_file "Gum already installed"
    echo ">>> Gum already installed"
else
    install_gum || true
fi

gum_status="NOT AVAILABLE"
command -v gum &>/dev/null && gum_status="AVAILABLE"
log_to_file "Gum status: $gum_status"
echo ""
echo ">>> Gum availability: $gum_status"
echo ""

log_to_file "Printing header..."
print_header \
    "${IMAGE_NAME:-mina-fedora-atomic}" \
    "${HOST_PROFILE:-default}" \
    "ghcr.io/ublue-os/base-main:43"

log_to_file "Starting Phase 1: Environment Preparation"
start_phase "Environment Preparation"

log "INFO" "Base Setup..."

# Pre-cleanup
log "INFO" "Performing pre-build cleanup..."
dnf5 clean all
rm -rf /usr/share/backgrounds/fedora-workstation
rm -rf /usr/share/backgrounds/f*

# Environment preparation
log "INFO" "Preparing OS environment..."
mkdir -vp /var/roothome
chmod 700 /var/roothome
mkdir -vp /var/lib/alternatives
mkdir -vp /etc/environment.d
mkdir -vp /var/lib/build-state

# Make /opt immutable
if [ -d /opt ]; then
  rm -v /opt && mkdir -vp /opt
fi

log "INFO" "Base Setup: Complete"

end_phase
