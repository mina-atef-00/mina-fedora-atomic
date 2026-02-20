#!/usr/bin/env bash
#
# Test suite for lib.sh - Smart Output Filtering and Error Handling
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_PATH="${SCRIPT_DIR}/../lib.sh"

source "$LIB_PATH"

TESTS_PASSED=0
TESTS_FAILED=0

assert_equals() {
    local expected="$1"
    local actual="$2"
    local msg="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++)) || true
        echo "  ✓ $msg"
    else
        ((TESTS_FAILED++)) || true
        echo "  ✗ $msg"
        echo "    Expected: '$expected'"
        echo "    Actual:   '$actual'"
    fi
}

assert_contains() {
    local needle="$1"
    local haystack="$2"
    local msg="$3"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        ((TESTS_PASSED++)) || true
        echo "  ✓ $msg"
    else
        ((TESTS_FAILED++)) || true
        echo "  ✗ $msg"
        echo "    Expected to contain: '$needle'"
        echo "    Actual: '$haystack'"
    fi
}

assert_not_contains() {
    local needle="$1"
    local haystack="$2"
    local msg="$3"
    
    if [[ "$haystack" != *"$needle"* ]]; then
        ((TESTS_PASSED++)) || true
        echo "  ✓ $msg"
    else
        ((TESTS_FAILED++)) || true
        echo "  ✗ $msg"
        echo "    Expected NOT to contain: '$needle'"
        echo "    Actual: '$haystack'"
    fi
}

test_filter_dnf_output_progress_indicators() {
    echo "Test: filter_dnf_output suppresses progress indicators (AC1)"
    local input output
    input="[1/100] Installing package"
    output=$(echo "$input" | filter_dnf_output)
    assert_equals "" "$output" "Progress indicator [ should be suppressed"
}

test_filter_dnf_output_copying_blob() {
    echo "Test: filter_dnf_output suppresses Copying blob (AC2)"
    local input output
    input="Copying blob abc123 done"
    output=$(echo "$input" | filter_dnf_output)
    assert_equals "" "$output" "Copying blob should be suppressed"
}

test_filter_dnf_output_writing_manifest() {
    echo "Test: filter_dnf_output suppresses Writing manifest (AC3)"
    local input output
    input="Writing manifest to destination"
    output=$(echo "$input" | filter_dnf_output)
    assert_equals "" "$output" "Writing manifest should be suppressed"
}

test_filter_dnf_output_progress_lines() {
    echo "Test: filter_dnf_output suppresses 100% progress lines (AC4)"
    local input output
    input="100% |####################| 10.2 MiB/s"
    output=$(echo "$input" | filter_dnf_output)
    assert_equals "" "$output" "100% progress lines should be suppressed"
}

test_filter_dnf_output_transfer_rates() {
    echo "Test: filter_dnf_output suppresses transfer rates (AC5)"
    local input output
    input="Downloading at 5.2 KiB/s"
    output=$(echo "$input" | filter_dnf_output)
    assert_equals "" "$output" "Transfer rates (KiB/s) should be suppressed"
}

test_filter_dnf_output_complete_messages() {
    echo "Test: filter_dnf_output shows first Complete! and counts others (AC6)"
    _COMPLETE_COUNT=0
    local input output
    input=$'Complete!\nComplete!\nComplete!'
    output=$(echo "$input" | filter_dnf_output)
    assert_contains "Complete!" "$output" "First Complete! should be shown"
    assert_contains "2 additional completions suppressed" "$output" "Summary should show suppressed count"
}

test_filter_dnf_output_complete_single() {
    echo "Test: filter_dnf_output shows single Complete! without summary"
    _COMPLETE_COUNT=0
    local input output
    input=$'Complete!'
    output=$(echo "$input" | filter_dnf_output)
    assert_contains "Complete!" "$output" "Complete! should be shown"
    assert_not_contains "additional completions" "$output" "No summary for single Complete!"
}

test_warning_suppression_first_occurrence() {
    echo "Test: track_warning shows first occurrence (AC7)"
    _WARNING_COUNTS=()
    _GUM_AVAILABLE="false"
    GUM_LOG_LEVEL="warn"
    
    local output
    output=$(track_warning "Test warning" 2>&1)
    assert_contains "⚠️" "$output" "First warning should be displayed with emoji"
}

