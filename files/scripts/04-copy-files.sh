#!/usr/bin/env bash
set -oue pipefail
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Starting Robust System Overlay..."

# 1. THE SAFETY GATE: Prevent stateful directory pollution
# We check if the source overlay contains folders that Bootc manages as runtime state.
FORBIDDEN_PATHS=("var" "home" "root" "run")
for path in "${FORBIDDEN_PATHS[@]}"; do
  if [ -d "${SYSTEM_DIR}/${path}" ]; then
    die "CRITICAL ERROR: Overlay contains '/${path}'. In Bootc images, this directory is for runtime state only and cannot be part of the immutable image. Use /usr/share/factory or /etc/skel instead."
  fi
done

# 2. THE ATOMIC COPY
log "INFO" "Copying files from ${SYSTEM_DIR} to / ..."
cp -drfp "${SYSTEM_DIR}/"* /

# 3. OWNERSHIP ENFORCEMENT
# We ensure root owns everything in the system paths.
# We loop through an array to keep the code clean and check existence.
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

log "INFO" "Enforcing root ownership on system paths..."
for path in "${SYSTEM_PATHS[@]}"; do
  if [ -d "$path" ]; then
    chown -R root:root "$path"
    log "DEBUG" "  [OK] Ownership set for $path"
  fi
done

# 4. SECURITY PERMISSIONS (Defensive Implementation)

# --- SSH Security ---
if [ -d "/etc/ssh/sshd_config.d" ]; then
  log "INFO" "Applying strict SSH permissions..."
  chmod 700 /etc/ssh/sshd_config.d
  # Find is safer than wildcards; it won't fail if no files exist
  find /etc/ssh/sshd_config.d -type f -name "*.conf" -exec chmod 600 {} +
fi

# --- Greetd / DMS / PAM ---
if [ -d "/etc/greetd" ]; then
  log "INFO" "Securing Greetd configuration..."
  chmod 755 /etc/greetd
  [ -f "/etc/greetd/config.toml" ] && chmod 644 /etc/greetd/config.toml
fi

if [ -f "/usr/lib/pam.d/greetd-spawn" ]; then
  log "INFO" "Setting PAM greetd-spawn permissions..."
  chmod 644 /usr/lib/pam.d/greetd-spawn
fi

# --- Polkit & Udev (Immutable System Rules) ---
log "INFO" "Setting permissions for system rules..."
[ -d "/usr/share/polkit-1/rules.d" ] && find /usr/share/polkit-1/rules.d -type f -exec chmod 644 {} +
[ -d "/usr/lib/udev/rules.d" ] && find /usr/lib/udev/rules.d -type f -exec chmod 644 {} +

# --- Environment ---
if [ -d "/etc/environment.d" ]; then
  log "INFO" "Securing environment variables..."
  find /etc/environment.d -type f -exec chmod 644 {} +
fi

# 5. FINAL LOGIC CHECK
if [ -d "/usr/lib/bootc/kargs.d" ]; then
  log "INFO" "Bootc Kernel Arguments detected and applied via overlay."
fi

# --- BLUETOOTH CONFIGURATION ---
# Force BlueZ to power up the controller on boot.
# We append this to the end of main.conf to override defaults.
if [ -f "/etc/bluetooth/main.conf" ]; then
  log "INFO" "Configuring Bluetooth AutoEnable..."
  cat <<EOF >>/etc/bluetooth/main.conf

[Policy]
AutoEnable=true
EOF
else
  log "WARN" "/etc/bluetooth/main.conf not found. Bluetooth config skipped."
fi

# --- LAPTOP POWER CONFIGURATION ---
if [[ "$HOST_PROFILE" == "lnvo" ]]; then
  log "INFO" "Profile 'lnvo' detected: Injecting custom logind.conf..."

  # Ensure the drop-in directory exists
  mkdir -p /etc/systemd/logind.conf.d

  # Write the configuration
  cat <<EOF >/etc/systemd/logind.conf.d/10-mina-power.conf
[Login]
# BATTERY BEHAVIOR: Sleep to save power
HandleLidSwitch=suspend

# CHARGING BEHAVIOR: Stay awake (Clamshell/Server mode)
HandleLidSwitchExternalPower=ignore

# DOCKED BEHAVIOR: Stay awake
HandleLidSwitchDocked=ignore

# HARDWARE KEYS
HandlePowerKey=poweroff
HandleSuspendKey=suspend
HandleRebootKey=reboot

# IDLE BEHAVIOR (Optional safety net)
# If system is idle for 20 mins on battery, suspend.
# IdleAction=suspend
# IdleActionSec=20min
EOF

  chmod 644 /etc/systemd/logind.conf.d/10-mina-power.conf
  log "INFO" "Power management configured for Laptop."
fi

git config --global commit.gpgsign false

# 6. TIMEZONE SETUP
log "INFO" "Setting system timezone to Africa/Cairo..."
ln -sf /usr/share/zoneinfo/Africa/Cairo /etc/localtime

log "INFO" "Overlay process completed successfully."
