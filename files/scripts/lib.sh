#!/usr/bin/env bash
#
# lib.sh - Gum-based logging library for bootc image builds
#
# Usage: source this file, then call log_init() before using logging functions.
#
# Environment Variables:
#   GUM_LOG_LEVEL  - Log verbosity: debug, info (default), warn, error
#   GUM_LOG_FORMAT - Output format: text (default), json
#   GUM_NO_EMOJI   - Set to disable emojis (useful for non-Unicode CI environments)
#
# Example:
#   source lib.sh
#   log_init
#   print_header "my-image" "asus" "ghcr.io/base:latest"
#   start_phase "Installing packages"
#   log_check "Package installed"
#   end_phase
#   print_footer "success" "5m" "4GB" "9" "500" "10" "latest"
#

set -euo pipefail

declare -g GUM_LOG_LEVEL=""
declare -g GUM_LOG_FORMAT=""
declare -g GUM_NO_EMOJI="${GUM_NO_EMOJI:-}"
declare -g _GUM_AVAILABLE=""
declare -g _PHASE_COUNT=0
declare -g _PHASE_TOTAL=8  # Default to 8 phases per PRD; use set_phase_total() to change
declare -g _PHASE_START_TIME=""
declare -g _BUILD_START_TIME=""
declare -g _CURRENT_PHASE="${_CURRENT_PHASE:-unknown}"
declare -g _CURRENT_STEP="${_CURRENT_STEP:-unknown}"
declare -g _ERROR_START_TIME=""
declare -A _WARNING_COUNTS=()
declare -g _COMPLETE_COUNT=0
declare -g _VERBOSE_MODE=""
declare -g _CURRENT_PHASE_NAME=""

declare -r COLOR_DEBUG="#6B7280"
declare -r COLOR_INFO="#3B82F6"
declare -r COLOR_WARN="#F59E0B"
declare -r COLOR_ERROR="#EF4444"
declare -r COLOR_SUCCESS="#10B981"
declare -r COLOR_HEADER="#8B5CF6"
declare -r COLOR_GOLD="#FBBF24"
declare -r COLOR_WHITE="#E5E7EB"
declare -r COLOR_DIM="#9CA3AF"

declare -r ANSI_GREEN=$'\033[32m'
declare -r ANSI_YELLOW=$'\033[33m'
declare -r ANSI_RED=$'\033[31m'
declare -r ANSI_GRAY=$'\033[90m'    # Approximation of #6B7280 (dark terminal optimized)
declare -r ANSI_BLUE=$'\033[34m'     # Approximation of #3B82F6
declare -r ANSI_BOLD=$'\033[1m'
declare -r ANSI_RESET=$'\033[0m'

_is_json_mode() {
    [[ "$GUM_LOG_FORMAT" == "json" ]]
}

_is_ci_environment() {
    [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ "${CI:-}" == "true" ]]
}

_json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

_json_escape_string() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

_get_iso_timestamp() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

output_json() {
    local level="$1"
    local msg
    msg=$(_json_escape_string "$2")
    local metadata="${3:-}"
    
    local timestamp
    timestamp=$(_get_iso_timestamp)
    
    local json_line="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$msg\""
    
    if [[ -n "$metadata" ]]; then
        json_line+=",\"metadata\":$metadata"
    fi
    
    json_line+="}"
    
    echo "$json_line"
}

_output_json_phase() {
    local phase_num="$1"
    local phase_name
    phase_name=$(_json_escape_string "$2")
    
    local metadata="{\"phase\":$phase_num,\"phase_name\":\"$phase_name\"}"
    output_json "info" "Phase started: $phase_name" "$metadata"
}