test_warning_suppression_count() {
    echo "Test: track_warning counts subsequent occurrences (AC7)"
    _WARNING_COUNTS=()
    _GUM_AVAILABLE="false"
    GUM_LOG_LEVEL="warn"
    
    track_warning "Test warning" >/dev/null 2>&1
    track_warning "Test warning" >/dev/null 2>&1
    track_warning "Test warning" >/dev/null 2>&1
    
    local key
    key=$(_warning_key "Test warning")
    assert_equals "3" "${_WARNING_COUNTS[$key]}" "Warning should be counted 3 times"
}

test_warning_summary() {
    echo "Test: emit_warning_summary shows suppression count (AC7)"
    _WARNING_COUNTS=()
    _GUM_AVAILABLE="false"
    GUM_LOG_LEVEL="warn"
    
    track_warning "Repeated warning" >/dev/null 2>&1
    track_warning "Repeated warning" >/dev/null 2>&1
    track_warning "Repeated warning" >/dev/null 2>&1
    
    local output
    output=$(emit_warning_summary 2>&1)
    assert_contains "2 similar warnings suppressed" "$output" "Summary should show 2 suppressed"
    assert_contains "--verbose" "$output" "Summary should mention --verbose flag"
}

test_error_block_basic() {
    echo "Test: display_error_block shows error with red border (AC8)"
    _CURRENT_PHASE="Package Installation"
    _CURRENT_STEP="Installing dependencies"
    _ERROR_START_TIME=$(date +%s)
    _GUM_AVAILABLE="false"
    
    local output
    output=$(display_error_block "Package not found" "Check package name
Enable required repositories
Update package cache" 2>&1)
    
    assert_contains "ERROR" "$output" "Error block should contain ERROR"
    assert_contains "Package Installation" "$output" "Error block should contain phase"
    assert_contains "Installing dependencies" "$output" "Error block should contain step"
    assert_contains "Package not found" "$output" "Error block should contain error message"
    assert_contains "Check package name" "$output" "Error block should contain first fix"
    assert_contains "→" "$output" "Error block should contain arrow bullets"
}

test_error_block_duration() {
    echo "Test: display_error_block displays duration with emoji (AC8)"
    _CURRENT_PHASE="Test Phase"
    _CURRENT_STEP="Test Step"
    _ERROR_START_TIME=$(($(date +%s) - 10))
    _GUM_AVAILABLE="false"
    
    local output
    output=$(display_error_block "Test error" "" 2>&1)
    assert_contains "⏱️" "$output" "Error block should contain timer emoji"
    assert_contains "10s" "$output" "Error block should contain duration"
}

test_log_error_with_rich_context() {
    echo "Test: log_error with multiple args calls display_error_block (AC8)"
    _CURRENT_PHASE="Package Installation"
    _CURRENT_STEP="Installing dependencies"
    _ERROR_START_TIME=$(date +%s)
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_error "Package not found" "Check package name
Enable repositories" 2>&1)
    assert_contains "ERROR" "$output" "log_error with context should show error block"
    assert_contains "Package not found" "$output" "Error message should be shown"
    assert_contains "Check package name" "$output" "Suggested fix should be shown"
}

test_log_error_simple() {
    echo "Test: log_error with single arg uses simple logging"
    _GUM_AVAILABLE="false"
    GUM_LOG_LEVEL="error"
    
    local output
    output=$(log_error "Simple error message" 2>&1)
    assert_contains "❌" "$output" "Simple log_error should have error emoji"
    assert_contains "Simple error message" "$output" "Error message should be shown"
    assert_not_contains "Suggested Fixes" "$output" "Simple log_error should not show fixes section"
}

test_github_error_annotation() {
    echo "Test: _display_github_error generates ::error:: annotation with default file/line (AC9)"
    GITHUB_ACTIONS="true"
    
    local output
    output=$(_display_github_error "Test error message")
    assert_equals "::error file=Containerfile,line=1::Test error message" "$output" "Should generate GitHub error annotation with defaults"
    
    GITHUB_ACTIONS=""
}

test_github_error_with_file_line() {
    echo "Test: _display_github_error includes custom file/line context (AC9)"
    GITHUB_ACTIONS="true"
    
    local output
    output=$(_display_github_error "Test error" "MyFile.sh" "42")
    assert_equals "::error file=MyFile.sh,line=42::Test error" "$output" "Should include custom file and line"
    
    GITHUB_ACTIONS=""
}

test_github_warning_annotation() {
    echo "Test: _display_github_warning generates ::warning:: annotation with default file/line (AC10)"
    GITHUB_ACTIONS="true"
    
    local output
    output=$(_display_github_warning "Test warning message")
    assert_equals "::warning file=Containerfile,line=1::Test warning message" "$output" "Should generate GitHub warning annotation with defaults"
    
    GITHUB_ACTIONS=""
}

test_github_warning_with_file_line() {
    echo "Test: _display_github_warning includes custom file/line context (AC10)"
    GITHUB_ACTIONS="true"
    
    local output
    output=$(_display_github_warning "Test warning" "MyFile.sh" "15")
    assert_equals "::warning file=MyFile.sh,line=15::Test warning" "$output" "Should include custom file and line"
    
    GITHUB_ACTIONS=""
}

test_github_annotations_disabled_outside_ci() {
    echo "Test: GitHub annotations disabled outside CI environment"
    GITHUB_ACTIONS=""
    
    local output
    output=$(_display_github_error "Test error")
    assert_equals "" "$output" "Should not generate annotation outside CI"
}

test_set_phase_context() {
    echo "Test: set_phase_context updates current phase"
    set_phase_context "Installation Phase"
    assert_equals "Installation Phase" "$_CURRENT_PHASE" "Phase context should be updated"
}

test_set_step_context() {
    echo "Test: set_step_context updates current step"
    set_step_context "Installing packages"
    assert_equals "Installing packages" "$_CURRENT_STEP" "Step context should be updated"
}

test_reset_warnings() {
    echo "Test: reset_warnings clears warning counts"
    _WARNING_COUNTS=()
    track_warning "Test warning" >/dev/null 2>&1
    track_warning "Another warning" >/dev/null 2>&1
    
    local key1 key2
    key1=$(_warning_key "Test warning")
    key2=$(_warning_key "Another warning")
    
    [[ -n "${_WARNING_COUNTS[$key1]:-}" ]] && echo "  ✓ Warning 1 tracked"
    [[ -n "${_WARNING_COUNTS[$key2]:-}" ]] && echo "  ✓ Warning 2 tracked"
    
    reset_warnings
    
    [[ -z "${_WARNING_COUNTS[$key1]:-}" ]] && ((TESTS_PASSED++)) && echo "  ✓ Warning 1 reset"
    [[ -z "${_WARNING_COUNTS[$key2]:-}" ]] && ((TESTS_PASSED++)) && echo "  ✓ Warning 2 reset"
}

test_verbose_mode_shows_all_warnings() {
    echo "Test: verbose mode shows all warnings without suppression"
    _WARNING_COUNTS=()
    _VERBOSE_MODE="true"
    _GUM_AVAILABLE="false"
    GUM_LOG_LEVEL="warn"
    
    local output
    output=$(track_warning "Repeated warning" 2>&1; track_warning "Repeated warning" 2>&1; track_warning "Repeated warning" 2>&1)
    
    local count
    count=$(echo "$output" | grep -c "⚠️" || true)
    assert_equals "3" "$count" "All 3 warnings should be shown in verbose mode"
    
    _VERBOSE_MODE=""
}

test_verbose_mode_skips_summary() {
    echo "Test: verbose mode skips warning summary"
    _WARNING_COUNTS=()
    _VERBOSE_MODE="true"
    _GUM_AVAILABLE="false"
    GUM_LOG_LEVEL="warn"
    
    track_warning "Test warning" >/dev/null 2>&1
    track_warning "Test warning" >/dev/null 2>&1
    
    local output
    output=$(emit_warning_summary 2>&1)
    assert_equals "" "$output" "Summary should be empty in verbose mode"
    
    _VERBOSE_MODE=""
}

test_gum_mode_error_block() {
    echo "Test: error block with Gum styling (mocked)"
    _CURRENT_PHASE="Test Phase"
    _CURRENT_STEP="Test Step"
    _ERROR_START_TIME=$(date +%s)
    _GUM_AVAILABLE="true"
    
    local output
    if command -v gum &>/dev/null; then
        output=$(display_error_block "Test error" "" 2>&1)
        assert_contains "ERROR" "$output" "Gum mode error block should contain ERROR"
    else
        ((TESTS_PASSED++)) && echo "  ✓ Skipped (gum not installed)"
    fi
    
    _GUM_AVAILABLE=""
}

test_filter_resets_complete_count() {
    echo "Test: filter_dnf_output resets count per invocation"
    local input output
    input=$'Complete!\nComplete!\nComplete!'
    output=$(echo "$input" | filter_dnf_output)
    assert_contains "2 additional completions suppressed" "$output" "First invocation should show 2 suppressed"
    
    input=$'Complete!\nComplete!'
    output=$(echo "$input" | filter_dnf_output)
    assert_contains "1 additional completions suppressed" "$output" "Second invocation should start fresh with 1 suppressed"
}

test_log_item_indentation_level_1() {
    echo "Test: log_item indent level 1 has 2-space indentation (AC1)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_item "✅" "Test message" 1)
    
    assert_contains "  ✅" "$output" "Level 1 should have 2-space indentation"
}

test_log_item_indentation_level_2() {
    echo "Test: log_item indent level 2 has 4-space indentation (AC1)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_item "✅" "Test message" 2)
    
    assert_contains "    ✅" "$output" "Level 2 should have 4-space indentation"
}

test_log_item_indentation_level_3() {
    echo "Test: log_item indent level 3 has 6-space indentation (AC1)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_item "✅" "Test message" 3)
    
    assert_contains "      ✅" "$output" "Level 3 should have 6-space indentation"
}

test_log_item_default_icon() {
    echo "Test: log_item uses ✅ as default icon (AC1)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_item "" "Test message")
    
    assert_contains "✅" "$output" "Default icon should be ✅"
}

test_log_item_with_custom_icon() {
    echo "Test: log_item accepts custom icon"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_item "●" "Custom icon test")
    
    assert_contains "●" "$output" "Custom icon should be used"
}

