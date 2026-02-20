# Story 4.2: Visual Design System Implementation

Status: done

## Story

As a DevOps engineer,
I want logs with consistent colors and emojis,
so that I can quickly scan and understand build status at a glance.

## Acceptance Criteria

1. **Given** a debug message is logged **When** `log_debug()` is called **Then** the message displays in gray (#6B7280) color **And** includes appropriate emoji if applicable

2. **Given** an info message is logged **When** `log_info()` is called **Then** the message displays in blue (#3B82F6) color **And** includes ℹ️ emoji prefix

3. **Given** a warning message is logged **When** `log_warn()` is called **Then** the message displays in amber (#F59E0B) color **And** includes ⚠️ emoji prefix

4. **Given** an error message is logged **When** `log_error()` is called **Then** the message displays in red (#EF4444) color with bold formatting **And** includes ❌ emoji prefix

5. **Given** a success message is logged **When** `log_success()` is called **Then** the message displays in green (#10B981) color with bold formatting **And** includes ✅ emoji prefix

6. **Given** hierarchical logging is used **When** `log_item()`, `log_detail()`, or `log_subdetail()` is called **Then** each level uses appropriate indentation (2, 4, or 6 spaces) **And** uses correct icon (✅, →, or •) for each level

## Tasks / Subtasks

- [x] Implement color palette functions in lib.sh (AC: 1-5)
  - [x] Add color constants with hex codes for all levels
  - [x] `log_debug()` - gray (#6B7280)
  - [x] `log_info()` - blue (#3B82F6) with ℹ️
  - [x] `log_warn()` - amber (#F59E0B) with ⚠️
  - [x] `log_error()` - red (#EF4444) with ❌, bold
  - [x] `log_success()` - green (#10B981) with ✅, bold
- [x] Implement hierarchical logging functions (AC: 6)
  - [x] `log_item()` - 2-space indent, ✅ icon
  - [x] `log_detail()` - 4-space indent, → icon
  - [x] `log_subdetail()` - 6-space indent, • icon
- [x] Ensure fallback colors work without Gum
  - [x] Use ANSI escape codes as fallback

## Dev Notes

### Color Palette (Dark Terminal Optimized)

| Purpose | Hex Code | Usage |
|---------|----------|-------|
| Debug | #6B7280 | `--foreground` for debug messages |
| Info | #3B82F6 | `--foreground` for info messages |
| Warning | #F59E0B | `--foreground` for warnings |
| Error | #EF4444 | `--foreground` and `--border-foreground` |
| Success | #10B981 | `--foreground` for success states |
| Header | #8B5CF6 | `--border-foreground` for header borders |
| Gold | #FBBF24 | timestamps and highlights |
| White | #E5E7EB | body text |
| Dim | #9CA3AF | secondary text |

### Emoji Indicators

| Emoji | Meaning | Context |
|-------|---------|---------|
| 🚀 | Build start | Header block |
| ✅ | Success/check | Completed items |
| ⚠️ | Warning | Warning messages |
| ❌ | Error | Error messages |
| ℹ️ | Info | Informational |
| ▶️ | Phase start | Phase headers |
| → | Detail arrow | Indented details |
| • | Bullet point | Lists |
| ⏱️ | Time/duration | Timestamps |

### Dependencies
- Requires Story 4.1 (core logging functions) to be complete

### References
- PRD: `_bmad-output/planning-artifacts/epic-logging/gum-logging-prd.md` (Section 3.2)

## Dev Agent Record

### Agent Model Used

opencode/glm-5-free

### Debug Log References

- Tested all log level functions with Gum and fallback modes
- Verified color output with debug level enabled
- Confirmed hierarchical indentation matches AC requirements
- Shellcheck validation passed with no warnings

### Completion Notes List

1. Added ANSI_GRAY, ANSI_BLUE, and ANSI_BOLD constants for fallback mode
2. Updated `_log_gum()` to add bold formatting for error and success messages
3. Updated `_log_echo()` to use correct colors: gray for debug, blue for info, bold for error/success
4. Fixed `log_item()` default indent from 4 to 2 spaces to match AC6
5. Removed unused ANSI_CYAN constant
6. All 6 acceptance criteria verified with functional tests

### Code Review Fixes Applied

1. **HIGH-1**: Removed non-spec 🔍 emoji from debug - debug now has no emoji prefix per PRD Table 3.2.2
2. **MED-1**: Added sprint-status.yaml to File List
3. **MED-2**: Added comments documenting ANSI color approximations
4. **MED-3**: Added `GUM_NO_EMOJI` environment variable for non-Unicode CI environments

### File List

- `files/scripts/lib.sh` (modified)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified)

## Change Log

- 2026-02-20: Implemented visual design system with color palette, bold formatting for error/success, and hierarchical logging indentation
- 2026-02-20: Code review fixes - removed non-spec emoji, added GUM_NO_EMOJI support, documented ANSI approximations
