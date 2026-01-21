#!/bin/bash

set -ouex pipefail

### Install Akmods
# Install Common Akmods (like v4l2loopback) here if shared across all profiles
# NOTE: NVIDIA akmods are handled in build_desktop.sh
echo "Installing Common Akmods..."

dnf5 install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"

if [ -d "/tmp/rpms/akmods-common" ]; then
	# 1. Install UBlue Akmod setup keys/repos
	dnf5 install -y /tmp/rpms/akmods-common/ublue-os/ublue-os-akmods*.rpm

	# 2. Install the Kernel Modules
	# dnf will now find 'v4l2loopback-kmod-common' in the enabled RPMFusion repo
	dnf5 install -y /tmp/rpms/akmods-common/kmods/kmod-v4l2loopback*.rpm
fi

dnf5 remove -y rpmfusion-free-release

### Install System Packages
# Core utilities and tools
echo "Installing System Packages..."

# Enable COPR Repositories
dnf5 -y copr enable che/nerd-fonts
dnf5 -y copr enable avengemedia/dms
dnf5 -y copr enable atim/bottom

dnf5 install -y \
	git \
	gh \
	bat \
	ripgrep \
	fd-find \
	inxi \
	syncthing \
	chezmoi \
	greetd \
	tuigreet \
	bluez-tools \
	power-profiles-daemon \
	bottom \
	zoxide \
	tealdeer \
	duf \
	ncdu \
	p7zip \
	p7zip-plugins \
	unrar \
	neovim \
	fastfetch \
	evtest \
	wev \
	age \
	kitty \
	fish \
	du-dust \
	nautilus \
	udiskie \
	file-roller \
	accountsservice \
	gnome-disk-utility \
	gvfs \
	seatd \
	v4l-utils \
	seahorse \
	chromium \
	qalculate-gtk \
	qalculate \
	pavucontrol \
	playerctl \
	sox \
	loupe \
	gammastep \
	wlr-randr \
	adw-gtk3-theme \
	goverlay \
	mangohud \
	xwayland-satellite \
	xdg-desktop-portal-gnome \
	mpv \
	android-tools \
	breeze-cursor-theme \
	papirus-icon-theme \
	audacity \
	picard \
	syncplay \
	swappy \
	qt6ct \
	qt5ct

### Install Fonts
echo "Installing Fonts..."
dnf5 install -y \
	nerd-fonts \
	fira-code-fonts \
	google-roboto-slab-fonts \
	google-noto-serif-cjk-fonts \
	terminus-fonts \
	jetbrains-mono-fonts \
	rsms-inter-fonts

### Install Window Manager & Shell (Placeholders)
# Using COPRs or direct install if available
dnf5 install -y niri
dnf5 install -y dms

### Remove Unwanted Packages
dnf5 remove -y \
	swaylock \
	alacritty \
	waybar \
	fuzzel \
	danksearch \
	dgop \
	nodejs \
	nodejs-docs \
	nodejs-npm \
	nodejs-full-i18n

# Copy Configuration Files
# NOTE /usr is immutable
cp -r /ctx/build_files/sysusers.d/* /usr/lib/sysusers.d/
cp -r /ctx/build_files/udev/rules.d/* /usr/lib/udev/rules.d/
cp -r /ctx/build_files/polkit-1/rules.d/* /usr/share/polkit-1/rules.d/
cp -r /ctx/build_files/systemd/system-preset/* /usr/lib/systemd/system-preset/
cp -r /ctx/build_files/modprobe.d/* /etc/modprobe.d/

# Bootc Kernel Arguments
mkdir -p /usr/lib/bootc/kargs.d
cp -r /ctx/build_files/bootc/kargs.d/* /usr/lib/bootc/kargs.d/

# SSH Config
# Note: /etc is mutable, but we seed it here
mkdir -p /etc/ssh/sshd_config.d
cp /ctx/build_files/etc/ssh/sshd_config.d/*.conf /etc/ssh/sshd_config.d/
chmod 600 /etc/ssh/sshd_config.d/*.conf

# Greetd Config
mkdir -p /etc/greetd
cp /ctx/build_files/etc/greetd/config.toml /etc/greetd/config.toml

# Localization
# Set default timezone to Africa/Cairo
ln -sf /usr/share/zoneinfo/Africa/Cairo /etc/localtime

# Bluetooth Configuration
# Ensure AutoEnable=true is set in /etc/bluetooth/main.conf
# We use sed here as it's a simple change to an existing config file provided by bluez
sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf || echo "AutoEnable=true" >>/etc/bluetooth/main.conf

# Enable Services
systemctl enable greetd.service \
	sshd.service \
	power-profiles-daemon.service \
	bluetooth.service \
	sshd.service

### cleanup
dnf5 clean all