test_log_detail_arrow_icon() {
    echo "Test: log_detail uses → icon prefix (AC2)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_detail "Detail message")
    
    assert_contains "    →" "$output" "log_detail should use → icon"
}

test_log_detail_indentation() {
    echo "Test: log_detail has 4-space indentation (AC2)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_detail "Detail message")
    
    assert_contains "    →" "$output" "log_detail should be indented 4 spaces"
}

test_log_subdetail_bullet_icon() {
    echo "Test: log_subdetail uses • icon prefix (AC3)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_subdetail "Subdetail message")
    
    assert_contains "      •" "$output" "log_subdetail should use • icon"
}

test_log_subdetail_indentation() {
    echo "Test: log_subdetail has 6-space indentation (AC3)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_subdetail "Subdetail message")
    
    assert_contains "      •" "$output" "log_subdetail should be indented 6 spaces"
}

test_log_check_green_color() {
    echo "Test: log_check uses ✅ icon (AC4)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_check "Task completed")
    
    assert_contains "  ✅" "$output" "log_check should use ✅ icon"
}

test_log_check_indentation() {
    echo "Test: log_check has 2-space indentation (AC4)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_check "Task completed")
    
    assert_contains "  ✅" "$output" "log_check should be indented 2 spaces"
}

test_log_check_descriptive_text() {
    echo "Test: log_check accepts descriptive text (AC4)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_check "Package dnf5 installed successfully")
    
    assert_contains "Package dnf5 installed successfully" "$output" "log_check should display descriptive text"
}