_output_json_error() {
    local error_msg
    error_msg=$(_json_escape_string "$1")
    local suggested_fixes="${2:-}"
    local file="${3:-}"
    local line="${4:-}"
    
    local phase_name
    phase_name=$(_json_escape_string "${_CURRENT_PHASE_NAME:-$_CURRENT_PHASE}")
    
    local metadata="{\"phase\":$_PHASE_COUNT,\"phase_name\":\"$phase_name\""
    
    if [[ -n "$suggested_fixes" ]]; then
        local fixes_json="["
        local first=true
        while IFS= read -r fix; do
            [[ -z "$fix" ]] && continue
            local escaped_fix
            escaped_fix=$(_json_escape_string "$fix")
            [[ "$first" != "true" ]] && fixes_json+=","
            fixes_json+="\"$escaped_fix\""
            first=false
        done <<< "$suggested_fixes"
        fixes_json+="]"
        metadata+=",\"suggested_fixes\":$fixes_json"
    fi
    
    if [[ -n "$file" ]]; then
        metadata+=",\"file\":\"$file\""
    fi
    
    if [[ -n "$line" ]]; then
        metadata+=",\"line\":$line"
    fi
    
    metadata+="}"
    
    output_json "error" "$error_msg" "$metadata"
}

log_init() {
    GUM_LOG_LEVEL="${GUM_LOG_LEVEL:-info}"
    GUM_LOG_FORMAT="${GUM_LOG_FORMAT:-text}"
    : "${_BUILD_START_TIME:=$(date +%s)}"
    case "$GUM_LOG_LEVEL" in
        debug|info|warn|error) ;;
        *) GUM_LOG_LEVEL="info" ;;
    esac
    if [[ "$GUM_LOG_LEVEL" == "debug" ]]; then
        _VERBOSE_MODE="true"
    fi
}

_log_level_num() {
    case "$1" in
        debug) echo 0 ;;
        info)  echo 1 ;;
        warn)  echo 2 ;;
        error) echo 3 ;;
        *)     echo 1 ;;
    esac
}

gum_available() {
    if [[ -z "$_GUM_AVAILABLE" ]]; then
        if command -v gum &>/dev/null; then
            _GUM_AVAILABLE="true"
        else
            _GUM_AVAILABLE="false"
        fi
    fi
    [[ "$_GUM_AVAILABLE" == "true" ]]
}

_should_log() {
    local level="$1"
    local current_level
    local msg_level
    
    current_level="$(_log_level_num "$GUM_LOG_LEVEL")"
    msg_level="$(_log_level_num "$level")"
    
    [[ $msg_level -ge $current_level ]]
}

_emit_github_annotation() {
    local level="$1"
    local msg="$2"
    local file="${3:-Containerfile}"
    local line="${4:-1}"
    
    if _is_ci_environment; then
        case "$level" in
            error)   echo "::error file=$file,line=$line::$msg" ;;
            warn)    echo "::warning file=$file,line=$line::$msg" ;;
            debug)   echo "::debug::$msg" ;;
            info)    echo "::notice::$msg" ;;
            success) echo "::notice::$msg" ;;
        esac
    fi
}

log() {
    local level="${1}"
    local msg="${*:2}"
    
    _should_log "$level" || return 0
    
    if _is_json_mode; then
        output_json "$level" "$msg"
    elif gum_available; then
        _log_gum "$level" "$msg"
    else
        _log_echo "$level" "$msg"
    fi
    
    _emit_github_annotation "$level" "$msg"
}

_log_gum() {
    local level="$1"
    local msg="$2"
    local color=""
    local prefix=""
    local bold=""
    
    if [[ -n "$GUM_NO_EMOJI" ]]; then
        case "$level" in
            debug)  color="$COLOR_DEBUG" ;;
            info)   color="$COLOR_INFO" ;;
            warn)   color="$COLOR_WARN" ;;
            error)  color="$COLOR_ERROR"; bold="--bold" ;;
            success) color="$COLOR_SUCCESS"; bold="--bold" ;;
        esac
    else
        case "$level" in
            debug)  color="$COLOR_DEBUG"; prefix="" ;;
            info)   color="$COLOR_INFO";  prefix="ℹ️ " ;;
            warn)   color="$COLOR_WARN";  prefix="⚠️ " ;;
            error)  color="$COLOR_ERROR"; prefix="❌ "; bold="--bold" ;;
            success) color="$COLOR_SUCCESS"; prefix="✅ "; bold="--bold" ;;
        esac
    fi
    
    if [[ -n "$bold" ]]; then
        echo "${prefix}$(gum style --foreground "$color" $bold "$msg")"
    else
        echo "${prefix}$(gum style --foreground "$color" "$msg")"
    fi
}

