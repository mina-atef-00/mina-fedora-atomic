#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log_init

echo "=========================================="
echo " MINA FEDORA ATOMIC BUILD"
echo "=========================================="

install_gum() {
    echo "Installing gum for enhanced logging..."
    if dnf5 install -y gum 2>&1; then
        echo "Gum installed successfully!"
        return 0
    else
        echo "Gum installation failed, using fallback mode"
        export GUM_NO_EMOJI=1
        return 1
    fi
}

if command -v gum &>/dev/null; then
    log_info "Gum already installed"
else
    install_gum || true
fi

echo ""
echo "Checking gum availability..."
if command -v gum &>/dev/null; then
    echo "Gum is available: $(gum --version)"
else
    echo "Gum NOT available, using echo fallback"
fi

print_header \
    "${IMAGE_NAME:-mina-fedora-atomic}" \
    "${HOST_PROFILE:-default}" \
    "ghcr.io/ublue-os/base-main:43"

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

# Make /opt immutable
if [ -d /opt ]; then
  rm -v /opt && mkdir -vp /opt
fi

log "INFO" "Base Setup: Complete"

end_phase
