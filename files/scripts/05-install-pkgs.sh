#!/usr/bin/env bash
set -oue pipefail
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Starting Package Management..."

# --- 1. DRIVER INSTALLATION (UBlue Akmods) ---
log "INFO" "Checking for Akmods..."

# Enable RPM Fusion Free Repo (NVIDIA dependencies)
dnf5 install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"

# Common Akmods (v4l2loopback, ublue-os-addons)
if [ -d "/tmp/rpms/akmods-common" ]; then
  log "INFO" "Installing Common Akmods..."
  dnf5 install -y /tmp/rpms/akmods-common/ublue-os/ublue-os-akmods*.rpm
  dnf5 install -y /tmp/rpms/akmods-common/kmods/kmod-v4l2loopback*.rpm
fi

# Profile Specific Drivers
if [[ "$HOST_PROFILE" == "asus" ]]; then
  log "INFO" ">> Profile ASUS: Installing NVIDIA Drivers..."
  if [ -d "/tmp/rpms/akmods-nvidia" ]; then
    dnf5 install -y /tmp/rpms/akmods-nvidia/ublue-os/ublue-os-nvidia*.rpm
    dnf5 install -y /tmp/rpms/akmods-nvidia/kmods/kmod-nvidia*.rpm
  fi
  # Desktop hardware tools
  dnf5 install -y i2c-tools ddcutil

elif [[ "$HOST_PROFILE" == "lnvo" ]]; then
  log "INFO" ">> Profile LNVO: Installing Intel/Laptop Drivers..."
  dnf5 install -y brightnessctl libva-intel-media-driver
fi

# Cleanup RPM Fusion Repo
dnf5 remove -y rpmfusion-free-release

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
  "xwayland-satellite"
  "xdg-desktop-portal-gnome"
  "xdg-terminal-exec"
  "cava"

  # CLI / Rust Tools
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
  "steam-devices"
  "udiskie"
  "openssh-askpass"
  "p7zip"
  "p7zip-plugins"
  "unrar"
  "evtest"
  "wev"
  "age"

  # Multimedia
  "playerctl"
  "webp-pixbuf-loader"
  "alsa-tools"

  # Editors & Git
  "neovim"
  "git"
  "gh"
  "lazygit"

  # GUI Utilities
  "kitty"
  "nautilus"
  "nautilus-python"
  "file-roller"
  "gammastep"
  "mangohud"
  "goverlay"
  "sox"
  "wlr-randr"
  "qalculate-gtk"
  "audacity"
  "v4l-utils"
  "qalculate"
  "picard"
  "syncplay"
  "swappy"
  "gnome-disk-utility"
  "gnome-keyring"
  "gnome-keyring-pam"
  "gvfs"
  "seatd"
  "chromium"
  "accountsservice"
  "seahorse"
  "loupe"
  "mpv"
  "pavucontrol"
  "papirus-icon-theme"
  "breeze-cursor-theme"

  # Hardware/System
  "bluez-tools"
  "power-profiles-daemon"
  "android-tools"
)

log "INFO" "Installing Main Packages..."
dnf5 install -y "${PKGS[@]}"

# --- 4. DEBLOAT ---
# CRITICAL: DO NOT REMOVE dgop OR dms WILL BREAK
REMOVE_PKGS=(
  "firefox"
  "firefox-langpacks"
  "gnome-tour"
  "gnome-software"
  "swaylock"
  "waybar"
  "fuzzel"
  "alacritty"
  "nodejs"
  "nodejs-docs"
  "nodejs-full-i18n"
)

log "INFO" "Removing Unwanted Packages..."
dnf5 remove -y "${REMOVE_PKGS[@]}"

# --- 5. CLEANUP REPOS ---
log "INFO" "Disabling COPRs to keep runtime clean..."
for copr in "${COPR_LIST[@]}"; do
  dnf5 -y copr disable "$copr"
done

log "INFO" "Package operations complete."
