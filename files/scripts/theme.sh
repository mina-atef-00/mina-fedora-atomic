#!/usr/bin/env bash
set -oue pipefail

source "/ctx/files/scripts/lib.sh"

log_init

start_phase "Cleanup"

log "INFO" "Theming & Fonts..."

# Install RPM font packages
log "INFO" "Installing font packages..."
FONT_PKGS=(
  # System fonts
  "google-noto-sans-vf-fonts"
  "google-noto-serif-vf-fonts"
  "google-noto-sans-mono-vf-fonts"
  "google-noto-emoji-color-fonts"
  "jetbrains-mono-fonts"
  "fira-code-fonts"
  "rsms-inter-fonts"
  "google-noto-serif-cjk-fonts"
  "google-roboto-slab-fonts"
  "terminus-fonts"
  "adobe-source-code-pro-fonts"

  # CJK support
  "google-noto-cjk-fonts"
  "google-noto-sans-cjk-vf-fonts"
)

dnf_install_quiet "${FONT_PKGS[@]}"

# Install external fonts (Nerd Fonts, etc.)
log "INFO" "Installing external fonts..."

install_external_fonts() {
  local FONTS_DIR="/usr/share/fonts"
  local TMP_DIR="/tmp/extra_fonts"
  local NERD_FONTS_REPO="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
  local -A EXTRA_FONTS=(
    ['JetBrainsMono']=""
    ['FiraCode']=""
    ['NerdFontsSymbolsOnly']=""
    ['Fira-Sans']="https://raw.githubusercontent.com/mozilla/Fira/refs/heads/master/ttf/FiraSans-Regular.ttf"
  )

  [[ ${#EXTRA_FONTS[@]} -eq 0 ]] && return 0

  for font_name in "${!EXTRA_FONTS[@]}"; do
    local font_url="${EXTRA_FONTS[$font_name]}"
    font_name="${font_name// /}"

    local dest_dir temp_dir
    if [[ -z "$font_url" ]]; then
      font_url="${NERD_FONTS_REPO}/${font_name}.tar.xz"
      dest_dir="${FONTS_DIR}/nerd-fonts/${font_name}"
    else
      dest_dir="${FONTS_DIR}/${font_name}"
    fi
    temp_dir="${TMP_DIR}/${font_name}"

    log "INFO" "Installing font: ${font_name}"

    mkdir -p "$temp_dir" "$dest_dir"

    local archive
    archive="$(basename "$font_url")"

    case "$font_url" in
      *.tar.* | *.zip | *.7z)
        curl_get "${TMP_DIR}/${archive}" "$font_url"
        unarchive "${TMP_DIR}/${archive}" "$temp_dir"
        ;;
      *.otf | *.ttf)
        curl_get "${temp_dir}/${archive}" "$font_url"
        ;;
      *.git)
        git clone --depth 1 "$font_url" "$temp_dir"
        ;;
      *)
        err "Unsupported URL: ${font_url}" && continue
        ;;
    esac

    find "$temp_dir" -type f \( -name "*.otf" -o -name "*.ttf" \) \
      -exec cp -vf {} "$dest_dir"/ \;
  done

  rm -rf "$TMP_DIR"

  [[ -d "$FONTS_DIR" ]] && {
    find "$FONTS_DIR" -type d -exec chmod 755 {} + 2>/dev/null || true
    find "$FONTS_DIR" -type f -exec chmod 644 {} + 2>/dev/null || true
  }

  log "INFO" "External fonts installed"
}

# Install Microsoft fonts
install_ms_fonts() {
  log "INFO" "Installing Microsoft fonts..."

  local ms_fonts_rpm_url="https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm"
  rpm -i --nodigest --nosignature "$ms_fonts_rpm_url" || {
    log "WARN" "Failed to install msttcore-fonts-installer"
  }
}

# Apply Papirus icon theme colors
change_papirus_folders_colors() {
  log "INFO" "Configuring Papirus Icon Theme..."

  # Install the tool from source
  local TMP_DIR="/tmp/papirus-folders"
  rm -rf "$TMP_DIR"
  log "INFO" "Cloning papirus-folders tool..."
  git clone --depth 1 https://github.com/PapirusDevelopmentTeam/papirus-folders.git "$TMP_DIR"

  # Install the script to /usr/bin
  chmod +x "${TMP_DIR}/papirus-folders"
  cp "${TMP_DIR}/papirus-folders" /usr/bin/

  # Apply the color
  if [ -d "/usr/share/icons/Papirus" ]; then
    log "INFO" "Applying $1 color to Papirus theme..."
    papirus-folders -C "$1"
  else
    log "WARN" "Papirus icon theme not found. Skipping coloring."
  fi

  rm -rf "$TMP_DIR"
  log "INFO" "Papirus folder colors updated to $1."
}

# Execute font installations
install_external_fonts
install_ms_fonts

# Configure font defaults
mkdir -p /etc/fonts/conf.d
cat > /etc/fonts/local.conf <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Default sans-serif font -->
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Sans</family>
    </prefer>
  </alias>

  <!-- Default serif font -->
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif</family>
    </prefer>
  </alias>

  <!-- Default monospace font -->
  <alias>
    <family>monospace</family>
    <prefer>
      <family>JetBrains Mono</family>
      <family>Fira Code</family>
    </prefer>
  </alias>
</fontconfig>
EOF

# Create themes directory structure
mkdir -p /usr/share/themes
mkdir -p /usr/share/icons
mkdir -p /etc/skel/.config

# Apply any custom themes from context
if [ -d "/ctx/files/themes" ]; then
  log "INFO" "Installing custom themes..."
  cp -r /ctx/files/themes/* /usr/share/themes/ 2>/dev/null || true
fi

if [ -d "/ctx/files/icons" ]; then
  log "INFO" "Installing custom icons..."
  cp -r /ctx/files/icons/* /usr/share/icons/ 2>/dev/null || true
fi

# Apply Papirus folder colors
change_papirus_folders_colors "violet"

# Update font cache
log "INFO" "Building font cache..."
fc-cache --system-only --really-force /usr/share/fonts

# Update icon cache
if command -v gtk-update-icon-cache &>/dev/null; then
  for theme in /usr/share/icons/*/; do
    if [ -f "${theme}index.theme" ]; then
      gtk-update-icon-cache -f -t "${theme}" || true
    fi
  done
fi

# Set default GTK4 theme (gtk-3.0 settings already in files/system)
mkdir -p /etc/skel/.config/gtk-4.0
cat > /etc/skel/.config/gtk-4.0/settings.ini <<EOF
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Breeze_Snow
EOF

# Cleanup DNF
log "INFO" "Cleaning up DNF cache..."
dnf5 clean all

log "INFO" "Theming: Complete"

end_phase
