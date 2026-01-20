#!/bin/bash
set -ouex pipefail

echo "Running Laptop Specific Build..."

### Install Laptop Specific Packages
echo "Installing Laptop Specific Packages..."
dnf5 install -y \
    brightnessctl \
    libva-intel-media-driver

### Power Management Configuration

### Touchpad Configuration
# Create libinput config for touchpad
mkdir -p /etc/X11/xorg.conf.d
cat >/etc/X11/xorg.conf.d/30-touchpad.conf <<EOF
Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "NaturalScrolling" "true"
    Option "ClickMethod" "clickfinger"
    Option "TappingButtonMap" "lrm"
    Option "ScrollMethod" "twofinger"
    Option "HorizontalScrolling" "true"
EndSection
EOF

### Lid Switch Configuration
# Configure logind for lid switch
# We use a drop-in file for systemd-logind
mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/lid-switch.conf <<EOF
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
EOF
