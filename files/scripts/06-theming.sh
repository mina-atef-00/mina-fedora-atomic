#!/usr/bin/env bash
set -oue pipefail
source "${SCRIPTS_DIR}/lib.sh"

log "INFO" "Installing themes..."

log "INFO" "Installing RPM fonts..."
# RPM Fonts
dnf5 install -y \
  "jetbrains-mono-fonts" \
  "rsms-inter-fonts" \
  "fira-code-fonts" \
  "google-noto-serif-cjk-fonts" \
  "google-roboto-slab-fonts" \
  "terminus-fonts"

log "INFO" "Installing external fonts..."

install_external_fonts() {
  log "INFO" "Defining Fonts"
  local -A EXTRA_FONTS=(
    # Nerd Fonts
    # When Nerd Font name is correct, URL is not needed
    ['JetBrainsMono']=
    ['FiraCode']=
    ['NerdFontsSymbolsOnly']=

    # From URL
    ['Fira-Sans']="\
    https://raw.githubusercontent.com/mozilla/Fira/refs/heads/master/ttf/FiraSans-Regular.ttf"
  )

  if [[ ${#EXTRA_FONTS[@]} -gt 0 ]]; then
    log "INFO" "Installing Extra Font(s)"
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
        err "Unsupported URL: ${font_url}" && return 1
        ;;
      esac
      find "$font_tmpd" -type f \( -name "*.otf" -o -name "*.ttf" \) \
        -exec cp -vf {} "$font_dest"/ \;
    done
    rm -rf "$TMP_DIR"
    log "INFO" "Extra Font(s) installed"
  fi

  log "INFO" "Building font cache"
  # Permit global fonts to be used by all users
  # Directories: 755, Files: 644
  if [[ -d "$FONTS_DIR" ]]; then
    find "$FONTS_DIR" -type d -exec chmod 755 {} + || true
    find "$FONTS_DIR" -type f -exec chmod 644 {} + || true
  fi

  fc-cache --system-only --really-force "$FONTS_DIR"
  log "INFO" "Done"
}

dnf5 clean all
