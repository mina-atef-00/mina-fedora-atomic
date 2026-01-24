#!/usr/bin/env bash
set -oue pipefail
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Adding Flathub Repository..."
curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

log "INFO" "Running Final Cleanup..."

# 1. Package Manager Cleanup
dnf5 clean all

# 2. /var Cleanup (Crucial for bootc linting)
# In Bootc, /var is mutable state. The image should NOT ship data here.
# We remove caches and logs that accumulated during the build.
rm -rf /var/cache/*
rm -rf /var/log/*
mkdir -p /var/log/journal

# 3. Remove /tmp artifacts
rm -rf /tmp/*
rm -rf /var/tmp/*

rm -rf /usr/share/doc
rm -rf /usr/bin/chsh
rm -rf /usr/share/doc/just

# 4. Remove desktopfiles
rm -vf /usr/share/applications/byobu.desktop
rm -vf /usr/share/applications/nvim.desktop
rm -vf /usr/share/applications/btop.desktop

# 5. Remove more stuffs in skel
rm -rvf /etc/skel/.mozilla
rm -rvf /etc/skel/.config/user-tmpfiles.d# 5. Remove /boot artifacts

# 6. The kernel is in /usr/lib/modules. /boot in the image should be empty.
rm -rf /boot/*

touch /etc/resolv.conf
mkdir -vp /var/tmp
chmod -vR 1777 /var/tmp

log "INFO" "Cleanup Complete."
