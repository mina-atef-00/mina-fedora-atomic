#!/usr/bin/env bash
set -oue pipefail

SCRIPTS_DIR="/ctx/files/scripts"
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Layer 5: Package Base Setup..."

# Enable RPM Fusion
log "INFO" "Enabling RPM Fusion repositories..."
dnf5 install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
dnf5 install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Enable COPR repositories
log "INFO" "Enabling COPR repositories..."
COPR_LIST=(
  "lihaohong/yazi"
  "alternateved/eza"
  "atim/starship"
  "dejan/rpms"
  "lilay/topgrade"
  "avengemedia/dms"
  "atim/bottom"
)

for copr in "${COPR_LIST[@]}"; do
  dnf5 -y copr enable "$copr"
done

# Store COPR list for later cleanup
printf '%s\n' "${COPR_LIST[@]}" > /tmp/copr-list.txt

log "INFO" "Layer 5: Complete"