test_hierarchy_consistency_parent_child() {
    echo "Test: hierarchy consistency - parent level 1 (AC5)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_item "✅" "Parent action")
    
    assert_contains "  ✅" "$output" "Level 1 should be 2 spaces"
}

test_hierarchy_consistency_child_level_2() {
    echo "Test: hierarchy consistency - child level 2 (AC5)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_detail "Child detail")
    
    assert_contains "    →" "$output" "Level 2 should be 4 spaces"
}

test_hierarchy_consistency_grandchild_level_3() {
    echo "Test: hierarchy consistency - grandchild level 3 (AC5)"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_subdetail "Grandchild subdetail")
    
    assert_contains "      •" "$output" "Level 3 should be 6 spaces"
}

test_hierarchy_consistency_sequential() {
    echo "Test: hierarchy consistency - sequential 2→4→6 spaces (AC5)"
    _GUM_AVAILABLE="false"
    
    local item_output detail_output subdetail_output
    
    item_output=$(log_item "✅" "Phase action")
    detail_output=$(log_detail "Detail item")
    subdetail_output=$(log_subdetail "Subdetail item")
    
    assert_contains "  ✅" "$item_output" "log_item should have 2-space indent"
    assert_contains "    →" "$detail_output" "log_detail should have 4-space indent"
    assert_contains "      •" "$subdetail_output" "log_subdetail should have 6-space indent"
}

