#!/usr/bin/env bash
# Profile Validation Script for Mina's Fedora Atomic
# Validates hardware profile configuration and provides helpful error messages

set -oue pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Valid profiles
VALID_PROFILES=("lnvo" "asus")

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="${SCRIPT_DIR}/../profiles"

# Error counter
ERRORS=0
WARNINGS=0

# ==============================================================================
# Helper Functions
# ==============================================================================

log_error() {
    echo -e "${RED}❌ ERROR:${NC} $1" >&2
    ((ERRORS++))
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1" >&2
    ((WARNINGS++))
}

log_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

show_usage() {
    cat << EOF
Usage: $(basename "$0") [PROFILE]

Validates hardware profile configuration for Mina's Fedora Atomic.

Arguments:
  PROFILE    Hardware profile to validate (lnvo, asus)
             If not provided, validates all profiles

Valid Profiles:
  lnvo       Laptop profile (Lenovo) - Power management, Intel graphics
  asus       Desktop profile (ASUS) - NVIDIA drivers, performance

Examples:
  $(basename "$0")              # Validate all profiles
  $(basename "$0") lnvo        # Validate laptop profile only
  $(basename "$0") asus        # Validate desktop profile only

Exit Codes:
  0          All validations passed
  1          One or more validations failed
  2          Invalid usage or missing arguments

EOF
}

# ==============================================================================
# Validation Functions
# ==============================================================================

validate_profile_name() {
    local profile="$1"
    
    if [[ -z "$profile" ]]; then
        log_error "Profile name is required"
        return 1
    fi
    
    local valid=false
    for valid_profile in "${VALID_PROFILES[@]}"; do
        if [[ "$profile" == "$valid_profile" ]]; then
            valid=true
            break
        fi
    done
    
    if [[ "$valid" == "false" ]]; then
        log_error "Invalid profile: '$profile'"
        log_info "Valid profiles are: ${VALID_PROFILES[*]}"
        log_info ""
        log_info "Did you mean one of these?"
        for valid_profile in "${VALID_PROFILES[@]}"; do
            log_info "  - $valid_profile"
        done
        return 1
    fi
    
    return 0
}

validate_profile_structure() {
    local profile="$1"
    local profile_dir="${PROFILES_DIR}/${profile}"
    
    log_info "Validating profile structure for: $profile"
    
    # Check profile directory exists
    if [[ ! -d "$profile_dir" ]]; then
        log_error "Profile directory not found: $profile_dir"
        return 1
    fi
    
    log_success "Profile directory exists: $profile_dir"
    
    # Check for etc directory
    if [[ ! -d "$profile_dir/etc" ]]; then
        log_warning "No etc/ directory found (optional but recommended)"
    else
        log_success "etc/ directory exists"
    fi
    
    # Check for usr directory
    if [[ ! -d "$profile_dir/usr" ]]; then
        log_warning "No usr/ directory found (optional)"
    else
        log_success "usr/ directory exists"
    fi
    
    return 0
}

validate_lnvo_profile() {
    local profile_dir="${PROFILES_DIR}/lnvo"
    
    log_info "Validating lnvo (laptop) specific configuration..."
    
    # Check TLP configuration
    if [[ ! -f "$profile_dir/etc/tlp.d/00-laptop.conf" ]]; then
        log_error "TLP configuration missing: etc/tlp.d/00-laptop.conf"
        log_info "Laptops require TLP for power management optimization"
    else
        log_success "TLP configuration found"
        
        # Validate TLP config has essential settings
        if grep -q "START_CHARGE_THRESH" "$profile_dir/etc/tlp.d/00-laptop.conf"; then
            log_success "Battery charge thresholds configured"
        fi
    fi
    
    # Check Intel graphics configuration
    if [[ ! -f "$profile_dir/etc/modprobe.d/i915.conf" ]]; then
        log_warning "Intel graphics config missing (optional for non-Intel laptops)"
    else
        log_success "Intel graphics configuration found"
    fi
    
    # Check for sleep/resume hooks
    if [[ -d "$profile_dir/usr/lib/systemd/system-sleep" ]]; then
        log_success "System sleep hooks directory exists"
    fi
}

