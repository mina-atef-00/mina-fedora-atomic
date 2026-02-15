#!/usr/bin/env bash
set -oue pipefail

SCRIPTS_DIR="/ctx/files/scripts"
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Layer 4: Multimedia, Codecs, Editors, and Git..."

PKGS=(
  # Multimedia & Codecs
  "playerctl"
  "webp-pixbuf-loader"
  "alsa-tools"
  "gammastep"
  "accountsservice"
  "pavucontrol"
  "audispd-plugins"
  "gum"
  "uxplay"

  # Editors & Git
  "neovim"
  "git"
  "gh"
)

dnf5 install -y "${PKGS[@]}"

log "INFO" "Layer 4: Complete"