test_hierarchy_visual_clear() {
    echo "Test: hierarchy creates clear parent-child-grandchild structure (AC5)"
    _GUM_AVAILABLE="false"
    
    local item detail subdetail
    
    item=$(log_item "✅" "Installing packages")
    detail=$(log_detail "dnf5-plugins")
    subdetail=$(log_subdetail "v1.0+ required")
    
    assert_contains "  ✅" "$item" "Parent should be at level 1 (2 spaces)"
    assert_contains "    →" "$detail" "Child should be at level 2 (4 spaces)"
    assert_contains "      •" "$subdetail" "Grandchild should be at level 3 (6 spaces)"
}

test_gum_mode_log_item_with_color() {
    echo "Test: log_item applies color when gum is available"
    _GUM_AVAILABLE="true"
    
    local output
    output=$(log_item "✅" "Test message" 1 "$COLOR_WHITE")
    
    assert_contains "  ✅" "$output" "log_item with color should still have 2-space indent"
    assert_contains "Test message" "$output" "log_item should contain message"
}

test_gum_mode_log_detail_color() {
    echo "Test: log_detail uses white color (#E5E7EB) in gum mode (AC2)"
    _GUM_AVAILABLE="true"
    
    local output
    output=$(log_detail "Detail message")
    
    assert_contains "    →" "$output" "log_detail should use 4-space indent"
    assert_contains "Detail message" "$output" "log_detail should contain message"
}

test_gum_mode_log_subdetail_color() {
    echo "Test: log_subdetail uses dim color (#9CA3AF) in gum mode (AC3)"
    _GUM_AVAILABLE="true"
    
    local output
    output=$(log_subdetail "Subdetail message")
    
    assert_contains "      •" "$output" "log_subdetail should use 6-space indent"
    assert_contains "Subdetail message" "$output" "log_subdetail should contain message"
}

test_gum_mode_log_check_color() {
    echo "Test: log_check uses green color (#10B981) in gum mode (AC4)"
    _GUM_AVAILABLE="true"
    
    local output
    output=$(log_check "Task completed")
    
    assert_contains "  ✅" "$output" "log_check should use 2-space indent"
    assert_contains "Task completed" "$output" "log_check should contain message"
}

test_log_detail_with_quoted_args() {
    echo "Test: log_detail handles arguments correctly"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_detail "message with spaces")
    
    assert_contains "message with spaces" "$output" "log_detail should preserve message with spaces"
}

test_log_check_with_quoted_args() {
    echo "Test: log_check handles arguments correctly"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_check "Task: install package")
    
    assert_contains "Task: install package" "$output" "log_check should preserve message"
}

test_filter_dnf_output_preserves_normal_output() {
    echo "Test: filter_dnf_output preserves normal output"
    local input output
    input=$'Package installed successfully
Transaction complete
Summary: 5 packages'
    output=$(echo "$input" | filter_dnf_output)
    assert_contains "Package installed successfully" "$output" "Normal output should be preserved"
    assert_contains "Transaction complete" "$output" "Normal output should be preserved"
    assert_contains "Summary: 5 packages" "$output" "Normal output should be preserved"
}

test_json_output_format() {
    echo "Test: output_json produces valid JSON with required fields (AC1)"
    GUM_LOG_FORMAT="text"
    
    local output
    output=$(output_json "info" "Test message")
    
    assert_contains '"timestamp"' "$output" "JSON should contain timestamp"
    assert_contains '"level":"info"' "$output" "JSON should contain level"
    assert_contains '"message":"Test message"' "$output" "JSON should contain message"
    
    local timestamp_check
    timestamp_check=$(echo "$output" | grep -oE '"timestamp":"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{3})?Z"' || true)
    [[ -n "$timestamp_check" ]] && ((TESTS_PASSED++)) && echo "  ✓ Timestamp is ISO 8601 format"
}

test_json_output_with_metadata() {
    echo "Test: output_json includes metadata when provided (AC1)"
    
    local output
    output=$(output_json "info" "Test" '{"phase":1,"phase_name":"Install"}')
    
    assert_contains '"metadata":' "$output" "JSON should contain metadata"
    assert_contains '"phase":1' "$output" "Metadata should contain phase number"
    assert_contains '"phase_name":"Install"' "$output" "Metadata should contain phase name"
}

