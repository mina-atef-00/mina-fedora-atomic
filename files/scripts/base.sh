#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log_init

install_gum() {
    log_info "Installing gum (enhanced CLI output)..."
    if dnf5 install -y gum --quiet 2>&1 | grep -v "^$"; then
        log_success "Gum installed successfully"
        return 0
    else
        log_warn "Gum installation failed, using fallback mode"
        export GUM_NO_EMOJI=1
        return 1
    fi
}

if command -v gum &>/dev/null; then
    log_info "Gum already installed"
else
    install_gum || true
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
