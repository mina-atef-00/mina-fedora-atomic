#!/usr/bin/env bash
# Set strict error handling
set -euo pipefail

# Check for the existence of the library before sourcing
# shellcheck source=/dev/null
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Starting Package Management..."

# --- 1. DRIVER INSTALLATION (UBlue Akmods) ---
log "INFO" "Checking for Akmods..."

# Enable RPM Fusion Free AND Non-Free (Needed for unrar & codecs)
dnf5 install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
dnf5 install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Common Akmods (v4l2loopback, ublue-os-addons)
if [ -d "/tmp/rpms/akmods-common" ]; then
  log "INFO" "Installing Common Akmods..."
  # Use shell expansion safely
  dnf5 install -y /tmp/rpms/akmods-common/ublue-os/ublue-os-akmods*.rpm
  dnf5 install -y /tmp/rpms/akmods-common/kmods/kmod-v4l2loopback*.rpm
fi

if [[ "$HOST_PROFILE" == "asus" ]]; then
  log "INFO" ">> Profile ASUS: Installing NVIDIA Drivers..."

  # Install kernel modules from ublue akmods
  if [ -d "/tmp/rpms/akmods-nvidia" ]; then
    dnf5 install -y /tmp/rpms/akmods-nvidia/ublue-os/ublue-os-nvidia*.rpm
    dnf5 install -y /tmp/rpms/akmods-nvidia/kmods/kmod-nvidia*.rpm
  fi

  # Install full NVIDIA driver stack (userspace components)
  dnf5 install -y --enablerepo=fedora-nvidia \
    nvidia-driver \
    nvidia-driver-cuda \
    nvidia-driver-libs \
    nvidia-modprobe \
    nvidia-persistenced \
    nvidia-settings \
    libnvidia-fbc \
    libva-nvidia-driver

  # Blacklist nouveau (Fixed: Removed indentation within the file content)
  cat > /usr/lib/modprobe.d/00-nouveau-blacklist.conf <<EOF
blacklist nouveau
options nouveau modeset=0
EOF

  # Configure dracut to force load NVIDIA (fixes black screen on boot)
  if [ -f "/usr/lib/dracut/dracut.conf.d/99-nvidia.conf" ]; then
    sed -i 's/omit_drivers/force_drivers/g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
  fi

  # Move nvidia-modeset config to correct location if it exists
  if [ -f "/etc/modprobe.d/nvidia-modeset.conf" ]; then
    mv /etc/modprobe.d/nvidia-modeset.conf /usr/lib/modprobe.d/nvidia-modeset.conf
  fi

  # Desktop hardware tools
  dnf5 install -y i2c-tools ddcutil

  # Create NVIDIA CDI service (Fixed: Heredoc alignment for systemd)
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

elif [[ "$HOST_PROFILE" == "lnvo" ]]; then
  log "INFO" ">> Profile LNVO: Installing Intel/Laptop Drivers..."
  dnf5 install -y brightnessctl libva-intel-media-driver
fi

# --- 2. REPOSITORY SETUP ---
log "INFO" "Enabling COPR Repositories..."

COPR_LIST=(
  "lihaohong/yazi"
  "alternateved/eza"
  "atim/starship"
  "dejan/rpms"
  "lilay/topgrade"
  "dejan/lazygit"
  "avengemedia/dms"
  "atim/bottom"
)

for copr in "${COPR_LIST[@]}"; do
  dnf5 -y copr enable "$copr"
done

# --- 3. PACKAGE INSTALLATION ---
PKGS=(
  # Core Desktop
  "niri"
  "dms"
  "greetd"
  "dms-greeter"
  "qt5ct"
  "qt6ct"
  "power-profiles-daemon"
  "cava"
  "papirus-icon-theme"
  "breeze-cursor-theme"
  "xwayland-satellite"
  "xdg-desktop-portal-gnome"
  "xdg-terminal-exec"
  "xdg-user-dirs"

  # GUI Utilities
  "kitty"
  "nautilus"
  "file-roller"
  "mangohud"
  "goverlay"
  "qalculate-gtk"
  "audacity"
  "sox"
  "v4l-utils"
  "qalculate"
  "picard"
  "syncplay"
  "swappy"
  "gnome-disk-utility"
  "chromium"
  "seahorse"
  "loupe"
  "mpv"

  # Editors & Git
  "neovim"
  "git"
  "gh"
  "lazygit"

  # CLI
  "eza"
  "bat"
  "ripgrep"
  "fd-find"
  "zoxide"
  "inxi"
  "bottom"
  "tealdeer"
  "du-dust"
  "procs"
  "fastfetch"
  "starship"
  "fish"
  "topgrade"
  "yazi"
  "chezmoi"
  "udiskie"
  "evtest"
  "wev"
  "age"
  "wlr-randr"

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

  # Networking
  "vpnc"
  "openssh-askpass"
  "openconnect"
  "bluez-tools"

  # Filesystems/Backends
  "gnome-keyring"
  "gnome-keyring-pam"
  "gvfs"
  "seatd"
  "cabextract"
  "fontconfig"
  "xorg-x11-font-utils"
  "nautilus-python"
  "greetd-selinux"
  "p7zip"
  "p7zip-plugins"
  "unrar"
  "android-tools"
)

log "INFO" "Installing Main Packages..."
dnf5 install -y "${PKGS[@]}"

# --- 4. CONFIGURATION FIXES ---
log "INFO" "Setting default user shell to Fish..."
if [ -f /etc/default/useradd ]; then
  sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd
fi

# --- 5. DEBLOAT ---
REMOVE_PKGS=(
  "firefox"
  "firefox-langpacks"
  "toolbox"
  "console-login-helper-messages"
  "gnome-tour"
  "gnome-software"
  "swaylock"
  "waybar"
  "fuzzel"
  "alacritty"
  "nodejs"
  "nodejs-docs"
  "nodejs-full-i18n"
  # Clean up RPM Fusion Release packages (but keep keys/libs installed)
  "rpmfusion-free-release"
  "rpmfusion-nonfree-release"
)

log "INFO" "Removing Unwanted Packages..."
dnf5 remove -y "${REMOVE_PKGS[@]}"

# --- 6. CLEANUP REPOS ---
log "INFO" "Disabling COPRs to keep runtime clean..."
for copr in "${COPR_LIST[@]}"; do
  dnf5 -y copr disable "$copr"
done

log "INFO" "Package operations complete."
