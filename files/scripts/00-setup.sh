#!/usr/bin/env bash
set -oue pipefail

# Define context paths
export BASE_DIR="/ctx/files"
export SCRIPTS_DIR="${BASE_DIR}/scripts"
export SYSTEM_DIR="${BASE_DIR}/system"

# Source the logging library
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Initializing Build Process..."
log "INFO" "Image Name: ${IMAGE_NAME}"
log "INFO" "Host Profile: ${HOST_PROFILE}"

# --- EXECUTION CHAIN ---

# 1. PRE-CLEANUP
log "INFO" ">>> Step 01: Pre-Cleanup"
bash "${SCRIPTS_DIR}/01-cleanup.sh"
ostree container commit

# 2. PREPARE ENVIRONMENT
log "INFO" ">>> Step 03: Prepare Environment"
bash "${SCRIPTS_DIR}/03-prep-env.sh"
ostree container commit

# 3. OVERLAY FILES (Configs)
log "INFO" ">>> Step 04: System Overlay"
bash "${SCRIPTS_DIR}/04-copy-files.sh"
ostree container commit

# 4. INSTALL PACKAGES (Drivers + Niri + Dank)
log "INFO" ">>> Step 05: Package Installation"
bash "${SCRIPTS_DIR}/05-install-pkgs.sh"
ostree container commit

# 5. THEMING SETUP
log "INFO" ">>> Step 06: Theming Configuration"
bash "${SCRIPTS_DIR}/06-theming.sh"
ostree container commit

# 6. SYSTEMD SERVICES
log "INFO" ">>> Step 10: Service Configuration"
bash "${SCRIPTS_DIR}/10-systemd.sh"
ostree container commit

# 7. POST-CLEANUP
log "INFO" ">>> Step 11: Final Cleanup"
bash "${SCRIPTS_DIR}/11-final-cleanup.sh"
ostree container commit

log "INFO" "Build Configuration Complete Successfully."
