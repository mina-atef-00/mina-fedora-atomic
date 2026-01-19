#!/bin/bash

set -ouex pipefail

### Install Akmods
# Install Common Akmods (like v4l2loopback) here if shared across all profiles
# NOTE: NVIDIA akmods are handled in build_desktop.sh
echo "Installing Common Akmods..."
if [ -d "/tmp/rpms/akmods-common" ]; then
	dnf5 install -y /tmp/rpms/akmods-common/ublue-os/ublue-os-akmods*.rpm
	dnf5 install -y /tmp/rpms/akmods-common/kmods/kmod-v4l2loopback*.rpm
fi
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
	htop \
	bat \
	ripgrep \
	fd-find \
	gamemode \
	jq \
	inxi \
	tree \
	wget2 \
	syncthing \
	bootupd \
	chezmoi \
	openssh-server \
	greetd \
	tuigreet \
	bluez \
	bluez-tools \
	udisks2 \
	power-profiles-daemon \
	zram-generator \
	polkit \
	ffmpeg \
	ffmpeg-free \
	gstreamer1-plugins-good \
	gstreamer1-plugins-bad-free \
	gstreamer1-plugins-ugly-free \
	gstreamer1-libav \
	pipewire \
	wireplumber \
	alsa-utils \
	bottom \
	zoxide \
	tealdeer \
	lsof \
	duf \
	ncdu \
	p7zip \
	p7zip-plugins \
	unrar \
	unzip \
	zip \
	neovim \
	fastfetch \
	i2c-tools \
	usbutils \
	pciutils \
	evtest \
	wev \
	ImageMagick \
	age \
	kitty \
	fish \
	curl \
	du-dust \
	fzf \
	psmisc \
	bzip2 \
	gzip \
	nautilus \
	ntfs-3g \
	udiskie \
	file-roller \
	xz \
	cmake \
	gcc \
	make \
	meson \
	ninja-build \
	nodejs \
	nodejs-npm \
	python3.13 \
	uv \
	accountsservice \
	efibootmgr \
	gnome-disk-utility \
	gvfs \
	hwdata \
	lshw \
	seatd \
	v4l-utils \
	openssl \
	seahorse \
	chromium \
	qalculate-gtk \
	qalculate \
	pavucontrol \
	playerctl \
	sox \
	loupe \
	gammastep \
	wl-clipboard \
	wlr-randr \
	adw-gtk3-theme \
	goverlay \
	mangohud \
	sdl2-compat \
	protontricks \
	xwayland-satellite \
	xdg-desktop-portal-gnome \
	xdg-desktop-portal-gtk \
	xdg-utils \
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
	mozilla-fira-sans-fonts \
	google-roboto-slab-fonts \
	google-noto-emoji-fonts \
	google-noto-sans-cjk-fonts \
	google-noto-serif-cjk-fonts \
	fontawesome-fonts \
	terminus-fonts \
	jetbrains-mono-fonts \
	rsms-inter-fonts \
	ubuntu-family-fonts

### Install Window Manager & Shell (Placeholders)
# Using COPRs or direct install if available
dnf5 install -y niri
dnf5 install -y dms

# Enable and start systemd service
echo "Enabling DMS systemd service..."
systemctl --user enable --now dms

# Bind to niri session (only start under niri)
echo "Binding DMS to niri session..."
systemctl --user add-wants niri.service dms
### System Configuration Migration
echo "Applying System Configuration..."

# Copy Configuration Files
cp -r /ctx/build_files/sysusers.d/* /usr/lib/sysusers.d/
cp -r /ctx/build_files/udev/rules.d/* /usr/lib/udev/rules.d/
cp -r /ctx/build_files/polkit-1/rules.d/* /usr/share/polkit-1/rules.d/
cp -r /ctx/build_files/systemd/system-preset/* /usr/lib/systemd/system-preset/
cp -r /ctx/build_files/modprobe.d/* /etc/modprobe.d/

# Bootc Kernel Arguments
mkdir -p /usr/lib/bootc/kargs.d
cp -r /ctx/build_files/bootc/kargs.d/* /usr/lib/bootc/kargs.d/

# SSH Config (Note: /etc is mutable, but we seed it here)
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

### cleanup
dnf5 clean all
