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
VERBOSE=2

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

# Error handler
die() {
  log "ERROR" "${1}"
  exit 1
}
