#!/usr/bin/env bash
set -oue pipefail
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
sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd

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