validate_asus_profile() {
    local profile_dir="${PROFILES_DIR}/asus"
    
    log_info "Validating asus (desktop) specific configuration..."
    
    # Check NVIDIA configuration
    if [[ ! -f "$profile_dir/etc/modprobe.d/nvidia.conf" ]]; then
        log_error "NVIDIA kernel module config missing: etc/modprobe.d/nvidia.conf"
        log_info "Desktop profile requires NVIDIA configuration"
    else
        log_success "NVIDIA kernel module configuration found"
    fi
    
    # Check X11 NVIDIA configuration
    if [[ ! -f "$profile_dir/etc/X11/xorg.conf.d/20-nvidia.conf" ]]; then
        log_warning "X11 NVIDIA config missing (optional if using Wayland only)"
    else
        log_success "X11 NVIDIA configuration found"
    fi
}

validate_profile_scripts() {
    log_info "Validating profile integration in build scripts..."
    
    local layer_script="${SCRIPT_DIR}/layer-07-profile.sh"
    
    if [[ ! -f "$layer_script" ]]; then
        log_error "Layer 7 profile script not found: $layer_script"
        return 1
    fi
    
    log_success "Layer 7 profile script exists"
    
    # Check that script handles both profiles
    if grep -q 'HOST_PROFILE.*asus' "$layer_script"; then
        log_success "Script handles 'asus' profile"
    else
        log_warning "Script may not handle 'asus' profile"
    fi
    
    if grep -q 'HOST_PROFILE.*lnvo' "$layer_script"; then
        log_success "Script handles 'lnvo' profile"
    else
        log_warning "Script may not handle 'lnvo' profile"
    fi
    
    # Check for error handling
    if grep -q 'HOST_PROFILE' "$layer_script"; then
        log_success "Script references HOST_PROFILE variable"
    else
        log_error "Script doesn't reference HOST_PROFILE"
    fi
}

validate_ci_integration() {
    log_info "Validating CI/CD integration..."
    
    local workflow_file="${SCRIPT_DIR}/../../.github/workflows/build.yml"
    
    if [[ ! -f "$workflow_file" ]]; then
        log_warning "CI workflow file not found: $workflow_file"
        return 0
    fi
    
    log_success "CI workflow file exists"
    
    # Check for profile matrix
    if grep -q 'profile:.*\[lnvo, asus\]' "$workflow_file"; then
        log_success "CI has profile matrix for lnvo and asus"
    else
        log_warning "CI may not have profile matrix configured"
    fi
    
    # Check for HOST_PROFILE build arg
    if grep -q 'HOST_PROFILE' "$workflow_file"; then
        log_success "CI passes HOST_PROFILE build argument"
    else
        log_error "CI doesn't pass HOST_PROFILE build argument"
    fi
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
    local target_profile="${1:-}"
    
    echo "=========================================="
    echo "Profile Validation for Mina's Fedora Atomic"
    echo "=========================================="
    echo ""
    
    # Show usage if requested
    if [[ "$target_profile" == "--help" || "$target_profile" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    # If no profile specified, validate all
    if [[ -z "$target_profile" ]]; then
        log_info "No profile specified, validating all profiles..."
        echo ""
        
        for profile in "${VALID_PROFILES[@]}"; do
            validate_profile_name "$profile"
            validate_profile_structure "$profile"
            
            if [[ "$profile" == "lnvo" ]]; then
                validate_lnvo_profile
            elif [[ "$profile" == "asus" ]]; then
                validate_asus_profile
            fi
            
            echo ""
        done
    else
        # Validate specific profile
        if ! validate_profile_name "$target_profile"; then
            show_usage
            exit 1
        fi
        
        validate_profile_structure "$target_profile"
        
        if [[ "$target_profile" == "lnvo" ]]; then
            validate_lnvo_profile
        elif [[ "$target_profile" == "asus" ]]; then
            validate_asus_profile
        fi
        
        echo ""
    fi
    
    # Validate common components
    validate_profile_scripts
    echo ""
    validate_ci_integration
    echo ""
    
    # Summary
    echo "=========================================="
    echo "Validation Summary"
    echo "=========================================="
    
    if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
        log_success "All validations passed!"
        echo ""
        echo "The profile configuration is ready for building."
        exit 0
    elif [[ $ERRORS -eq 0 ]]; then
        log_warning "$WARNINGS warning(s) found (non-critical)"
        echo ""
        echo "Profile configuration is functional but could be improved."
        exit 0
    else
        log_error "$ERRORS error(s) found"
        if [[ $WARNINGS -gt 0 ]]; then
            log_warning "$WARNINGS warning(s) found"
        fi
        echo ""
        echo "Please fix the errors above before building."
        exit 1
    fi
}

main "$@"
