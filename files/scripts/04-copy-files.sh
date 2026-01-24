#!/usr/bin/env bash
set -oue pipefail
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Applying file overlay from ${SYSTEM_DIR}..."

# Safety Check: Prevent writing to /var or /home in the image
if [ -d "${SYSTEM_DIR}/var" ] || [ -d "${SYSTEM_DIR}/home" ] || [ -d "${SYSTEM_DIR}/root" ]; then
  die "Detected /var, /home, or /root in overlay. In Bootc/Atomic, these are state directories and should not be in the container image. Use /usr/share or /etc/skel."
fi

# 1. The Brute Force Copy
# -d: preserve links
# -r: recursive
# -f: force overwrite
cp -drf "${SYSTEM_DIR}/"* /

# 2. Fix Permissions (Crucial for SSH and Greetd)
log "INFO" "Fixing file permissions..."

# SSH Configs must be 600
if [ -d "/etc/ssh/sshd_config.d" ]; then
  chmod 600 /etc/ssh/sshd_config.d/*.conf 2>/dev/null || true
fi

# Greetd config must be readable
if [ -f "/etc/greetd/config.toml" ]; then
  chmod 644 /etc/greetd/config.toml
fi

if [ -d "/usr/lib/bootc/kargs.d" ]; then
  log "INFO" "Kernel arguments injected via bootc/kargs.d"
fi

log "INFO" "Overlay applied successfully."
