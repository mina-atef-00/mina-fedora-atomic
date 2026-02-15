#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log "INFO" "Multimedia, Codecs, Editors, and Git..."

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

log "INFO" "Multimedia & Editors: Complete"
