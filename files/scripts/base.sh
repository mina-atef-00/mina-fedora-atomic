#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log_init

echo "==========================================" >&2
echo " MINA FEDORA ATOMIC BUILD" >&2
echo " Profile: ${HOST_PROFILE:-default}" >&2
echo " Image: ${IMAGE_NAME:-mina-fedora-atomic}" >&2
echo "==========================================" >&2

install_gum() {
    echo ">>> Installing gum for enhanced logging..." >&2
    if dnf5 install -y gum; then
        echo ">>> Gum installed successfully!" >&2
        return 0
    else
        echo ">>> Gum installation failed, using fallback mode" >&2
        export GUM_NO_EMOJI=1
        return 1
    fi
}

if command -v gum &>/dev/null; then
    echo ">>> Gum already installed" >&2
else
    install_gum || true
fi

echo "" >&2
echo ">>> Checking gum availability..." >&2
if command -v gum &>/dev/null; then
    echo ">>> Gum is AVAILABLE: $(which gum)" >&2
else
    echo ">>> Gum NOT available, using echo fallback" >&2
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