_log_echo() {
    local level="$1"
    local msg="$2"
    local color=""
    local bold=""
    
    case "$level" in
        debug)  color="$ANSI_GRAY" ;;
        info)   color="$ANSI_BLUE" ;;
        warn)   color="$ANSI_YELLOW" ;;
        error)  color="$ANSI_RED"; bold="$ANSI_BOLD" ;;
        success) color="$ANSI_GREEN"; bold="$ANSI_BOLD" ;;
    esac
    
    if [[ -n "$GUM_NO_EMOJI" ]]; then
        echo -e "${color}${bold}[${level^^}]${ANSI_RESET} ${msg}"
    else
        local prefix=""
        case "$level" in
            debug)  prefix="" ;;
            info)   prefix="ℹ️ " ;;
            warn)   prefix="⚠️ " ;;
            error)  prefix="❌ " ;;
            success) prefix="✅ " ;;
        esac
        echo -e "${prefix}${color}${bold}${msg}${ANSI_RESET}"
    fi
}

log_debug() {
    log "debug" "$*"
}

log_info() {
    log "info" "$*"
}

log_warn() {
    log "warn" "$*"
}

log_error() {
    if [[ $# -gt 1 ]]; then
        local error_msg="$1"
        local suggested_fixes="$2"
        local file="${3:-Containerfile}"
        local line="${4:-1}"
        display_error_block "$error_msg" "$suggested_fixes" "$file" "$line"
    else
        log "error" "$*"
    fi
}

log_success() {
    log "success" "$*"
}

log_item() {
    local icon="${1:-✅}"
    local msg="${2:-}"
    local indent="${3:-1}"
    local color="${4:-}"
    
    local spaces=""
    case "$indent" in
        1) spaces="  " ;;
        2) spaces="    " ;;
        3) spaces="      " ;;
        *) spaces="  " ;;
    esac
    
    if gum_available; then
        if [[ -n "$color" ]]; then
            echo "${spaces}${icon} $(gum style --foreground "$color" "$msg")"
        else
            echo "${spaces}${icon} ${msg}"
        fi
    else
        echo "${spaces}${icon} ${msg}"
    fi
}

log_detail() {
    log_item "→" "$@" 2 "$COLOR_WHITE"
}

log_subdetail() {
    log_item "•" "$@" 3 "$COLOR_DIM"
}

log_check() {
    log_item "✅" "$@" 1 "$COLOR_SUCCESS"
}

print_header() {
    local image_name="${1:-mina-fedora-atomic}"
    local profile="${2:-default}"
    local base_ref="${3:-ghcr.io/ublue-os/base-main:43}"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    echo ""
    if gum_available; then
        gum style --border double --border-foreground "$COLOR_HEADER" --padding "1 2" <<EOF
🚀  BUILD STARTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$(gum style --foreground "$COLOR_DIM" "Image:")    $image_name
$(gum style --foreground "$COLOR_DIM" "Profile:")  $profile
$(gum style --foreground "$COLOR_DIM" "Base:")     $base_ref
$(gum style --foreground "$COLOR_DIM" "Started:")  $(gum style --foreground "$COLOR_GOLD" "⏱️ $timestamp")
EOF
    else
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║                                                                ║"
        echo "║   🚀  BUILD STARTED                                           ║"
        echo "║   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   ║"
        echo "║                                                                ║"
        echo "║   Image:    $image_name"
        echo "║   Profile:  $profile"
        echo "║   Base:     $base_ref"
        echo "║   Started:  ⏱️ $timestamp"
        echo "║                                                                ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
    fi
    echo ""
}

