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
  local -A EXTRA_FONTS=(
    # Nerd Fonts - When name is correct, URL is not needed
    ['JetBrainsMono']=""
    ['FiraCode']=""
    ['NerdFontsSymbolsOnly']=""

    # From URL
    ['Fira-Sans']="https://raw.githubusercontent.com/mozilla/Fira/refs/heads/master/ttf/FiraSans-Regular.ttf"
  )

  if [[ ${#EXTRA_FONTS[@]} -gt 0 ]]; then
    local FONTS_DIR="/usr/share/fonts"
    local TMP_DIR="/tmp/extra_fonts"
    local nf_repo="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
    local font_name font_url url_file font_file font_dest font_tmpd
    
    for font_name in "${!EXTRA_FONTS[@]}"; do
      font_url="${EXTRA_FONTS[$font_name]}"
      font_name=${font_name// /} # remove spaces
      font_dest="${FONTS_DIR}/${font_name}"
      font_tmpd="${TMP_DIR}/${font_name}"
      [[ -z "$font_url" ]] && {
        font_url="${nf_repo}/${font_name}.tar.xz"
        font_dest="${FONTS_DIR}/nerd-fonts/${font_name}"
      }
      url_file="$(basename "$font_url")"

      log "INFO" "Adding font(s): ${font_name}"
      log "INFO" "From URL: ${font_url}"

      mkdir -vp "$font_tmpd" "$font_dest"
      case "$font_url" in
      *.zip | *.7z | *.rar | *.tar.* | *.tar | *.tbz | *.tbz2 | *.tgz | *.tlz | *.txz | *.tzst)
        curl_get "${TMP_DIR}/${url_file}" "$font_url"
        unarchive "${TMP_DIR}/${url_file}" "$font_tmpd"
        ;;
      *.otf | *.ttf)
        curl_get "${font_tmpd}/${url_file}" "$font_url"
        ;;
      *.git)
        git clone --depth 1 "$font_url" "$font_tmpd"
        ;;
      *)
        err "Unsupported URL: ${font_url}" && continue
        ;;
      esac
      find "$font_tmpd" -type f \( -name "*.otf" -o -name "*.ttf" \) \
        -exec cp -vf {} "$font_dest"/ \;
    done
    rm -rf "$TMP_DIR"

    log "INFO" "External fonts installed"
  fi

  # Set proper permissions
  if [[ -d "$FONTS_DIR" ]]; then
    find "$FONTS_DIR" -type d -exec chmod 755 {} + || true
    find "$FONTS_DIR" -type f -exec chmod 644 {} + || true
  fi
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