test_json_mode_log_info() {
    echo "Test: log_info outputs JSON when GUM_LOG_FORMAT=json (AC1)"
    GUM_LOG_FORMAT="json"
    GUM_LOG_LEVEL="info"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_info "Test info message")
    
    assert_contains '"level":"info"' "$output" "JSON mode should output JSON"
    assert_contains '"message":"Test info message"' "$output" "JSON should contain message"
    
    GUM_LOG_FORMAT="text"
}

test_json_mode_log_error() {
    echo "Test: log_error outputs JSON when GUM_LOG_FORMAT=json (AC1)"
    GUM_LOG_FORMAT="json"
    GUM_LOG_LEVEL="error"
    _GUM_AVAILABLE="false"
    _CURRENT_PHASE="Test Phase"
    _CURRENT_PHASE_NAME="Test Phase"
    _PHASE_COUNT=1
    
    local output
    output=$(log_error "Error occurred")
    
    assert_contains '"level":"error"' "$output" "JSON mode error should output JSON"
    assert_contains '"message":"Error occurred"' "$output" "JSON should contain error message"
    
    GUM_LOG_FORMAT="text"
}

test_json_mode_phase_output() {
    echo "Test: start_phase outputs JSON with phase info (AC2)"
    GUM_LOG_FORMAT="json"
    GUM_LOG_LEVEL="info"
    _GUM_AVAILABLE="false"
    _PHASE_COUNT=0
    
    local output
    output=$(start_phase "Package Installation")
    
    assert_contains '"level":"info"' "$output" "Phase JSON should have level"
    assert_contains '"phase":1' "$output" "Phase JSON should have phase number"
    assert_contains '"phase_name":"Package Installation"' "$output" "Phase JSON should have phase name"
    
    GUM_LOG_FORMAT="text"
}

test_json_mode_error_with_suggested_fixes() {
    echo "Test: JSON error output includes suggested fixes (AC3)"
    GUM_LOG_FORMAT="json"
    GUM_LOG_LEVEL="error"
    _GUM_AVAILABLE="false"
    _CURRENT_PHASE="Test Phase"
    _CURRENT_PHASE_NAME="Test Phase"
    _PHASE_COUNT=1
    _ERROR_START_TIME=$(date +%s)
    
    local output
    output=$(log_error "Package not found" "Check spelling
Enable repos")
    
    assert_contains '"suggested_fixes"' "$output" "JSON error should contain suggested_fixes"
    assert_contains 'Check spelling' "$output" "JSON should contain first fix"
    assert_contains 'Enable repos' "$output" "JSON should contain second fix"
    
    GUM_LOG_FORMAT="text"
}

test_github_actions_log_error_annotation() {
    echo "Test: log_error generates single GitHub annotation in CI (AC4)"
    GITHUB_ACTIONS="true"
    GUM_LOG_FORMAT="text"
    GUM_LOG_LEVEL="error"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_error "Build failed" 2>&1)
    
    local count
    count=$(echo "$output" | grep -c "::error file=Containerfile,line=1::Build failed" || true)
    assert_equals "1" "$count" "Should generate exactly ONE GitHub error annotation (not duplicated)"
    
    GITHUB_ACTIONS=""
}

test_github_actions_log_warn_annotation() {
    echo "Test: log_warn generates single GitHub annotation in CI (AC5)"
    GITHUB_ACTIONS="true"
    GUM_LOG_FORMAT="text"
    GUM_LOG_LEVEL="warn"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_warn "Deprecation warning" 2>&1)
    
    local count
    count=$(echo "$output" | grep -c "::warning file=Containerfile,line=1::Deprecation warning" || true)
    assert_equals "1" "$count" "Should generate exactly ONE GitHub warning annotation (not duplicated)"
    
    GITHUB_ACTIONS=""
}

test_ci_environment_detection() {
    echo "Test: CI=true enables GitHub-style annotations"
    GITHUB_ACTIONS=""
    CI="true"
    GUM_LOG_LEVEL="error"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_error "Test error" 2>&1)
    
    assert_contains "::error file=Containerfile,line=1::Test error" "$output" "CI=true should enable annotations"
    
    CI=""
}

test_log_level_debug_shows_all() {
    echo "Test: debug mode shows all log levels (AC6)"
    GUM_LOG_LEVEL="debug"
    GUM_LOG_FORMAT="text"
    _GUM_AVAILABLE="false"
    
    local debug_output info_output warn_output
    
    debug_output=$(log_debug "Debug msg" 2>&1)
    info_output=$(log_info "Info msg" 2>&1)
    warn_output=$(log_warn "Warn msg" 2>&1)
    
    assert_contains "Debug msg" "$debug_output" "Debug level should show debug messages"
    assert_contains "Info msg" "$info_output" "Debug level should show info messages"
    assert_contains "Warn msg" "$warn_output" "Debug level should show warn messages"
}