print_footer() {
    local status="${1:-success}"
    local duration="${2:-0s}"
    local image_size="${3:-unknown}"
    local layers="${4:-0}"
    local packages_installed="${5:-0}"
    local packages_removed="${6:-0}"
    local tags="${7:-}"
    
    local emoji border_color status_text
    
    if [[ "$status" == "success" ]]; then
        emoji="✅"
        border_color="$COLOR_SUCCESS"
        status_text="BUILD SUCCESSFUL"
    else
        emoji="❌"
        border_color="$COLOR_ERROR"
        status_text="BUILD FAILED"
    fi
    
    echo ""
    if gum_available; then
        local tags_content=""
        if [[ -n "$tags" ]]; then
            tags_content=$'\n'"🏷️  Tags:"
            while IFS= read -r tag; do
                [[ -n "$tag" ]] && tags_content+=$'\n'"  → $tag"
            done <<< "$tags"
        fi
        
        gum style --border double --border-foreground "$border_color" --padding "1 2" <<EOF
${emoji}  ${status_text}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$(gum style --foreground "$COLOR_DIM" "Duration:")     $(gum style --foreground "$COLOR_GOLD" "⏱️ $duration")
$(gum style --foreground "$COLOR_DIM" "Image Size:")   $image_size
$(gum style --foreground "$COLOR_DIM" "Layers:")       $layers
$(gum style --foreground "$COLOR_DIM" "Packages:")     $packages_installed installed, $packages_removed removed${tags_content}
EOF
    else
        local border_char="═"
        echo "╔${border_char}════════════════════════════════════════════════════════════════${border_char}╗"
        echo "║                                                                ║"
        echo "║   ${emoji}  ${status_text}                                          ║"
        echo "║   ${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}   ║"
        echo "║                                                                ║"
        echo "║   Duration:     ⏱️ $duration"
        echo "║   Image Size:   $image_size"
        echo "║   Layers:       $layers"
        echo "║   Packages:     $packages_installed installed, $packages_removed removed"
        if [[ -n "$tags" ]]; then
            echo "║                                                                ║"
            echo "║   🏷️  Tags:"
            while IFS= read -r tag; do
                [[ -n "$tag" ]] && echo "║   → $tag"
            done <<< "$tags"
        fi
        echo "║                                                                ║"
        echo "╚${border_char}════════════════════════════════════════════════════════════════${border_char}╝"
    fi
    echo ""
}

set_phase_total() {
    local total="${1:-8}"
    _PHASE_TOTAL="$total"
}

start_phase() {
    local phase_name="${1:-Phase}"
    ((_PHASE_COUNT++)) || true
    _PHASE_START_TIME="$(date +%s)"
    _CURRENT_PHASE_NAME="$phase_name"
    
    if _is_json_mode; then
        _output_json_phase "$_PHASE_COUNT" "$phase_name"
        return
    fi
    
    echo ""
    if gum_available; then
        local phase_text="▶️ Phase ${_PHASE_COUNT}/${_PHASE_TOTAL}: ${phase_name}"
        gum style --border rounded --border-foreground "$COLOR_INFO" --padding "0 1" "$phase_text"
    else
        echo "▶️ Phase ${_PHASE_COUNT}/${_PHASE_TOTAL}: ${phase_name}"
    fi
    echo ""
}

end_phase() {
    local end_time duration
    
    end_time="$(date +%s)"
    duration=$((end_time - _PHASE_START_TIME))
    
    if _is_json_mode; then
        local phase_name
        phase_name=$(_json_escape_string "$_CURRENT_PHASE_NAME")
        local metadata="{\"phase\":$_PHASE_COUNT,\"phase_name\":\"$phase_name\",\"duration_seconds\":$duration}"
        output_json "info" "Phase complete: $phase_name" "$metadata"
        return
    fi
    
    if gum_available; then
        echo "  ✅ Phase complete in $(gum style --foreground "$COLOR_GOLD" "⏱️ ${duration}s")"
    else
        echo "  ✅ Phase complete in ⏱️ ${duration}s"
    fi
    echo ""
}

