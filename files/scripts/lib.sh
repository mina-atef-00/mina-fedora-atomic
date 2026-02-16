#!/usr/bin/env bash

# Color formatting
declare -r green=$'\033[32m'
declare -r yellow=$'\033[33m'
declare -r red=$'\033[31m'
declare -r cyan=$'\033[36m'
declare -r bold=$'\033[1m'
declare -r noc=$'\033[0m'

# Default Verbosity
QUIET=false
VERBOSE=1  # Reduced from 2 to suppress DEBUG logs

# Logging function
log() {
  # Fix SC2124: Use "${*:2}" to concatenate arguments 2-N into a single string
  local level="${1}"
  local msg="${*:2}"
  local color=""
  local datetime=""

  # Fix SC2155: Separate declaration from logic to avoid masking return codes
  if [[ ${VERBOSE} -ge 2 ]]; then
    datetime="$(date '+[%Y-%m-%d %H:%M:%S] ')"
  fi

  case "${level^^}" in
  "DEBUG")
    color=${cyan}
    # Only print debug if Verbose is high and not Quiet
    [[ ${QUIET} == "false" && ${VERBOSE} -ge 2 ]] || return 0
    ;;
  "INFO")
    color=${green}
    [[ ${QUIET} == "false" ]] || return 0
    ;;
  "WARN")
    color=${yellow}
    [[ ${QUIET} == "false" ]] || return 0
    ;;
  "ERROR")
    color=${red}
    ;;
  *)
    color=${noc}
    ;;
  esac

  # Print to stderr to avoid polluting pipe outputs, or stdout if preferred
  echo -e "${bold}${datetime}${color}[${level^^}]${noc} ${msg}"
}

# Visual section header
section() {
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "  $1"
  echo "═══════════════════════════════════════════════════════════════"
}

# Quiet DNF install - suppresses progress spam but keeps errors
dnf_install_quiet() {
  dnf5 install -y "$@" --quiet 2>&1 | grep -v "^\[\|Installing:\|Installing dependencies:\|Transaction Summary:\|^Total size\|^After this operation\|^Running transaction\|^Complete!\|Verify package\|Prepare transaction" || true
}

# Quiet COPR enable - suppresses warning spam
copr_enable_quiet() {
  dnf5 -y copr enable "$1" 2>&1 | grep -v "Please note\|quality may vary\|Fedora Project\|Bugzilla\|documentation.html\|owner of this repository\|Be aware that\|content. Please review\|These repositories are being" || true
}

# Error handler
die() {
  log "ERROR" "${1}"
  exit 1
}

err() {
  log "ERROR" "${1}"
  return 1
}

curl_fetch() { curl -fsS -X GET --retry 5 "${1}"; }

curl_get() {
  if [[ ! $# -eq 2 ]]; then
    { err "Specify local file path and URL"; } 2>/dev/null
    return 1
  fi
  curl -fLsS --retry 5 "${2}" -o "${1}"
}

unarchive() {
  local archive="${1}" dest="${2}"
  if [[ ! $# -eq 2 ]]; then
    { err "Specify paths to archive and destination"; } 2>/dev/null
    return 1
  fi

  [[ ! -d "$dest" ]] && mkdir "${VERBOSE:+-v}" -p "$dest"

  case "$archive" in
  *.zip)
    { log "DEBUG" "Extracting ZIP archive in: ${dest}"; } 2>/dev/null
    unzip "$archive" -d "$dest"
    ;;
  *.7z)
    { log "DEBUG" "Extracting 7-ZIP archive in: ${dest}"; } 2>/dev/null
    7z x -o"$dest" "$archive"
    ;;
  *.tar.* | *.tar | *.tbz | *.tbz2 | *.tgz | *.tlz | *.txz | *.tzst)
    { log "DEBUG" "Extracting TAR archive in: ${dest}"; } 2>/dev/null
    tar "${VERBOSE:+-v}" -xf "$archive" -C "$dest"
    ;;
  *.rar)
    { log "DEBUG" "Extracting RAR archive in: ${dest}"; } 2>/dev/null
    cd "$dest" || return 1
    unrar x "$archive"
    cd - || return 1
    ;;
  *)
    err "Unknown archive file: ${archive}" && return 1
    ;;
  esac
}
