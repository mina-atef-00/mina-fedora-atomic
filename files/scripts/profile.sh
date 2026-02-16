#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log "INFO" "Hardware Profile - ${HOST_PROFILE}..."

# Install profile-specific drivers and configurations
if [[ "$HOST_PROFILE" == "asus" ]]; then
  log "INFO" "Configuring ASUS Desktop Profile..."

  # Blacklist nouveau
  cat > /usr/lib/modprobe.d/00-nouveau-blacklist.conf <<EOF
blacklist nouveau
options nouveau modeset=0
EOF

  # Configure dracut to force load NVIDIA
  if [ -f "/usr/lib/dracut/dracut.conf.d/99-nvidia.conf" ]; then
    sed -i 's/omit_drivers/force_drivers/g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
  fi

  # Move nvidia-modeset config to correct location
  if [ -f "/etc/modprobe.d/nvidia-modeset.conf" ]; then
    mv /etc/modprobe.d/nvidia-modeset.conf /usr/lib/modprobe.d/nvidia-modeset.conf
  fi

  # Desktop hardware tools
  dnf_install_quiet i2c-tools ddcutil

  # Create NVIDIA CDI service
  cat > /usr/lib/systemd/system/nvctk-cdi.service <<'EOF'
[Unit]
Description=nvidia container toolkit CDI auto-generation
ConditionFileIsExecutable=/usr/bin/nvidia-ctk
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

[Install]
WantedBy=multi-user.target
EOF

  systemctl enable nvctk-cdi.service

  # Copy profile-specific files
  if [ -d "/ctx/files/profiles/asus" ]; then
    cp -r /ctx/files/profiles/asus/* / 2>/dev/null || true
  fi

elif [[ "$HOST_PROFILE" == "lnvo" ]]; then
  log "INFO" "Configuring LNVO Laptop Profile..."

  # Install laptop-specific packages (libva-intel-media-driver already installed in akmods stage)
  dnf_install_quiet brightnessctl

  # Copy profile-specific files
  if [ -d "/ctx/files/profiles/lnvo" ]; then
    cp -r /ctx/files/profiles/lnvo/* / 2>/dev/null || true
  fi
else
  die "Unknown HOST_PROFILE: '$HOST_PROFILE'. Valid profiles: asus, lnvo"
fi

# Apply common system files (always run after profile-specific)
if [ -d "/ctx/files/system" ]; then
  log "INFO" "Applying common system configuration..."
  
  # Safety check: Prevent stateful directory pollution
  FORBIDDEN_PATHS=("var" "home" "root" "run")
  for path in "${FORBIDDEN_PATHS[@]}"; do
    if [ -d "/ctx/files/system/${path}" ]; then
      die "CRITICAL ERROR: Overlay contains '/${path}'. In Bootc images, this directory is for runtime state only."
    fi
  done
  
  cp -r /ctx/files/system/* / 2>/dev/null || true
fi

# --- SYSTEMD SERVICE MANAGEMENT ---
log "INFO" "Configuring systemd services..."

# Services to be explicitly enabled
ENABLED_SERVICES=(
  "force-unblock-radios.service"
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
  "udiskie"
)

# Services to be explicitly disabled AND masked
DISABLED_SERVICES=(
  "NetworkManager-wait-online.service"
  "flatpak-add-fedora-repos.service"
  "bootc-fetch-apply-updates.timer"
)

# Enable services
log "INFO" "Enabling services..."
for service in "${ENABLED_SERVICES[@]}"; do
  systemctl enable "$service" &>/dev/null && log "INFO" "  [+] $service" || die "CRITICAL: Failed to enable $service"
done

# Enable global services
log "INFO" "Enabling global services..."
for service in "${ENABLED_GLOBAL_SERVICES[@]}"; do
  systemctl enable --global "$service" &>/dev/null && log "INFO" "  [+] $service" || die "CRITICAL: Failed to enable $service globally"
done

# Apply presets (non-critical, just log warnings if they fail)
log "INFO" "Applying presets..."
for preset in "${ENABLED_PRESETS[@]}"; do
  if systemctl preset --global "$preset" &>/dev/null; then
    log "INFO" "  [+] $preset"
  else
    log "WARN" "  [!] Preset '$preset' not found (skipping)"
  fi
done

# Disable and mask services
log "INFO" "Disabling and masking services..."
for service in "${DISABLED_SERVICES[@]}"; do
  systemctl disable "$service" &>/dev/null
  systemctl mask "$service" &>/dev/null && log "INFO" "  [-] $service"
done

# --- SYSTEM FILE PERMISSIONS ---
log "INFO" "Setting system file permissions..."

# Enforce root ownership on system paths
SYSTEM_PATHS=(
  "/etc/ssh"
  "/etc/greetd"
  "/etc/environment.d"
  "/usr/lib/bootc"
  "/usr/lib/sysusers.d"
  "/usr/lib/udev/rules.d"
  "/usr/share/polkit-1/rules.d"
  "/usr/lib/pam.d"
)

for path in "${SYSTEM_PATHS[@]}"; do
  if [ -d "$path" ]; then
    chown -R root:root "$path"
  fi
done

# SSH Security
if [ -d "/etc/ssh/sshd_config.d" ]; then
  chmod 700 /etc/ssh/sshd_config.d
  find /etc/ssh/sshd_config.d -type f -name "*.conf" -exec chmod 600 {} +
fi

# Greetd / PAM
if [ -d "/etc/greetd" ]; then
  chmod 755 /etc/greetd
  [ -f "/etc/greetd/config.toml" ] && chmod 644 /etc/greetd/config.toml
fi

if [ -f "/usr/lib/pam.d/greetd-spawn" ]; then
  chmod 644 /usr/lib/pam.d/greetd-spawn
fi

# Polkit & Udev
[ -d "/usr/share/polkit-1/rules.d" ] && find /usr/share/polkit-1/rules.d -type f -exec chmod 644 {} +
[ -d "/usr/lib/udev/rules.d" ] && find /usr/lib/udev/rules.d -type f -exec chmod 644 {} +

# Environment
[ -d "/etc/environment.d" ] && find /etc/environment.d -type f -exec chmod 644 {} +

# --- BLUETOOTH CONFIGURATION ---
if [ -f "/etc/bluetooth/main.conf" ]; then
  log "INFO" "Configuring Bluetooth AutoEnable..."
  cat <<EOF >>/etc/bluetooth/main.conf

[Policy]
AutoEnable=true
EOF
fi

# --- LAPTOP POWER CONFIGURATION ---
if [[ "$HOST_PROFILE" == "lnvo" ]]; then
  log "INFO" "Configuring laptop power management..."
  mkdir -p /etc/systemd/logind.conf.d
  cat > /etc/systemd/logind.conf.d/10-mina-power.conf <<EOF
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
HandlePowerKey=poweroff
HandleSuspendKey=suspend
HandleRebootKey=reboot
EOF
  chmod 644 /etc/systemd/logind.conf.d/10-mina-power.conf
fi

log "INFO" "Hardware Profile: Complete"
