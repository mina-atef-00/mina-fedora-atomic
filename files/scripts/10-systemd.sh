#!/usr/bin/env bash
set -oue pipefail
source "${SCRIPTS_DIR}/lib.sh"

# --- CONFIGURATION ARRAYS ---

# Services to be explicitly enabled
ENABLED_SERVICES=(
  "greetd.service"
  "bluetooth.service"
  "power-profiles-daemon.service"
  "systemd-timesyncd.service"
  "systemd-resolved.service"
  "firewalld.service"
)

# Global services to be explicitly enabled
ENABLED_GLOBAL_SERVICES=(
  "gnome-keyring-daemon.service"
  "gnome-keyring-daemon.socket"
)

# Presets to be explicitly enabled
ENABLED_PRESETS=(
  "chezmoi-init"
  "chezmoi-update"
  "udiskie"
)
# Services to be explicitly disabled AND masked
DISABLED_SERVICES=(
  "NetworkManager-wait-online.service"
  "flatpak-add-fedora-repos.service"
  "bootc-fetch-apply-updates.timer"
)

# --- PROFILE SPECIFIC LOGIC ---

# Add Laptop specific services if profile is 'lnvo'
if [[ "$HOST_PROFILE" == "lnvo" ]]; then
  # ENABLED_SERVICES+=("tlp.service")
  log "INFO" "Profile 'lnvo' detected: No specific services enabled."
fi

# --- FUNCTIONS ---

enable_list() {
  log "INFO" "Enabling selected services..."
  for service in "${ENABLED_SERVICES[@]}"; do
    log "INFO" "  [+] Enabling: $service"
    systemctl enable "$service" || log "WARN" "Failed to enable $service"
  done
}

enable_global_list() {
  log "INFO" "Enabling selected global services..."
  for service in "${ENABLED_GLOBAL_SERVICES[@]}"; do
    log "INFO" "  [+] Enabling: $service"
    systemctl enable --global "$service" || log "WARN" "Failed to enable $service globally"
  done
}

enable_preset_list() {
  log "INFO" "Enabling selected presets..."
  for preset in "${ENABLED_PRESETS[@]}"; do
    log "INFO" "  [+] Enabling: $preset"
    systemctl preset --global "$preset" || log "WARN" "Failed to enable preset $preset"
  done
}

disable_list() {
  log "INFO" "Disabling and masking selected services..."
  for service in "${DISABLED_SERVICES[@]}"; do
    log "INFO" "  [-] Disabling: $service"
    # Disable then mask to link to /dev/null
    systemctl disable "$service" 2>/dev/null || true
    systemctl mask "$service" 2>/dev/null || true
  done
}

main() {
  log "INFO" "Starting Systemd Configuration..."

  enable_list
  enable_global_list
  disable_list

  log "INFO" "Systemd Configuration Complete."
}

# --- EXECUTION ---
main