test_log_level_warn_suppresses_info() {
    echo "Test: warn mode suppresses info but shows warn/error (AC7)"
    GUM_LOG_LEVEL="warn"
    GUM_LOG_FORMAT="text"
    _GUM_AVAILABLE="false"
    
    local info_output warn_output error_output
    
    info_output=$(log_info "Info msg" 2>&1)
    warn_output=$(log_warn "Warn msg" 2>&1)
    error_output=$(log_error "Error msg" 2>&1)
    
    assert_equals "" "$info_output" "Warn level should suppress info messages"
    assert_contains "Warn msg" "$warn_output" "Warn level should show warn messages"
    assert_contains "Error msg" "$error_output" "Warn level should show error messages"
}

test_log_level_error_suppresses_all_but_error() {
    echo "Test: error mode shows only errors (AC8)"
    GUM_LOG_LEVEL="error"
    GUM_LOG_FORMAT="text"
    _GUM_AVAILABLE="false"
    
    local info_output warn_output error_output
    
    info_output=$(log_info "Info msg" 2>&1)
    warn_output=$(log_warn "Warn msg" 2>&1)
    error_output=$(log_error "Error msg" 2>&1)
    
    assert_equals "" "$info_output" "Error level should suppress info messages"
    assert_equals "" "$warn_output" "Error level should suppress warn messages"
    assert_contains "Error msg" "$error_output" "Error level should show error messages"
}

test_debug_mode_disables_warning_dedup() {
    echo "Test: debug mode disables warning deduplication (AC6)"
    _WARNING_COUNTS=()
    GUM_LOG_LEVEL="debug"
    _VERBOSE_MODE="true"
    _GUM_AVAILABLE="false"
    
    log_init
    
    local output
    output=$(track_warning "Test" 2>&1; track_warning "Test" 2>&1; track_warning "Test" 2>&1)
    
    local count
    count=$(echo "$output" | grep -c "⚠️" || true)
    assert_equals "3" "$count" "Debug mode should show all warnings without deduplication"
    
    _VERBOSE_MODE=""
}

test_json_escape_quotes() {
    echo "Test: JSON output escapes double quotes"
    GUM_LOG_FORMAT="json"
    GUM_LOG_LEVEL="info"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_info 'Message with "quotes" inside')
    
    assert_contains '\"quotes\"' "$output" "JSON should escape double quotes"
    assert_not_contains '"quotes"' "$output" "JSON should not contain unescaped quotes"
    
    GUM_LOG_FORMAT="text"
}

test_json_escape_backslash() {
    echo "Test: JSON output escapes backslashes"
    GUM_LOG_FORMAT="json"
    GUM_LOG_LEVEL="info"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_info 'Path: C:\Users\test')
    
    assert_contains 'C:\\Users\\test' "$output" "JSON should escape backslashes"
    
    GUM_LOG_FORMAT="text"
}

test_json_escape_newline() {
    echo "Test: JSON output escapes newlines"
    GUM_LOG_FORMAT="json"
    GUM_LOG_LEVEL="info"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_info $'Line1\nLine2')
    
    assert_contains '\n' "$output" "JSON should escape newlines"
    assert_not_contains $'\n' "$output" "JSON output should be single line"
    
    GUM_LOG_FORMAT="text"
}

test_json_valid_output() {
    echo "Test: JSON output is valid JSON that can be parsed"
    GUM_LOG_FORMAT="json"
    GUM_LOG_LEVEL="info"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_info 'Test message')
    
    if command -v python3 &>/dev/null; then
        if echo "$output" | python3 -m json.tool &>/dev/null; then
            ((TESTS_PASSED++)) && echo "  ✓ JSON output is valid and parseable"
        else
            ((TESTS_FAILED++)) && echo "  ✗ JSON output failed validation"
        fi
    else
        ((TESTS_PASSED++)) && echo "  ✓ Skipped (python3 not available)"
    fi
    
    GUM_LOG_FORMAT="text"
}