get_build_duration() {
    local end_time duration
    
    end_time="$(date +%s)"
    duration=$((end_time - _BUILD_START_TIME))
    
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    if [[ $minutes -gt 0 ]]; then
        echo "${minutes}m ${seconds}s"
    else
        echo "${seconds}s"
    fi
}

die() {
    log "error" "$*"
    exit 1
}

err() {
    log "error" "$*"
    return 1
}

section() {
    local title="${1:-Section}"
    echo ""
    if gum_available; then
        gum style --border normal --border-foreground "$COLOR_HEADER" --padding "0 2" "$title"
    else
        echo "═══════════════════════════════════════════════════════════════"
        echo "  $title"
        echo "═══════════════════════════════════════════════════════════════"
    fi
}

dnf_install_quiet() {
    local output
    local exit_code
    
    output=$(dnf5 install -y "$@" --quiet 2>&1) || true
    exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo "$output" | filter_dnf_output
        return $exit_code
    fi
    
    echo "$output" | filter_dnf_output
}

copr_enable_quiet() {
    dnf5 -y copr enable "$1" 2>&1 | grep -v "Please note\|quality may vary\|Fedora Project\|Bugzilla\|documentation.html\|owner of this repository\|Be aware that\|content. Please review\|These repositories are being" || true
}

filter_dnf_output() {
    local line
    local complete_shown=0
    _COMPLETE_COUNT=0
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^\[ ]]; then
            continue
        fi
        if [[ "$line" == *"Copying blob"* ]]; then
            continue
        fi
        if [[ "$line" == *"Writing manifest"* ]]; then
            continue
        fi
        if [[ "$line" =~ ^[0-9]+%\ \| ]]; then
            continue
        fi
        if [[ "$line" == *"KiB/s"* ]]; then
            continue
        fi
        if [[ "$line" == *"Complete!"* ]]; then
            ((_COMPLETE_COUNT++)) || true
            if [[ $complete_shown -eq 0 ]]; then
                echo "$line"
                complete_shown=1
            fi
            continue
        fi
        echo "$line"
    done
    
    if [[ $_COMPLETE_COUNT -gt 1 ]]; then
        log_item "✅" "$((_COMPLETE_COUNT - 1)) additional completions suppressed" 1
    fi
}

set_phase_context() {
    _CURRENT_PHASE="${1:-unknown}"
    _ERROR_START_TIME="$(date +%s)"
}

set_step_context() {
    _CURRENT_STEP="${1:-unknown}"
}

_warning_key() {
    echo "$1" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]'
}

track_warning() {
    local msg="$1"
    local key
    key="$(_warning_key "$msg")"
    
    if [[ -n "${_VERBOSE_MODE:-}" ]]; then
        log_warn "$msg"
        ((_WARNING_COUNTS[$key]++)) || true
    elif [[ -z "${_WARNING_COUNTS[$key]:-}" ]]; then
        _WARNING_COUNTS[$key]=1
        log_warn "$msg"
    else
        ((_WARNING_COUNTS[$key]++)) || true
    fi
}

reset_warnings() {
    _WARNING_COUNTS=()
}

emit_warning_summary() {
    if [[ -n "${_VERBOSE_MODE:-}" ]]; then
        return 0
    fi
    
    local key count
    for key in "${!_WARNING_COUNTS[@]}"; do
        count="${_WARNING_COUNTS[$key]}"
        if [[ $count -gt 1 ]]; then
            log_item "⚠️" "$((_WARNING_COUNTS[$key] - 1)) similar warnings suppressed (use --verbose to see all)" 1
        fi
    done
}

_display_github_error() {
    local msg="$1"
    local file="${2:-Containerfile}"
    local line="${3:-1}"
    
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "::error file=$file,line=$line::$msg"
    fi
}

_display_github_warning() {
    local msg="$1"
    local file="${2:-Containerfile}"
    local line="${3:-1}"
    
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "::warning file=$file,line=$line::$msg"
    fi
}