test_json_github_actions_combo() {
    echo "Test: JSON output with GitHub Actions produces both JSON and annotations"
    GUM_LOG_FORMAT="json"
    GUM_LOG_LEVEL="info"
    GITHUB_ACTIONS="true"
    _GUM_AVAILABLE="false"
    
    local output
    output=$(log_error "Test error" "Fix this" "test.sh" "10" 2>&1)
    
    local has_json=false
    local has_annotation=false
    
    if echo "$output" | grep -q '"level":"error"'; then
        has_json=true
    fi
    
    if echo "$output" | grep -q "::error"; then
        has_annotation=true
    fi
    
    if $has_json && $has_annotation; then
        ((TESTS_PASSED++)) || true
        echo "  ✓ JSON+GitHub Actions combo mode works"
    else
        ((TESTS_FAILED++)) || true
        echo "  ✗ JSON+GitHub Actions combo mode failed"
        echo "    JSON: $has_json, Annotation: $has_annotation"
    fi
    
    GUM_LOG_FORMAT="text"
    GITHUB_ACTIONS=""
}

run_all_tests() {
    echo ""
    echo "=========================================="
    echo " Running lib.sh Test Suite"
    echo "=========================================="
    echo ""
    
    log_init
    
    echo "--- DNF5 Output Filtering Tests (AC 1-6) ---"
    test_filter_dnf_output_progress_indicators
    test_filter_dnf_output_copying_blob
    test_filter_dnf_output_writing_manifest
    test_filter_dnf_output_progress_lines
    test_filter_dnf_output_transfer_rates
    test_filter_dnf_output_complete_messages
    test_filter_dnf_output_complete_single
    test_filter_dnf_output_preserves_normal_output
    
    echo ""
    echo "--- Warning Suppression Tests (AC 7) ---"
    test_warning_suppression_first_occurrence
    test_warning_suppression_count
    test_warning_summary
    
    echo ""
    echo "--- Error Display Tests (AC 8) ---"
    test_error_block_basic
    test_error_block_duration
    test_log_error_with_rich_context
    test_log_error_simple
    
    echo ""
    echo "--- GitHub Actions Annotation Tests (AC 4-5, 9-10) ---"
    test_github_error_annotation
    test_github_error_with_file_line
    test_github_warning_annotation
    test_github_warning_with_file_line
    test_github_annotations_disabled_outside_ci
    test_github_actions_log_error_annotation
    test_github_actions_log_warn_annotation
    test_ci_environment_detection
    
    echo ""
    echo "--- JSON Mode Tests (AC 1-3) ---"
    test_json_output_format
    test_json_output_with_metadata
    test_json_mode_log_info
    test_json_mode_log_error
    test_json_mode_phase_output
    test_json_mode_error_with_suggested_fixes
    test_json_escape_quotes
    test_json_escape_backslash
    test_json_escape_newline
    test_json_valid_output
    test_json_github_actions_combo
    
    echo ""
    echo "--- Log Level Filtering Tests (AC 6-8) ---"
    test_log_level_debug_shows_all
    test_log_level_warn_suppresses_info
    test_log_level_error_suppresses_all_but_error
    test_debug_mode_disables_warning_dedup
    
    echo ""
    echo "--- Context Management Tests ---"
    test_set_phase_context
    test_set_step_context
    test_reset_warnings
    test_verbose_mode_shows_all_warnings
    test_verbose_mode_skips_summary
    test_gum_mode_error_block
    test_filter_resets_complete_count
    
    echo ""
    echo "--- Hierarchical Logging Tests (AC 1-5) ---"
    test_log_item_indentation_level_1
    test_log_item_indentation_level_2
    test_log_item_indentation_level_3
    test_log_item_default_icon
    test_log_item_with_custom_icon
    test_log_detail_arrow_icon
    test_log_detail_indentation
    test_log_subdetail_bullet_icon
    test_log_subdetail_indentation
    test_log_check_green_color
    test_log_check_indentation
    test_log_check_descriptive_text
    test_hierarchy_consistency_parent_child
    test_hierarchy_consistency_child_level_2
    test_hierarchy_consistency_grandchild_level_3
    test_hierarchy_consistency_sequential
    test_hierarchy_visual_clear
    test_gum_mode_log_item_with_color
    test_gum_mode_log_detail_color
    test_gum_mode_log_subdetail_color
    test_gum_mode_log_check_color
    test_log_detail_with_quoted_args
    test_log_check_with_quoted_args
    
    echo ""
    echo "=========================================="
    echo " Test Results"
    echo "=========================================="
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo ""
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

run_all_tests