display_error_block() {
    local error_msg="${1:-An error occurred}"
    local suggested_fixes="${2:-}"
    local file="${3:-Containerfile}"
    local line="${4:-1}"
    
    local end_time duration
    end_time="$(date +%s)"
    if [[ -n "${_ERROR_START_TIME:-}" ]]; then
        duration=$((end_time - _ERROR_START_TIME))
    else
        duration=0
    fi
    
    if _is_json_mode; then
        _output_json_error "$error_msg" "$suggested_fixes" "$file" "$line"
        _emit_github_annotation "error" "$error_msg" "$file" "$line"
        return
    fi
    
    local duration_str
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    if [[ $minutes -gt 0 ]]; then
        duration_str="${minutes}m ${seconds}s"
    else
        duration_str="${seconds}s"
    fi
    
    _emit_github_annotation "error" "$error_msg" "$file" "$line"
    
    echo ""
    if gum_available; then
        local fixes_content=""
        if [[ -n "$suggested_fixes" ]]; then
            fixes_content=$'\n'"$(gum style --foreground "$COLOR_DIM" "Suggested Fixes:")"
            while IFS= read -r fix; do
                [[ -n "$fix" ]] && fixes_content+=$'\n'"  → $fix"
            done <<< "$suggested_fixes"
        fi
        
        gum style --border normal --border-foreground "$COLOR_ERROR" --padding "1 2" <<EOF
$(gum style --foreground "$COLOR_ERROR" --bold "❌  ERROR")
$(gum style --foreground "$COLOR_ERROR" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

$(gum style --foreground "$COLOR_DIM" "Phase:")    $_CURRENT_PHASE
$(gum style --foreground "$COLOR_DIM" "Step:")     $_CURRENT_STEP
$(gum style --foreground "$COLOR_DIM" "Duration:") $(gum style --foreground "$COLOR_GOLD" "⏱️ $duration_str")

$(gum style --foreground "$COLOR_ERROR" --bold "Error: $error_msg")${fixes_content}
EOF
    else
        echo "┌─────────────────────────────────────────┐"
        echo "│                                         │"
        echo "│   ❌  ERROR                             │"
        echo "│   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │"
        echo "│                                         │"
        echo "│   Phase:    $_CURRENT_PHASE"
        echo "│   Step:     $_CURRENT_STEP"
        echo "│   Duration: ⏱️ $duration_str"
        echo "│                                         │"
        echo "│   Error: $error_msg"
        if [[ -n "$suggested_fixes" ]]; then
            echo "│                                         │"
            echo "│   Suggested Fixes:"
            while IFS= read -r fix; do
                [[ -n "$fix" ]] && echo "│   → $fix"
            done <<< "$suggested_fixes"
        fi
        echo "│                                         │"
        echo "└─────────────────────────────────────────┘"
    fi
    echo ""
}

curl_fetch() { curl -fsS -X GET --retry 5 "${1}"; }

curl_get() {
    if [[ ! $# -eq 2 ]]; then
        err "Specify local file path and URL"
        return 1
    fi
    curl -fLsS --retry 5 "${2}" -o "${1}"
}

unarchive() {
    local archive="${1}" dest="${2}"
    if [[ ! $# -eq 2 ]]; then
        err "Specify paths to archive and destination"
        return 1
    fi

    [[ ! -d "$dest" ]] && mkdir -p "$dest"

    case "$archive" in
        *.zip)
            log_debug "Extracting ZIP archive in: ${dest}"
            unzip "$archive" -d "$dest"
            ;;
        *.7z)
            log_debug "Extracting 7-ZIP archive in: ${dest}"
            7z x -o"$dest" "$archive"
            ;;
        *.tar.* | *.tar | *.tbz | *.tbz2 | *.tgz | *.tlz | *.txz | *.tzst)
            log_debug "Extracting TAR archive in: ${dest}"
            tar -xf "$archive" -C "$dest"
            ;;
        *.rar)
            log_debug "Extracting RAR archive in: ${dest}"
            cd "$dest" || return 1
            unrar x "$archive"
            cd - || return 1
            ;;
        *)
            err "Unknown archive file: ${archive}" && return 1
            ;;
    esac
}
